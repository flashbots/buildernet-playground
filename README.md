# BuilderNet Playground

This repository orchestrates three main components:

1. **[builder-hub](./builder-hub)** – A service (and Postgres DB) for managing builder configs/secrets.  
2. **[builder-playground](./builder-playground)** – A tool that spawns ephemeral Ethereum L1/CL services (Reth, Lighthouse, mev-boost, etc.) via a generated Docker Compose.  
3. **QEMU** (TODO) – A VM environment (“BuilderNet”) that can persist state (e.g., a 2 TB disk), bridging or port-forwarding to the Docker containers.

---

## Repository Layout

buildernet-playground/  
├── builder-hub/          # submodule  
├── builder-playground/   # submodule  
├── docker-compose.yml    # Docker Compose for builder-hub + Postgres  
├── Makefile              # Orchestration tasks  
└── README.md

**Key points**:
- `builder-hub/` and `builder-playground/` are **git submodules** pointing to their respective repos.
- `docker-compose.yml` launches builder-hub + Postgres for stable usage.
- The **Makefile** orchestrates everything: submodules, builder-hub, ephemeral L1, and optional QEMU commands.

---

## Requirements

- **Docker** & **Docker Compose**  
- **Go** 1.20+ (for running builder-playground from source)  
- **QEMU** & **KVM** (optional, if you plan to run the VM)

---

## Cloning
```
git clone --recurse-submodules https://github.com/your-org/buildernet-playground.git  
cd buildernet-playground  
# If you forgot --recurse-submodules:  
git submodule update --init --recursive  
```
---

## Makefile Targets

- **setup-submodules**: Clones/updates `builder-hub` and `builder-playground`.  
- **build**: Builds images for builder-hub (if Dockerfile is present).  
- **up**: Starts builder-hub + Postgres (docker compose up -d).  
- **down**: Stops builder-hub + Postgres (docker compose down).  
- **start-playground**: Runs `go run main.go --recipe l1` in builder-playground, spinning up ephemeral L1.  
- **stop-playground**: Placeholder (commented) if builder-playground supports a “stop” command.  
- **create-disk**: Placeholder (TODO) for creating a 2 TB QEMU disk.  
- **start-qemu / stop-qemu**: Placeholders (TODO) for launching and stopping QEMU.  
- **all**: Calls `setup-submodules`, `up`, and `start-playground` in sequence.  
- **stop-all**: Calls `down`, `stop-playground`, and `stop-qemu` (all in minimal form) to stop everything.  
- **clean**: A full reset. It runs `stop-all`, then removes volumes/images, and calls `clean-qemu` to stop and remove the qemu disk image.

---

## Networking Notes

- **builder-hub** is defined in `docker-compose.yml`; by default it publishes ports 8080, 8081, and 8082.  
- **Ephemeral L1** from builder-playground typically reserves ports like 8545, 8551, 5052, 5054. The local_runner code in builder-playground auto-assigns them.  
- **QEMU** (TODO): If you use `-nic user`, the VM can reach Docker containers at `10.0.2.2:<port>`. For bridging, you’d edit `start-qemu` with a TAP device or bridging config.

---

## License

This project is under the MIT License. See [LICENSE](LICENSE) for details.  
Submodules (builder-hub, builder-playground) may have their own licenses. Check each repository for specifics.
