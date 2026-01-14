locals {
  document_data_extraction_config = var.enable_document_data_extraction ? {
    name                         = "${var.app_name}-${var.environment}"
    input_bucket_name            = "${var.app_name}-${var.environment}-bda-input"
    output_bucket_name           = "${var.app_name}-${var.environment}-bda-output"
    document_metadata_table_name = "${var.app_name}-${var.environment}-document-metadata"
    blueprints_path              = "./document-data-extraction-blueprints/"

    standard_output_configuration = {
      document = {
        extraction = {
          granularity = {
            types = ["PAGE"]
          }
          bounding_box = {
            state = "ENABLED"
          }
        }
        output_format = {
          additional_file_format = {
            state = "DISABLED"
          }
          text_format = {
            types = ["PLAIN_TEXT"]
          }
        }
      }
    }

  } : null
}
