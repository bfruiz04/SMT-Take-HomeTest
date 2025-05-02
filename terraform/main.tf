# main.tf

# --- Provider Configuration ---
# Define required providers and their versions.
terraform {
  required_version = ">= 1.4.6" # Specify minimum Terraform version
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.45.2" # Specify Google provider version constraint
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.2" # Specify Random provider version constraint
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2" # Specify Archive provider version constraint
    }
  }
}

# --- Google Provider ---
# Configure the Google provider.
# Credentials can be provided via environment variables (GOOGLE_CREDENTIALS, GOOGLE_PROJECT),
# gcloud CLI authentication, or service account key file.
provider "google" {
  # The project ID will be dynamically set by the project module upon creation.
  # For initial plan/apply before project creation, you might need to set a placeholder
  # or use credentials with organization-level permissions.
  # project = var.project_id # This will be set later if the project is created by this config
  region = var.region
}

# --- Random String Resource ---
# Generate a random 4-character string for the project ID.
resource "random_string" "suffix" {
  length  = 4
  special = false # Do not include special characters
  upper   = false # Do not include uppercase letters
  lower   = true  # Only include lowercase letters
}

# --- Project Module ---
# Call the module responsible for creating the GCP project.
module "gcp_project" {
  source = "./modules/gcp_project" # Path to the project module

  # --- Input Variables for the Project Module ---
  org_id          = var.org_id                  # GCP Organization ID
  billing_account = var.billing_account         # GCP Billing Account ID
  project_name    = "SMT Take Home Exercise"    # Desired project display name
  environment     = var.environment             # Deployment environment (dev, tst, prd)
  user_name       = var.user_name               # User's name for the project ID
  random_suffix   = random_string.suffix.result # Pass the generated random string
  region          = var.region                  # Default region for the project
  # List of APIs to enable in the newly created project
  activate_apis = [
    "compute.googleapis.com",              # Needed for Load Balancers, VPC, Firewall, NEG
    "cloudfunctions.googleapis.com",       # Needed for Cloud Functions v1/v2
    "run.googleapis.com",                  # Needed for Cloud Functions v2 (runs on Cloud Run)
    "iam.googleapis.com",                  # Needed for IAM policies
    "cloudresourcemanager.googleapis.com", # Needed for project management
    "cloudbilling.googleapis.com",         # Needed for linking billing account
    "serviceusage.googleapis.com",         # Needed for enabling APIs
    "artifactregistry.googleapis.com",     # Needed for Cloud Functions build artifacts (often default)
    "cloudbuild.googleapis.com",           # Needed for building Cloud Functions
    "logging.googleapis.com",              # Needed for Cloud Logging
    "monitoring.googleapis.com",           # Needed for Cloud Monitoring
    "eventarc.googleapis.com",             # Needed for Eventarc (if used)
  ]

  project_owners  = ["user:brayam@lionex.co"]
  project_editors = []
  project_viewers = []
}

# --- Provider Alias for the New Project ---
# Configure a Google provider alias specifically for the newly created project.
# This ensures subsequent resources are created within that project.
provider "google" {
  alias   = "new_project_provider"
  project = module.gcp_project.project_id # Use the output project ID from the module
  region  = var.region
}

# --- Archive Function Code ---
# Create a zip archive of the Cloud Function source code.
data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "../function"                                                                # Path to the directory containing main.py and requirements.txt
  output_path = "/tmp/function-source-${var.environment}-${random_string.suffix.result}.zip" # Temporary path for the zip file
}

# --- Cloud Function Module ---
# Call the module responsible for creating the Cloud Function and related resources.
module "cloud_function" {
  source = "./modules/cloud_function" # Path to the function module
  # Use the provider alias to ensure resources are created in the new project
  providers = {
    google = google.new_project_provider
  }

  # --- Input Variables for the Function Module ---
  project_id          = module.gcp_project.project_id                         # Pass the new project ID
  region              = var.region                                            # Region for the function
  function_name       = "hello-world-function-${var.environment}"             # Unique function name
  function_entrypoint = "hello_world_http"                                    # Function entry point in main.py
  function_runtime    = "python311"                                           # Python runtime version
  source_archive_path = data.archive_file.function_source.output_path         # Path to the zipped source code
  source_archive_hash = data.archive_file.function_source.output_base64sha256 # Hash for change detection
  environment         = var.environment                                       # Pass environment for naming/tagging
  random_suffix       = random_string.suffix.result                           # Pass random suffix for bucket naming
}

# --- Security Policy Module ---
# Call the module responsible for creating the Cloud Armor security policy.
module "security_policy" {
  source = "./modules/security_policy" # Path to the security policy module
  # Use the provider alias
  providers = {
    google = google.new_project_provider
  }

  # --- Input Variables for the Security Policy Module ---
  project_id  = module.gcp_project.project_id           # Pass the new project ID
  policy_name = "smt-the-waf-policy-${var.environment}" # Unique policy name
  description = "WAF policy with OWASP rules for SMT Take Home Exercise (${var.environment})"
}


# --- Load Balancer Module ---
# Call the module responsible for creating the Load Balancer and related networking.
module "load_balancer" {
  source = "./modules/load_balancer" # Path to the load balancer module
  # Use the provider alias
  providers = {
    google = google.new_project_provider
  }

  # --- Input Variables for the Load Balancer Module ---
  project_id           = module.gcp_project.project_id           # Pass the new project ID
  region               = var.region                              # Region for regional resources (like NEG)
  lb_name              = "smt-the-lb-${var.environment}"         # Base name for LB components
  function_name        = module.cloud_function.function_name     # Pass the deployed function name
  security_policy_link = module.security_policy.policy_self_link # Link to the Cloud Armor policy
  environment          = var.environment                         # Pass environment for naming/tagging

  # Ensure the Cloud Function exists before setting up the LB components that depend on it
  depends_on = [module.cloud_function]
}

