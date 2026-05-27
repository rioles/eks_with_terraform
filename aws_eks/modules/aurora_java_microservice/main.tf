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

resource "aws_security_group" "register_ms_app_security_group" {
  name        = "register_ms_app_security_group"
  description = "Security Group pour l'application Register Microservice (derriere Ingress Controller)"
  vpc_id      = var.vpc_id

  tags = {
    Name = "register_ms_app_security_group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "register_ms_allow_http_from_ingress" {
  security_group_id = aws_security_group.register_ms_app_security_group.id
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"

  referenced_security_group_id = var.ingress_controller_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "register_ms_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.register_ms_app_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "aurora_security_group" {
  name        = "aurora_security_group"
  description = "Allow inbound traffic only for PostgreSQL and all outbound traffic"

  vpc_id = var.vpc_id

  tags = {
    Name = "register_ms_aurora_security_group"
  }
}

resource "aws_vpc_security_group_egress_rule" "aurora_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.aurora_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


resource "aws_vpc_security_group_ingress_rule" "aurora_allow_postgres_ipv4" {
  security_group_id            = aws_security_group.aurora_security_group.id
  referenced_security_group_id = aws_security_group.register_ms_app_security_group.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_db_subnet_group" "register_ms_subnet_group" {
  name        = "register-ms-subnet-group"
  description = "Groupe de sous-reseaux pour le RDS Register Microservice"

  subnet_ids = var.private_subnet_ids

  tags = {
    Project = "register_ms_subnet_group"
  }
}

resource "random_password" "aurora_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*-_=+"   
}

resource "aws_secretsmanager_secret" "aurora_secret" {
  name                    = "register-db-credentials"
  recovery_window_in_days = 0 
  tags = {
    Project = "register-microservice"
  }       
}

resource "aws_secretsmanager_secret_version" "aurora_secret_val" {
  secret_id = aws_secretsmanager_secret.aurora_secret.id
  secret_string = jsonencode({
    username = "register_user"
    password = random_password.aurora_password.result
    engine   = "aurora-postgresql"
    port     = 5432
    db_name  = "db_registration"
  })
}


resource "aws_rds_cluster" "register_ms_aurora_cluster" {
  cluster_identifier = "register-ms-aurora-cluster"
  engine             = "aurora-postgresql"
  engine_version     = "15.4"
  database_name      = "db_registration"

  master_username = "register_user"                      
  master_password = random_password.aurora_password.result

  db_subnet_group_name   = aws_db_subnet_group.register_ms_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aurora_security_group.id]

  storage_encrypted       = true   
  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  serverlessv2_scaling_configuration {
    max_capacity = 2.0
    min_capacity = 0.5
  }

  tags = { Project = "register_ms_aurora_db" }
}

resource "aws_rds_cluster_instance" "register_ms_aurora_instance" {
  count              = 2
  identifier         = "register-ms-aurora-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.register_ms_aurora_cluster.id
  engine             = aws_rds_cluster.register_ms_aurora_cluster.engine
  engine_version     = aws_rds_cluster.register_ms_aurora_cluster.engine_version
  instance_class     = "db.serverless"
}