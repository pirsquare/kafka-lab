# Troubleshooting

- Advertised listeners mismatch
  - Ensure `HOST_IP` in local `.env` matches how clients reach Docker (Docker Desktop: `host.docker.internal`; WSL2: host IP from `ipconfig` under vEthernet).
  - Cloud: if clients are inside the VPC/VNet, keep `advertise_public=false` so `bootstrap_servers` use private IPs.

- Ports blocked / firewalls
  - Open 9092 (broker), 9093 (controller), 9094 (external), 22 (SSH), and optional 9999 (JMX) to your client CIDR only.

- Disk or formatting issues
  - If you change `data_dir`, the storage formatter may need to re-run. Delete the data dir on the VM (demo only) or keep the same `cluster_id`.

- Service not starting (cloud VMs)
  - `journalctl -u kafka -f` to view systemd logs.
  - Verify Java installed and tarball fetched; cloud-init logs: `/var/log/cloud-init-output.log`.

- CLI connectivity
  - From your laptop: `kafka-topics --bootstrap-server <bootstrap> --list`.
  - From inside a VM: use private `kafka:9092` equivalent (node private IP).

- Windows newline / PowerShell
  - Scripts use LF-compatible pipes; avoid Notepad mangling. Re-copy `.env` from `.env.example` if parsing errors occur.
