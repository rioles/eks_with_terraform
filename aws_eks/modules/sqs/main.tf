resource "aws_sqs_queue" "transcode_dlq" {
  name                      = "${var.name_prefix}-transcode-dlq"
  message_retention_seconds = 604800

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-transcode-dlq"
  })
}

resource "aws_sqs_queue" "transcode_queue" {
  name                       = "${var.name_prefix}-transcode-queue"
  visibility_timeout_seconds = var.transcode_visibility_timeout  # ✅ variable
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.transcode_dlq.arn
    maxReceiveCount     = var.max_receive_count  # ✅ variable
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-transcode-queue"
  })
}
