PYTHON_VERSION = 3.11
PROJECT_ROOT = fprime-scales-ref

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: setup
.ONESHELL:
setup: #Set up the repo
	@echo "Setting up development environment for fprime-scales-ref..."
	git checkout kellydev
	@echo "Making the fprime virtual environment..."
	python3.11 -m venv fprime-venv
	source fprime-venv/bin/activate
	@echo "Updating the git submodules..."
	cd lib
	git submodule init && git submodule update
	pip install -r fprime/requirements.txt
	cd fprime-python
	git submodule init && git submodule update
	cd ../..
	cd Components/MLComponent
	git submodule init && git submodule update
	cd ../..
	@echo "Finished setup."
	@echo "     Don't forget to source your fprime environment with
	    source fprime-venv/bin/activate"