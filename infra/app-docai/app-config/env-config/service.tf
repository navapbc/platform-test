locals {
  service_config = {
    service_name             = "${var.app_name}-${var.environment}"
    region                   = var.default_region
    cpu                      = var.service_cpu
    memory                   = var.service_memory
    desired_instance_count   = var.service_desired_instance_count
    enable_command_execution = var.enable_command_execution

    extra_environment_variables = merge(
      local.default_extra_environment_variables,
      var.service_override_extra_environment_variables
    )

    secrets = local.secrets

    file_upload_jobs = {
      for job_name, job_config in local.file_upload_jobs :
      # For job configs that don't define a source_bucket, add the source_bucket config property
      job_name => merge({ source_bucket = local.bucket_name }, job_config)
    }

    # /tmp is required for pdf2image and other document processing libraries
    # that need to create temporary files during PDF conversion
    ephemeral_write_volumes = ["/tmp"]
  }
}
