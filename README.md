# sync-s3-to-b2 - Synchronize the content of an AWS S3 bucket on a Backblaze B2 bucket

This Terraform module replicates the changes in an AWS S3 bucket onto a Backblaze B2 bucket resulting in the B2 bucket content being identical to the S3 bucket content.

## What this does

* Creates an IAM user with permissions to read the S3 bucket
* Creates an ECS task definition
* Schedules that task to run the `sync-s3-to-b2` Docker image

## Required Inputs

* `app_name` - Name of the application
* `app_env` - Short name of the environment, e.g., prod, stg, etc.
* `b2_application_key_id` - Backblaze Application Key ID
* `b2_application_key` - Backblaze Application Key secret
* `b2_bucket` - Name of the Backblaze B2 bucket
* `b2_path` - Path within the Backblaze B2 bucket where files will be stored
* `cpu` - Amount of CPU to allocate to the task
* `ecs_cluster_id` - ID of the ECS Cluster where this scheduled task should run
* `log_group_name` - CloudWatch Log Group to write logs to
* `memory` - Amount of memory to allocate to the task
* `schedule` - S3-to-B2 backup schedule, e.g., `cron(10 2 * * ? *)`
* `s3_bucket_name` - Name of the S3 bucket to sync to B2, e.g., `my-bucket`
* `s3_path` - Path to be backed up within the AWS S3 bucket

## Optional Inputs

* `rclone_arguments` - Extra arguments to pass to the `rclone` command; default is ""

## Outputs

_none_

## Example Usage

```hcl
module "sync_s3_to_b2" {
  source = "./modules/sync-s3-to-b2"

  app_name              = var.app_name
  app_env               = var.app_env
  b2_application_key_id = var.b2_application_key_id
  b2_application_key    = var.b2_application_key
  b2_bucket             = var.b2_bucket_name
  b2_path               = var.b2_path
  cpu                   = var.backup_cpu
  ecs_cluster_id        = data.terraform_remote_state.common.outputs.ecs_cluster_id
  log_group_name        = aws_cloudwatch_log_group.my_loggroup.name
  memory                = var.backup_memory
  rclone_arguments      = "--verbose"
  schedule              = "cron(10 2 * * ? *)"
  s3_bucket_name        = var.s3_bucket_name
  s3_path               = var.s3_path
}
```
