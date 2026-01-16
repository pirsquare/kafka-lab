variable "broker_count" {
  description = "Number of brokers/controllers"
  type        = number
  default     = 3
  validation {
    condition     = var.broker_count >= 1
    error_message = "broker_count must be at least 1"
  }
}

variable "private_ips" {
  description = "Private IPs for each broker"
  type        = list(string)
}

variable "public_ips" {
  description = "Public IPs for each broker (optional, aligns by index)"
  type        = list(string)
  default     = []
}

variable "advertise_public" {
  description = "Advertise public IPs instead of private"
  type        = bool
  default     = false
}

variable "data_dir" {
  description = "Kafka data directory"
  type        = string
  default     = "/var/lib/kafka"
}

variable "kafka_version" {
  description = "Kafka version to download"
  type        = string
  default     = "3.8.0"
}

variable "kafka_scala_variant" {
  description = "Scala binary variant"
  type        = string
  default     = "2.13"
}

variable "kafka_download_base_url" {
  description = "Base URL for Kafka downloads"
  type        = string
  default     = "https://downloads.apache.org/kafka"
}

variable "heap_opts" {
  description = "Heap options for Kafka"
  type        = string
  default     = "-Xms1g -Xmx1g"
}

variable "jmx_port" {
  description = "JMX port"
  type        = number
  default     = 9999
}

variable "enable_jmx" {
  description = "Enable JMX"
  type        = bool
  default     = true
}

variable "broker_listener_port" {
  description = "Broker listener port"
  type        = number
  default     = 9092
}

variable "controller_listener_port" {
  description = "Controller listener port"
  type        = number
  default     = 9093
}

variable "external_listener_port" {
  description = "External listener port for clients"
  type        = number
  default     = 9094
}

variable "cluster_name" {
  description = "Logical cluster name for identification"
  type        = string
  default     = "kraft-demo"
}
