
locals {
  current_year                  = formatdate("YYYY", timestamp())
  glue_database_name            = replace("${local.documentai_prefix}reporting_database", "-", "_")
  job_status_metrics_table_name = replace("${local.documentai_prefix}job_status_metrics", "-", "_")
  sqs_job_completion_queue_name = "${local.documentai_prefix}job-status-metrics-queue"

  ddb_table_columns = [
    # Core identifiers
    { name = "file_name", type = "string" },
    { name = "job_id", type = "string" },
    { name = "trace_id", type = "string" },
    { name = "client_id", type = "string" },
    { name = "external_reference_id", type = "string" },

    # Status & results
    { name = "process_status", type = "string" },
    { name = "error_message", type = "string" },
    { name = "response_code", type = "string" },
    
    # Timestamps
    { name = "created_at", type = "string" },
    { name = "updated_at", type = "string" },
    { name = "bda_started_at", type = "string" },
    { name = "bda_completed_at", type = "string" },
    
    # Performance metrics
    { name = "total_processing_time_seconds", type = "double" },
    { name = "bda_processing_time_seconds", type = "double" },
    { name = "bda_wait_time_seconds", type = "double" },
    
    # Document metadata
    { name = "user_provided_document_category", type = "string" },
    { name = "file_size_bytes", type = "bigint" },
    { name = "content_type", type = "string" },
    { name = "pages_detected", type = "int" },
    
    # Quality indicators
    { name = "is_document_blurry", type = "string" },
    { name = "is_password_protected", type = "string" },
    { name = "overall_blur_score", type = "double" },
    
    # BDA results
    { name = "bda_region_used", type = "string" },
    { name = "matched_blueprint_name", type = "string" },
    { name = "matched_blueprint_confidence", type = "double" },
    { name = "bda_matched_document_class", type = "string" },
    { name = "matched_blueprint_field_count", type = "int" },
    { name = "matched_blueprint_field_count_not_empty", type = "int" },
    { name = "matched_blueprint_field_not_empty_avg_confidence", type = "double" },
    
    # Operational
    { name = "retry_count", type = "int" },
  ]


  metrics_environment_variables = local.document_data_extraction_config != null ? {
    DOCUMENTAI_GLUE_DATABASE_NAME         = local.glue_database_name
    DOCUMENTAI_METRICS_RAW_TABLE_NAME     = local.job_status_metrics_table_name
    DOCUMENTAI_METRICS_QUEUE_URL          = aws_sqs_queue.documentai_job_completion_metrics[0].url
    DOCUMENTAI_METRICS_BUCKET_NAME        = module.documentai_metrics_bucket[0].bucket_name
    DOCUMENTAI_ATHENA_RESULTS_BUCKET_NAME = module.documentai_athena_results_bucket[0].bucket_name
  } : {}
}

module "documentai_metrics_bucket" {
  providers = {
    aws = aws.documentai
  }

  count        = local.document_data_extraction_config != null ? 1 : 0
  source       = "../../modules/storage"
  name         = "${local.documentai_prefix}metrics"
  is_temporary = local.is_temporary
}

module "documentai_athena_results_bucket" {
  providers = {
    aws = aws.documentai
  }

  count        = local.document_data_extraction_config != null ? 1 : 0
  source       = "../../modules/storage"
  name         = "${local.documentai_prefix}athena-results"
  is_temporary = local.is_temporary
}

resource "aws_sqs_queue" "documentai_job_completion_metrics" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name                       = local.sqs_job_completion_queue_name
  visibility_timeout_seconds = 300
  message_retention_seconds  = (14 * 24 * 60 * 60) # 14 days
  
  tags = local.tags
}

resource "aws_sqs_queue_policy" "documentai_job_completion_metrics" {
  count = local.document_data_extraction_config != null ? 1 : 0

  queue_url = aws_sqs_queue.documentai_job_completion_metrics[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.documentai_job_completion_metrics[0].arn
    }]
  })
}

resource "aws_glue_catalog_database" "documentai_metrics_database" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name        = local.glue_database_name
  description = "DocumentAI Job Completion Metrics"
  tags        = local.tags
}

resource "aws_glue_catalog_table" "documentai_metrics_job_status_table" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name          = local.job_status_metrics_table_name
  database_name = aws_glue_catalog_database.documentai_metrics_database[0].name

  storage_descriptor {
    location      = "s3://${module.documentai_metrics_bucket[0].bucket_name}/raw"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    
    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    dynamic "columns" {
      for_each = local.ddb_table_columns
      content {
        name    = columns.value.name
        type    = columns.value.type
      }
    }
  }

  partition_keys {
    name = "date"
    type = "string"
  }

  partition_keys {
    name = "hour"
    type = "string"
  }

  parameters = {
    "projection.enabled": "true",
    "projection.date.type": "date",
    "projection.date.range": "${local.current_year - 1}-01-01,${local.current_year + 5}-12-31",
    "projection.date.format": "yyyy-MM-dd",
    "projection.hour.type": "integer",
    "projection.hour.range": "00,23",
    "projection.hour.digits": "2",
  }
}

resource "aws_athena_workgroup" "documentai_metrics" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name = "${local.documentai_prefix}metrics-workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${module.documentai_athena_results_bucket[0].bucket_name}/"
    }
  }

  tags = local.tags
}

resource "aws_iam_policy" "sqs_send_message" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  name = "${local.prefix}sqs-send-message"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.documentai_job_completion_metrics[0].arn
      Effect   = "Allow"
    }]
  })
}

resource "aws_iam_policy" "documentai_metrics_processor" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name = "${local.documentai_prefix}metrics-processor"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.documentai_job_completion_metrics[0].arn
        Effect   = "Allow"
      },
      {
        Action = [
          "s3:PutObject"
        ]
        Resource = "${module.documentai_metrics_bucket[0].bucket_arn}/*"
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "documentai_metrics_aggregator" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name = "${local.documentai_prefix}metrics-aggregator"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:StopQueryExecution"
        ]
        Resource = aws_athena_workgroup.documentai_metrics[0].arn
        Effect   = "Allow"
      },
      {
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetPartitions"
        ]
        Resource = [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${local.glue_database_name}",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.glue_database_name}/*"
        ]
        Effect = "Allow"
      }
    ]
  })
}

#-------------------
# EventBridge Schedules
#-------------------
resource "aws_cloudwatch_event_rule" "metrics_processor_schedule" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name                = "${local.documentai_prefix}metrics-processor-schedule"
  description         = "Trigger metrics processor every 5 minutes"
  schedule_expression = "rate(5 minutes)"

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "metrics_processor_target" {
  count = local.document_data_extraction_config != null ? 1 : 0

  rule      = aws_cloudwatch_event_rule.metrics_processor_schedule[0].name
  target_id = "MetricsProcessor"
  arn       = aws_lambda_function.functions["documentai_metrics_processor"].arn
}

resource "aws_lambda_permission" "allow_eventbridge_metrics_processor" {
  count = local.document_data_extraction_config != null ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions["documentai_metrics_processor"].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.metrics_processor_schedule[0].arn
}

resource "aws_cloudwatch_event_rule" "metrics_aggregator_schedule" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name                = "${local.documentai_prefix}metrics-aggregator-schedule"
  description         = "Trigger metrics aggregator daily at 1 AM UTC"
  schedule_expression = "cron(0 1 * * ? *)"

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "metrics_aggregator_target" {
  count = local.document_data_extraction_config != null ? 1 : 0

  rule      = aws_cloudwatch_event_rule.metrics_aggregator_schedule[0].name
  target_id = "MetricsAggregator"
  arn       = aws_lambda_function.functions["documentai_metrics_aggregator"].arn
}

resource "aws_lambda_permission" "allow_eventbridge_metrics_aggregator" {
  count = local.document_data_extraction_config != null ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions["documentai_metrics_aggregator"].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.metrics_aggregator_schedule[0].arn
}
