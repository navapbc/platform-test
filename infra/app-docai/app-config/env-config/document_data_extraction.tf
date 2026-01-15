locals {
  document_data_extraction_config = var.enable_document_data_extraction ? {
    name                         = "${var.app_name}-${var.environment}"
    input_bucket_name            = "${var.app_name}-${var.environment}-bda-input"
    output_bucket_name           = "${var.app_name}-${var.environment}-bda-output"
    document_metadata_table_name = "${var.app_name}-${var.environment}-document-metadata"
    custom_blueprints_path       = "../../modules/document-data-extraction/resources/bedrock-data-automation/"

    # BDA can only be deployed to us-east-1, us-west-2, and us-gov-west-1
    bda_region = "us-east-1"
    
    aws_managed_blueprints = [
      # Financial Documents
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-bank-statement",
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-invoice",
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-receipt",
      
      # Identity Documents
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-us-driver-license",
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-us-passport",
      
      # Tax/Employment Documents
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-form-1099-misc",
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-payslip",
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-w2-form",
    ]

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
