/****************************************
* Base VPC
*****************************************/
resource "aws_vpc" "craft_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    "Name" : "Craft ECS"
  }
}

/****************************************
* Subnets
*****************************************/
locals {
  az_count = 2
}

resource "aws_subnet" "craft_public" {
  count             = local.az_count
  vpc_id            = aws_vpc.craft_vpc.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  cidr_block        = cidrsubnet(aws_vpc.craft_vpc.cidr_block, 2, count.index)

  tags = {
    "Name" : "Craft Public ${count.index + 1}"
  }
}

resource "aws_subnet" "craft_private" {
  count             = local.az_count
  vpc_id            = aws_vpc.craft_vpc.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  cidr_block        = cidrsubnet(aws_vpc.craft_vpc.cidr_block, 2, count.index + local.az_count) // Pickup cidr range where public subnets left off

  tags = {
    "Name" : "Craft Private ${count.index + 1}"
  }
}

/****************************************
* Internet Gateway
*****************************************/
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.craft_vpc.id
}

/****************************************
* Route Tables
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
  subnet_id      = element(aws_subnet.craft_public.*.id, 0)
}

resource "aws_route_table_association" "public_2_web_access" {
  route_table_id = aws_route_table.web_access.id
  subnet_id      = element(aws_subnet.craft_public.*.id, 1)
}

// OUTBOUND ONLY WEB ACCESS
resource "aws_route_table" "outbound_web_access" {
  vpc_id = aws_vpc.craft_vpc.id

  #  route {
  #    cidr_block     = "0.0.0.0/0"
  #    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  #  }

  tags = {
    Name = "ECS Outbound Web Access"
  }
}

resource "aws_route_table_association" "private_web_access" {
  count          = local.az_count
  route_table_id = aws_route_table.outbound_web_access.id
  subnet_id      = element(aws_subnet.craft_private.*.id, count.index)
}

/****************************************
* Elastic IPs
*****************************************/
#resource "aws_eip" "nat_eip" {
#}

/****************************************
* NAT Gateway
*****************************************/
#resource "aws_nat_gateway" "nat_gateway" {
#  subnet_id         = element(aws_subnet.craft_public.*.id, 0)
#  connectivity_type = "public"
#  allocation_id     = aws_eip.nat_eip.id
#
#  depends_on = [aws_internet_gateway.internet_gateway]
#}

/****************************************
* Load Balancer
*****************************************/
resource "aws_alb" "load_balancer" {
  name               = "craft-ecs-lb"
  load_balancer_type = "application"
  subnets            = aws_subnet.craft_public.*.id
  security_groups    = [aws_security_group.load_balancer_sg.id]
}

// Target Group
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

// Listeners
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
