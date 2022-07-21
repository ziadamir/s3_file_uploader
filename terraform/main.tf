terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# //////////////////////////////
# PROVIDERS
# //////////////////////////////

provider "aws" {
  region = var.aws_region
}

# //////////////////////////////
# VARIABLES
# //////////////////////////////
variable "aws_account_id" {
    type = string
}

variable "aws_region" {
    type = string
}


variable "vpc_cidr" {
    type = string
}

variable "subnet_a_cidr" {
    type = string
}

variable "subnet_b_cidr" {
    type = string
}

variable "image_tag" {
    type = string
}

variable "process" {
    type = string
}


# //////////////////////////////
# NETWORK RESOURCES
# //////////////////////////////

# VPC
resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = "true"
}

# subnet_a
resource "aws_subnet" "public_subnet_a" {
  cidr_block = var.subnet_a_cidr
  vpc_id = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone = "${var.aws_region}a"
}

# subnet_b
resource "aws_subnet" "public_subnet_b" {
  cidr_block = var.subnet_b_cidr
  vpc_id = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone = "${var.aws_region}b"
}

# INTERNET_GATEWAY
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
}

# ROUTE_TABLE
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "route_public_subnet_a" {
  subnet_id = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "route_public_subnet_b" {
  subnet_id = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}


# SECURITY_GROUP
resource "aws_security_group" "ecs_service_security_group" {
  name = "ecs_service_security_group"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# //////////////////////////////
# IAM RESOURCES
# //////////////////////////////

# IAM ROLE POLICY

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "${var.process}_ecs_task_policy"
  role = aws_iam_role.ecs_task_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:Get*",
          "s3:Put*",
          "s3:List*",
          "s3:Create*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action =  [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Effect    = "Allow"
        Resource  =  "*"
        Condition = {
          "StringEquals": {
            "aws:sourceVpc": "${aws_vpc.vpc.id}"
            }
          }
      }    
    ]
  })
}

# IAM ROLE

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.process}_ecs_task_role"
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "environment-${var.env}"
  }
}

# //////////////////////////////
# CONTAINER RESOURCES
# //////////////////////////////

# Create log group
resource "aws_cloudwatch_log_group" "s3_file_uploader_ecs_log_group" {
  name = "/ecs/${var.process}"
  retention_in_days = 30
}


# Create ECS cluster
resource "aws_ecs_cluster" "s3_file_uploader_cluster" {
  name = "${var.process}_ecs_cluster"
}

# Create task definition in ECS
resource "aws_ecs_task_definition" "s3_file_uploader_task_definition" {
  family                   = var.process
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  container_definitions = <<TASK_DEFINITION
[
  {
    "image": "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.process}:${var.image_tag}",
    "name": "${var.process}_ecs_cluster",
    "cpu": 1024,
    "memory": 2048,
    "command": ["java", "-jar", "S3FileUpload-1.0.jar"],
	"portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-region" : "us-east-1",
                    "awslogs-group" : "/ecs/${var.process}",
                    "awslogs-stream-prefix" : "ecs"
                }
            },
    "networkMode": "awsvpc"
  }
]
TASK_DEFINITION
  
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

# ECS service that runs all the time and is able to launch and auto-heal our task if/when it dies
resource "aws_ecs_service" "ecs_service" {
  name             = "${var.process}_service"
  cluster          = aws_ecs_cluster.s3_file_uploader_cluster.id
  task_definition  = aws_ecs_task_definition.s3_file_uploader_task_definition.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  network_configuration {
    security_groups = [aws_security_group.ecs_service_security_group.id]
    subnets         = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
    assign_public_ip = true
  }

}


