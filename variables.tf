variable "aws_region" {
  description = "The AWS region to deploy resources"
  default     = "us-east-1"
}

variable "app_name" {
  description = "Name of the application"
  default     = "ghost-app"
}

variable "db_username" {
  description = "The database username"
  default     = "admin"
}

variable "db_password" {
  description = "The database password"
  default     = "kenza123"  
}
