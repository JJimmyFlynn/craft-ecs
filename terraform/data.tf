# Fetch AZs in the current region
data "aws_availability_zones" "available" {
}

resource "random_string" "craft_security_key" {
  length  = 32
  special = false
}
