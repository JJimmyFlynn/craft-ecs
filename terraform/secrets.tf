data "aws_secretsmanager_secret" "database_password" {
  arn = "arn:aws:secretsmanager:us-east-1:504200660083:secret:craft-ecs/database-credentials-etRROU"
}

data "aws_secretsmanager_secret_version" "database_password_json" {
  secret_id = data.aws_secretsmanager_secret.database_password.id
}
