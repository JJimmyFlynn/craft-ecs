/****************************************
* ECR Repository
*****************************************/
data "aws_ecr_repository" "craft_europa" {
  name = "craft-europa"
}

/****************************************
* VPC Interface Endpoints
*****************************************/
resource "aws_vpc_endpoint" "ecr_dkr_endpoint" {
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_id              = aws_vpc.craft_vpc.id
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.craft_private.*.id
  security_group_ids  = [aws_security_group.allow_ecs.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_api_endpoint" {
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  vpc_id              = aws_vpc.craft_vpc.id
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.craft_private.*.id
  security_group_ids  = [aws_security_group.allow_ecs.id]
  private_dns_enabled = true
}
