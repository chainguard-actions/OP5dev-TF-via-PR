terraform {
  required_version = ">= 1.0"
}

variable "name" {
  description = "A simple variable"
  type        = string
  default     = "test"
}

output "name" {
  value = var.name
}
