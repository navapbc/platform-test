locals {
  prefix = var.ecs_cluster_name
}

data "aws_ecs_cluster" "cluster" {
  cluster_name = var.ecs_cluster_name
}
