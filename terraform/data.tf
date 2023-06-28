resource "random_string" "craft_security_key" {
  length  = 32
  special = false
}

data "aws_secretsmanager_secret" "database_password" {
  arn = aws_rds_cluster.database_cluster.master_user_secret.0.secret_arn
}

data "aws_secretsmanager_secret_version" "database_password_json" {
  secret_id = data.aws_secretsmanager_secret.database_password.id
}
