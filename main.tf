##########
# Defaults
##########

provider "aws" {
  region = "us-east-1"
}
resource "aws_ecr_repository" "ecs_push" {
  name = "ecs_push"
}

resource "aws_codebuild_project" "codebuild_project" {
  name          = "ecr_push"
  description   = "ecr_push"
  build_timeout = "120"
  service_role  = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/Datsent/ECR_PUSH.git"
    git_clone_depth = 1
    git_submodules_config {
      fetch_submodules = true
    }
  }

  environment {
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    environment_variable {
      name  = "DOCKERHUB_USERNAME"
      value = "dockerhub:username"
      type = "SECRETS_MANAGER"
    }
    environment_variable {
      name  = "DOCKERHUB_PASSWORD"
      value = "dockerhub:password"
      type = "SECRETS_MANAGER"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status = "DISABLED"
    }
  }
}

# IAM
resource "aws_iam_role" "codebuild_role" {
  name  = "ecr_push_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codebuild_deploy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}