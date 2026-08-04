terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.33.0"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = var.primary
}

resource "aws_security_group" "keycloak_app_security_group" {
  name        = "keycloak_app_security_group"
  description = "Security Group pour application Keycloak (derriere Ingress Controller)"
  vpc_id      = var.vpc_id

  tags = {
    Name = "keycloak_app_security_group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "keycloak_allow_http_from_ingress" {
  security_group_id = aws_security_group.keycloak_app_security_group.id
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"

  referenced_security_group_id = var.ingress_controller_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "keycloak_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.keycloak_app_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "rds_security_group" {
  name        = "rds_security_group"
  description = "Allow inbound traffic only for PostgreSQL and all outbound traffic"

  vpc_id = var.vpc_id

  tags = {
    Name = "rds_security_group"
  }
}

resource "aws_vpc_security_group_egress_rule" "rds_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.rds_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


resource "aws_vpc_security_group_ingress_rule" "rds_allow_postgres_ipv4" {
  security_group_id            = aws_security_group.rds_security_group.id
  referenced_security_group_id = aws_security_group.keycloak_app_security_group.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_db_subnet_group" "keycloak_subnet_group" {
  name        = "keycloak-subnet-group"
  description = "Groupe de sous-reseaux pour le RDS Keycloak"

  subnet_ids = var.private_subnet_ids

  tags = {
    Project = "Keycloak"
  }
}

resource "random_password" "rds_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name                    = "keycloak-db-credentials"
  recovery_window_in_days = 0
  tags = {
    Project = "Keycloak"
  }
}

resource "aws_secretsmanager_secret_version" "rds_secret_val" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = "keycloak"
    password = random_password.rds_password.result
    engine   = "postgres"
    port     = 5432
    db_name  = "keycloak"
  })
}

resource "aws_db_instance" "keycloak_db" {
  identifier             = "keycloak-db"
  instance_class         = "db.t3.medium"
  engine                 = "postgres"
  engine_version         = "15.8"
  allocated_storage      = 20
  storage_type           = "gp3"
  db_name                = "keycloak"
  username               = jsondecode(aws_secretsmanager_secret_version.rds_secret_val.secret_string)["username"]
  password               = jsondecode(aws_secretsmanager_secret_version.rds_secret_val.secret_string)["password"]
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.keycloak_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]

  backup_retention_period = 7
  multi_az                = false
  skip_final_snapshot     = true

  tags = {
    Project = "Keycloak"
  }
}




