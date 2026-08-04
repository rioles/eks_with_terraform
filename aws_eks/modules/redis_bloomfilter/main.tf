terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.33.0"
    }
  }
}

# 1. SECRET
resource "random_password" "redis_auth_token" {
  length  = 32
  special = false  # auth_token n'accepte pas les caractères spéciaux
}

resource "aws_secretsmanager_secret" "redis_secret" {
  name                    = "${var.name_prefix}-redis-auth-token"
  description             = "Mot de passe AUTH pour le cluster Valkey (Bloom)"
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "redis_secret_val" {
  secret_id     = aws_secretsmanager_secret.redis_secret.id
  secret_string = random_password.redis_auth_token.result
}

# 2. RÉSEAU
resource "aws_elasticache_subnet_group" "redis" {
  # CORRECTION 1 : Forcer en minuscules pour respecter la contrainte ElastiCache
  name       = lower("${var.name_prefix}-redis-subnet-group")
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "redis_bloomfilter_security_group" {
  name        = "${var.name_prefix}-redis-sg"
  description = "Security Group pour Valkey (Bloom)"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "redis_allow_lambda" {
  security_group_id            = aws_security_group.redis_bloomfilter_security_group.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.lambda_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "redis_allow_all" {
  security_group_id = aws_security_group.redis_bloomfilter_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_elasticache_replication_group" "redis_bloom" {
  replication_group_id       = "${var.name_prefix}-redis"
  description                = "Valkey pour Bloom Filter"
  node_type                  = "cache.t3.micro"
  num_cache_clusters         = 1
  port                       = 6379
  engine                     = "valkey"
  engine_version             = "8.1"
  parameter_group_name       = "default.valkey8"

  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis_bloomfilter_security_group.id]
  auth_token                 = random_password.redis_auth_token.result
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  apply_immediately           = true
  tags                       = var.tags
}

  
