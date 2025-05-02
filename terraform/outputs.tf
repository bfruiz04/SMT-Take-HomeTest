# outputs.tf

# --- Project Outputs ---
output "project_id" {
  description = "The ID of the created GCP project."
  value       = module.gcp_project.project_id
}

output "project_number" {
  description = "The number of the created GCP project."
  value       = module.gcp_project.project_number
}

# --- Cloud Function Outputs ---
output "cloud_function_uri" {
  description = "The HTTPS trigger URL for the deployed Cloud Function (should require authentication)."
  value       = module.cloud_function.function_uri
  sensitive   = true # The URI might be considered sensitive depending on security posture
}

output "cloud_function_name" {
  description = "The name of the deployed Cloud Function."
  value       = module.cloud_function.function_name
}

# --- Load Balancer Outputs ---
output "load_balancer_ip_address" {
  description = "The external IP address of the HTTP Load Balancer."
  value       = module.load_balancer.lb_ip_address
}

output "load_balancer_url" {
  description = "The base URL to access the service via the Load Balancer."
  value       = "http://${module.load_balancer.lb_ip_address}"
}

output "hello_world_url" {
  description = "The specific URL to access the 'Hello World' endpoint via the Load Balancer."
  value       = "http://${module.load_balancer.lb_ip_address}/helloWorld"
}

# --- Security Policy Outputs ---
output "security_policy_name" {
  description = "The name of the created Cloud Armor security policy."
  value       = module.security_policy.policy_name
}

