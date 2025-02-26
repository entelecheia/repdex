# Default values for variables
IMAGE_VARIANT ?= dev
DOCKER_PROJECT_ID ?= default
DOCKER_SCRIPT := .docker/.docker-scripts/docker-compose.sh

# Define common functions
define log
	@echo "🚀 $(1)"
endef

define run_docker
	@IMAGE_VARIANT=$(IMAGE_VARIANT) DOCKER_PROJECT_ID=$(DOCKER_PROJECT_ID) bash $(DOCKER_SCRIPT) $(1)
endef

# Mark all targets as PHONY
.PHONY: help install check test build clean-build publish build-and-publish docs-test docs \
        install-uv install-pipx install-copier init-project reinit-project reinit-docker-project \
        docker-build docker-config docker-push docker-run docker-up docker-up-detach docker-tag docker-down docker-clean

#######################
# Development Setup   #
#######################

install: install-uv ## Install the virtual environment and pre-commit hooks
	$(call log,Creating virtual environment using uv)
	@uv sync
	@uv run pre-commit install

install-uv: ## Install uv (pre-requisite for initialize)
	$(call log,Installing uv)
	@command -v uv &> /dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh || true

install-pipx: ## Install pipx (pre-requisite for external tools)
	$(call log,Installing pipx)
	@command -v pipx &> /dev/null || pip install --user pipx || true

install-copier: install-pipx ## Install copier (pre-requisite for init-project)
	$(call log,Installing copier)
	@command -v copier &> /dev/null || pipx install copier || true

#######################
# Quality Assurance   #
#######################

check: ## Run code quality tools
	$(call log,Checking lock file consistency with 'pyproject.toml')
	@uv lock --locked
	$(call log,Linting code: Running pre-commit)
	@uv run pre-commit run -a
	$(call log,Static type checking: Running mypy)
	@uv run mypy --config-file pyproject.toml src
	$(call log,Checking for obsolete dependencies: Running deptry)
	@uv run deptry .

test: ## Test the code with pytest
	$(call log,Testing code: Running pytest)
	@uv run python -m pytest --cov --cov-config=pyproject.toml --cov-report=xml --junitxml=tests/pytest.xml | tee tests/pytest-coverage.txt

#######################
# Build & Publish     #
#######################

build: clean-build ## Build wheel file
	$(call log,Creating wheel file)
	@uvx --from build pyproject-build --installer uv

clean-build: ## Clean build artifacts
	$(call log,Removing build artifacts)
	@uv run python -c "import shutil; import os; shutil.rmtree('dist') if os.path.exists('dist') else None"

publish: ## Publish a release to PyPI
	$(call log,Publishing to PyPI)
	@uvx twine upload --repository-url https://upload.pypi.org/legacy/ dist/*

build-and-publish: build publish ## Build and publish

#######################
# Documentation       #
#######################

docs-test: ## Test if documentation can be built without warnings or errors
	@uv run mkdocs build -s

docs: ## Build and serve the documentation
	@uv run mkdocs serve

#######################
# Project Management  #
#######################

init-project: initialize ## Initialize the project (Warning: do this only once!)
	$(call log,Initializing project from template)
	@copier copy --trust --answers-file .copier-config.yaml gh:entelecheia/hyperfast-uv-template .

reinit-project: install-copier ## Reinitialize the project (Warning: this may overwrite existing files!)
	$(call log,Reinitializing project from template)
	@bash -c 'args=(); while IFS= read -r file; do args+=("--skip" "$$file"); done < .copierignore; \
		copier copy --trust "$${args[@]}" --answers-file .copier-config.yaml gh:entelecheia/hyperfast-uv-template .'

reinit-docker-project: install-copier ## Reinitialize the docker project (Warning: this may overwrite existing files!)
	$(call log,Reinitializing docker project from template)
	@bash -c 'args=(); while IFS= read -r file; do args+=("--skip" "$$file"); done < .copierignore; \
		copier copy --trust "$${args[@]}" --answers-file .copier-docker-config.yaml gh:entelecheia/hyperfast-docker-template .'

#######################
# Docker Operations   #
#######################

docker-config: ## Show the Docker Compose configuration
	$(call log,Showing Docker Compose configuration)
	$(call run_docker,config)

docker-run: ## Run a command in the Docker container (default: bash)
	$(call log,Running Docker container)
	$(call run_docker,run)

docker-up: ## Start the Docker container
	$(call log,Starting Docker container)
	$(call run_docker,up)

docker-up-detach: ## Start the Docker container in detached mode
	$(call log,Starting Docker container in detached mode)
	$(call run_docker,up --detach)

docker-down: ## Stop and remove the Docker container
	$(call log,Stopping and removing Docker container)
	$(call run_docker,down)

docker-clean: ## Remove all Docker artifacts (images, containers, volumes)
	$(call log,Removing all Docker artifacts)
	$(call run_docker,down -v --rmi all)

#######################
# Help                #
#######################

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@uv run python -c "import re; \
	[[print(f'\033[36m{m[0]:<25}\033[0m {m[1]}') for m in re.findall(r'^([a-zA-Z_-]+):.*?## (.*)$$', open(makefile).read(), re.M)] for makefile in ('$(MAKEFILE_LIST)').strip().split()]"

.DEFAULT_GOAL := help
