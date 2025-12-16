locals {
  document_data_extraction_config = local.environment_config.document_data_extraction_config

  # convert tags map to bedrock data automation format
  tags_dict = [
    for key, value in local.tags : {
      key   = key
      value = value
    }
  ]

  document_data_extraction_environment_variables = local.document_data_extraction_config != null ? {
    DDE_INPUT_BUCKET_NAME  = local.document_data_extraction_config.input_bucket_name
    DDE_OUTPUT_BUCKET_NAME = local.document_data_extraction_config.output_bucket_name
    DDE_PROJECT_ARN        = module.dde[0].bda_project_arn
  } : {}
}

module "dde_input_bucket" {
  count        = local.document_data_extraction_config != null ? 1 : 0
  source       = "../../modules/storage"
  name         = local.document_data_extraction_config.input_bucket_name
  is_temporary = local.is_temporary
}

module "dde_output_bucket" {
  count        = local.document_data_extraction_config != null ? 1 : 0
  source       = "../../modules/storage"
  name         = local.document_data_extraction_config.output_bucket_name
  is_temporary = local.is_temporary
}

module "dde" {
  count  = local.document_data_extraction_config != null ? 1 : 0
  source = "../../modules/document-data-extraction/resources"

  standard_output_configuration = local.document_data_extraction_config.standard_output_configuration
  tags                          = local.tags_dict

  blueprints_map = {
    for blueprint in local.document_data_extraction_config.enabled_blueprints :
    split(".", blueprint)[0] => {
      schema                 = file("${local.document_data_extraction_config.blueprints_path}/${blueprint}")
      type                   = "DOCUMENT"
      kms_encryption_context = null
      kms_key_id             = null
      tags                   = local.tags_dict
    }
  }

  name = "${local.prefix}${local.document_data_extraction_config.name}"

  bucket_policy_arns = {
    input_bucket  = module.dde_input_bucket[0].access_policy_arn,
    output_bucket = module.dde_output_bucket[0].access_policy_arn
  }
}
