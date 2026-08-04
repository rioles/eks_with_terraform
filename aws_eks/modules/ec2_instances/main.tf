terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
data "aws_caller_identity" "current" {}

resource "aws_key_pair" "bastion" {
  key_name = "${var.cluster_name}-bastion-key"
  #public_key = file("~/.ssh/k8s-key.pub")
  public_key = var.public_key # ← votre clé publique envoyée sur AWS
  tags       = var.tags
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id                     # ← subnet public depuis module/vpc
  vpc_security_group_ids      = [var.bastion_sg_id]               # ← SG depuis module/eks
  iam_instance_profile        = var.bastion_instance_profile_name # ← depuis module/iam
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion.key_name

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # Installation automatique des outils au démarrage
  user_data = <<-EOF
    #!/bin/bash
    set -e  # Arrête le script si une commande échoue

    # 1. Mettre à jour APT et installer les outils de base (SANS awscli)
    apt-get update -y
    apt-get install -y unzip curl git jq

    # 2. Installer AWS CLI v2 (Officiel AWS)
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
    rm -rf /tmp/awscliv2.zip /tmp/aws

    # 3. Installer kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/

    # 4. Installer Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # 5. Configurer kubeconfig pour l'utilisateur ubuntu
    mkdir -p /home/ubuntu/.kube
    /usr/local/bin/aws eks update-kubeconfig \
      --region ${var.primary} \
      --name ${var.cluster_name} \
      --kubeconfig /home/ubuntu/.kube/config

    chown -R ubuntu:ubuntu /home/ubuntu/.kube
  EOF

  tags = merge(var.tags, {
    Name        = "${var.cluster_name}-bastion"
    Environment = var.environment
  })
}
