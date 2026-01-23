
/*
 * Create role for getting files from the bucket
 */
/*
 * Create ECS task role
 */
resource "aws_iam_role" "clone" {
  name = "clone-${local.app_name_and_env}-${random_id.this.hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "ECSAssumeRole"
      Effect    = "Allow"
      Principal = { Service = ["ecs-tasks.amazonaws.com"] }
      Action    = "sts:AssumeRole"
      Condition = {
        ArnLike      = { "aws:SourceArn" = "arn:aws:ecs:${local.aws_region}:${local.aws_account}:*" }
        StringEquals = { "aws:SourceAccount" = local.aws_account }
      }
    }]
  })
}

resource "aws_iam_role_policy" "clone" {
  name = "S3-Clone-Backup-${random_id.this.hex}"
  role = aws_iam_role.clone.name

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

data "aws_caller_identity" "this" {}

data "aws_region" "current" {}

data "aws_s3_bucket" "this" {
  bucket = var.s3_bucket_name
}

/*
 * Create ECS service container definition
 */
locals {
  app_name_and_env = "${var.app_name}-${var.app_env}"
  aws_account      = data.aws_caller_identity.this.account_id
  aws_region       = data.aws_region.current.name

  task_def_clone = jsonencode([
    {
      dnsSearchDomains = null
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = local.aws_region
          awslogs-stream-prefix = var.app_name
        }
      }
      cpu = var.cpu
      environment = [
        {
          name  = "AWS_REGION"
          value = local.aws_region
        },
        {
          name  = "S3_BUCKET"
          value = var.s3_bucket_name
        },
        {
          name  = "S3_PATH"
          value = var.s3_path
        },
        {
          name  = "B2_BUCKET"
          value = var.b2_bucket
        },
        {
          name  = "B2_PATH"
          value = var.b2_path
        },
        {
          name  = "RCLONE_ARGUMENTS"
          value = var.rclone_arguments
        },
        {
          name  = "RCLONE_S3_ENV_AUTH"
          value = true
        },
      ]
      secrets = [
        {
          name      = "B2_APPLICATION_KEY_ID"
          valueFrom = var.b2_application_key_id_arn
        },
        {
          name      = "B2_APPLICATION_KEY"
          valueFrom = var.b2_application_key_arn
        },
      ]
      memoryReservation = var.memory
      image             = "ghcr.io/sil-org/sync-s3-to-b2:0.2.0"
      essential         = true
      name              = "rclone"
    }
    ]
  )
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
    Statement = [
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          aws_iam_role.clone.arn,
          aws_iam_role.ecs_task_execution_role.arn,
        ]
      },
      {
        Effect   = "Allow"
        Action   = "ecs:RunTask"
        Resource = "${aws_ecs_task_definition.clone_cron_td.arn_without_revision}:*"
      }
    ]
  })
}

/*
 * Create bucket clone task definition
 */
resource "aws_ecs_task_definition" "clone_cron_td" {
  family                = "${var.app_name}-clone-${var.app_env}"
  container_definitions = local.task_def_clone
  network_mode          = "bridge"
  execution_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn         = aws_iam_role.clone.arn
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


/*
 * ECS Task Execution Role to allow ECS to assume a role for access to SSM Parameter Store
 */

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "clone-task-exec-${var.app_name}-${var.app_env}-${random_id.this.hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "TaskExecution"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_ssm_policy" {
  name = "ssm-parameter-access"
  role = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ssm:GetParameters"]
        Resource = [
          var.b2_application_key_id_arn,
          var.b2_application_key_arn,
        ]
      }
    ]
  })
}
