resource "aws_rds_cluster" "database_cluster" {
  cluster_identifier     = "craft-europa-postgres"
  engine                 = "aurora-postgresql"
  engine_version         = "14.6"
  engine_mode            = "provisioned"
  database_name          = "craft"
  master_username        = "craft"
  master_password        = jsondecode(data.aws_secretsmanager_secret_version.database_password_json.secret_string)["password"]
  skip_final_snapshot    = true
  storage_encrypted      = false
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids = [aws_security_group.database_allow_ecs.id]
  snapshot_identifier    = "craft-ecs-seed"
}

resource "aws_rds_cluster_instance" "database_instance" {
  identifier           = "reader-writer"
  cluster_identifier   = aws_rds_cluster.database_cluster.id
  instance_class       = "db.t3.medium"
  engine               = aws_rds_cluster.database_cluster.engine
  engine_version       = aws_rds_cluster.database_cluster.engine_version
  db_subnet_group_name = aws_db_subnet_group.database_subnet_group.name
}

resource "aws_db_subnet_group" "database_subnet_group" {
  subnet_ids = aws_subnet.craft_private.*.id
}
