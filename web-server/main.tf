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

# 단일 인스턴스
#resource "aws_instance" "example" {
#  instance_type     = "t2.micro"
#  availability_zone = data.aws_availability_zones.this.names[0]
#  ami               = data.aws_ami.this.id
#  vpc_security_group_ids = [aws_security_group.instance.id]
#  user_data = <<-EOF
#              #!/bin/bash
#              echo "Hello, World" > index.html
#              nohup busybox httpd -f -p ${var.server_port} &
#              EOF
#  user_data_replace_on_change = true
#  tags = {
#    Name = "terraform-example"
#  }
#}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  # ap-northeast-2d는 t2.micro 인스턴스를 지원하지 않아 필터 추가
  filter {
    name   = "availability-zone"
    values = ["ap-northeast-2a", "ap-northeast-2c"]
  }
}

# ASG
resource "aws_launch_configuration" "example" {
  image_id        = data.aws_ami.this.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnets.default.ids
  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance" {
  name        = "terraform-example-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}