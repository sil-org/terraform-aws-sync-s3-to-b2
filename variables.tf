variable "app_env" {
  description = "A short version of the application environment (e.g. `stg`)"
  type        = string
}

variable "app_name" {
  description = "A short app name for use in configuration and infrastructure"
  type        = string
}

variable "b2_application_key_id" {
  description = "Backblaze application key ID"
  type        = string
}

variable "b2_application_key" {
  description = "Backblaze application key secret"
  type        = string
}

variable "b2_bucket" {
  description = "Name of the Backblaze B2 bucket"
  type        = string
}

variable "b2_path" {
  description = "Path within the Backblaze B2 bucket where files will be stored"
  type        = string
}

variable "cpu" {
  description = "Amount of CPU to allocate to the task"
  type        = string
}

variable "ecs_cluster_id" {
  description = "The ID of the ECS Cluster where this scheduled task should run"
  type        = string
}

variable "log_group_name" {
  description = "The CloudWatch Log Group to write logs to"
  type        = string
}

variable "memory" {
  description = "Amount of memory to allocate to the task"
  type        = string
}

variable "rclone_arguments" {
  description = "(optional) e.g., --combined -"
  type        = string
}

variable "schedule" {
  description = "S3-to-B2 backup schedule, e.g., 'cron(10 2 * * ? *)'"
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket to sync to B2 (e.g. `my-bucket`)"
  type        = string
}

variable "s3_path" {
  description = "Path to be backed up within the AWS S3 bucket"
  type        = string
}
