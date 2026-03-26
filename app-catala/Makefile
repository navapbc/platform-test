##################################################
# Constants
##################################################

APP_NAME := app-catala

SHELL = /bin/bash -o pipefail

APP_DIR := app
ifdef CI
 DOCKER_EXEC_ARGS := -T -e CI -e PYTEST_ADDOPTS="--color=yes"
 MYPY_FLAGS := --no-pretty
 MYPY_POSTPROC := | perl -pe "s/^(.+):(\d+):(\d+): error: (.*)/::warning file=$(APP_DIR)\/\1,line=\2,col=\3::\4/"
endif

ifeq "$(PY_RUN_APPROACH)" "local"
PY_RUN_CMD := poetry run
else
PY_RUN_CMD := docker compose run $(DOCKER_EXEC_ARGS) --rm $(APP_NAME) poetry run
endif

# Docker user configuration
ifeq ($(user),)
RUN_USER ?= $(or $(strip $(USER)),nodummy)
RUN_UID ?= $(or $(strip $(shell id -u)),4000)
else
RUN_USER = $(user)
RUN_UID = $(or $(strip $(uid)),0)
endif

export RUN_USER
export RUN_UID

release-build:
	docker buildx build \
		--target release \
		--platform=linux/amd64 \
		--build-arg RUN_USER=$(RUN_USER) \
		--build-arg RUN_UID=$(RUN_UID) \
		$(OPTS) \
		.

##################################################
# Local Development Environment Setup
##################################################

setup-local:
	poetry config virtualenvs.in-project true
	poetry install --no-root

##################################################
# Build & Run
##################################################

build:
	docker compose build

start:
	docker compose up --detach

run-logs: start
	docker compose logs --follow --no-color $(APP_NAME)

init: build

stop:
	docker compose down

check: format-check lint test

##################################################
# Catala Compilation
##################################################

CATALA_DIR := catala
CATALA_GEN_DIR := src/generated

catala-build: ## Compile Catala sources to Python via clerk
	cd $(CATALA_DIR) && clerk build
	# There's a bug where dates.py is missing from the target code
	# https://github.com/CatalaLang/catala/issues/981
	cp $(CATALA_DIR)/_build/libcatala/python/dates.py $(CATALA_GEN_DIR)/
	cp $(CATALA_DIR)/_target/paidleave/python/* $(CATALA_GEN_DIR)/

catala-test: ## Run Catala test assertions via clerk
	cd $(CATALA_DIR) && clerk test

catala-ci: ## Run Catala CI build and tests
	cd $(CATALA_DIR) && clerk ci

##################################################
# Testing
##################################################

test: ## Run Python tests
	$(PY_RUN_CMD) pytest $(args)

test-watch: ## Run tests continually and watch for changes
	$(PY_RUN_CMD) pytest-watch --clear $(args)

test-coverage: ## Run tests and generate coverage report
	$(PY_RUN_CMD) coverage run --branch --source=src -m pytest $(args)
	$(PY_RUN_CMD) coverage report

test-coverage-report: ## Open HTML test coverage report
	$(PY_RUN_CMD) coverage html --directory .coverage_report
	open .coverage_report/index.html

test-all: catala-test test ## Run all Catala and Python tests

##################################################
# Formatting and linting
##################################################

format: ## Format Python files
	$(PY_RUN_CMD) ruff format src tests

format-check: ## Check Python file formatting
	$(PY_RUN_CMD) ruff format --check src tests

lint: lint-ruff lint-mypy ## Lint all files

lint-ruff:
	$(PY_RUN_CMD) ruff check src tests

lint-mypy:
	$(PY_RUN_CMD) mypy --show-error-codes $(MYPY_FLAGS) src $(MYPY_POSTPROC)

##################################################
# Miscellaneous Utilities
##################################################

login: start ## Start shell in running container
	docker exec -it $(APP_NAME) bash

help: ## Prints the help documentation and info about each command
	@grep -E '^[/a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
