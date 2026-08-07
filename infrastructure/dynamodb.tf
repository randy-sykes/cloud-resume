resource "aws_dynamodb_table" "site" {
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = true
  hash_key                    = "id"
  name                        = var.dynamodb_table_name
  range_key                   = null
  read_capacity               = 0
  region                      = var.crc_region
  restore_backup_arn          = null
  restore_date_time           = null
  restore_source_name         = null
  restore_source_table_arn    = null
  restore_to_latest_time      = null
  stream_enabled              = false
  table_class                 = "STANDARD"
  tags                        = {}
  tags_all                    = {}
  write_capacity              = 0
  attribute {
    name = "id"
    type = "S"
  }
  point_in_time_recovery {
    enabled = false
  }
  ttl {
    attribute_name = null
    enabled        = false
  }
  lifecycle {
    prevent_destroy = true
  }
}