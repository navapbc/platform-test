locals {
  job_configs = {
    file_upload_jobs = {
      etl = {
        path_prefix  = "etl/input",
        task_command = ["python", "-m", "flask", "--app", "app.py", "etl", "<object_key>"]
      }
    }
  }
}
