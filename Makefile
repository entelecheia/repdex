.PHONY: install
install: install-uv ## Install the virtual environment and install the pre-commit hooks
	@echo "🚀 Creating virtual environment using uv"
	@uv sync
	@uv run pre-commit install

.PHONY: check
check: ## Run code quality tools.
	@echo "🚀 Checking lock file consistency with 'pyproject.toml'"
	@uv lock --locked
	@echo "🚀 Linting code: Running pre-commit"
	@uv run pre-commit run -a
	@echo "🚀 Static type checking: Running mypy"
	@uv run mypy --config-file pyproject.toml src
	@echo "🚀 Checking for obsolete dependencies: Running deptry"
	@uv run deptry .

.PHONY: test
test: ## Test the code with pytest
	@echo "🚀 Testing code: Running pytest"
	@uv run python -m pytest --cov --cov-config=pyproject.toml --cov-report=xml --junitxml=tests/pytest.xml | tee tests/pytest-coverage.txt

.PHONY: build
build: clean-build ## Build wheel file
	@echo "🚀 Creating wheel file"
	@uvx --from build pyproject-build --installer uv

.PHONY: clean-build
clean-build: ## Clean build artifacts
	@echo "🚀 Removing build artifacts"
	@uv run python -c "import shutil; import os; shutil.rmtree('dist') if os.path.exists('dist') else None"

.PHONY: publish
publish: ## Publish a release to PyPI.
	@echo "🚀 Publishing."
	@uvx twine upload --repository-url https://upload.pypi.org/legacy/ dist/*

.PHONY: build-and-publish
build-and-publish: build publish ## Build and publish.

.PHONY: docs-test
docs-test: ## Test if documentation can be built without warnings or errors
	@uv run mkdocs build -s

.PHONY: docs
docs: ## Build and serve the documentation
	@uv run mkdocs serve

.PHONY: install-uv
install-uv: ## Install uv (pre-requisite for initialize)
	@echo "🚀 Installing uv"
	@command -v uv &> /dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh || true

.PHONY: install-pipx
install-pipx: ## Install pipx (pre-requisite for external tools)
	@echo "🚀 Installing pipx"
	@command -v pipx &> /dev/null || pip install --user pipx || true

.PHONY: install-copier
install-copier: install-pipx ## Install copier (pre-requisite for init-project)
	@echo "🚀 Installing copier"
	@command -v copier &> /dev/null || pipx install copier || true

.PHONY: init-project
init-project: initialize ## Initialize the project (Warning: do this only once!)
	@echo "🚀 Initializing project from template"
	@copier copy --trust --answers-file .copier-config.yaml gh:entelecheia/hyperfast-uv-template .

.PHONY: reinit-project
reinit-project: install-copier ## Reinitialize the project (Warning: this may overwrite existing files!)
	@echo "🚀 Reinitializing project from template"
	@bash -c 'args=(); while IFS= read -r file; do args+=("--skip" "$$file"); done < .copierignore; copier copy --trust "$${args[@]}" --answers-file .copier-config.yaml gh:entelecheia/hyperfast-uv-template .'

.PHONY: reinit-docker-project
reinit-docker-project: install-copier ## Reinitialize the docker project (Warning: this may overwrite existing files!)
	@echo "🚀 Reinitializing docker project from template"
	@bash -c 'args=(); while IFS= read -r file; do args+=("--skip" "$$file"); done < .copierignore; copier copy --trust "$${args[@]}" --answers-file .copier-docker-config.yaml gh:entelecheia/hyperfast-docker-template .'

.PHONY: docker-build docker-config docker-push docker-run docker-up docker-up-detach docker-tag docker-down docker-clean

docker-build: ## Build the Docker image (variant: IMAGE_VARIANT, default: dev)
	@echo "🚀 Building Docker image"
	@IMAGE_VARIANT=$${IMAGE_VARIANT:-"dev"} \
	DOCKER_PROJECT_ID=$${DOCKER_PROJECT_ID:-"default"} \
	bash .docker/.docker-scripts/docker-compose.sh build

docker-config: ## Show the Docker Compose configuration
	@echo "🚀 Showing Docker Compose configuration"
	@IMAGE_VARIANT=$${IMAGE_VARIANT:-"dev"} \
	DOCKER_PROJECT_ID=$${DOCKER_PROJECT_ID:-"default"} \
	bash .docker/.docker-scripts/docker-compose.sh config

docker-push: ## Push the Docker image to registry
	@echo "🚀 Pushing Docker image"
	@IMAGE_VARIANT=$${IMAGE_VARIANT:-"dev"} \
	DOCKER_PROJECT_ID=$${DOCKER_PROJECT_ID:-"default"} \
	bash .docker/.docker-scripts/docker-compose.sh push

docker-run: ## Run a command in the Docker container (default: bash)
	@echo "🚀 Running Docker container"
	@IMAGE_VARIANT=$${IMAGE_VARIANT:-"dev"} \
	DOCKER_PROJECT_ID=$${DOCKER_PROJECT_ID:-"default"} \
	bash .docker/.docker-scripts/docker-compose.sh run

docker-up: ## Start the Docker container
	@echo "🚀 Starting Docker container"
	@IMAGE_VARIANT=$${IMAGE_VARIANT:-"dev"} \
	DOCKER_PROJECT_ID=$${DOCKER_PROJECT_ID:-"default"} \
	bash .docker/.docker-scripts/docker-compose.sh up

docker-up-detach: ## Start the Docker container in detached mode
	@echo "🚀 Starting Docker container in detached mode"
	@IMAGE_VARIANT=$${IMAGE_VARIANT:-"dev"} \
	DOCKER_PROJECT_ID=$${DOCKER_PROJECT_ID:-"default"} \
	bash .docker/.docker-scripts/docker-compose.sh up --detach

docker-down: ## Stop and remove the Docker container
	@echo "🚀 Stopping and removing Docker container"
	@IMAGE_VARIANT=$${IMAGE_VARIANT:-"dev"} \
	DOCKER_PROJECT_ID=$${DOCKER_PROJECT_ID:-"default"} \
	bash .docker/.docker-scripts/docker-compose.sh down

docker-tag: ## Tag the Docker image as latest
	@echo "🚀 Tagging Docker image as latest"
	@IMAGE_VARIANT=$${IMAGE_VARIANT:-"dev"} \
	DOCKER_PROJECT_ID=$${DOCKER_PROJECT_ID:-"default"} \
	bash .docker/.docker-scripts/docker-compose.sh tag

docker-clean: ## Remove all Docker artifacts (images, containers, volumes)
	@echo "🚀 Removing all Docker artifacts (images, containers, volumes)"
	@IMAGE_VARIANT=$${IMAGE_VARIANT:-"dev"} \
	DOCKER_PROJECT_ID=$${DOCKER_PROJECT_ID:-"default"} \
	bash .docker/.docker-scripts/docker-compose.sh down -v --rmi all

.PHONY: help
help:
	@uv run python -c "import re; \
	[[print(f'\033[36m{m[0]:<25}\033[0m {m[1]}') for m in re.findall(r'^([a-zA-Z_-]+):.*?## (.*)$$', open(makefile).read(), re.M)] for makefile in ('$(MAKEFILE_LIST)').strip().split()]"

.DEFAULT_GOAL := help
