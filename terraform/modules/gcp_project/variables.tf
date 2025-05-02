# modules/gcp_project/variables.tf

variable "org_id" {
  description = "GCP Organization ID."
  type        = string
}

variable "billing_account" {
  description = "GCP Billing Account ID."
  type        = string
}

variable "project_name" {
  description = "The desired display name for the GCP project."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., 'dev', 'tst', 'prd')."
  type        = string
}

variable "user_name" {
  description = "User identifier for the project ID."
  type        = string
}

variable "random_suffix" {
  description = "A random string to ensure project ID uniqueness."
  type        = string
}

variable "region" {
  description = "Default GCP region for the project."
  type        = string
}

variable "activate_apis" {
  description = "A list of Google Cloud APIs to enable in the project."
  type        = list(string)
  default     = [] # Default to an empty list
}

variable "project_owners" {
  type        = list(string)
  description = "List of members to grant project-level owner access"
  default     = []
}

variable "project_editors" {
  type        = list(string)
  description = "List of members to grant project-level editor access"
  default     = []
}

variable "project_viewers" {
  type        = list(string)
  description = "List of members to grant project-level viewer access"
  default     = []
}
