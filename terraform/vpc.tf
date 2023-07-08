/****************************************
* BASE VPC
*****************************************/
resource "aws_vpc" "craft_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    "Name" : "Craft ECS"
  }
}

/****************************************
* SUBNETS
*****************************************/
resource "aws_subnet" "craft_public_1" {
  vpc_id            = aws_vpc.craft_vpc.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.0.0/18"

  tags = {
    "Name" : "Craft Public 1"
  }
}

resource "aws_subnet" "craft_public_2" {
  vpc_id            = aws_vpc.craft_vpc.id
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.64.0/18"

  tags = {
    "Name" : "Craft Public 2"
  }
}

resource "aws_subnet" "craft_private_1" {
  vpc_id            = aws_vpc.craft_vpc.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.128.0/18"

  tags = {
    "Name" : "Craft Private 1"
  }
}

resource "aws_subnet" "craft_private_2" {
  vpc_id            = aws_vpc.craft_vpc.id
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.192.0/18"

  tags = {
    "Name" : "Craft Private 2"
  }
}

/****************************************
* INTERNET GATEWAY
*****************************************/
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.craft_vpc.id
}

/****************************************
* ROUTE TABLES
*****************************************/

// PUBLIC WEB ACCESS
resource "aws_route_table" "web_access" {
  vpc_id = aws_vpc.craft_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    "Name" : "Web Access"
  }
}

resource "aws_route_table_association" "public_1_web_access" {
  route_table_id = aws_route_table.web_access.id
  subnet_id      = aws_subnet.craft_public_1.id
}

resource "aws_route_table_association" "public_2_web_access" {
  route_table_id = aws_route_table.web_access.id
  subnet_id      = aws_subnet.craft_public_2.id
}

// OUTBOUND ONLY WEB ACCESS
resource "aws_route_table" "outbound_web_access" {
  vpc_id = aws_vpc.craft_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "private_1_web_access" {
  route_table_id = aws_route_table.outbound_web_access.id
  subnet_id      = aws_subnet.craft_private_1.id
}

resource "aws_route_table_association" "private_2_web_access" {
  route_table_id = aws_route_table.outbound_web_access.id
  subnet_id      = aws_subnet.craft_private_2.id
}

/****************************************
* ELASTIC IPS
*****************************************/
resource "aws_eip" "nat_eip" {
}

/****************************************
* NAT GATEWAY
*****************************************/
resource "aws_nat_gateway" "nat_gateway" {
  subnet_id         = aws_subnet.craft_public_1.id
  connectivity_type = "public"
  allocation_id     = aws_eip.nat_eip.id

  depends_on = [aws_internet_gateway.internet_gateway]
}

/****************************************
* LOAD BALANCER
*****************************************/
resource "aws_alb" "load_balancer" {
  name               = "craft-ecs-lb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.craft_public_1.id, aws_subnet.craft_public_2.id]
  security_groups    = [aws_security_group.load_balancer_sg.id]
}

resource "aws_lb_target_group" "craft_europa_ecs" {
  name        = "craft-europa-ecs"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.craft_vpc.id

  health_check {
    path     = "/actions/app/health-check"
    interval = 35
    timeout  = 30
  }

  tags = {
    Name = "Craft Europa Web TG"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_alb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.craft_europa_ecs.arn
  }
}

resource "aws_lb_listener_rule" "http" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.craft_europa_ecs.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
