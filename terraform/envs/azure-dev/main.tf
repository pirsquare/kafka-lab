terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

module "kafka" {
  source                   = "../../modules/azure"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  broker_count             = var.broker_count
  vnet_cidr                = var.vnet_cidr
  subnet_cidr              = var.subnet_cidr
  allowed_cidr             = var.allowed_cidr
  vm_size                  = var.vm_size
  os_disk_gb               = var.os_disk_gb
  admin_username           = var.admin_username
  public_key_path          = var.public_key_path
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

output "bootstrap_servers" {
  value = module.kafka.bootstrap_servers
}

output "public_ips" {
  value = module.kafka.public_ips
}

output "ssh_command" {
  value = module.kafka.ssh_command
}
