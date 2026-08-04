variable "name_prefix" {
  description = "Préfixe commun pour toutes les ressources"
  type        = string
}

variable "tags" {
  description = "Tags appliqués à toutes les ressources SQS"
  type        = map(string)
  default     = {}
}

variable "transcode_visibility_timeout" {
  description = "Temps (en secondes) pendant lequel le message est caché aux autres workers"
  type        = number
  default     = 180
}

variable "max_receive_count" {
  description = "Nombre max d'échecs avant envoi en DLQ"
  type        = number
  default     = 3
}
