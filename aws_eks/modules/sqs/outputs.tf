output "transcode_queue_url" {
  description = "URL de la file SQS à donner à Django pour envoyer les messages au Transcode Service"
  value       = aws_sqs_queue.transcode_queue.url
}

output "transcode_queue_arn" {
  description = "ARN de la file SQS (Utile pour configurer les politiques IAM)"
  value       = aws_sqs_queue.transcode_queue.arn
}

output "transcode_dlq_arn" {
  description = "ARN de la Dead Letter Queue"
  value       = aws_sqs_queue.transcode_dlq.arn
}
