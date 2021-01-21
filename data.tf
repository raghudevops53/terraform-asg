data "aws_ami" "ami" {
  most_recent       = true
  owners            = ["self"]

  filter {
    name            = "name"
    values          = ["${var.COMPONENT}-${var.APP_ARTIFACT_VERSION}"]
  }
}

data "terraform_remote_state" "vpc" {
  backend           = "s3"
  config            = {
    bucket          = var.bucket
    key             = "vpc/${var.ENV}/terraform.tfstate"
    region          = var.region
  }
}