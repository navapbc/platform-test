# Set up network

The network setup process will create the network resources (security groups, etc.) needed for your system.

## Requirements

Before setting up the application's build repository you'll need to have:

1. [Set up the AWS account](./set-up-aws-account.md)

## 1. Configure backend

To create the tfbackend file for the build repository using the backend configuration values from your current AWS account, run

```bash
make infra-configure-network NETWORK_NAME=<NETWORK_NAME>
```

Choose a name for your network. If you plan on having multiple environments, you can use the environment name (e.g. "prod", "staging") for your network.

## 2. Create network resources

Now run the following command to create the resources, making sure to verify the plan before confirming the apply.

```bash
make infra-update-network NETWORK_NAME=<NETWORK_NAME>
```

## Set up application environments

Once you set up the network, you can proceed to set up the application's [build repository](./set-up-app-build-repository.md) and [application environments](./set-up-app-env.md).
