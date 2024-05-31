#!/bin/bash
set -euo pipefail

APP_NAME=$1
IMAGE_TAG=$2
ENVIRONMENT=$3

CLUSTER_NAME=$(terraform -chdir="infra/$APP_NAME/service" output -raw service_cluster_name)
SERVICE_NAME=$(terraform -chdir="infra/$APP_NAME/service" output -raw service_name)

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
echo
echo "Starting $APP_NAME deploy of $IMAGE_TAG to $ENVIRONMENT"


TF_CLI_ARGS_apply="-input=false -auto-approve -var=image_tag=$IMAGE_TAG" make infra-update-app-service APP_NAME="$APP_NAME" ENVIRONMENT="$ENVIRONMENT"

# Wait for the service to become stable
echo "Waiting for service $SERVICE_NAME to become stable"
aws ecs wait services-stable --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME"

echo "Completed $APP_NAME deploy of $IMAGE_TAG to $ENVIRONMENT"
