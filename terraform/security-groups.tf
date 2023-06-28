/****************************************
* LOAD BALANCER SECURITY GROUP
*****************************************/
resource "aws_security_group" "load_balancer_sg" {
  name   = "load-balancer-sg"
  vpc_id = aws_vpc.craft_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.load_balancer_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = "80"
  to_port           = "80"
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.load_balancer_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = "443"
  to_port           = "443"
}

resource "aws_vpc_security_group_egress_rule" "allow_ecs" {
  security_group_id            = aws_security_group.load_balancer_sg.id
  referenced_security_group_id = aws_security_group.ecs_service_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  description                  = "Allow outbound access to ECS"
}

/****************************************
* ECS TASK SECURITY GROUP
*****************************************/
resource "aws_security_group" "ecs_service_sg" {
  name   = "ecs-service-sg"
  vpc_id = aws_vpc.craft_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_allow_lb_in" {
  security_group_id = aws_security_group.ecs_service_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
}

resource "aws_vpc_security_group_egress_rule" "ecs_allow_all_out" {
  security_group_id = aws_security_group.ecs_service_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
}

/****************************************
* DATABASE SECURITY GROUP
*****************************************/
resource "aws_security_group" "database_allow_ecs" {
  name   = "database-allow-ecs"
  vpc_id = aws_vpc.craft_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ecs_sg" {
  security_group_id            = aws_security_group.database_allow_ecs.id
  referenced_security_group_id = aws_security_group.ecs_service_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}
