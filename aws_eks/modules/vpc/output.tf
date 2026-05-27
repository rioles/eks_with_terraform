# modules/vpc/outputs.tf

output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block du VPC"
  value       = aws_vpc.main.cidr_block
}

# --- SUBNETS PUBLICS ---
output "public_subnet_ids" {
  description = "Liste des IDs des subnets publics"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "Liste des CIDRs des subnets publics"
  value       = aws_subnet.public[*].cidr_block
}

# --- SUBNETS PRIVÉS ---
output "private_subnet_ids" {
  description = "Liste des IDs des subnets privés"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "Liste des CIDRs des subnets privés"
  value       = aws_subnet.private[*].cidr_block
}

# --- NAT & IGW ---
output "nat_gateway_ids" {
  description = "IDs des NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "internet_gateway_id" {
  description = "ID de l'Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "ingress_controller_sg_id" {
  value       = aws_security_group.ingress_controller_sg.id
  description = "L'ID du Security Group de l'Ingress Controller (à passer aux modules applicatifs)"
}