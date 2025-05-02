# modules/cloud_function/variables.tf

variable "project_id" {
  description = "The ID of the GCP project where the function will be deployed."
  type        = string
}

variable "region" {
  description = "The GCP region for the Cloud Function."
  type        = string
}

variable "function_name" {
  description = "The name for the Cloud Function."
  type        = string
}

variable "function_entrypoint" {
  description = "The name of the function (entry point) in your source code."
  type        = string
}

variable "function_runtime" {
  description = "The runtime environment for the function (e.g., 'python311', 'nodejs18')."
  type        = string
}

variable "source_archive_path" {
  description = "The local path to the zipped source code archive."
  type        = string
}

variable "source_archive_hash" {
  description = "Base64 SHA256 hash of the source archive file for change detection."
  type        = string
  # This helps Terraform detect changes in the zip file content.
}

variable "environment" {
  description = "Deployment environment identifier (e.g., 'dev', 'tst', 'prd')."
  type        = string
}

variable "random_suffix" {
  description = "Random string for resource name uniqueness (e.g., bucket name)."
  type        = string
}