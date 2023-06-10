resource "aws_ecs_cluster" "craft_ecs" {
  name = "Craft_ECS"
}

#resource "aws_ecs_service" "craft_web" {
#  name = "craft_web"
#  cluster = aws_ecs_cluster.craft_ecs.id
#}
