# Terraform: KRaft VM clusters

This folder contains a common KRaft module plus thin cloud wrappers for AWS, GCP, and Azure. Each env under `envs/` wires up the wrapper with sane defaults for a small demo cluster.

## Design
- `modules/kafka_vm_cluster` builds cloud-init scripts, KRaft configs, and outputs (bootstrap servers, quorum voters).
- `modules/aws|gcp|azure` create network + compute for each cloud and feed node addresses into the common module.
- `envs/<cloud>-dev` are runnable examples with tfvars templates.

## Variables (common)
- `broker_count` — number of brokers/controllers (default 3 for cloud, but you can set 1 for a tiny demo).
- `advertise_public` — advertise public IPs instead of private (default false; keep false when using private networking).
- `kafka_version` — override Kafka download version (defaults to 3.8.0; change via tfvars).
- `data_dir` — data directory used by Kafka and storage formatter (default `/var/lib/kafka`).

## Outputs (common)
- `bootstrap_servers` — comma-delimited `host:port` for clients.
- `controller_quorum_voters` — string for KRaft controller config.
- `cluster_id` — generated UUID used for storage formatting.

## Cloud notes
- SSH uses your provided key; hardening (TLS/SASL, disk encryption, private-only) is noted but not enforced.
- Instance types are modest by default; bump CPU/memory to handle more partitions or higher throughput.
- Open security groups/firewalls are limited to broker, controller, JMX, and SSH ports. Tighten to your CIDR ranges.

## Managed Kafka (optional)
If you prefer managed offerings, replace the module call with:
- AWS: `aws_msk_cluster` or `aws_msk_serverless_cluster`
- Azure: Event Hubs namespace with Kafka enabled
- Confluent Cloud: no infra, only credentials; wire outputs to your apps

## Workflow
```pwsh
cd terraform/envs/<cloud>-dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```
Use `terraform destroy` to clean up.
