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


resource "aws_efs_access_point" "craft_europa_ap" {
  file_system_id = aws_efs_file_system.craft_efs.id
  posix_user {
    gid = 82
    uid = 82
  }
  root_directory {
    path = "/craft-europa-shared-storage"
    creation_info {
      owner_gid   = 82
      owner_uid   = 82
      permissions = "744"
    }
  }
}
