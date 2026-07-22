PYTHON_VERSION = 3.12
PROJECT_ROOT = $(CURDIR)
# Make sure you have python3.12 installed prio to running make setup
# JRE is also required, it is included in make setup (line 28)

VENV := fprime-venv
PYTHON := $(VENV)/bin/python

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: setup
.ONESHELL:
setup: ## Set up the repo
	@set -e
	@echo "Setting up development environment for fprime-scales-ref..."
	git checkout lucadev
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
	@echo "Downloading python ML dependencies..."
	fprime-venv/bin/pip install -r requirements-ml.txt
	@echo "Installing fpp dependencies..."
	sudo apt install default-jre -y
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

.PHONY: clean
clean: ## Remove venv and reset submodules
	@echo "Removing fprime virtual environment..."
	rm -rf fprime-venv
	@echo "Resetting git submodules..."
	git submodule deinit -f .
	git submodule update --init --recursive
	@echo "Clean complete. You can now run 'make setup' again."
