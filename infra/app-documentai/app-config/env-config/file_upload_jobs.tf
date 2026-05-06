locals {
  # Configuration for default jobs to run in every environment.
  # See description of `file_upload_jobs` variable in the service module (infra/modules/service/variables.tf)
  # for the structure of this configuration object.
  # One difference is that `source_bucket` is optional here. If `source_bucket` is not
  # specified, then the source bucket will be set to the storage bucket's name
  file_upload_jobs = {
    document_processor = {
      source_bucket = local.document_data_extraction_config != null ? local.document_data_extraction_config.input_bucket_name : null
      path_prefix   = "input/"
      task_command  = ["document_processor", "<object_key>", "<bucket_name>"]
    }
    bda_result_processor = {
      source_bucket = local.document_data_extraction_config != null ? local.document_data_extraction_config.output_bucket_name : null
      path_prefix   = "processed/"
      task_command  = ["bda_result_processor", "<bucket_name>", "<object_key>"]
    }
  }
}
