## Terraform

The project has 5 infrastructure layers representing root modules: account layer at `infra/accounts`, network at `infra/networks`, build repository at `infra/app/build-repository`, database at `infra/app/database`, and service at `infra/app/service`.

Write code that complies with checkov recommendations.

### Creating modules

Define a variable called `name` that is used to name the primary resource.

#### Modules that create resources that will be used in a single layer

Create the module as `infra/<layer>/modules/<module_name>`.

Prefix the name or identifier of all resources with `var.name`.

#### Modules that create resources that will be used across multiple layers

Create a pair of modules, a module for the resources (`infra/modules/<module_name>/resources`) and a data-only module (`infra/modules/<module_name>/data`).

Unless specified otherwise, define only a single variable called `name` in the data module.

If there are multiple data sources in the data module, define the names of the associated resources in a third interface module `infra/modules/<module_name>/interface`. Unless specified otherwise, define only a single variable called `name` in the interface module. Define outputs of the interface module to be the names of the resources in the data module. In the resources module, use the interface module to generate the names of all resources that will be referenced by the data module. In the data module, use the interface module to generate the names of all resources it needs to access via data sources.

## Bash

Follow patterns recommended by ShellCheck.

Follow Google's Shell Style Guide.

Quote variables (`"${var}"` not `$var`).

Quote command output (`var="$(command)"`).

## GitHub Actions workflows

Separate jobs with a blank line.

Separate steps with a blank line.
