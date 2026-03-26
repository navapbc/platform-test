# Getting started

This application is dockerized. Take a look at [Dockerfile](/app-catala/Dockerfile) to see how it works.

A simple [docker-compose.yml](/app-catala/docker-compose.yml) has been included to support local development. Take a look at [docker-compose.yml](/app-catala/docker-compose.yml) for more information.

## Prerequisites

1. Install Python 3.13+.
   [pyenv](https://github.com/pyenv/pyenv#installation) is one popular option for installing Python,
   or [asdf](https://asdf-vm.com/).

2. Install [poetry](https://python-poetry.org/docs/#installation):

   ```bash
   curl -sSL https://install.python-poetry.org | python3 -
   ```

3. Install a container runtime. Any Docker-compatible runtime will work:
   - [Podman](https://podman.io/docs/installation) (open source)
   - [Colima](https://github.com/abiosoft/colima) (lightweight, macOS/Linux)

4. (Optional) Install the [Catala compiler](https://catala-lang.org/en/install) if you want to compile Catala sources locally outside of Docker.

## Run the application

**Note:** Run everything from within the `/app-catala` folder:

1. Run `make init start` to build the image and start the container.
2. Navigate to `localhost:3001/docs` to access the API documentation (Swagger UI).
3. Run `make run-logs` to see the logs of the running container.
4. Run `make stop` when you are done to stop the container.

## Working with Catala

Catala source files live in the `catala/src/` directory and are built using [clerk](https://catala-lang.org/), the Catala build system. The build is configured via `catala/clerk.toml`. The typical workflow is:

1. Write or edit rules in `.catala_en` files (see `catala/src/paidleave.catala_en` for an example).
2. Write test assertions in `catala/tests/`.
3. Compile Catala to Python: `make catala-build`
4. Run Catala tests: `make catala-test`
5. Run all checks: `make test-all`

The compiled Python output goes into `src/generated/` and can be imported by the API layer.
If new scopes or outputs are added, also update `src/api.py` to add functionality to the API.

## Running natively

- Run `export PY_RUN_APPROACH=local`
- Run `make setup-local`
- Run `poetry install --all-extras --with dev`

## Next steps

Now that you're up and running, read the [application docs](README.md) to familiarize yourself with the project.
