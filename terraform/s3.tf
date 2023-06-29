data "aws_s3_bucket" "app_storage" {
  bucket = "craft-europa-app-storage-jjf"
}

#resource "aws_s3_bucket_policy" "app_storage_bucket_policy" {
#  bucket = ""
#  policy = ""
#}
