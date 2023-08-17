# ------------------------------------------------------
# PROVIDER
# ------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token = var.aws_session_token
}

module "us-east-1" {
  source            = "./deployment/amazon"
  id                = random_id.stack_id.hex
  region            = "us-east-1"
  providers = {
    aws = aws.us-east-1
  }
}

# use this snippet for deployment in another region

# provider "aws" {
#   alias  = "eu-west-1"
#   region = "eu-west-1"
#   access_key = var.aws_access_key
#   secret_key = var.aws_secret_key
#   token = var.aws_session_token
# }

# module "eu-west-1" {
#   source            = "./deployment/amazon"
#   id                = random_id.stack_id.hex
#   region            = "eu-west-1"
#   providers = {
#     aws = aws.eu-west-1
#   }
# }