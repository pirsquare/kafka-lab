terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "kafka-kraft-vnet"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "kafka-kraft-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidr]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "kafka-kraft-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Broker"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.broker_listener_port)
    source_address_prefix      = var.allowed_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Controller"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.controller_listener_port)
    source_address_prefix      = var.allowed_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "External"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.external_listener_port)
    source_address_prefix      = var.allowed_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "JMX"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.jmx_port)
    source_address_prefix      = var.allowed_cidr
    destination_address_prefix = "*"
  }
}

locals {
  node_ids    = range(var.broker_count)
  private_ips = [for idx in local.node_ids : cidrhost(var.subnet_cidr, 10 + idx)]
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

resource "azurerm_public_ip" "pip" {
  count               = var.broker_count
  name                = "kafka-pip-${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  count               = var.broker_count
  name                = "kafka-nic-${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.private_ips[count.index]
    public_ip_address_id          = azurerm_public_ip.pip[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "attach" {
  count                     = var.broker_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "broker" {
  count                 = var.broker_count
  name                  = "kafka-kraft-${count.index + 1}"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(module.kafka.cloud_init_scripts[count.index])
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
  value       = "ssh -i ${var.public_key_path} ${var.admin_username}@${azurerm_public_ip.pip[0].ip_address}"
  description = "SSH into the first broker"
}

output "public_ips" {
  value       = [for p in azurerm_public_ip.pip : p.ip_address]
  description = "Public IPs for brokers"
}

output "private_ips" {
  value       = [for n in azurerm_network_interface.nic : n.ip_configuration[0].private_ip_address]
  description = "Private IPs for brokers"
}
