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
ENVIRONMENT_VARIABLES=${4:-""}

echo "==============="
echo "Running command"
echo "==============="
echo "Input parameters"
echo "  APP_NAME=$APP_NAME"
echo "  ENVIRONMENT=$ENVIRONMENT"
echo "  COMMAND=$COMMAND"
echo "  ENVIRONMENT_VARIABLES=$ENVIRONMENT_VARIABLES"
echo

# Use the same cluster, task definition, and network configuration that the application service uses
CLUSTER_NAME=$(terraform -chdir=infra/$APP_NAME/service output -raw service_cluster_name)
SERVICE_NAME=$(terraform -chdir=infra/$APP_NAME/service output -raw service_name)

SERVICE_TASK_DEFINITION_ARN=$(aws ecs describe-services --no-cli-pager --cluster $CLUSTER_NAME --services $SERVICE_NAME --query "services[0].taskDefinition" --output text)
# For subsequent commands, use the task definition family rather than the service's task definition ARN
# because in the case of migrations, we'll deploy a new task definition revision before updating the
# service, so the service will be using an old revision, but we want to use the latest revision.
TASK_DEFINITION_FAMILY=$(aws ecs describe-task-definition --no-cli-pager --task-definition $SERVICE_TASK_DEFINITION_ARN --query "taskDefinition.family" --output text)

NETWORK_CONFIG=$(aws ecs describe-services --no-cli-pager --cluster $CLUSTER_NAME --services $SERVICE_NAME --query "services[0].networkConfiguration")
CURRENT_REGION=$(./bin/current-region.sh)
AWS_USER_ID=$(aws sts get-caller-identity --no-cli-pager --query UserId --output text)

ENVIRONMENT_OVERRIDES=""
if [ ! -z "$ENVIRONMENT_VARIABLES" ]; then
  ENVIRONMENT_OVERRIDES="\"environment\": $ENVIRONMENT_VARIABLES,"
fi
CONTAINER_NAME=$(aws ecs describe-task-definition --task-definition $TASK_DEFINITION_FAMILY --query "taskDefinition.containerDefinitions[0].name" --output text)
OVERRIDES=$(cat << EOF
{
  "containerOverrides": [
    {
      $ENVIRONMENT_OVERRIDES
      "name": "$CONTAINER_NAME",
      "command": $COMMAND
    }
  ]
}
EOF
)

START_TIME=$(date +%s)
START_TIME_MILLIS=$((START_TIME * 1000))

AWS_ARGS=(
  ecs run-task
  --region=$CURRENT_REGION
  --cluster=$CLUSTER_NAME
  --task-definition=$TASK_DEFINITION_FAMILY
  --started-by=$AWS_USER_ID
  --launch-type=FARGATE
  --platform-version=1.4.0
  --network-configuration "$NETWORK_CONFIG"
  --overrides "$OVERRIDES"
)
echo "::group::Running AWS CLI command"
printf " ... %s\n" "${AWS_ARGS[@]}"
TASK_ARN=$(aws --no-cli-pager "${AWS_ARGS[@]}" --query "tasks[0].taskArn" --output text)
echo "::endgroup::"
echo
echo "Waiting for task to stop"
echo "  TASK_ARN=$TASK_ARN"
aws ecs wait tasks-stopped --region $CURRENT_REGION --cluster $CLUSTER_NAME --tasks $TASK_ARN
echo

# The log group name is defined in modules/service and is set to
# "service/${var.service_name}"
# TODO: DRY this up by getting it from the service module output
LOG_GROUP="service/$SERVICE_NAME"

# The log stream prefix is defined by the logConfiguration.options["awslogs-stream-prefix"]
# parameter in the ECS task definition in the modules/service module and is set to be
# the same as the service name
# TODO: DRY this up by getting it from the service module output
LOG_STREAM_PREFIX="$SERVICE_NAME"

# Get the task id by extracting the substring after the last '/' since the task ARN is of
# the form "arn:aws:ecs:<region>:<account id>:task/<cluster name>/<task id>"
ECS_TASK_ID=$(basename $TASK_ARN)

# The log stream has the format "prefix-name/container-name/ecs-task-id"
# See https://docs.aws.amazon.com/AmazonECS/latest/userguide/using_awslogs.html
LOG_STREAM="$LOG_STREAM_PREFIX/$CONTAINER_NAME/$ECS_TASK_ID"

echo "::group::Task logs"
aws logs get-log-events \
  --no-cli-pager \
  --log-group-name $LOG_GROUP \
  --log-stream-name $LOG_STREAM \
  --start-time $START_TIME_MILLIS \
  --start-from-head \
  --no-paginate \
  --output text
echo "::endgroup::"

CONTAINER_EXIT_CODE=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN --query "tasks[0].containers[?name=='$CONTAINER_NAME'].exitCode" --output text)

if [[ "$CONTAINER_EXIT_CODE" == "null" || "$CONTAINER_EXIT_CODE" != "0" ]]; then
  echo "Task failed" >&2
  # Although we could avoid extra calls to AWS CLI if we just got the full JSON response from
  # `aws ecs describe-tasks` and parsed it with jq, we are trying to avoid unnecessary dependencies.
  CONTAINER_STATUS=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN --query "tasks[0].containers[?name=='$CONTAINER_NAME'].[lastStatus,exitCode,reason]" --output text)
  TASK_STATUS=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN --query "tasks[0].[lastStatus,stopCode,stoppedAt,stoppedReason]" --output text)

  echo "Container status (lastStatus, exitCode, reason): $CONTAINER_STATUS" >&2
  echo "Task status (lastStatus, stopCode, stoppedAt, stoppedReason): $TASK_STATUS" >&2
  exit 1
fi
