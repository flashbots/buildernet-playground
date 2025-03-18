# File: Makefile

# The Docker Compose file that starts builder-hub + DB
COMPOSE_FILE = docker-compose.yml

# Submodules
HUB_SUBMODULE_DIR = builder-hub
PLAYGROUND_SUBMODULE_DIR = builder-playground

# Name of the QCOW2 disk for QEMU
QEMU_DISK = buildernet.qcow2
# Desired size for the disk
QEMU_DISK_SIZE = 2T

# We'll store QEMU's PID in a file so we can stop it later
QEMU_PID_FILE = .qemu.pid

# 1. SETUP: initialize or update submodules
setup-submodules:
	git submodule update --init --recursive

# 2. BUILD or pull images if needed
build:
	docker compose -f $(COMPOSE_FILE) build

# 3. Bring up builder-hub + DB
up:
	docker compose -f $(COMPOSE_FILE) up -d

# 4. Tear down builder-hub + DB
down:
	docker compose -f $(COMPOSE_FILE) down

# 5. Start ephemeral L1 environment with builder-playground
start-playground:
	cd $(PLAYGROUND_SUBMODULE_DIR) && go run main.go --recipe l1

# 6. Stop ephemeral containers from builder-playground
#    (assuming builder-playground supports a "stop" command.)
stop-playground:
#	cd $(PLAYGROUND_SUBMODULE_DIR) && go run main.go stop || true

# 7. Create a QEMU disk image of size 2T
# TODO: replace with the correct qemu-img command to create a disk image of the desired size
create-disk:
#	qemu-img create -f qcow2 $(QEMU_DISK) $(QEMU_DISK_SIZE)

# 8. Start QEMU with that disk (placeholder command – adapt as needed)
# TODO: replace with correct qemu command with the correct network configuration and port mapping and disk image attached configuration
start-qemu:
#	@if [ -f $(QEMU_PID_FILE) ]; then echo "QEMU appears to be running ($(QEMU_PID_FILE) exists). Stop it first with 'make stop-qemu'."; exit 1; fi
#	qemu-system-x86_64 \\
#	  -m 4096 \\
#	  -enable-kvm \\
#	  -drive file=$(QEMU_DISK),if=virtio \\
#	  -nic user,model=virtio-net-pci,hostfwd=tcp::10022-:22 \\
#	  -daemonize \\
#	  -pidfile $(QEMU_PID_FILE)
#	@echo "QEMU started in background, PID stored in $(QEMU_PID_FILE)."

# 9. Stop QEMU by killing PID in .qemu.pid
stop-qemu:
#	 @if [ ! -f $(QEMU_PID_FILE) ]; then echo "No QEMU pid file found. Maybe QEMU isn't running?"; exit 0; fi
#	 @pid=$$(cat $(QEMU_PID_FILE)) && echo "Stopping QEMU with PID $$pid..." && kill $$pid
#	 @rm -f $(QEMU_PID_FILE)

# 10. Clean QEMU: ensures QEMU is stopped, optionally removes disk
clean-qemu: stop-qemu
#	@echo "Removing QEMU disk $(QEMU_DISK) (optional)..."
#	rm -f $(QEMU_DISK)

# 11. Combined “all” target that sets up submodules, starts builder-hub, and playground
all: setup-submodules up start-playground
	@echo "All services are up. (QEMU optional)"

# 12. Stop everything: remove containers, ephemeral L1, (optionally volumes)
stop-all: down stop-playground stop-qemu
	@echo "All containers down and qemu is stopped."

# 13. Stops all and fully remove volumes, images, ephemeral, etc.
#     This is the "start-from-scratch" environment.
clean: stop-all
	@echo "Performing distribution-level cleanup..."
	docker compose -f $(COMPOSE_FILE) down --volumes --rmi local
	@echo "Volumes, local images for builder-hub, and containers removed."
	$(MAKE) clean-qemu
	@echo "Dist-clean complete."
