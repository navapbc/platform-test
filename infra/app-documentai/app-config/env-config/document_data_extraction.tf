locals {
  document_data_extraction_config = var.enable_document_data_extraction ? {
    name               = "${var.app_name}-${var.environment}"
    input_bucket_name  = "${local.bucket_name}-dde-input"
    output_bucket_name = "${local.bucket_name}-dde-output"

    # List of blueprint file paths or ARNs
    # File paths are relative to the service directory
    # ARNs reference AWS-managed or existing custom blueprints
    blueprints = [
      # TODO(pre-merge): Add trailing comma to this line in template
      "./document-data-extraction-blueprints/*",

      ## AWS Managed Blueprints
      # Financial Documents
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-bank-statement",
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-invoice",
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-receipt",

      # Identity Documents
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-us-driver-license",
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-us-passport",
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-birth-certificate",

      # Tax/Employment Documents
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-form-1040",
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-form-1099-int",
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-form-1099-misc",
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-payslip",
      "arn:aws:bedrock:us-east-1:aws:blueprint/bedrock-data-automation-public-w2-form",
    ]

    # BDA can only be deployed to us-east-1, us-west-2, and us-gov-west-1
    # TODO(https://github.com/navapbc/template-infra/issues/993) Add GovCloud Support
    bda_region = "us-east-1"

    standard_output_configuration = {
      # TODO(pre-merge): this is standard
      image = {
        extraction = {
          bounding_box = {
            state = "ENABLED"
          }
          category = {
            state = "ENABLED"
            types = ["TEXT_DETECTION", "LOGOS"]
          }
        }
        generative_field = {
          state = "ENABLED"
          types = ["IMAGE_SUMMARY"]
        }
      }

      # TODO(pre-merge): this is new, what should we be using?
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
