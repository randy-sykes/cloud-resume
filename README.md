# Cloud Resume
Working on [The Cloud Challenge](https://cloudresumechallenge.dev/docs/the-challenge/aws/) with my resume



## Static Site Hosting

**S3**
- Bucket is private — no public bucket policy, no S3 static website hosting endpoint exposed. Only CloudFront can read from it, via Origin Access Control (OAC)
- Hosts `frontend/index.html`, `frontend/style.css`, `frontend/script.js`, and `frontend/assets/`

**CloudFront**
- Serves the site over HTTPS in front of the private S3 bucket
- Certificate issued through ACM in `us-east-1` — the only region CloudFront will accept a certificate from, regardless of where other resources live

**DNS (Cloudflare, not Route 53)**
- `randy-sykes.me` was already managed in Cloudflare before this project started, so DNS stayed there instead of moving to Route 53
- Two records point at the CloudFront distribution: `@` (apex) and `www`, both set to **DNS-only** (grey-clouded) — Cloudflare just resolves them straight to CloudFront rather than proxying, so CloudFront (with its ACM cert) is the only TLS termination point in the request path
- Other records/subdomains on the same zone proxy elsewhere and aren't part of this project

**HTML/CSS**
- Hand-written, no frameworks — `frontend/index.html` + `frontend/style.css`
- Mobile responsiveness (collapsing nav, typewriter text scaling on narrow viewports) implemented with CSS media queries. The nav's open/close behavior itself is a JS-toggled hamburger button (`script.js`) rather than a CSS-only checkbox toggle, since closing the menu automatically after a link click was simpler to express in JS

## Lambda Info

### Visitor Counter Architecture

The visitor counter tracks unique visitors (not page views/refreshes) using a DynamoDB table, a Lambda function, and an API Gateway REST API, called from the frontend via `fetch`.

**DynamoDB**
- Table: `cloud-resume-visitors`
- Partition key: `id` (String), no sort key — single-item table, one row (`id: "visitor_count"`) holds the running total
- Billing mode: On-demand (pay-per-request) — traffic is low/unpredictable, stays in the free tier
- Counts are updated with an `UpdateItem` `ADD` expression (atomic increment), not a read-then-write, to avoid race conditions under concurrent visits

**Lambda** (`backend/lambda/cloud_resume_visitors/lambda_function.py`)
- Python, handler `lambda_function.lambda_handler`
- Branches on `event['httpMethod']`: `GET` reads the count without incrementing, anything else (`POST`) increments it
- Execution role has an inline policy scoped to just `dynamodb:GetItem` / `dynamodb:UpdateItem` on the table's ARN — not full DynamoDB access
- Handles two edge cases explicitly: the item not existing yet (`GET` returns `count: 0` instead of erroring) and DynamoDB being unreachable (`ClientError` returns a `500` with an error body, still with CORS headers, instead of crashing unhandled and losing those headers)

**API Gateway**
- REST API, **Regional** endpoint type (not Private — a Private endpoint would only be reachable from inside a VPC, not from a visitor's browser; not Edge-optimized — no benefit here since the static site already has its own CloudFront distribution)
- `/count` resource with `GET` and `POST` methods, both using **Lambda proxy integration**
- CORS enabled on the resource, `Access-Control-Allow-Origin` locked to `https://randy-sykes.me`
- Stage-level default method throttling set (rather than a Usage Plan, since there's no API key gating a public endpoint)

**Frontend** (`frontend/script.js`)
- On page load, checks a `localStorage` flag (`crc_visited`). First visit (flag unset) sends `POST` to increment and sets the flag; subsequent visits send `GET` to just read the current count
- This tracks unique *browsers* (persisted via localStorage), not unique humans — clearing storage, incognito, or a different device will recount. Acceptable tradeoff for a project this size vs. IP-based/session-based dedup

### Running Lambda tests locally

The visitor counter Lambda has unit tests under `backend/lambda/cloud_resume_visitors/`. This uses `moto` to mock DynamoDB, so no AWS credentials or real AWS resources are needed to run it.

Set up a virtual environment once:
```bash
cd backend/lambda/cloud_resume_visitors
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
```

Run the tests:
```bash
pytest -v
```

Next time, only need to activate the existing environment before running tests:
```bash
cd backend/lambda/cloud_resume_visitors
source .venv/bin/activate
pytest -v
```
