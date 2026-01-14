locals {
  # convert standard terraform tags to bedrock data automation format
  bda_tags = [
    for key, value in var.tags : {
      key   = key
      value = value
    }
  ]
}

resource "awscc_bedrock_data_automation_project" "bda_project" {
  project_name                  = "${var.name}-project"
  project_description           = "Project for ${var.name}"
  tags                          = local.bda_tags
  standard_output_configuration = var.standard_output_configuration
  custom_output_configuration = {
    blueprints = [for k, v in awscc_bedrock_blueprint.bda_blueprint : {
      blueprint_arn   = v.blueprint_arn
      blueprint_stage = v.blueprint_stage
    }]
  }
  override_configuration = var.override_configuration
}

resource "awscc_bedrock_blueprint" "bda_blueprint" {
  for_each = var.blueprints_map

  blueprint_name         = "${var.name}-${each.key}"
  schema                 = each.value.schema
  type                   = each.value.type
  tags                   = local.bda_tags
}