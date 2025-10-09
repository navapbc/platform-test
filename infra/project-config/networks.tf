locals {
  network_configs = {
    dev = {
      account_name = "dev"

      domain_config = {
        manage_dns  = true
        hosted_zone = "platform-test-dev.navateam.com"

        certificate_configs = {
          "platform-test-dev.navateam.com" = {
            source = "issued"
          }

          "app-flask.platform-test-dev.navateam.com" = {
            source = "issued"
          }

          "app-nextjs.platform-test-dev.navateam.com" = {
            source = "issued"
          }

          "app-rails.platform-test-dev.navateam.com" = {
            source = "issued"
          }
        }
      }
    }

    staging = {
      account_name = "staging"

      domain_config = {
        manage_dns  = true
        hosted_zone = "platform-test-dev.navateam.com"

        certificate_configs = {
          "platform-test-dev.navateam.com" = {
            source = "issued"
          }
        }
      }
    }

    prod = {
      account_name = "prod"

      domain_config = {
        manage_dns  = true
        hosted_zone = "platform-test.navateam.com"

        certificate_configs = {
          "platform-test.navateam.com" = {
            source = "issued"
          }
        }
      }
    }
  }
}
