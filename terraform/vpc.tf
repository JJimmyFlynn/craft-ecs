/*
    BASE VPC
*/
resource "aws_vpc" "craft_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        "Name": "Craft ECS"
    }
}

/*
    SUBNETS
*/
resource "aws_subnet" "craft_public_1" {
    vpc_id = aws_vpc.craft_vpc.id
    availability_zone = "us-east-1a"
    cidr_block = "10.0.0.0/18"

    tags = {
        "Name": "Craft Public 1"
    }
}

resource "aws_subnet" "craft_public_2" {
    vpc_id = aws_vpc.craft_vpc.id
    availability_zone = "us-east-1b"
    cidr_block = "10.0.64.0/18"

    tags = {
        "Name": "Craft Public 2"
    }
}

resource "aws_subnet" "craft_private_1" {
    vpc_id = aws_vpc.craft_vpc.id
    availability_zone = "us-east-1a"
    cidr_block = "10.0.128.0/18"

    tags = {
        "Name": "Craft Private 1"
    }
}

resource "aws_subnet" "craft_private_2" {
    vpc_id = aws_vpc.craft_vpc.id
    availability_zone = "us-east-1b"
    cidr_block = "10.0.192.0/18"

    tags = {
        "Name": "Craft Private 2"
    }
}

/*
    INTERNET GATEWAY
*/
resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.craft_vpc.id
}

/*
    ROUTE TABLE
*/
resource "aws_route_table" "web_dmz" {
    vpc_id = aws_vpc.craft_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet_gateway.id
    }

    tags = {
        "Name": "Web DMZ"
    }
}


resource "aws_route_table_association" "public_1_web_dmz" {
    route_table_id = aws_route_table.web_dmz.id
    subnet_id = aws_subnet.craft_public_1.id
}

resource "aws_route_table_association" "public_2_web_dmz" {
    route_table_id = aws_route_table.web_dmz.id
    subnet_id = aws_subnet.craft_public_2.id
}
