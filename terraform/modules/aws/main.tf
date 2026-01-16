terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

data "aws_availability_zones" "available" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-*"]
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "kafka-kraft-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "kafka-kraft-public"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "kafka" {
  name        = "kafka-kraft-sg"
  description = "Kafka demo security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "Kafka broker"
    from_port   = var.broker_listener_port
    to_port     = var.broker_listener_port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "KRaft controller"
    from_port   = var.controller_listener_port
    to_port     = var.controller_listener_port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "External listener"
    from_port   = var.external_listener_port
    to_port     = var.external_listener_port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "JMX"
    from_port   = var.jmx_port
    to_port     = var.jmx_port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "ssh" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

locals {
  node_ids    = range(var.broker_count)
  private_ips = [for idx in local.node_ids : cidrhost(var.public_subnet_cidr, 10 + idx)]
}

module "kafka" {
  source                   = "../kafka_vm_cluster"
  broker_count             = var.broker_count
  private_ips              = local.private_ips
  advertise_public         = var.advertise_public
  data_dir                 = var.data_dir
  kafka_version            = var.kafka_version
  kafka_scala_variant      = var.kafka_scala_variant
  kafka_download_base_url  = var.kafka_download_base_url
  heap_opts                = var.heap_opts
  jmx_port                 = var.jmx_port
  broker_listener_port     = var.broker_listener_port
  controller_listener_port = var.controller_listener_port
  external_listener_port   = var.external_listener_port
  cluster_name             = var.cluster_name
}

resource "aws_instance" "broker" {
  count                       = var.broker_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  private_ip                  = local.private_ips[count.index]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh.key_name
  vpc_security_group_ids      = [aws_security_group.kafka.id]
  user_data                   = module.kafka.cloud_init_scripts[count.index]

  root_block_device {
    volume_size = var.root_volume_size
  }

  tags = {
    Name = "kafka-kraft-${count.index + 1}"
  }
}

output "bootstrap_servers" {
  value       = module.kafka.bootstrap_servers
  description = "Bootstrap servers (advertised hosts)"
}

output "controller_quorum_voters" {
  value       = module.kafka.controller_quorum_voters
  description = "KRaft controller voters"
}

output "ssh_command" {
  value       = "ssh -i ${var.public_key_path} ubuntu@${aws_instance.broker[0].public_ip}"
  description = "SSH into the first broker"
}

output "public_ips" {
  value       = [for i in aws_instance.broker : i.public_ip]
  description = "Public IPs for the brokers"
}

output "private_ips" {
  value       = [for i in aws_instance.broker : i.private_ip]
  description = "Private IPs for the brokers"
}
