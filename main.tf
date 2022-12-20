variable "version" {
  type = string
}

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

resource "aws_ecr_repository_policy" "ytdl_repo_policy" {
  repository = aws_ecr_repository.ytdl_repo.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": {
              "AWS": "arn:aws:iam::981644780922:root"
            },
            "Action": [
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
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
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


resource "aws_lambda_function" "api_lambda" {
  image_uri     = "981644780922.dkr.ecr.eu-north-1.amazonaws.com/ytdl:${var.version}"
  function_name = "ytdl"
  package_type  = "Image"
  role          = aws_iam_role.iam_ytdl.arn
  handler       = "app.handler"
  runtime       = "python3.9"
}