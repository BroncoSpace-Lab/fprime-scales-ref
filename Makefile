PYTHON_VERSION = 3.12
PROJECT_ROOT = $(CURDIR)
# Make sure you have python3.12 installed prio to running make setup
# JRE is also required, it is included in make setup (line 33)

VENV := fprime-venv
PYTHON := $(VENV)/bin/python

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

patch_gds ?= 1
gds_channel_window ?= 200

# Allow 'make setup nopatch' as a shorthand for 'patch_gds=0' (skip patching
# the vendored fprime-gds Channels table to widen its virtualized row window
# past the default 40, which otherwise causes rows to intermittently vanish
# from view until manually scrolled).
ifneq (,$(filter nopatch,$(MAKECMDGOALS)))
patch_gds := 0
endif

.PHONY: nopatch
nopatch: ## No-op flag target; combine with setup to skip the fprime-gds channel-table patch (same as patch_gds=0)
	@:

# Allow 'make setup lucadev' / 'make setup datdev' / 'make setup main' to pick
# which branch setup checks out first. Defaults to staying on whatever branch
# is currently checked out (no checkout at all) when none of these are given,
# since silently switching branches is exactly what caused prior confusion.
setup_branch ?=
ifneq (,$(filter lucadev,$(MAKECMDGOALS)))
setup_branch := lucadev
endif
ifneq (,$(filter datdev,$(MAKECMDGOALS)))
setup_branch := datdev
endif
ifneq (,$(filter main,$(MAKECMDGOALS)))
setup_branch := main
endif

.PHONY: lucadev
lucadev: ## No-op flag target; combine with setup to checkout lucadev first (e.g. 'make setup lucadev')
	@:

.PHONY: datdev
datdev: ## No-op flag target; combine with setup to checkout datdev first (e.g. 'make setup datdev')
	@:

.PHONY: main
main: ## No-op flag target; combine with setup to checkout main first (e.g. 'make setup main')
	@:

.PHONY: setup
.ONESHELL:
setup: ## Set up the repo. Use 'make setup lucadev|datdev|main' to pick a branch first, and 'nopatch' to skip the fprime-gds channel-table patch
	@set -e
	@echo "Setting up development environment for fprime-scales-ref..."
	@if [ -n "$(setup_branch)" ]; then
		echo "Checking out branch: $(setup_branch)..."
		git checkout $(setup_branch)
	else
		echo "No branch specified (use 'make setup lucadev|datdev|main'); staying on current branch ($$(git branch --show-current))."
	fi
	@echo "Making the fprime virtual environment..."
	python$(PYTHON_VERSION) -m venv fprime-venv
	@echo "Sourcing fprime virtual environment..."
	. fprime-venv/bin/activate
	@echo "Initializing and updating all git submodules recursively..."
	git submodule update --init --recursive
	@echo "Installing Python requirements into venv..."
	fprime-venv/bin/pip install -r ./lib/fprime/requirements.txt
	fprime-venv/bin/pip install -r requirements-fprime.txt
	@echo "Installing fprime-python dependencies..."
	fprime-venv/bin/pip install -e ./lib/fprime-python
	@echo "Installing fpp dependencies..."
	sudo apt install default-jre -y

	@if [ "$(patch_gds)" = "1" ]; then
		echo "Patching fprime-gds Channels table row window to $(gds_channel_window)..."
		FPTABLE_JS="$(VENV)/lib/python$(PYTHON_VERSION)/site-packages/fprime_gds/flask/static/js/vue-support/fptable.js"
		if [ -f "$$FPTABLE_JS" ]; then
			sed -i -E "s/(ScrollHandler\(displayed,)[0-9]+(, 5\))/\1$(gds_channel_window)\2/" "$$FPTABLE_JS"
		else
			echo "WARNING: $$FPTABLE_JS not found, skipping fprime-gds patch."
		fi
	else
		echo "Skipping fprime-gds channel-table patch (nopatch)."
	fi

	@echo "Finished setup."
	@echo ""
	@echo "███████╗ ██████╗ █████╗ ██╗     ███████╗███████╗"
	@echo "██╔════╝██╔════╝██╔══██╗██║     ██╔════╝██╔════╝"
	@echo "███████╗██║     ███████║██║     █████╗  ███████╗"
	@echo "╚════██║██║     ██╔══██║██║     ██╔══╝  ╚════██║"
	@echo "███████║╚██████╗██║  ██║███████╗███████╗███████║"
	@echo "╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝"
	@echo "                                                "
	@echo "\tPowered by F\` Flight Software\t\t\t\t   \t\t   "
	@echo "     \t\t(NASA/JPL)                         "
	@echo ""

.PHONY: arena-init
.ONESHELL:
arena-init: ## Set up the Arena SDK
	@set -e; \
	echo "Pulling ArenaSDK archive from Git LFS..."; \
	git lfs pull; \
	echo "Extracting the tarball..."; \
	ARENA_ROOT="$(PROJECT_ROOT)/lib/ArenaSDK"; \
	ARENA_ARCHIVE="$$ARENA_ROOT/ArenaSDK_v0.1.77_Linux_ARM64.tar.xz"; \
	cd "$$ARENA_ROOT" && tar -xvf "$$ARENA_ARCHIVE"; \
	echo "Moving the files..."; \
	ARENA_EXTRACTED_DIR=$$(find "$$ARENA_ROOT" -maxdepth 1 -type d -name "ArenaSDK_v0.1.77_Linux_ARM64*" | head -n 1); \
	if [ -z "$$ARENA_EXTRACTED_DIR" ]; then \
		echo "ERROR: Extracted ArenaSDK directory not found."; \
		echo "Current ArenaSDK contents:"; \
		ls -la "$$ARENA_ROOT"; \
		exit 1; \
	fi; \
	ARENA_SDK_DIR="$$ARENA_EXTRACTED_DIR/ArenaSDK_Linux_ARM64"; \
	if [ ! -d "$$ARENA_SDK_DIR" ]; then \
		echo "ERROR: ArenaSDK_Linux_ARM64 directory not found."; \
		echo "Expected:"; \
		echo "  $$ARENA_SDK_DIR"; \
		echo "Current extracted directory contents:"; \
		ls -la "$$ARENA_EXTRACTED_DIR"; \
		exit 1; \
	fi; \
	cp -r "$$ARENA_SDK_DIR"/* "$$ARENA_ROOT/"; \
	rm -rf "$$ARENA_EXTRACTED_DIR"; \
	echo "Finished setting up ArenaSDK"

generate ?= 1

# Allow 'make build-imx8x nogen' / 'make build-jetson nogen' as a shorthand
# for 'generate=0' (skip regenerating the build before building).
ifneq (,$(filter nogen,$(MAKECMDGOALS)))
generate := 0
endif

.PHONY: nogen
nogen: ## No-op flag target; combine with build-imx8x/build-jetson to skip regeneration (same as generate=0)
	@:

.PHONY: build-jetson
.ONESHELL:
build-jetson: ## Build F' for the Jetson and restart the systemd service
	@set -e

	@if [ "$(generate)" = "1" ]; then
		echo "Generating JetsonDeployment for aarch64-linux..."
		fprime-util generate aarch64-linux -f
	else
		echo "Skipping JetsonDeployment generation..."
	fi

	@echo "Building JetsonDeployment for aarch64-linux..."
	fprime-util build aarch64-linux

	@echo "Making the Images folder..."
	mkdir -p build-artifacts/python/Images

	@printf "Enter the username for the GDS computer at 10.3.2.13: "
	read -r NAME_OF_USERNAME

	if [ -z "$$NAME_OF_USERNAME" ]; then
		echo "ERROR: Username cannot be empty."
		exit 1
	fi

	echo "Copying JetsonDeploymentTopologyDictionary.json to the GDS computer..."
	scp \
		build-artifacts/aarch64-linux/JetsonDeployment/dict/JetsonDeploymentTopologyDictionary.json \
		"$${NAME_OF_USERNAME}@10.3.2.13:~/fprime-scales-ref/GDS-Dictionary/"

	@echo "Restarting the JetsonDeployment systemd service..."
	sudo systemctl restart jetson-deployment.service

	@echo "Checking service status..."
	systemctl status jetson-deployment.service --no-pager

	@echo "make build-jetson Done"

.PHONY: jetson-setup
.ONESHELL:
jetson-setup: ## One-time Jetson OS setup: ML deps, jetson-deployment systemd service, and nvpmodel sudoers rule
	@set -e

	@if [ ! -x "$(PYTHON)" ]; then
		echo "ERROR: Python virtual environment not found."
		echo "Expected: $(PYTHON)"
		echo "Run 'make setup' first."
		exit 1
	fi

	@echo "Installing Jetson-specific (ML) Python dependencies..."
	fprime-venv/bin/pip install -r requirements-ml.txt

	@printf "Enter the username the jetson-deployment service should run as: "
	read -r JETSON_USERNAME

	if [ -z "$$JETSON_USERNAME" ]; then
		echo "ERROR: Username cannot be empty."
		exit 1
	fi

	@echo "Writing /etc/systemd/system/jetson-deployment.service..."
	sudo tee /etc/systemd/system/jetson-deployment.service > /dev/null <<SERVICE_EOF
	[Unit]
	Description=fprime-scales JetsonDeployment Flight Software
	# Wait for network (needed to connect to the IMX hub)
	After=network-online.target
	Wants=network-online.target
	
	[Service]
	Type=simple
	User=$$JETSON_USERNAME
	WorkingDirectory=$(PROJECT_ROOT)
	
	ExecStart=$(PROJECT_ROOT)/jetson-startup.sh
	
	# Restart on crash, but not on clean exit (exit 0)
	Restart=on-failure
	RestartSec=5
	
	# Give the network and fprime-gds time to be ready before retrying hard failures
	StartLimitIntervalSec=120
	StartLimitBurst=5
	
	# Log stdout/stderr to the journal (view with: journalctl -u jetson-deployment)
	StandardOutput=journal
	StandardError=journal
	
	[Install]
	WantedBy=multi-user.target
	SERVICE_EOF

	@echo "Enabling and starting jetson-deployment.service..."
	sudo systemctl daemon-reload
	sudo systemctl enable jetson-deployment.service
	sudo systemctl restart jetson-deployment.service
	systemctl status jetson-deployment.service --no-pager

	@echo "Setting up passwordless sudo for nvpmodel (used for Jetson power mode changes)..."
	NVPMODEL_TMP=$$(mktemp)
	echo "$$JETSON_USERNAME ALL=(ALL) NOPASSWD: /usr/sbin/nvpmodel" > "$$NVPMODEL_TMP"
	if sudo visudo -c -f "$$NVPMODEL_TMP"; then
		sudo install -o root -g root -m 0440 "$$NVPMODEL_TMP" /etc/sudoers.d/fprime-nvpmodel
		echo "Installed /etc/sudoers.d/fprime-nvpmodel"
	else
		echo "ERROR: Generated nvpmodel sudoers rule failed validation (visudo -c). Not installing."
		rm -f "$$NVPMODEL_TMP"
		exit 1
	fi
	rm -f "$$NVPMODEL_TMP"

	@echo "Ensuring /etc/sudoers includes /etc/sudoers.d..."
	if sudo grep -q "^#includedir /etc/sudoers.d" /etc/sudoers; then
		echo "/etc/sudoers already includes /etc/sudoers.d, nothing to do."
	else
		echo "#includedir /etc/sudoers.d" | sudo EDITOR='tee -a' visudo
	fi

	@echo "make jetson-setup done"

.PHONY: data-products
.ONESHELL:
data-products:
	@echo "Moving fdp files over"
	cp ~/Downloads/*.fdp $(PROJECT_ROOT)/DataProducts
	./data-products.sh

.PHONY: build-imx8x
.ONESHELL:
build-imx8x: ## Build F' for the IMX, deploy it, and reboot use 'make build-imx generate=0' to skip generation
	@set -e

	@if [ "$(generate)" = "1" ]; then
		echo "Generating ImxDeployment..."
		fprime-util generate imx8x -f
	else
		echo "Skipping ImxDeployment generation..."
	fi

	@echo "Building ImxDeployment..."
	fprime-util build imx8x

	@echo "Transferring ImxDeployment binary to the IMX..."
	scp \
		build-artifacts/imx8x/ImxDeployment/bin/ImxDeployment \
		root@10.3.2.10:/tmp/

	@echo "Overwriting the ImxDeployment binary on the IMX..."
	ssh root@10.3.2.10 \
		'mv /tmp/ImxDeployment /root/ImxDeployment'

	@echo "Restarting the IMX flight software..."
	ssh root@10.3.2.10 'reboot'

	@echo "make build-imx done"

.PHONY: cpseq
.ONESHELL:
cpseq: ## Copy all .bin files in Sequences/ to the IMX (root@10.3.2.10:/root)
	@set -e
	@echo "Copying sequence files to the IMX..."
	scp Sequences/*.bin root@10.3.2.10:/root
	@echo "make cpseq done"

.PHONY: gds-setup
.ONESHELL:
gds-setup: ## Generate the merged dictionary, deploy the IMX binary, and reboot it
	@set -e

	@if [ ! -x "$(PYTHON)" ]; then
		echo "ERROR: Python virtual environment not found."
		echo "Expected: $(PYTHON)"
		echo "Run 'make setup' first."
		exit 1
	fi

	@echo "Copying ImxDeploymentTopologyDictionary.json to GDS-Dictionary..."
	cp \
		build-artifacts/imx8x/ImxDeployment/dict/ImxDeploymentTopologyDictionary.json \
		GDS-Dictionary/

	@echo "Generating merged dictionary using $(PYTHON)..."
	(
		cd GDS-Dictionary
		../$(PYTHON) merger.py \
			--base-prefix jetson_ \
			--secondary-prefix imx_ \
			JetsonDeploymentTopologyDictionary.json \
			ImxDeploymentTopologyDictionary.json \
			GDSDictionary.json
	)

	@echo "make gds done"

.PHONY: gds-uart
.ONESHELL:
gds-uart: ## Launch the GDS over the UART connection (GDS-Dictionary/uart-gds.sh)
	@cd GDS-Dictionary && ./uart-gds.sh

.PHONY: gds-tcp
.ONESHELL:
gds-tcp: ## Launch the GDS over TCP, use 'make gds-tcp ip=<ip> port=<port>' to override the target (defaults 10.3.2.10:50000)
	@cd GDS-Dictionary && ./tcp-gds.sh $(ip) $(port)

.PHONY: clean
clean: ## Remove venv and reset submodules
	@echo "Removing fprime virtual environment..."
	rm -rf fprime-venv
	@echo "Resetting git submodules..."
	git submodule deinit -f .
	git submodule update --init --recursive
	@echo "Clean complete. You can now run 'make setup' again."
