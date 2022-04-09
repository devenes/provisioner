terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "tf-sec-gr" {
  name        = "tf-provisioner-sg"
  description = "Security group for terraform provisioner"

  tags = {
    Name = "tf-provisioner-sg"
  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "instance" {
  ami             = var.ec2_ami
  instance_type   = var.ec2_type
  key_name        = var.key_name
  security_groups = ["tf-provisioner-sg"]

  tags = {
    Name = "terraform-instance-with-provisioner"
  }

  provisioner "local-exec" {
    command = "echo http://${self.public_ip} > public_ip.txt"
  }

  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/enes.pem")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install httpd",
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd"
    ]
  }

  provisioner "file" {
    content     = self.public_ip
    destination = "/home/ec2-user/my_public_ip.txt"
  }
}
