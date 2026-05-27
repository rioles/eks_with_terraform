resource "aws_security_group" "ingress_controller_sg" {
  name        = "ingress-controller-sg"
  description = "Security Group unique pour l'Ingress Controller - Point d'entree global"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "ingress-controller-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_allow_https" {
  security_group_id = aws_security_group.ingress_controller_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_allow_http" {
  security_group_id = aws_security_group.ingress_controller_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ingress_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.ingress_controller_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
