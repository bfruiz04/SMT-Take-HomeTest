output "function_name" {
  description = "The name of the deployed Cloud Function."
  value       = google_cloudfunctions2_function.function.name
}

output "function_uri" {
  description = "The HTTPS trigger URI of the Cloud Function."
  value       = google_cloudfunctions2_function.function.service_config[0].uri
  sensitive   = true # URI can be sensitive
}

output "function_service_account" {
  description = "The service account the function runs as."
  # If using default SA: google_cloudfunctions2_function.function.service_config[0].service_account_email
  # If using dedicated SA: google_service_account.function_sa.email
  value = google_cloudfunctions2_function.function.service_config[0].service_account_email
}

output "source_bucket_name" {
  description = "The name of the GCS bucket holding the function source code."
  value       = google_storage_bucket.source_bucket.name
}
