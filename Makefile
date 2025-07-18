PYTHON_VERSION = 3.11
PROJECT_ROOT = $(CURDIR)

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: setup
.ONESHELL:
setup: ## Set up the repo
	@echo "Setting up development environment for fprime-scales-ref..."
	git checkout kellydev
	@echo "Making the fprime virtual environment..."
	python$(PYTHON_VERSION) -m venv fprime-venv
	@echo "Updating the git submodules..."
	cd lib && git submodule init && git submodule update
	cd lib/fprime-python && git submodule init && git submodule update
	cd $(PROJECT_ROOT)/Components/MLComponent && git submodule init && git submodule update
	@echo "Installing Python requirements into venv..."
	fprime-venv/bin/pip install -r lib/fprime/requirements.txt
	@echo "Finished setup."

.PHONY: arena-init
.ONESHELL:
arena-init: ## Set up the Arena SDK
	@echo "Extracting the tarball..."
	cd lib/ArenaSDK && tar -xvf ArenaSDK_v0.1.77_Linux_ARM64.tar.xz
	@echo "Moving the files..."
	cd lib/ArenaSDK/ArenaSDK_v0.1.77_Linux_ARM64*/ArenaSDK_Linux_ARM64 && cp -r * $(PROJECT_ROOT)/lib/ArenaSDK/
	cd lib/ArenaSDK && rm -rf ArenaSDK_v0.1.77_Linux_ARM64*/
	@echo "Finished setting up"