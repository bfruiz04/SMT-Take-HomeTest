# modules/cloud_function/main.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  alias   = "new_project_provider"
  region  = var.region
  project = module.project.project_id
}

# --- Cloud Storage Bucket and Object for Source Code ---
resource "google_storage_bucket" "source_bucket" {
  project                    = var.project_id
  name                       = "smt-the-func-src-${var.environment}-${var.random_suffix}"
  location                   = var.region
  force_destroy              = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "source_archive" {
  name   = "function-source-${filemd5(var.source_archive_path)}.zip"
  bucket = google_storage_bucket.source_bucket.name
  source = var.source_archive_path

  content_type = "application/zip"
  metadata = {
    md5hash = filemd5(var.source_archive_path)
  }
}

# --- Dedicated Service Account for Function Invocation ---
resource "google_service_account" "function_invoker_sa" {
  project      = var.project_id
  account_id   = "func-invoker-${var.environment}-${var.random_suffix}"
  display_name = "Service Account for ${var.function_name} Invocation"
}

# --- Cloud Functions (2nd gen) Function Resource ---
resource "google_cloudfunctions2_function" "function" {
  project  = var.project_id
  name     = var.function_name
  location = var.region

  build_config {
    runtime     = var.function_runtime
    entry_point = var.function_entrypoint
    source {
      storage_source {
        bucket = google_storage_bucket.source_bucket.name
        object = google_storage_bucket_object.source_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 3
    min_instance_count = 0
    available_memory   = "256Mi"
    timeout_seconds    = 60
    ingress_settings   = "ALLOW_INTERNAL_AND_GCLB"
    all_traffic_on_latest_revision = true

    environment_variables = {
      ENVIRONMENT = var.environment
    }

    # Optional but recommended: specify the service account the function will run as.
    # If not specified, it defaults to the project's Compute Engine default service account.
    # service_account_email = "another-service-account@your-project-id.iam.gserviceaccount.com"
  }

  lifecycle {
    replace_triggered_by = [
      google_storage_bucket_object.source_archive
    ]
  }

  depends_on = [google_storage_bucket_object.source_archive]
}


