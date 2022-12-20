variable "image_version" {
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

resource "aws_api_gateway_rest_api" "ytdl" {
  name        = "ytdl-rest-api"
  description = "ytdl api gateway for lambda functions"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.ytdl.id}"
  parent_id   = "${aws_api_gateway_rest_api.ytdl.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.ytdl.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "ytdl_lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.ytdl.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.api_lambda.invoke_arn}"
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

resource "aws_iam_role_policy_attachment" "lambda_role_attach" {  # Required to provide access to write cloudwatch logs
  role       = aws_iam_role.iam_ytdl.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_lambda_function" "api_lambda" {
  image_uri     = "981644780922.dkr.ecr.eu-north-1.amazonaws.com/ytdl:${var.image_version}"
  function_name = "ytdl"
  package_type  = "Image"
  timeout = "8"  # Seconds before the function times out and returns internal server error
  role          = aws_iam_role.iam_ytdl.arn
  
}

resource "aws_api_gateway_deployment" "ytdl_api" {
  depends_on = [
    aws_api_gateway_integration.ytdl_lambda
  ]

  rest_api_id = "${aws_api_gateway_rest_api.ytdl.id}"
  stage_name  = "prod"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.api_lambda.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.ytdl.execution_arn}/*/*"
}