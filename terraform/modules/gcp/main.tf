terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

resource "google_compute_network" "vpc" {
  name                    = "kafka-kraft-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "kafka-kraft-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "allow" {
  name    = "kafka-kraft-allow"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", var.broker_listener_port, var.controller_listener_port, var.external_listener_port, var.jmx_port]
  }

  source_ranges = [var.allowed_cidr]
  target_tags   = ["kafka-broker"]
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

resource "google_compute_instance" "broker" {
  count        = var.broker_count
  name         = "kafka-kraft-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["kafka-broker"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-focal-v20240130"
      size  = var.boot_disk_gb
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.name
    network_ip = local.private_ips[count.index]

    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)}"
  }

  metadata_startup_script = module.kafka.cloud_init_scripts[count.index]

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
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
  value       = "gcloud compute ssh kafka-kraft-1 --zone ${var.zone} --project ${var.project}"
  description = "SSH into the first broker"
}

output "public_ips" {
  value       = [for i in google_compute_instance.broker : i.network_interface[0].access_config[0].nat_ip]
  description = "Public IPs for brokers"
}

output "private_ips" {
  value       = [for i in google_compute_instance.broker : i.network_interface[0].network_ip]
  description = "Private IPs for brokers"
}
