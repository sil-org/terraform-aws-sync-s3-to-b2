
/*
 * Create user for getting files from the bucket
 */
resource "aws_iam_user" "clone" {
  name = "s3-clone-${local.app_name_and_env}-${random_id.this.hex}"
}

resource "aws_iam_access_key" "clone" {
  user = aws_iam_user.clone.name
}

resource "aws_iam_user_policy" "clone" {
  name = "S3-Clone-Backup-${random_id.this.hex}"
  user = aws_iam_user.clone.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource = [
          "${data.aws_s3_bucket.this.arn}/*",
          data.aws_s3_bucket.this.arn
        ]
      }
    ]
  })
}

data "aws_region" "current" {}

data "aws_s3_bucket" "this" {
  bucket = var.s3_bucket_name
}

/*
 * Create ECS service container definition
 */
locals {
  app_name_and_env = "${var.app_name}-${var.app_env}"
  aws_region       = data.aws_region.current.name

  task_def_clone = templatefile("${path.module}/task-def-copys3b2.json", {
    app_name              = var.app_name
    aws_access_key        = aws_iam_access_key.clone.id
    aws_secret_key        = aws_iam_access_key.clone.secret
    aws_region            = local.aws_region
    b2_application_key_id = var.b2_application_key_id
    b2_application_key    = var.b2_application_key
    s3_bucket             = var.s3_bucket_name
    s3_path               = var.s3_path
    b2_bucket             = var.b2_bucket
    b2_path               = var.b2_path
    rclone_arguments      = var.rclone_arguments
    log_group_name        = var.log_group_name
    cpu                   = var.cpu
    memory                = var.memory
  })
}

/*
 * Create role for scheduled running of rclone task definition.
 */
resource "aws_iam_role" "rclone_event" {
  name = "rclone_event-${local.app_name_and_env}-s3copy-${random_id.this.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "rclone_event_run_task_with_any_role" {
  name = "rclone_event_run_task_with_any_role-${random_id.this.hex}"
  role = aws_iam_role.rclone_event.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "ecs:RunTask"
        Resource = "${aws_ecs_task_definition.clone_cron_td.arn_without_revision}:*"
      }
    ])
  })
}

/*
 * Create bucket clone task definition
 */
resource "aws_ecs_task_definition" "clone_cron_td" {
  family                = "${var.app_name}-clone-${var.app_env}"
  container_definitions = local.task_def_clone
  network_mode          = "bridge"
}

/*
 * CloudWatch configuration to start scheduled backup of S3 using rclone.
 */
resource "aws_cloudwatch_event_rule" "s3_clone_event_rule" {
  name        = "${local.app_name_and_env}-s3clone-${random_id.this.hex}"
  description = "Start scheduled backup of S3 using rclone"

  schedule_expression = var.schedule
}

resource "aws_cloudwatch_event_target" "clone_event_target" {
  target_id = "${local.app_name_and_env}-s3clone-${random_id.this.hex}"
  rule      = aws_cloudwatch_event_rule.s3_clone_event_rule.name
  arn       = var.ecs_cluster_id
  role_arn  = aws_iam_role.rclone_event.arn

  ecs_target {
    task_count          = 1
    launch_type         = "EC2"
    task_definition_arn = aws_ecs_task_definition.clone_cron_td.arn
  }
}

resource "random_id" "this" {
  byte_length = 2
}
