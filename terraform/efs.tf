resource "aws_efs_file_system" "craft_efs" {
  tags = {
    Name = "Craft Europa EFS"
  }
}

resource "aws_efs_mount_target" "craft_private_1" {
  file_system_id  = aws_efs_file_system.craft_efs.id
  subnet_id       = aws_subnet.craft_private_1.id
  security_groups = [aws_security_group.efs_allow_ecs.id]
}

resource "aws_efs_mount_target" "craft_private_2" {
  file_system_id  = aws_efs_file_system.craft_efs.id
  subnet_id       = aws_subnet.craft_private_2.id
  security_groups = [aws_security_group.efs_allow_ecs.id]
}
