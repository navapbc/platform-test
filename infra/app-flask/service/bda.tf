module "bda_input_bucket" {
  source       = "../../modules/storage"
  name         = "bda-test-input-app-flask"
  is_temporary = local.is_temporary
}

module "bda_output_bucket" {
  source       = "../../modules/storage"
  name         = "bda-test-output-app-flask"
  is_temporary = local.is_temporary
}

module "bda_test" {
  source = "../../modules/bedrock-data-automation"

  bda_standard_output_configuration = {
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
  }

  blueprints_map = {
    "drivers_license" = {
      schema                 = file("blueprints/template_blueprint.json")
      type                   = "DOCUMENT"
      kms_encryption_context = null
      kms_key_id             = null
      tags                   = [{ key = "example_tag_key", value = "example_tag_value" }]
    }
  }
  name_prefix        = "bda_module_test"
  bucket_policy_arns = toset([module.bda_input_bucket.access_policy_arn, module.bda_output_bucket.access_policy_arn])
}
