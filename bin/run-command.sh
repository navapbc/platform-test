#!/bin/bash
# -----------------------------------------------------------------------------
# Run an application command using the application image
# 
# Positional parameters:
#   APP_NAME (required) – the name of subdirectory of /infra that holds the
#     application's infrastructure code.
#   ENVIRONMENT (required) – the name of the application environment (e.g. dev,
#     staging, prod)
#   COMMAND (required) – a JSON list representing the command to run
#     e.g. To run the command `db-migrate-up` with no arguments, set
#     COMMAND='["db-migrate-up"]'
#     e.g. To run the command `echo "Hello, world"` set
#     COMMAND='["echo", "Hello, world"]')
# -----------------------------------------------------------------------------
set -euo pipefail

APP_NAME="$1"
ENVIRONMENT="$2"
COMMAND="$3"


echo "==============="
echo "Running command"
echo "==============="
echo "Input parameters"
echo "  APP_NAME=$APP_NAME"
echo "  ENVIRONMENT=$ENVIRONMENT"
echo "  COMMAND=$COMMAND"
echo

# Use the same cluster, task definition, and network configuration that the application service uses
CLUSTER_NAME=$(terraform -chdir=infra/$APP_NAME/service output -raw service_cluster_name)
SERVICE_NAME=$(terraform -chdir=infra/$APP_NAME/service output -raw service_name)

TASK_DEFINITION=$(aws ecs describe-services --no-cli-pager --cluster $CLUSTER_NAME --services $SERVICE_NAME --query "services[0].taskDefinition" --output text)
NETWORK_CONFIG=$(aws ecs describe-services --no-cli-pager --cluster $CLUSTER_NAME --services $SERVICE_NAME --query "services[0].networkConfiguration")
CURRENT_REGION=$(./bin/current-region.sh)
AWS_USER_ID=$(aws sts get-caller-identity --no-cli-pager --query UserId --output text)

CONTAINER_NAME=$(aws ecs describe-task-definition --task-definition $TASK_DEFINITION --query "taskDefinition.containerDefinitions[0].name" --output text)
OVERRIDES=$(cat << EOF
{
  "containerOverrides": [
    {
      "name": "$CONTAINER_NAME",
      "command": $COMMAND
    }
  ]
}
EOF
)

AWS_ARGS=(
  ecs run-task
  --region=$CURRENT_REGION
  --cluster=$CLUSTER_NAME
  --task-definition=$TASK_DEFINITION
  --started-by=$AWS_USER_ID
  --launch-type=FARGATE
  --platform-version=1.4.0
  --network-configuration "$NETWORK_CONFIG"
  --overrides "$OVERRIDES"
)
echo "Running AWS CLI command"
printf " ... %s\n" "${AWS_ARGS[@]}"
echo
TASK_ARN=$(aws --no-cli-pager "${AWS_ARGS[@]}" --query "tasks[0].taskArn" --output text)
echo
echo "Waiting for task to stop"
echo "  TASK_ARN=$TASK_ARN"
echo
aws ecs wait tasks-stopped --region $CURRENT_REGION --cluster $CLUSTER_NAME --tasks $TASK_ARN
