resource "aws_ecs_cluster" "craft_ecs" {
  name = "Craft_ECS"
}

resource "aws_ecs_service" "craft_web" {
  name                   = "craft_web"
  cluster                = aws_ecs_cluster.craft_ecs.id
  task_definition        = aws_ecs_task_definition.craft_web.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets         = [aws_subnet.craft_private_1.id, aws_subnet.craft_private_2.id]
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
  container_definitions = jsonencode([
    {
      name  = "craft-europa"
      image = "${data.aws_ecr_repository.craft_europa.repository_url}:latest"
      portMappings = [
        {
          containerPort : 8080
          hostPort : 8080
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
  ])
}

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
          Action   = "s3:*"
          Effect   = "Allow"
          Resource = data.aws_s3_bucket.app_storage.arn
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
