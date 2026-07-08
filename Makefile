PYTHON_VERSION = 3.12
PROJECT_ROOT = $(CURDIR)
# Make sure you have python3.12 installed prio to running make setup
# JRE is also required, it is included in make setup (line 28)

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: setup
.ONESHELL:
setup: ## Set up the repo
	@set -e
	@echo "Setting up development environment for fprime-scales-ref..."
	git checkout lucadev_v4.2.2
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

.PHONY: build-jetson
.ONESHELL:
build-jetson: ## Build fprime for the Jetson and restart the systemd service
	@set -e
	@echo "Building JetsonDeployment for aarch64-linux..."
	fprime-util build aarch64-linux
	@echo "Making the Images folder..."
	mkdir -p Images
	@echo "Restarting the JetsonDeployment systemd service..."
	sudo systemctl restart jetson-deployment.service
	@echo "Checking service status..."
	systemctl status jetson-deployment.service --no-pager
	@echo "make build-jetson Done"

.PHONY: clean
clean: ## Remove venv and reset submodules
	@echo "Removing fprime virtual environment..."
	rm -rf fprime-venv
	@echo "Resetting git submodules..."
	git submodule deinit -f .
	git submodule update --init --recursive
	@echo "Clean complete. You can now run 'make setup' again."
