variable "name_prefix" { 
  type        = string
  description = "Préfixe pour nommer les ressources"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags appliqués aux tables"
}



