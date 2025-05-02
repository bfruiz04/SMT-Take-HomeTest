# modules/security_policy/variables.tf

variable "project_id" {
  description = "The ID of the GCP project where the security policy will be created."
  type        = string
}

variable "policy_name" {
  description = "The name for the Cloud Armor security policy."
  type        = string
}

variable "description" {
  description = "Description for the Cloud Armor security policy."
  type        = string
  default     = "Default WAF security policy"
}
