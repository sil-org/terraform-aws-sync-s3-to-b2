
module "minimal" {
  source = "../"

  app_env               = ""
  app_name              = ""
  b2_application_key_id = ""
  b2_application_key    = ""
  b2_bucket             = ""
  b2_path               = ""
  cpu                   = ""
  ecs_cluster_id        = ""
  log_group_name        = ""
  memory                = ""
  rclone_arguments      = ""
  schedule              = ""
  s3_bucket_name        = ""
  s3_path               = ""
}

module "full" {
  source = "../"

  app_env               = ""
  app_name              = ""
  b2_application_key_id = ""
  b2_application_key    = ""
  b2_bucket             = ""
  b2_path               = ""
  cpu                   = ""
  ecs_cluster_id        = ""
  log_group_name        = ""
  memory                = ""
  rclone_arguments      = ""
  schedule              = ""
  s3_bucket_name        = ""
  s3_path               = ""
}

provider "aws" {
  region = "us-east-1"
}
