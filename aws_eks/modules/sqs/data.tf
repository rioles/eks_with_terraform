locals {
  # Regroupement des configurations nommées si tu souhaites étendre le module plus tard
  sqs_queue_name = "${var.name_prefix}-transcode-queue"
  sqs_dlq_name   = "${var.name_prefix}-transcode-dlq"
}
