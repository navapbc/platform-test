locals {
  # The prefix key/value pair is used for Terraform Workspaces, which is useful for projects with multiple infrastructure developers.
  # By default, Terraform creates a workspace named “default.” If a non-default workspace is not created this prefix will equal “default”, 
  # if you choose not to use workspaces set this value to "dev" 
  prefix = terraform.workspace == "default" ? "" : "${terraform.workspace}-"

  bucket_name = "${local.prefix}${var.project_name}-${var.app_name}-${var.environment}"

  # Configuration for default jobs to run in every environment
  # See description of the file_upload_job_overrides variable
  # for more info
  default_file_upload_jobs = {
    etl = {
      path_prefix  = "etl/input",
      task_command = ["python", "-m", "flask", "--app", "app.py", "etl", "<object_key>"]
    }
  }
}
