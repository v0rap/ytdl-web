terraform {
  required_providers {
    aws = {  # AWS Provider for... well... AWS stuff
      source = "hashicorp/aws"
    }
  }

  cloud {  # Required to use app.terraform.com to deploy
    organization = "thvxl"

    workspaces {
      name = "ytdl"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

resource "aws_ecr_repository" "ytdl_repo" {
  name                 = "ytdl"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_role" "iam_ytdl" {  # Used to only allow access to lambda for the function
  name               = "iam_ytdl"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

/*
resource "aws_lambda_function" "api_lambda" {
  image_uri     = "ghcr.io/v0rap/ytdl-web:latest"
  function_name = "ytdl"
  package_type  = "Image"
  role          = aws_iam_role.iam_ytdl.arn
  handler       = "app.handler"
  runtime       = "python3.9"
} */