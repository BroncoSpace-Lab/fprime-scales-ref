PYTHON_VERSION = 3.11
PROJECT_ROOT = $(CURDIR)

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: setup
.ONESHELL:
setup: ## Set up the repo
	@echo "Setting up development environment for fprime-scales-ref..."
	git checkout tanyadev
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
	@echo "Fetching LFS files..."
	git lfs pull
	@echo "Extracting the tarball..."
	tar -xvf lib/ArenaSDK/ArenaSDK_v0.1.77_Linux_ARM64.tar.xz -C lib/ArenaSDK
	@echo "Moving the files..."    
	EXTRACTED_DIR=$$(find lib/ArenaSDK -maxdepth 1 -type d -name 'ArenaSDK_v0.1.77_Linux_ARM64*')    
	cp -r $$EXTRACTED_DIR/ArenaSDK_Linux_ARM64/* $(PROJECT_ROOT)/lib/ArenaSDK/    
	rm -rf $$EXTRACTED_DIR
	@echo "Finished setting up Arena SDK"

.PHONY: build-jetson
.ONESHELL:
build-jetson: ## Build fprime for the Jetson
	@echo "Building aarch64-linux..."
	export SCALES_TRT_PYTHON="$${SCALES_TRT_PYTHON:-/usr/bin/python3}"
	export TRT_FP16="$${TRT_FP16:-1}"
	export SCALES_TRT_MODEL="$${SCALES_TRT_MODEL:-microsoft/resnet-18}"
	export SCALES_YOLO_WEIGHTS="$${SCALES_YOLO_WEIGHTS:-yolov8n.pt}"
	fprime-util build aarch64-linux -j999
	bash ./scripts/jetson-python.sh
	@echo "Making the Images folder..."
	cd build-python-fprime-aarch64-linux
	mkdir -p Images
	@echo "make build-jetson Done"

.PHONY: ml-trt-setup
.ONESHELL:
ml-trt-setup: ## TensorRT cache build (MODEL=resnet|yolo, SCALES_TRT_PYTHON=/usr/bin/python3)
	bash ./scripts/ml_trt_setup.sh

.PHONY: clean
clean: ## Remove venv and reset submodules
	@echo "Removing fprime virtual environment..."
	rm -rf fprime-venv
	@echo "Resetting git submodules..."
	git submodule deinit -f .
	git submodule update --init --recursive
	@echo "Clean complete. You can now run 'make setup' again."