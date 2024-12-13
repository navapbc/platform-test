locals {
  topics = {
    "workflows" = {
    }
  }

  channels = {
    "slack" = {
      "name" = "slack"
      "type" = "slack"
      "config" = {
        "url" = "https://hooks.slack"
      }
    }
    "email" = {
      "name" = "email"
      "type" = "email"
      "config" = {
        "email" = "platform-admins@navapbc.com"
      }
    }
}
