resource "aws_appautoscaling_target" "craft_web" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.craft_ecs.name}/${aws_ecs_service.craft_web.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

/****************************************
* CPU Tracking Scaling
*****************************************/
resource "aws_appautoscaling_policy" "craft_web_cpu" {
  name               = "craft_web_cpu_tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.craft_web.id
  scalable_dimension = aws_appautoscaling_target.craft_web.scalable_dimension
  service_namespace  = aws_appautoscaling_target.craft_web.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

/****************************************
* Memory Tracking Scaling
*****************************************/
resource "aws_appautoscaling_policy" "craft_web_memory" {
  name               = "craft_web_memory_tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.craft_web.id
  scalable_dimension = aws_appautoscaling_target.craft_web.scalable_dimension
  service_namespace  = aws_appautoscaling_target.craft_web.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}
