terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
data "aws_caller_identity" "current" {}

resource "aws_key_pair" "bastion" {
  key_name   = "${var.cluster_name}-bastion-key"
  #public_key = file("~/.ssh/k8s-key.pub")
  public_key = var.public_key  # ← votre clé publique envoyée sur AWS
  tags       = var.tags
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id              # ← subnet public depuis module/vpc
  vpc_security_group_ids      = [var.bastion_sg_id]        # ← SG depuis module/eks
  iam_instance_profile        = var.bastion_instance_profile_name  # ← depuis module/iam
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
    set -e  # ← arrête le script si une commande échoue
    apt-get update -y

    # AWS CLI + dépendances
    apt-get install -y awscli unzip curl git jq

    # kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/

    # Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # Configurer kubeconfig
    mkdir -p /home/ubuntu/.kube
    aws eks update-kubeconfig \
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