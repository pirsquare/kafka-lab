# Kafka Lab (KRaft)

Quickstart-friendly repo to run Apache Kafka without ZooKeeper in two modes:

- Local single-broker demo on Windows via Docker Compose.
- Multi-cloud Terraform modules that spin up VM-based KRaft clusters (plus optional managed Kafka notes).

## What you get
- KRaft-only configuration (no ZooKeeper).
- Minimal moving parts, defaults tuned for quick demos.
- Scripts for topic creation, producing, consuming, and smoke tests.
- Optional JMX port exposure and basic logging.
- Terraform modules with a common interface across AWS, GCP, and Azure.

---
## Local (Docker Compose)
1) Install Docker Desktop and Python 3.9+.
2) Install local Python deps:
```bash
python -m pip install -r local/requirements.txt
```
3) Copy env template and start:
```bash
cd local
cp .env.example .env
python ./scripts/up.py
```
4) Smoke test (Python client):
```bash
python ./scripts/demo_client.py --bootstrap host.docker.internal:9094 --topic demo-topic --messages one two three
# or the short wrapper
python ./scripts/smoke_test.py
```
5) Tear down:
```bash
python ./scripts/down.py
```

### Advertised listeners (local)
- `EXTERNAL` listener binds to `0.0.0.0:9094` and advertises `host.docker.internal:9094` by default (works on Docker Desktop for Windows).
- `PLAINTEXT` listener binds to `0.0.0.0:9092` for internal container traffic; inter-broker uses this too.
- `CONTROLLER` listener binds to `0.0.0.0:9093` for the KRaft controller.
- Update `.env` if your host IP differs (e.g., WSL2 or remote VM).

### JMX / observability (local)
- JMX optional: exposed on `9999` when `ENABLE_JMX=true` in `.env`.
- Logs are stdout (via Docker) plus Kafka log files inside the container under `/bitnami/kafka/logs`.

### Scaling locally
- Default is a single broker/controller combined process. To scale toward 3 brokers, duplicate the service block and adjust `node.id`, ports, and `controller.quorum.voters` accordingly.

---
## Terraform (VM-based KRaft clusters)
- Common interface via `modules/kafka_vm_cluster` for KRaft config, cloud-init, and outputs.
- Thin per-cloud wrappers under `modules/aws`, `modules/gcp`, `modules/azure` create networking + VMs and feed node info to the common module.
- Environments live under `terraform/envs/<cloud>-dev` with example tfvars.

### Prereqs
- Terraform >= 1.6
- Provider credentials configured (AWS CLI, gcloud auth, Azure CLI) and SSH key pair available.

### AWS quickstart (defaults to ap-southeast-1)
```pwsh
cd terraform/envs/aws-dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```
Outputs include bootstrap servers and SSH instructions.

### GCP quickstart (defaults to asia-southeast1)
```pwsh
cd terraform/envs/gcp-dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

### Azure quickstart (defaults to southeastasia)
```pwsh
cd terraform/envs/azure-dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

### Managed Kafka (optional)
- AWS: MSK (Kafka-compatible) can replace the self-hosted module; supply the MSK bootstrap server to your clients.
- Azure: Event Hubs Kafka endpoint works for most Kafka clients; mind protocol differences (SASL/PLAIN + TLS).
- Confluent Cloud: drop-in Kafka-compatible SaaS; provide bootstrap + API keys.

---
## KRaft basics
- KRaft uses an internal controller quorum (no ZooKeeper). Minimum 1 controller for demo, 3 for resilience.
- Each node has a `node.id` and participates in both broker and controller roles in this sample.
- Cluster ID must be consistent across all nodes; the cloud-init script generates one and formats storage via `kafka-storage.sh`.
- `controller.quorum.voters` lists `nodeId@controllerHost:controllerPort` for all controllers.

---
## Repository layout
- local/ — Docker Compose + Python helpers.
- terraform/ — modules and per-cloud envs.
- docs/ — architecture and troubleshooting notes.

---
## Next steps
- Check [docs/architecture.md](docs/architecture.md) for diagram and flow.
- See [docs/troubleshooting.md](docs/troubleshooting.md) for common pitfalls (advertised listeners, networking, firewall, disk).
