resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.primary}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = distinct(flatten([
    for rt in aws_route_table.private : rt.id
  ]))

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpce-dynamodb"
  })
}

# Endpoint S3 Gateway
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id  # ← même que DynamoDB
  service_name      = "com.amazonaws.${var.primary}.s3"  # ← utilise var.primary, pas hardcodé
  vpc_endpoint_type = "Gateway"
  route_table_ids = distinct(flatten([
    for rt in aws_route_table.private : rt.id
  ]))
  tags = merge(var.tags, {  # ← merge comme DynamoDB pour cohérence
    Name = "${var.name_prefix}-vpce-s3"
  })
}
