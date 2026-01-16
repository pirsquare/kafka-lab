terraform {
  required_version = ">= 1.6"
  required_providers {
    random = {
      source = "hashicorp/random"
    }
  }
}

resource "random_uuid" "cluster" {}

locals {
  node_ids = range(var.broker_count)

  controller_quorum_voters = join(",",
    [for idx in local.node_ids : "${idx + 1}@${var.private_ips[idx]}:${var.controller_listener_port}"]
  )

  nodes = {
    for idx in local.node_ids : idx => {
      node_id          = idx + 1
      private_ip       = var.private_ips[idx]
      public_ip        = length(var.public_ips) > idx ? var.public_ips[idx] : ""
      advertised_host  = var.advertise_public && length(var.public_ips) > idx && var.public_ips[idx] != "" ? var.public_ips[idx] : var.private_ips[idx]
      cloud_init_index = idx
    }
  }
}

data "templatefile" "node" {
  for_each = local.nodes
  template = file("${path.module}/cloud-init/install_kafka.sh")
  vars = {
    node_id                   = each.value.node_id
    private_ip                = each.value.private_ip
    advertised_host           = each.value.advertised_host
    controller_voters         = local.controller_quorum_voters
    cluster_id                = random_uuid.cluster.result
    data_dir                  = var.data_dir
    broker_port               = var.broker_listener_port
    controller_port           = var.controller_listener_port
    external_port             = var.external_listener_port
    kafka_version             = var.kafka_version
    scala_variant             = var.kafka_scala_variant
    kafka_download_base_url   = var.kafka_download_base_url
    heap_opts                 = var.heap_opts
    enable_jmx                = var.enable_jmx
    jmx_port                  = var.jmx_port
    cluster_name              = var.cluster_name
  }
}

output "cluster_id" {
  value       = random_uuid.cluster.result
  description = "KRaft cluster ID used for storage formatting"
}

output "controller_quorum_voters" {
  value       = local.controller_quorum_voters
  description = "controller.quorum.voters string"
}

output "cloud_init_scripts" {
  value       = [for idx in local.node_ids : data.templatefile.node[idx].rendered]
  description = "Cloud-init scripts aligned by node index"
}

output "bootstrap_servers" {
  value       = join(",", [for idx in local.node_ids : "${local.nodes[idx].advertised_host}:${var.external_listener_port}"])
  description = "Bootstrap servers for clients"
}

output "node_configs" {
  description = "Per-node configuration context"
  value = {
    for idx in local.node_ids : idx => {
      node_id         = local.nodes[idx].node_id
      private_ip      = local.nodes[idx].private_ip
      public_ip       = local.nodes[idx].public_ip
      advertised_host = local.nodes[idx].advertised_host
    }
  }
}
