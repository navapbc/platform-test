# This module finds existing phone pool resources for reuse in temporary environments
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Check for existing phone pools in the account
data "external" "existing_pools" {
  program = ["bash", "-c", <<-EOF
    # List all SMS phone pools and return the first one if it exists
    # Use pinpoint-sms-voice-v2 as the correct AWS CLI service name
    pools=$(aws pinpoint-sms-voice-v2 describe-pools --query 'Pools[0].{PoolId:PoolId,PoolArn:PoolArn}' --output json 2>/dev/null || echo '{}')
    if [[ "$pools" == "{}" ]] || [[ "$pools" == "null" ]]; then
      echo '{"pool_id":"","pool_arn":"","exists":"false"}'
    else
      pool_id=$(echo "$pools" | jq -r '.PoolId // ""')
      pool_arn=$(echo "$pools" | jq -r '.PoolArn // ""')
      if [[ "$pool_id" == "" ]] || [[ "$pool_id" == "null" ]]; then
        echo '{"pool_id":"","pool_arn":"","exists":"false"}'
      else
        echo "{\"pool_id\":\"$pool_id\",\"pool_arn\":\"$pool_arn\",\"exists\":\"true\"}"
      fi
    fi
  EOF
  ]
}