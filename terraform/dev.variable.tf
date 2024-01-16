variable "region" {
  type        = string
  description = "This ia default region"
}

variable "ecr_name" {
  type        = string
  description = "This is ecr repository name"
}

variable "ecs_name" {
  type        = string
  description = "This is ecs cluster and service name"
}

variable "image_name" {
  type        = string
  description = "This is ecs cluster and service name"
}

variable "cluster_name" {
  type        = string
  description = "This is ecs cluster and service name"
}

variable "task_definition" {
  type        = string
  description = "This is task for ecs service"
}

variable "vpc_id" {
  type        = string
  description = "This is a default vpc"
}


variable "subnet" {
  type        = string
  description = "This is a default vpc"
}

variable "task_role_dev" {
  type        = string
  description = "This is a new role"
}
