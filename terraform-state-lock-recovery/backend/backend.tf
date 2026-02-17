terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "my-tf-state-prod"
    key            = "envs/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-prod"
    encrypt        = true
  }
}
