# modules/security_policy/outputs.tf

output "policy_name" {
  description = "The name of the created Cloud Armor security policy."
  value       = google_compute_security_policy.policy.name
}

output "policy_self_link" {
  description = "The self-link of the created Cloud Armor security policy, used to attach to backends."
  value       = google_compute_security_policy.policy.self_link
}

output "policy_id" {
  description = "The ID of the created Cloud Armor security policy."
  value       = google_compute_security_policy.policy.id
}