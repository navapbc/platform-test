# Background jobs

The application may have background jobs that support the application. Types of background jobs include:

* Jobs that occur on a fixed schedule (e.g. every hour or every night) — This type of job is useful for ETL jobs that can't be event-driven, such as ETL jobs that ingest source files from an SFTP server or from an S3 bucket managed by another team that we have little control or influence over.
* Jobs that trigger on an event (e.g. when a file is uploaded to the document storage service). This type of job can be processed by two types of tasks:
  * Tasks that spin up on demand to process the job — This type of task is appropriate for low-frequency ETL jobs
  * Worker tasks that are running continuously, waiting for jobs to enter a queue that the worker then processes — This type of process is task is ideal for high frequency, low-latency jobs such as processing user uploads or submitting claims to an unreliable or high-latency legacy system

## Job configuration

Background jobs for the application are configured via the application's `env-config` module. The current infrastructure supports jobs that spin up on demand tasks when a file is uploaded to the document storage service. These are configured in the `file_upload_jobs` configuration.

Jobs that you want to have enabled on all environments should be added to the `default_file_upload_jobs` property. Exceptions for an environment this can be defined by setting the `file_upload_job_overrides` variable for that environment's `[env].tf` file.
