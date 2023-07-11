data "aws_s3_bucket" "app_storage" {
  bucket = "craft-europa-app-storage-jjf"
}

/****************************************
* BUCKET POLICY
*****************************************/
resource "aws_s3_bucket_policy" "app_storage" {
  bucket = "craft-europa-app-storage-jjf"
  policy = data.aws_iam_policy_document.s3_allow_ecs_and_cloudfront.json
}

data "aws_iam_policy_document" "s3_allow_ecs_and_cloudfront" {
  statement {
    sid    = "AllowECSCraftWebTaskReadWrite"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.craft_web_task_role.arn]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      data.aws_s3_bucket.app_storage.arn,
      "${data.aws_s3_bucket.app_storage.arn}/*"
    ]
  }

  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = [
      data.aws_s3_bucket.app_storage.arn,
      "${data.aws_s3_bucket.app_storage.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      values   = [aws_cloudfront_distribution.craft_europa.arn]
      variable = "AWS:SourceArn"
    }
  }
}

/****************************************
* S3 VPC ENDPOINT
*****************************************/
resource "aws_vpc_endpoint" "app_storage_s3_endpoint" {
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.craft_vpc.id
  auto_accept       = true
  route_table_ids   = [aws_route_table.outbound_web_access.id]
}
