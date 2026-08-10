# Cloud Resume
Working on [The Cloud Challenge](https://cloudresumechallenge.dev/docs/the-challenge/aws/) with my resume.

## Static Site Hosting

**S3**
I kept the bucket private. No public bucket policy, no S3 static website hosting endpoint exposed. Only CloudFront can read from it, through Origin Access Control (OAC). It holds `frontend/index.html`, `frontend/style.css`, `frontend/script.js`, and `frontend/assets/`.

**CloudFront**
Sits in front of the private bucket and serves everything over HTTPS. The cert's issued through ACM in `us-east-1`, since that's the only region CloudFront will accept a certificate from no matter where the rest of my resources live.

**DNS (Cloudflare, not Route 53)**
`randy-sykes.me` was already sitting in Cloudflare before I started this project, so I left DNS there instead of migrating it to Route 53. Two records point at the CloudFront distribution, `@` (apex) and `www`, both set to **DNS-only** (grey-clouded), so Cloudflare just resolves them straight to CloudFront instead of proxying. That means CloudFront (with its ACM cert) is the only TLS termination point in the request path. Everything else in the zone is unrelated to this project.

**HTML/CSS**
Hand-written, no frameworks. Mobile responsiveness (collapsing nav, typewriter text scaling on narrow viewports) is CSS media queries; the nav's open/close behavior is a JS-toggled hamburger button rather than a CSS-only checkbox trick, since auto-closing the menu after a link click was easier to do in JS.

## Visitor Counter

Tracks unique visitors, not page views/refreshes, using a DynamoDB table, a Lambda function, and an API Gateway REST API, called from the frontend with `fetch`.

**DynamoDB**
- Table: `cloud-resume-visitors`, partition key `id` (String), no sort key. It's a single-item table, one row (`id: "visitor_count"`) holding the running total
- Billing mode is on-demand (pay-per-request) since traffic is low and unpredictable
- Counts update through an `UpdateItem` `ADD` expression (atomic increment) instead of a read-then-write, so concurrent visits can't race each other into an undercount
- Protected two different ways once it went under Terraform: `deletion_protection_enabled = true` (AWS enforces this at the API level, blocks deletion no matter how someone tries, console, CLI, or Terraform) plus `lifecycle { prevent_destroy = true }` on top, so even a mistaken `terraform destroy` can't touch it

**Lambda** (`backend/lambda/cloud_resume_visitors/lambda_function.py`)
- Python, handler `lambda_function.lambda_handler`
- Branches on `event['httpMethod']`: `GET` reads the count without incrementing, `POST` increments it
- Execution role's inline policy is scoped to just `dynamodb:GetItem`/`dynamodb:UpdateItem` on the table's ARN, not full DynamoDB access
- Handles two edge cases on purpose: the item not existing yet (`GET` returns `count: 0` instead of erroring) and DynamoDB being unreachable (`ClientError` returns a `500` with an error body, still carrying CORS headers, instead of crashing unhandled and losing those headers along with it)

**API Gateway**
- REST API, Regional endpoint type, not Private (only reachable from inside a VPC, no good for a public visitor's browser) and not Edge-optimized (no benefit, the static site already has its own CloudFront distribution in front of it)
- `/count` resource with `GET` and `POST` methods, both Lambda proxy integration
- CORS headers come straight from the Lambda's response (`Access-Control-Allow-Origin` locked to `https://randy-sykes.me`) rather than a separate OPTIONS/Mock setup. The frontend's `fetch` call never sends custom headers or a body, so it counts as a CORS "simple request" and never triggers a preflight in the first place. Confirmed there's genuinely no OPTIONS method on the resource before assuming that.
- Stage-level default method throttling instead of a Usage Plan, since there's no API key gating a public endpoint

**Frontend** (`frontend/script.js`)
- On page load it checks a `localStorage` flag (`crc_visited`). First visit sends `POST` to increment and sets the flag; every visit after that sends `GET` to just read the count
- This tracks unique *browsers*, not unique humans. Clearing storage, incognito, or a different device recounts, which is an acceptable tradeoff for a project this size versus IP- or session-based dedup
- Fetches the API's URL at runtime from `/api_url.txt` instead of having it hardcoded in the JS. That file is a Terraform-managed S3 object generated from the API Gateway stage's real invoke URL, so it can't go stale

### Running Lambda tests locally

The visitor counter Lambda has unit tests under `backend/lambda/cloud_resume_visitors/`, using `moto` to mock DynamoDB, so no AWS credentials or real AWS resources needed to run them.

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

Next time, just activate the existing environment before running:
```bash
cd backend/lambda/cloud_resume_visitors
source .venv/bin/activate
pytest -v
```

## Infrastructure as Code

Everything above was originally built by hand in the console. Once it was working, I brought all of it under Terraform. Imported, not rebuilt from scratch, so there was zero downtime, no reset visitor count, and no changed URLs along the way.

### State bucket

I can't keep state on my local machine once CI/CD is doing applies too, so state lives remotely in S3 with native locking (`use_lockfile = true` in the backend block, no separate DynamoDB lock table needed for that anymore). This one bucket is the single manual exception to "no ClickOps," since Terraform can't create the bucket that holds its own state. I did the whole thing through the CLI instead of the console:

```bash
aws s3api create-bucket --region us-east-1 --bucket <name-for-s3-bucket>
```

Versioning on, in case I ever need to roll back a bad state write:
```bash
aws s3api put-bucket-versioning --bucket <name-for-s3-bucket> --versioning-configuration Status=Enabled
```

Encryption at rest, since state can contain sensitive attribute values:
```bash
aws s3api put-bucket-encryption --bucket <name-for-s3-bucket> --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

Blocked all public access, since this bucket should never be reachable outside my account:
```bash
aws s3api put-public-access-block --bucket <name-for-s3-bucket> --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### How I approached the import

I split the config into one file per service: `s3.tf`, `cloudfront.tf`, `acm.tf`, `dynamodb.tf`, `lambda.tf`, `iam.tf`, `api_gateway.tf`, `cloudflare-dns.tf`, plus `providers.tf` and `variables.tf`. No nested modules; this is a single-instance, single-environment project, so a module would just add indirection (input/output variables, `module.x.` prefixes) for something that's only ever provisioned once.

For each resource, I wrote an `import` block pointing at its real AWS/Cloudflare ID and used `terraform plan -generate-config-out=generated.tf` to have Terraform write a first-draft config from the live resource, instead of typing every attribute by hand. That draft always needed a cleanup pass afterward: literal values that should be cross-resource references (an ARN that's really `aws_iam_role.site.arn`, a domain name that's really `aws_s3_bucket.site.bucket_regional_domain_name`) instead of a copy-pasted string. The whole point of doing it that way instead of just leaving the literals in: if any of this ever has to be destroyed and rebuilt from scratch, the config heals itself instead of pointing at IDs that no longer exist.

I imported in small batches by service rather than everything at once, so when something broke I only had one thing to debug instead of untangling a wall of errors across a dozen resources at the same time. That turned out to matter more than expected. A few real generator bugs showed up along the way (DynamoDB's `point_in_time_recovery` block writing an invalid `recovery_period_in_days = 0`, CloudFront's `endpoint_configuration` writing an empty `vpc_endpoint_ids = []` that the schema rejects for a Regional endpoint) where the generated file was a faithful mirror of real AWS state but still technically invalid HCL. Both were a one-line fix once I knew what was actually wrong.

### Things that came up along the way

A few decisions and discoveries worth remembering, since they're not obvious just from reading the final config:

- **IAM role conflicts.** The generated `aws_iam_role` included `inline_policy`/`managed_policy_arns` blocks that duplicated what I was already importing as standalone `aws_iam_role_policy`/`aws_iam_role_policy_attachment` resources. The AWS provider explicitly warns against managing both at once, since two resources would each think they own the same policy attachment. Removed the inline versions from the role, kept the standalone resources.
- **Lambda has no clean way to import its code.** `filename`/`s3_bucket`/`image_uri` can't be generated from existing state, since AWS doesn't hand back something reusable as config for already-deployed code. Solved it with a `data "archive_file"` data source zipping `backend/lambda/cloud_resume_visitors/lambda_function.py` directly, with `source_code_hash` wired to it so future code changes are detected reliably. That first import also surfaced real drift: the deployed Lambda was still running the version from before the error-handling work, since I hadn't redeployed after those edits. The import fixed that for free.
- **Lambda permission `statement_id`.** AWS auto-generates this when the console creates the permission. I import it as-is (has to match reality), but I don't hardcode it into config afterward. It's Optional+Computed, so leaving it unset means a hypothetical full rebuild gets a fresh AWS-generated ID instead of reusing one tied to a resource that no longer exists.
- **The CloudFront distribution requires a Web ACL, and I can't remove it.** Tried to detach it and got `"Distributions with a pricing plan subscription must have a web ACL resource."` Turned out to be included free as part of the distribution's CloudFront pricing plan, not something costing extra, not something I can opt out of. Left it as a literal ARN reference rather than building a full `aws_wafv2_web_acl` resource for it, since it's AWS/console-managed boilerplate, not something I authored.
- **No OPTIONS method exists**, and that's correct, not missing. Confirmed via `aws apigateway get-resource` before assuming; the frontend's `fetch` call never needs a CORS preflight, so nothing ever created one.
- **The ACM DNS validation CNAME is under Terraform now too**, tied dynamically to `aws_acm_certificate.site.domain_validation_options` instead of the record being a static value someone manually clicked into Cloudflare. If the cert's ever recreated with a new validation token, this record follows automatically instead of silently breaking renewal a year later.
- **`api_url.txt`** is an `aws_s3_object` generated from `aws_api_gateway_stage.site.invoke_url`, not a file I maintain by hand. Same self-healing idea as everything else.

### Secrets and variables

The Cloudflare provider needs an API token, scoped narrowly to Zone → DNS → Edit on just this one zone, not account-wide access. Locally it lives in a gitignored `cloudflare.auto.tfvars` (Terraform loads `*.auto.tfvars` automatically, no flag needed, no re-exporting it every new terminal session). In CI it'll come from a GitHub Actions secret injected as `TF_VAR_cloudflare_api_token` instead, same mechanism, different source. Everything else that isn't actually secret (bucket name, domain, table/function/API names) just got real `default` values in `variables.tf`, since they're constants for this project and there's no reason CI should need to supply them separately.

## CI/CD

Two GitHub Actions workflows drive Terraform: `infra-terraform-plan.yml` runs on every PR touching `infrastructure/**` or the workflow files themselves, `infra-terraform-apply.yml` runs on push to `main` (i.e. after a PR merges).

**OIDC, not long-lived keys**
Both workflows authenticate to AWS through a GitHub OIDC provider (`aws_iam_openid_connect_provider.github_actions` in `github_oidc.tf`) instead of storing an AWS access key/secret in GitHub Secrets. GitHub mints a short-lived signed token per run; AWS validates it against the OIDC provider and a trust policy condition on the token's `sub` claim. No static credentials sitting in GitHub to leak or rotate.

**Two roles, split by privilege**
- `github-actions-plan`: read-only actions across every service (S3, CloudFront, ACM, DynamoDB, Lambda, API Gateway, IAM), enough to run `terraform plan` and comment the diff on the PR, never enough to change anything.
- `github-actions-apply`: everything `plan` has, plus the specific write/update actions each resource needs (`s3:PutObject`, `lambda:UpdateFunctionCode`, `iam:PutRolePolicy`, etc.), scoped to this project's resource ARNs, not `*`.

**The trust policy `sub` claim, and a gotcha**
GitHub rolled out immutable subject claims in 2026: the `sub` claim now embeds the owner's and repo's permanent numeric IDs (`repo:OWNER@OWNER_ID/REPO@REPO_ID:...`) instead of just the mutable name, so a renamed/recycled repo or org can't mint a token that still matches an old trust policy. Both roles' conditions use this format.

The part that isn't obvious: the segment *after* the owner/repo also depends on how the token was requested, and the two forms don't combine. `plan` runs on `pull_request` with no `environment:` set, so its claim ends in `:pull_request`. `apply` runs on push to `main`, but the job also sets `environment: production` for approval-gating, and setting `environment:` replaces the ref-based ending entirely: the claim becomes `...:environment:production`, never `...:environment:production:ref:refs/heads/main`. Got bitten by assuming both endings could appear together, cost a broken `apply` role until the trust policy was corrected to match.

**Approval gate before apply**
`apply`'s `environment: production` isn't only about the `sub` claim shape, the `production` environment in GitHub also has a required-reviewer protection rule, so even after a PR merges to `main`, the actual `terraform apply` run pauses until manually approved in the Actions UI. PR review covers the diff being merged; this is a separate checkpoint on the specific run that's about to touch real AWS resources.

### Local setup

**Git hooks**
Hooks live in the tracked `.githooks/` directory rather than the untracked `.git/hooks/`, currently just a `pre-commit` hook blocking commits made directly on `main` (branch protection would reject the push anyway; this just catches it earlier, locally). `core.hooksPath` is a local git config value, not something `git clone` picks up automatically, so it needs to be set once per clone:

```bash
git config core.hooksPath .githooks
```
