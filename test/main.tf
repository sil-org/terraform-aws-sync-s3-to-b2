
module "minimal" {
  source = "../"

  app_env                   = ""
  app_name                  = ""
  b2_application_key_id_arn = ""
  b2_application_key_arn    = ""
  b2_bucket                 = ""
  b2_path                   = ""
  cpu                       = 1
  ecs_cluster_id            = ""
  log_group_name            = ""
  memory                    = 1
  rclone_arguments          = ""
  schedule                  = ""
  s3_bucket_name            = ""
  s3_path                   = ""
}

module "full" {
  source = "../"

  app_env                   = ""
  app_name                  = ""
  b2_application_key_id_arn = ""
  b2_application_key_arn    = ""
  b2_bucket                 = ""
  b2_path                   = ""
  cpu                       = 1
  ecs_cluster_id            = ""
  log_group_name            = ""
  memory                    = 1
  rclone_arguments          = ""
  schedule                  = ""
  s3_bucket_name            = ""
  s3_path                   = ""
}

provider "aws" {
  region = "us-east-1"
}
