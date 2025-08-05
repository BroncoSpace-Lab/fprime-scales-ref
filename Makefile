PYTHON_VERSION = 3.11
PROJECT_ROOT = $(CURDIR)

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: setup
.ONESHELL:
setup: ## Set up the repo
	@echo "Setting up development environment for fprime-scales-ref..."
	git checkout main
	@echo "Making the fprime virtual environment..."
	python$(PYTHON_VERSION) -m venv fprime-venv
	@echo "Initializing and updating all git submodules recursively..."
	git submodule update --init --recursive
	@echo "Installing Python requirements into venv..."
	fprime-venv/bin/pip install -r lib/fprime/requirements.txt
	@echo "Finished setup."
	@echo ""
	@echo "███████╗ ██████╗ █████╗ ██╗     ███████╗███████╗"
	@echo "██╔════╝██╔════╝██╔══██╗██║     ██╔════╝██╔════╝"
	@echo "███████╗██║     ███████║██║     █████╗  ███████╗"
	@echo "╚════██║██║     ██╔══██║██║     ██╔══╝  ╚════██║"
	@echo "███████║╚██████╗██║  ██║███████╗███████╗███████║"
	@echo "╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝"
	@echo "                                                "
	@echo ""

.PHONY: arena-init
.ONESHELL:
arena-init: ## Set up the Arena SDK
	@echo "Extracting the tarball..."
	cd lib/ArenaSDK && tar -xvf ArenaSDK_v0.1.77_Linux_ARM64.tar.xz --strip-components=1
	@echo "Moving the files..."
	cd ArenaSDK_Linux_ARM64
	cp -r * $(PROJECT_ROOT)/lib/ArenaSDK/
	cd ..
	rm -rf ArenaSDK_Linux_ARM64/
	sudo sh Arena_SDK_ARM64.conf
	@echo "Finished setting up ArenaSDK"

.PHONY: build-jetson
build-jetson: ## Build fprime for the Jetson
	@echo "Building aarch64-linux..."
	fprime-util build arch64-linux -j999
	./jetson-python.sh
	@echo "Making the Images folder..."
	cd build-python-fprime-aarch64-linux
	mkdir Images
	@echo "make build-jetson Complete"

.PHONY: clean
clean: ## Remove venv and reset submodules
	@echo "Removing fprime virtual environment..."
	rm -rf fprime-venv
	@echo "Resetting git submodules..."
	git submodule deinit -f .
	git submodule update --init --recursive
	@echo "Clean complete. You can now run 'make setup' again."
