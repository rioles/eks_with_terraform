terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.33.0"
    }
  }
}

resource "aws_dynamodb_table" "chunk_hashes" {
  name         = "${var.name_prefix}-chunk-hashes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "chunk_hash"

  attribute {
    name = "chunk_hash"
    type = "S"
  }

  tags = var.tags
}
