/****************************************
* ECR REPOSITORY
*****************************************/
data "aws_ecr_repository" "craft_europa" {
  name = "craft-europa"
}
