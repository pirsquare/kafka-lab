variable "project" {
  description = "GCP project"
  type        = string
}

variable "project" {
  description = "GCP project"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "broker_count" {
  description = "Number of brokers"
  type        = number
  default     = 3
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.30.10.0/24"
}

variable "allowed_cidr" {
  description = "CIDR allowed to reach Kafka and SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "machine_type" {
  description = "Compute machine type"
  type        = string
  default     = "e2-medium"
}

variable "boot_disk_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "ubuntu"
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
  default     = "gcp-kraft-demo"
}
