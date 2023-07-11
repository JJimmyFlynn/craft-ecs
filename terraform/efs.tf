/****************************************
* EFS for Shared Task Storage
*****************************************/
resource "aws_efs_file_system" "craft_efs" {
  tags = {
    Name = "Craft Europa EFS"
  }
}

resource "aws_efs_mount_target" "craft_private" {
  count           = local.az_count
  file_system_id  = aws_efs_file_system.craft_efs.id
  subnet_id       = element(aws_subnet.craft_private.*.id, count.index)
  security_groups = [aws_security_group.efs_allow_ecs.id]
}

resource "aws_efs_access_point" "craft_europa_ap" {
  file_system_id = aws_efs_file_system.craft_efs.id
  posix_user {
    gid = 82 // www-data
    uid = 82 // www-data
  }
  root_directory {
    path = "/craft-europa-shared-storage"
    creation_info {
      owner_gid   = 82 // www-data
      owner_uid   = 82 // www-data
      permissions = "744"
    }
  }
}
