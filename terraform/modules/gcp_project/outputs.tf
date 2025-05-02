# modules/gcp_project/outputs.tf

output "project_id" {
  description = "The unique ID of the created project."
  value       = google_project.project.project_id
}

output "project_number" {
  description = "The numeric identifier of the created project."
  value       = google_project.project.number
}

output "project_name" {
  description = "The display name of the created project."
  value       = google_project.project.name
}