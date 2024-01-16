terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~> 4.16"
    }
  }
  backend "s3" {}

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "default_vpc" {
  default = true
  id      = var.vpc_id
}

data "aws_subnet" "subnets" {
  for_each          = toset(["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"])
  vpc_id            = data.aws_vpc.default_vpc.id
  availability_zone = each.value
}

data "aws_iam_policy_document" "taskpolicy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
    ]
  }
}

resource "aws_iam_role" "task_role" {

  name = var.task_role_dev
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name   = "EcsTaskExecutionPolicy"
    policy = data.aws_iam_policy_document.taskpolicy.json
  }
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = aws_iam_role.task_role.name
}

resource "aws_ecs_cluster" "cluster" {
  name               = var.cluster_name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = "1"
  }
}

resource "aws_ecs_task_definition" "task" {
  family = "service"
  requires_compatibilities = [
    "FARGATE"
  ]
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  network_mode       = "awsvpc"
  cpu                = 256
  memory             = 512
  container_definitions = jsonencode([
    {
      name      = var.ecs_name
      image     = var.image_name
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "service" {
  name            = var.ecs_name
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1

  network_configuration {
    subnets          = [for s in data.aws_subnet.subnets : s.id]
    assign_public_ip = true
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

resource "aws_ecr_repository" "repository" {
  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"
}