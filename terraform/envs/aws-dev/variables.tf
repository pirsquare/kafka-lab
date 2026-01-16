variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "broker_count" {
  description = "Number of brokers"
  type        = number
  default     = 3
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
  default     = "10.20.10.0/24"
}

variable "allowed_cidr" {
  description = "CIDR allowed to reach Kafka and SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root volume size"
  type        = number
  default     = 50
}

variable "key_name" {
  description = "Key pair name"
  type        = string
  default     = "kafka-demo-key"
}

variable "public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "advertise_public" {
  description = "Advertise public IPs"
  type        = bool
  default     = false
}

variable "data_dir" {
  description = "Kafka data dir"
  type        = string
  default     = "/var/lib/kafka"
}

variable "kafka_version" {
  description = "Kafka version"
  type        = string
  default     = "3.8.0"
}

variable "kafka_scala_variant" {
  description = "Scala variant"
  type        = string
  default     = "2.13"
}

variable "kafka_download_base_url" {
  description = "Kafka download base URL"
  type        = string
  default     = "https://downloads.apache.org/kafka"
}

variable "heap_opts" {
  description = "Kafka heap opts"
  type        = string
  default     = "-Xms1g -Xmx1g"
}

variable "jmx_port" {
  description = "JMX port"
  type        = number
  default     = 9999
}

variable "broker_listener_port" {
  description = "Broker port"
  type        = number
  default     = 9092
}

variable "controller_listener_port" {
  description = "Controller port"
  type        = number
  default     = 9093
}

variable "external_listener_port" {
  description = "External client port"
  type        = number
  default     = 9094
}

variable "cluster_name" {
  description = "Cluster name"
  type        = string
  default     = "aws-kraft-dev"
}
