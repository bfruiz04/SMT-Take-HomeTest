# variables.tf

# --- GCP Configuration ---
variable "org_id" {
  description = "GCP Organization ID (e.g., '1234567890'). Required for project creation."
  type        = string
  # Sensitive flag prevents showing in console output, but it's needed for project creation.
  # Consider using environment variables or .tfvars for sensitive values.
  # sensitive = true
}

variable "billing_account" {
  description = "GCP Billing Account ID (e.g., '012345-6789AB-CDEF01'). Required for project creation."
  type        = string
  # sensitive = true
}

variable "region" {
  description = "The GCP region to deploy resources into."
  type        = string
  default     = "us-central1" # Example default region
}

# --- Environment Configuration ---
variable "environment" {
  description = "Deployment environment identifier (e.g., 'dev', 'tst', 'prd')."
  type        = string
  validation {
    # Ensure the environment is one of the allowed values
    condition     = contains(["dev", "tst", "prd"], var.environment)
    error_message = "The environment variable must be one of: dev, tst, prd."
  }
}

variable "user_name" {
  description = "Your name or identifier (lowercase, no spaces/special chars except hyphen) for project ID uniqueness."
  type        = string
  validation {
    # Basic validation for the user name format
    condition     = can(regex("^[a-z0-9-]+$", var.user_name))
    error_message = "User name must contain only lowercase letters, numbers, and hyphens."
  }
}

