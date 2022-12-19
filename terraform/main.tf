terraform {
  cloud {
    organization = "thvxl"

    workspaces {
      name = "ytdl"
    }
  }
}
resource "aws_iam_role" "iam_ytdl" {  # Used to only allow access to lambda for the function
  name = "iam_ytdl"
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

resource "aws_lambda_function" "test_lambda" {
  image_uri     = "ghcr.io/v0rap/ytdl:latest"
  function_name = "ytdl"
  role          = aws_iam_role.iam_ytdl.arn
  handler       = "app.handler"
  runtime = "python3.9"
}