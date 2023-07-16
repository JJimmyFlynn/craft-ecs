/****************************************
* Load Balancer Security Group
*****************************************/
resource "aws_security_group" "load_balancer_sg" {
  name        = "load-balancer-sg"
  vpc_id      = aws_vpc.craft_vpc.id
  description = "Allow LB to communicate with internet and with ECS"
}

resource "aws_vpc_security_group_ingress_rule" "lb_allow_http" {
  security_group_id = aws_security_group.load_balancer_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = "80"
  to_port           = "80"
  description       = "Allow HTTP"
}

resource "aws_vpc_security_group_ingress_rule" "lb_allow_https" {
  security_group_id = aws_security_group.load_balancer_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = "443"
  to_port           = "443"
  description       = "Allow HTTPS"
}

resource "aws_vpc_security_group_egress_rule" "lb_allow_ecs" {
  security_group_id            = aws_security_group.load_balancer_sg.id
  referenced_security_group_id = aws_security_group.ecs_service_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  description                  = "Allow outbound access to ECS"
}

/****************************************
* ECS Task Security Group
*****************************************/
resource "aws_security_group" "ecs_service_sg" {
  name   = "ecs-service-sg"
  vpc_id = aws_vpc.craft_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_allow_lb_in" {
  security_group_id = aws_security_group.ecs_service_sg.id
  #  referenced_security_group_id = aws_security_group.load_balancer_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  description = "Allow ALB inbound connections"
}

resource "aws_vpc_security_group_egress_rule" "ecs_allow_all_out" {
  security_group_id = aws_security_group.ecs_service_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
  description       = "Allow ECS to initiate outbound TCP connections"
}

/****************************************
* Allow ECS Security Group
*****************************************/
resource "aws_security_group" "allow_ecs" {
  name        = "allow_ecs"
  vpc_id      = aws_vpc.craft_vpc.id
  description = "Allows inbound originated traffic from the ECS Service security group"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ecs_inbound" {
  security_group_id            = aws_security_group.allow_ecs.id
  referenced_security_group_id = aws_security_group.ecs_service_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 0
  to_port                      = 65535
}

/****************************************
* Database Security Group
*****************************************/
resource "aws_security_group" "database_allow_ecs" {
  name   = "database-allow-ecs"
  vpc_id = aws_vpc.craft_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "db_allow_ecs_sg" {
  security_group_id            = aws_security_group.database_allow_ecs.id
  referenced_security_group_id = aws_security_group.ecs_service_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "Allow ECS Service access to DB"
}

/****************************************
* EFS Security Group
*****************************************/
resource "aws_security_group" "efs_allow_ecs" {
  name   = "efs-allow-ecs"
  vpc_id = aws_vpc.craft_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "efs_allow_ecs_sg" {
  security_group_id            = aws_security_group.efs_allow_ecs.id
  referenced_security_group_id = aws_security_group.ecs_service_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  description                  = "Allow ECS access to EFS"
}
