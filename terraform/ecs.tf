/****************************************
* Base Container Definition
* Shared by web and init tasks
*****************************************/
locals {
  craft_base_container_definition = {
    image = "${data.aws_ecr_repository.craft_europa.repository_url}:latest"
    mountPoints = [
      {
        "containerPath" : "/app/storage"
        "sourceVolume" : "shared-storage"
      }
    ]
    environment = [
      {
        name : "CRAFT_ENVIRONMENT"
        value : "production"
      },
      {
        name : "CRAFT_SECURITY_KEY"
        value : random_string.craft_security_key.result
      },
      {
        name : "CRAFT_DB_DRIVER"
        value : "pgsql"
      },
      {
        name : "CRAFT_DB_SERVER"
        value : aws_rds_cluster_instance.database_instance.endpoint
      },
      {
        name : "CRAFT_DB_PORT"
        value : "5432"
      },
      {
        name : "CRAFT_DB_USER"
        value : "craft"
      },
      {
        name : "CRAFT_DB_DATABASE"
        value : "craft"
      },
      {
        name : "CRAFT_DB_PASSWORD"
        value : jsondecode(data.aws_secretsmanager_secret_version.database_password_json.secret_string)["password"]
      },
      {
        name : "DEFAULT_SITE_URL"
        value : "http://europa.johnjflynn.net"
      },
      {
        name : "S3_BASE_URL",
        value : "https://${data.aws_s3_bucket.app_storage.bucket_domain_name}"
      },
      {
        name : "S3_BUCKET",
        value : data.aws_s3_bucket.app_storage.bucket
      },
      {
        name : "FS_HANDLE",
        value : "images"
      },
      {
        name : "CLOUDFRONT_URL",
        value : "https://${aws_cloudfront_distribution.craft_europa.domain_name}"
      },
      {
        name : "AWS_REGION",
        value : "us-east-1"
      }
    ]
    logConfiguration : {
      logDriver = "awslogs"
      options : {
        awslogs-region        = "us-east-1"
        awslogs-group         = "craft_ecs"
        awslogs-stream-prefix = "streaming"
      }
    }
  }
}

/****************************************
* EFS Volume Config
* Shared by web and init tasks
*****************************************/
locals {
  /* Additions made here should be added to task definition volume configs */
  volume_config = {
    name = "shared-storage"
    efs_volume_configuration = {
      file_system_id     = aws_efs_file_system.craft_efs.id
      transit_encryption = "ENABLED"
      authorization_config = {
        access_point_id = aws_efs_access_point.craft_europa_ap.id
      }
    }
  }
}

/****************************************
* ECS Cluster
*****************************************/
resource "aws_ecs_cluster" "craft_ecs" {
  name = "Craft_ECS"
}

/****************************************
* Web Service
*****************************************/
resource "aws_ecs_service" "craft_web" {
  name            = "craft_web"
  cluster         = aws_ecs_cluster.craft_ecs.id
  task_definition = aws_ecs_task_definition.craft_web.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.craft_private.*.id
    security_groups = [aws_security_group.ecs_service_sg.id]
  }

  load_balancer {
    container_name   = "craft-europa"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.craft_europa_ecs.arn
  }
}

resource "aws_ecs_task_definition" "craft_web" {
  family                   = "craft_web"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.craft_web_task_execution_role.arn
  task_role_arn            = aws_iam_role.craft_web_task_role.arn
  volume {
    name = local.volume_config.name
    efs_volume_configuration {
      file_system_id     = local.volume_config.efs_volume_configuration.file_system_id
      transit_encryption = local.volume_config.efs_volume_configuration.transit_encryption
      authorization_config {
        access_point_id = local.volume_config.efs_volume_configuration.authorization_config.access_point_id
      }
    }
  }
  container_definitions = jsonencode([merge(local.craft_base_container_definition, {
    name = "craft-europa"
    portMappings = [
      {
        containerPort : 8080
        hostPort : 8080
      }
    ]
  })])
}

resource "aws_ecs_task_definition" "craft_init" {
  family                   = "craft_init"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.craft_web_task_execution_role.arn
  task_role_arn            = aws_iam_role.craft_web_task_role.arn
  volume {
    name = local.volume_config.name
    efs_volume_configuration {
      file_system_id     = local.volume_config.efs_volume_configuration.file_system_id
      transit_encryption = local.volume_config.efs_volume_configuration.transit_encryption
      authorization_config {
        access_point_id = local.volume_config.efs_volume_configuration.authorization_config.access_point_id
      }
    }
  }
  container_definitions = jsonencode([merge(local.craft_base_container_definition, {
    name       = "craft-init"
    entrypoint = [".deploy/init.sh"]
  })])
}

/****************************************
* Web Task Role
*****************************************/
resource "aws_iam_role" "craft_web_task_role" {
  name = "CraftWebTaskRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "s3_storage_access"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "s3:*"
          Effect = "Allow"
          Resource = [
            data.aws_s3_bucket.app_storage.arn,
            "${data.aws_s3_bucket.app_storage.arn}/*"
          ]
        }
      ]
    })
  }

  inline_policy {
    name = "allow_ecs_ssm_execute"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
          ],
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

/****************************************
* Task Execution Role
* AWS Manged Policy
*****************************************/
resource "aws_iam_role" "craft_web_task_execution_role" {
  name                = "ECSTaskExecutionRole"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

/****************************************
* ECS Agent VPC Interface Endpoint
*****************************************/
resource "aws_vpc_endpoint" "ecs_agent_endpoint" {
  service_name        = "com.amazonaws.us-east-1.ecs-agent"
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.craft_vpc.id
  subnet_ids          = aws_subnet.craft_private.*.id
  security_group_ids  = [aws_security_group.allow_ecs.id]
  private_dns_enabled = true
}

/****************************************
* ECS Telemetry VPC Interface Endpoint
*****************************************/
resource "aws_vpc_endpoint" "ecs_telemetry_endpoint" {
  service_name        = "com.amazonaws.us-east-1.ecs-telemetry"
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.craft_vpc.id
  subnet_ids          = aws_subnet.craft_private.*.id
  security_group_ids  = [aws_security_group.allow_ecs.id]
  private_dns_enabled = true
}

/****************************************
* Cloudwatch VPC Interface Endpoint
*****************************************/
resource "aws_vpc_endpoint" "ecs_cloudwatch_endpoint" {
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_id              = aws_vpc.craft_vpc.id
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.craft_private.*.id
  security_group_ids  = [aws_security_group.allow_ecs.id]
  private_dns_enabled = true
}
