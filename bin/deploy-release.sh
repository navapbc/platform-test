#!/bin/bash
set -euo pipefail

APP_NAME=$1
IMAGE_TAG=$2
ENVIRONMENT=$3

CLUSTER_NAME=$(terraform -chdir="infra/$APP_NAME/service" output -raw service_cluster_name)
SERVICE_NAME=$(terraform -chdir="infra/$APP_NAME/service" output -raw service_name)
LOG_GROUP=$(terraform -chdir="infra/$APP_NAME/service" output -raw application_log_group)

echo "--------------"
echo "Deploy release"
echo "--------------"
echo "Input parameters:"
echo "  APP_NAME=$APP_NAME"
echo "  IMAGE_TAG=$IMAGE_TAG"
echo "  ENVIRONMENT=$ENVIRONMENT"
echo "Additional context:"
echo "  CLUSTER_NAME=$CLUSTER_NAME"
echo "  SERVICE_NAME=$SERVICE_NAME"
echo "  LOG_GROUP=$LOG_GROUP"
echo
echo "Starting $APP_NAME deploy of $IMAGE_TAG to $ENVIRONMENT"


TF_CLI_ARGS_apply="-input=false -auto-approve -var=image_tag=$IMAGE_TAG" make infra-update-app-service APP_NAME="$APP_NAME" ENVIRONMENT="$ENVIRONMENT"

# Start tailing the logs in the background
aws logs tail "$LOG_GROUP" --follow & LOG_TAIL_PID=$!

# Wait for the service to become stable
aws ecs wait services-stable --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME"

# Once the service is stable, kill the log tailing process
kill $LOG_TAIL_PID

echo "Completed $APP_NAME deploy of $IMAGE_TAG to $ENVIRONMENT"
