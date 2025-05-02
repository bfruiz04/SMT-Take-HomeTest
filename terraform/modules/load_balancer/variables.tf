# modules/load_balancer/variables.tf

variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The GCP region for regional resources like the Serverless NEG."
  type        = string
}

variable "lb_name" {
  description = "Base name for Load Balancer components (e.g., 'my-app-lb')."
  type        = string
}

variable "function_name" {
  description = "The name of the Cloud Function to target."
  type        = string
}

variable "security_policy_link" {
  description = "The self-link of the Cloud Armor security policy to attach."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g., 'dev', 'tst', 'prd')."
  type        = string
}

# Optional: Add variables for custom network/subnetwork if needed
# variable "network_name" {
#   description = "Name of the VPC network to use."
#   type        = string
#   default     = "default"
# }