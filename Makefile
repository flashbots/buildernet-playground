# Configuration variables
BZIMAGE_PATH ?= $(PWD)/bzImage
ORIGINAL_CPIO ?= $(PWD)/cvm-initramfs-tdx.cpio.gz
DEBUG_SCRIPT := $(PWD)/debug-yolo
AZURE_SCRIPT := $(PWD)/azure-complete-provisioning
DISK_ENCRYPTION_INIT_SCRIPT := $(PWD)/disk-encryption
RETH_SYNC_SCRIPT := $(PWD)/reth-sync
CVM_REVERSE_PROXY_CLIENT_INIT_SCRIPT := $(PWD)/cvm-reverse-proxy-client-init
LIGHTHOUSE_INIT_SCRIPT := $(PWD)/lighthouse
RETH_INIT_SCRIPT := $(PWD)/reth
WORKDIR := $(PWD)/build
EXTRACT_DONE := $(WORKDIR)/.extract_done
INJECT_DONE := $(WORKDIR)/.inject_done
FIXED_CPIO := $(WORKDIR)/fixed-initramfs.cpio
FIXED_CPIO_GZ := $(WORKDIR)/fixed-initramfs.cpio.gz
QCOW2_IMAGE := $(PWD)/persistent.qcow2
QCOW2_SIZE := 2T

# SSH & port configuration
QEMU_MEM ?= 8G
QEMU_SMP ?= 8

# SSH key for development (comment out if you don't want to inject a key)
# Will use ~/.ssh/id_rsa.pub as default if it exists
SSH_KEY_PATH ?= $(shell if [ -f ~/.ssh/id_rsa.pub ]; then echo ~/.ssh/id_rsa.pub; fi)

# Default target
all: inject

# Create working directory
$(WORKDIR):
	mkdir -p $(WORKDIR)

# Extract initramfs (only if not already done or dependencies changed)
$(EXTRACT_DONE): $(ORIGINAL_CPIO) | $(WORKDIR)
	@echo "Extracting original initramfs..."
	rm -rf $(WORKDIR)/extract
	mkdir -p $(WORKDIR)/extract
	cd $(WORKDIR)/extract && gunzip -c $(ORIGINAL_CPIO) | sudo cpio -idmv > /dev/null 2>&1
	touch $(EXTRACT_DONE)

# Inject debug script (only if not already done or dependencies changed)
$(INJECT_DONE): $(EXTRACT_DONE) $(DEBUG_SCRIPT) $(AZURE_SCRIPT)
	@echo "Installing debug script..."
	sudo cp $(DEBUG_SCRIPT) $(WORKDIR)/extract/etc/init.d/debug-yolo
	sudo chmod +x $(WORKDIR)/extract/etc/init.d/debug-yolo
	sudo chown root:root $(WORKDIR)/extract/etc/init.d/debug-yolo
	@echo "Creating runlevel symlinks..."
	cd $(WORKDIR)/extract && \
		sudo ln -sf ../init.d/debug-yolo etc/rc2.d/S89debug-yolo && \
		sudo ln -sf ../init.d/debug-yolo etc/rc3.d/S89debug-yolo && \
		sudo ln -sf ../init.d/debug-yolo etc/rc4.d/S89debug-yolo && \
		sudo ln -sf ../init.d/debug-yolo etc/rc5.d/S89debug-yolo

	@echo "Overwriting /etc/init.d/azure-complete-provisioning..."
	sudo cp $(AZURE_SCRIPT) $(WORKDIR)/extract/etc/init.d/azure-complete-provisioning
	sudo chmod +x $(WORKDIR)/extract/etc/init.d/azure-complete-provisioning
	sudo chown root:root $(WORKDIR)/extract/etc/init.d/azure-complete-provisioning

	@echo "Overwriting /etc/init.d/disk-encryption..."
	sudo cp $(DISK_ENCRYPTION_INIT_SCRIPT) $(WORKDIR)/extract/etc/init.d/disk-encryption
	sudo chmod +x $(WORKDIR)/extract/etc/init.d/disk-encryption
	sudo chown root:root $(WORKDIR)/extract/etc/init.d/disk-encryption

	@echo "Overwriting /etc/init.d/cvm-reverse-proxy-client-init..."
	sudo cp $(CVM_REVERSE_PROXY_CLIENT_INIT_SCRIPT) $(WORKDIR)/extract/etc/init.d/cvm-reverse-proxy-client-init
	sudo chmod +x $(WORKDIR)/extract/etc/init.d/cvm-reverse-proxy-client-init
	sudo chown root:root $(WORKDIR)/extract/etc/init.d/cvm-reverse-proxy-client-init

	@echo "Overwriting /etc/init.d/reth-sync..."
	sudo cp $(RETH_SYNC_SCRIPT) $(WORKDIR)/extract/etc/init.d/reth-sync
	sudo chmod +x $(WORKDIR)/extract/etc/init.d/reth-sync
	sudo chown root:root $(WORKDIR)/extract/etc/init.d/reth-sync

	@echo "Overwriting /etc/init.d/lighthouse..."
	sudo cp $(LIGHTHOUSE_INIT_SCRIPT) $(WORKDIR)/extract/etc/init.d/lighthouse
	sudo chmod +x $(WORKDIR)/extract/etc/init.d/lighthouse
	sudo chown root:root $(WORKDIR)/extract/etc/init.d/lighthouse

	@echo "Overwriting /etc/init.d/reth..."
	sudo cp $(RETH_INIT_SCRIPT) $(WORKDIR)/extract/etc/init.d/reth
	sudo chmod +x $(WORKDIR)/extract/etc/init.d/reth
	sudo chown root:root $(WORKDIR)/extract/etc/init.d/reth

	@echo "Setting up SSH directories..."
	@if [ -n "$(SSH_KEY_PATH)" ] && [ -f "$(SSH_KEY_PATH)" ]; then \
		echo "Injecting SSH key from $(SSH_KEY_PATH)..."; \
		cat $(SSH_KEY_PATH) | sudo tee -a $(WORKDIR)/extract/home/root/.ssh/authorized_keys; \
		sudo chmod 700 $(WORKDIR)/extract/home/root/.ssh; \
		sudo chmod 600 $(WORKDIR)/extract/home/root/.ssh/authorized_keys; \
	else \
		echo "No SSH key specified or found, creating empty authorized_keys file."; \
		sudo touch $(WORKDIR)/extract/home/root/.ssh/authorized_keys; \
		sudo chmod 700 $(WORKDIR)/extract/home/root/.ssh; \
		sudo chmod 600 $(WORKDIR)/extract/home/root/.ssh/authorized_keys; \
	fi
	
	@echo "Fixing Dropbear init script links..."
	@if [ -f "$(WORKDIR)/extract/etc/rcS.d/K10dropbear" ]; then \
		sudo mv $(WORKDIR)/extract/etc/rcS.d/K10dropbear $(WORKDIR)/extract/etc/rcS.d/S10dropbear; \
		echo "Dropbear init script link fixed."; \
	else \
		echo "Warning: Could not find rc directories to fix Dropbear links."; \
	fi
	
	touch $(INJECT_DONE)

# Create uncompressed cpio
$(FIXED_CPIO): $(INJECT_DONE)
	@echo "Creating new initramfs..."
	cd $(WORKDIR)/extract && sudo find . -print | sort | sudo cpio -H newc -o > $(FIXED_CPIO) 2>/dev/null

# Create compressed cpio.gz
$(FIXED_CPIO_GZ): $(FIXED_CPIO)
	@echo "Compressing initramfs..."
	cat $(FIXED_CPIO) | gzip -6 > $(FIXED_CPIO_GZ)

# Create QEMU disk image if it doesn't exist
$(QCOW2_IMAGE):
	@echo "Creating QEMU disk image of size $(QCOW2_SIZE)..."
	qemu-img create -f qcow2 $(QCOW2_IMAGE) $(QCOW2_SIZE)

# Target aliases
extract: $(EXTRACT_DONE)
inject: $(INJECT_DONE) $(FIXED_CPIO) $(FIXED_CPIO_GZ)
	@echo "Done! Modified initramfs is at $(FIXED_CPIO) and $(FIXED_CPIO_GZ)"
	@if [ -n "$(SSH_KEY_PATH)" ] && [ -f "$(SSH_KEY_PATH)" ]; then \
		echo "SSH key from $(SSH_KEY_PATH) injected."; \
	else \
		echo "WARNING: No SSH key injected. Password-less root login will be enabled."; \
	fi

disk: $(QCOW2_IMAGE)

# Run QEMU with injected initramfs
run: $(FIXED_CPIO) $(QCOW2_IMAGE)
	@echo "Starting QEMU with modified initramfs..."
	@echo "==================================================================="
	@echo "SSH ACCESS: Use 'ssh -p 10022 root@localhost' to connect (port 40192)"
	@echo "==================================================================="
	qemu-system-x86_64 -accel kvm -m $(QEMU_MEM) -smp $(QEMU_SMP) \
	  -name dev-test,process=dev-test \
	  -kernel $(BZIMAGE_PATH) \
	  -initrd $(FIXED_CPIO) \
	  -cpu host -machine q35 \
	  -append "console=ttyS0 earlyprintk=serial,ttyS0 debug loglevel=8 nokaslr" \
	  -nographic \
	  -netdev user,id=net0,hostfwd=tcp::10022-:40192,hostfwd=tcp::19000-:9000,hostfwd=udp::19000-:9000,hostfwd=tcp::19100-:9100,hostfwd=tcp::13500-:3500,hostfwd=tcp::39303-:30303,hostfwd=tcp::18545-:8545,hostfwd=tcp::18551-:8551 \
	  -device e1000,netdev=net0 \
	  -device virtio-scsi-pci,id=scsi0 \
	  -drive file=$(QCOW2_IMAGE),if=none,id=persistent,format=qcow2 \
	  -device scsi-hd,drive=persistent,bus=scsi0.0,lun=10

# Run QEMU with injected and gzipped initramfs
run-gz: $(FIXED_CPIO_GZ) $(QCOW2_IMAGE)
	@echo "Starting QEMU with modified gzipped initramfs..."
	@echo "==================================================================="
	@echo "SSH ACCESS: Use 'ssh -p 10022 root@localhost' to connect (port 40192)"
	@echo "==================================================================="
	qemu-system-x86_64 -accel kvm -m $(QEMU_MEM) -smp $(QEMU_SMP) \
	  -name dev-test,process=dev-test \
	  -kernel $(BZIMAGE_PATH) \
	  -initrd $(FIXED_CPIO_GZ) \
	  -cpu host -machine q35 \
	  -append "console=ttyS0 earlyprintk=serial,ttyS0 debug loglevel=8 nokaslr" \
	  -nographic \
	  -netdev user,id=net0,hostfwd=tcp::10022-:40192,hostfwd=tcp::19000-:9000,hostfwd=udp::19000-:9000,hostfwd=tcp::19100-:9100,hostfwd=tcp::13500-:3500,hostfwd=tcp::39303-:30303,hostfwd=tcp::18545-:8545,hostfwd=tcp::18551-:8551 \
	  -device e1000,netdev=net0 \
	  -device virtio-scsi-pci,id=scsi0 \
	  -drive file=$(QCOW2_IMAGE),if=none,id=persistent,format=qcow2 \
	  -device scsi-hd,drive=persistent,bus=scsi0.0,lun=10

# Run QEMU with direct console shell
run-shell: $(FIXED_CPIO_GZ) $(QCOW2_IMAGE)
	@echo "Starting QEMU with direct shell access..."
	@echo "==================================================================="
	@echo "You will get a direct shell. Run 'exec /sbin/init' to continue normal boot."
	@echo "==================================================================="
	qemu-system-x86_64 -accel kvm -m $(QEMU_MEM) -smp $(QEMU_SMP) \
	  -name dev-test,process=dev-test \
	  -kernel $(BZIMAGE_PATH) \
	  -initrd $(FIXED_CPIO_GZ) \
	  -cpu host -machine q35 \
	  -append "console=ttyS0 earlyprintk=serial,ttyS0 debug loglevel=8 nokaslr rdinit=/bin/sh" \
	  -nographic \
	  -netdev user,id=net0,hostfwd=tcp::10022-:40192,hostfwd=tcp::19000-:9000,hostfwd=udp::19000-:9000,hostfwd=tcp::19100-:9100,hostfwd=tcp::13500-:3500,hostfwd=tcp::39303-:30303,hostfwd=tcp::18545-:8545,hostfwd=tcp::18551-:8551 \
	  -device e1000,netdev=net0 \
	  -device virtio-scsi-pci,id=scsi0 \
	  -drive file=$(QCOW2_IMAGE),if=none,id=persistent,format=qcow2 \
	  -device scsi-hd,drive=persistent,bus=scsi0.0,lun=10

post-provision:
	# Transfer all files first
	scp -P 10022 -r builder-playground/output/data_beacon_node/beacon/network/ root@localhost:/persistent/network
	scp -P 10022 -r builder-playground/output/genesis.json root@localhost:/persistent/
	scp -P 10022 -r builder-playground/output/testnet/ root@localhost:/persistent/
	scp -P 10022 ./lighthouse-bin root@localhost:/usr/bin/lighthouse

	# Then set permissions and ownership with a single SSH command
	ssh -p 10022 root@localhost "chown -R lighthouse:eth /persistent/network/ /persistent/testnet/ && \
		chmod -R 775 /persistent/network/ /persistent/testnet/ && \
		chown reth:eth /persistent/genesis.json && \
		chmod 775 /persistent/genesis.json && \
		chown root:root /usr/bin/lighthouse && \
		chmod 755 /usr/bin/lighthouse"

	# Continue booting after provisioning
	ssh -p 10022 root@localhost "touch /tmp/continue-boot"

	@echo "Post-provisioning completed successfully!"

# Force rebuild of initramfs
rebuild: clean
	$(MAKE) inject

# Clean up
clean:
	sudo rm -rf $(WORKDIR)

# Very clean (includes disk image)
distclean: clean
	rm -f $(QCOW2_IMAGE)

.PHONY: all extract inject disk run run-gz rebuild clean distclean
