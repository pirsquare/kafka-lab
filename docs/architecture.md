# Architecture

## Local (Docker Compose)
- Single container running Kafka in KRaft mode (broker + controller roles).
- Listeners
  - PLAINTEXT: internal container comms and inter-broker (9092)
  - CONTROLLER: KRaft controller listener (9093)
  - EXTERNAL: client access from host (9094), advertised as `host.docker.internal` by default on Docker Desktop for Windows
- Data is persisted to a named Docker volume `kafka_data`.
- Optional JMX on 9999.

Scaling to 3 brokers locally:
- Duplicate the service stanza (kafka2, kafka3), increment `KAFKA_CFG_NODE_ID`, adjust ports, and expand `controller.quorum.voters` (e.g., `1@kafka:9093,2@kafka2:19093,3@kafka3:29093`).

## Cloud (Terraform, VM-based KRaft)
- Common module `modules/kafka_vm_cluster` generates per-node cloud-init that:
  - Installs Java + Kafka
  - Writes `server.properties` with KRaft settings
  - Generates cluster ID (Terraform `random_uuid`) and formats storage via `kafka-storage.sh`
  - Starts Kafka via systemd
- Per-cloud wrappers provision network + VMs and feed node IPs to the common module.
  - AWS: VPC + subnet + SG + EC2 instances with user-data
  - GCP: VPC + subnet + firewall + Compute Engine instances with startup scripts
  - Azure: VNet + subnet + NSG + Linux VMs with cloud-init
- Listeners (per node)
  - PLAINTEXT on private IP/9092 for inter-broker
  - CONTROLLER on private IP/9093 for quorum
  - EXTERNAL on advertised host/9094 for clients (public or private depending on `advertise_public`)
- Outputs expose `bootstrap_servers` and `controller_quorum_voters` for client configs and scaling.

## Optional managed Kafka paths
- AWS MSK, Azure Event Hubs (Kafka endpoint), Confluent Cloud can replace the self-hosted module by supplying their bootstrap endpoints to clients.
