terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
  profile = "terraform-up-and-running-oyj"
}

# Ubuntu AMI 찾기
data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Ubuntu AMI 소유자인 Canonical의 AWS 계정 ID
}

data "aws_availability_zones" "this" {
  state = "available"
}

resource "aws_instance" "app" {
  instance_type     = "t2.micro"
  availability_zone = data.aws_availability_zones.this.names[0]
  ami               = data.aws_ami.this.id
  user_data = <<-EOF
              #!/bin/bash
              sudo service apache2 start
              EOF
}

