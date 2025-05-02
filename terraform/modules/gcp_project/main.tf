# modules/gcp_project/main.tf


# --- GCP Project Resource ---
# Creates the actual GCP Project.
resource "google_project" "project" {
  # Construct the project ID using input variables.
  project_id      = "smt-the-${var.environment}-${var.user_name}-${var.random_suffix}"
  name            = var.project_name # Display name for the project
  billing_account = var.billing_account
  org_id          = var.org_id
  # Optional: Set a default region for the project metadata (doesn't restrict resource regions)
  # labels = {
  #   environment = var.environment
  #   owner       = var.user_name
  # }
}

# --- API Activation ---
# Enables the necessary Google Cloud APIs within the created project.
# It depends on the project creation being complete.
resource "google_project_service" "apis" {
  # Loop through the list of APIs passed as a variable.
  for_each = toset(var.activate_apis)

  project                    = google_project.project.project_id
  service                    = each.key # The API service name (e.g., "compute.googleapis.com")
  disable_dependent_services = false    # Do not disable services that depend on these
  disable_on_destroy         = false    # Keep APIs enabled even after terraform destroy (optional, set to true to disable on destroy)

  # Ensure the project exists before trying to enable APIs.
  depends_on = [google_project.project]
}

# --- Project IAM Binding (Optional Example) ---
# Example: Grant the user running Terraform project owner rights for setup ease.
# WARNING: Be cautious with broad permissions in production.
# Consider creating specific service accounts with least privilege instead.

resource "google_project_iam_member" "owners" {
  for_each = toset(var.project_owners)
  project  = google_project.project.project_id
  role     = "roles/owner"
  member   = each.key

  depends_on = [google_project.project]
}

resource "google_project_iam_member" "editors" {
  for_each = toset(var.project_editors)
  project  = google_project.project.project_id
  role     = "roles/editor"
  member   = each.key

  depends_on = [google_project.project]
}

resource "google_project_iam_member" "viewers" {
  for_each = toset(var.project_viewers)
  project  = google_project.project.project_id
  role     = "roles/viewer"
  member   = each.key

  depends_on = [google_project.project]
}

data "google_project" "project_data" {
  project_id = google_project.project.project_id
  depends_on = [google_project.project]
}

resource "google_project_iam_member" "cloudbuild_sa_permissions" {
  for_each = toset([
    "roles/cloudfunctions.developer",
    "roles/iam.serviceAccountUser",
    "roles/storage.admin",
    "roles/artifactregistry.writer",
    "roles/artifactregistry.reader",
    "roles/cloudbuild.builds.builder",
    "roles/storage.objectViewer",
    "roles/logging.logWriter",
    "roles/run.invoker",
  ])

  project = google_project.project.project_id
  role    = each.key
  member  = "serviceAccount:${data.google_project.project_data.number}-compute@developer.gserviceaccount.com"

  depends_on = [data.google_project.project_data]
}

resource "google_project_iam_member" "user_logs_viewer" {
  project = "smt-the-dev-brayam-ruiz-wr4j"
  role    = "roles/logging.viewer"
  member  = "user:brayam@lionex.co"
}

