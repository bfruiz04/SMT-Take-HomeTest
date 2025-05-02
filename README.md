# GCP Cloud Function with Load Balancer - Terraform Deployment
![image](https://github.com/user-attachments/assets/a3a8e457-fbfb-4bcd-b549-0b2b91c66ed2)

This repository contains Terraform code to deploy a simple "Hello World" application on Google Cloud Platform (GCP). The application consists of a Python Cloud Function (Gen 2) exposed via a Global HTTP Load Balancer, secured with Cloud Armor, and deployed within a newly created GCP project.

## Architecture

The infrastructure created by this Terraform configuration includes:

1.  **GCP Project:** A new GCP project is created with a unique ID based on environment, user name, and a random suffix (`smt-the-{env}-{yourname}-{random}`). Necessary APIs are automatically enabled.
2.  **Cloud Function (Gen 2):**
    * A Python function (`main.py`) triggered via HTTP.
    * Returns "Hello World!" for GET requests to the root (`/`).
    * Returns 405 Method Not Allowed for other HTTP methods.
    * Source code is packaged and uploaded to a dedicated Cloud Storage bucket.
    * Deployed using Cloud Functions Gen 2 (runs on Cloud Run).
    * **Security:** Ingress is restricted to `ALLOW_INTERNAL_AND_GCLB`, preventing direct public access.
3.  **Cloud Storage Bucket:** Stores the zipped source code for the Cloud Function.
4.  **Global HTTP Load Balancer:**
    * **Frontend:** A global static IP address and forwarding rule listening on port 80.
    * **Backend:** A backend service routing traffic to the Cloud Function via a Serverless Network Endpoint Group (NEG).
    * **Routing:** A URL map directs traffic from the path `/helloWorld` on the Load Balancer to the root (`/`) of the Cloud Function.
    * **Health Check:** A basic HTTP health check monitors the function's availability (best-effort for serverless).
5.  **Cloud Armor:**
    * A security policy is attached to the Load Balancer's backend service.
    * Includes preconfigured rules to block common OWASP Top 10 attacks (e.g., SQLi, XSS, LFI) detected by ModSecurity CRS 3.3.
6.  **IAM:** While specific user roles aren't heavily configured in this example, the function's ingress settings provide the primary access control. The function runs under a default or dedicated service account.
7.  **Networking:** Uses the default VPC network. Firewall rules are added to allow health checks from Google's specified IP ranges.

## Prerequisites

1.  **GCP Account:** You need a Google Cloud Platform account with billing enabled.
2.  **Organization:** Your GCP user account must belong to a GCP Organization.
3.  **Permissions:** The user or service account running Terraform needs sufficient permissions at the **Organization level** to:
    * Create projects (`roles/resourcemanager.projectCreator`).
    * Link projects to a billing account (`roles/billing.user` on the billing account).
    * Manage resources within the created project (or `roles/owner` on the project, though least privilege is recommended).
    * Enable APIs (`roles/serviceusage.serviceUsageAdmin`).
    * Manage IAM policies if modifying them (`roles/resourcemanager.organizationAdmin` or `roles/iam.securityAdmin` might be needed depending on scope).
4.  **Terraform:** Install Terraform (version 1.0 or later). [Download Terraform](https://www.terraform.io/downloads.html)
5.  **Google Cloud SDK (gcloud):** Install and configure the gcloud CLI. [Install gcloud](https://cloud.google.com/sdk/docs/install)
    * Authenticate with GCP: Run `gcloud auth application-default login`. This allows Terraform to use your user credentials. Alternatively, configure a service account key.
6.  **Git:** To clone this repository.

## Setup

1.  **Clone Repository:**
    ```bash
    git clone https://github.com/bfruiz04/SMT-Take-HomeTest.git
    cd smt-gcp-terraform-project
    ```
2.  **Configure Variables:**
    * Navigate to the `terraform/` directory: `cd terraform`
    * Copy the example variables file: `cp terraform.tfvars.example terraform.tfvars`
    * Edit `terraform.tfvars` and replace the placeholder values with your actual GCP `org_id`, `billing_account`, desired `environment` (`dev`, `tst`, or `prd`), and `user_name`. **Do not commit `terraform.tfvars` if it contains sensitive information.**

## Deployment

1.  **Initialize Terraform:**
    * Navigate to the `terraform/` directory if you aren't already there.
    * Run `terraform init`. This downloads the necessary provider plugins.

2.  **Plan Deployment:**
    * Run `terraform plan -var-file="terraform.tfvars"`.
    * Review the plan carefully to see what resources Terraform will create, modify, or destroy.

3.  **Apply Deployment:**
    * Run `terraform apply -var-file="terraform.tfvars" -auto-approve`.
    * The `-auto-approve` flag skips interactive confirmation. Remove it if you want to confirm before applying.
    * This process can take several minutes, especially for project creation and API enablement.
    * Upon successful completion, Terraform will output the Load Balancer IP address and other relevant information.

## Validation

After `terraform apply` completes successfully:

1.  **Get Load Balancer IP:** Note the `load_balancer_ip_address` or `hello_world_url` from the Terraform output.
2.  **Test GET Request (Success):**
    * Open your browser or use `curl` to access the `/helloWorld` path on the Load Balancer's IP:
        ```bash
        curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" http://34.95.105.197/helloWorld
        ```
    * You should receive the response: `Hello World!`

3.  **Test POST Request (Failure):**
    * Use `curl` to send a POST request:
        ```bash
        curl -X POST -H "Authorization: Bearer $(gcloud auth print-identity-token)" -d "" http://34.95.105.197/helloWorld
        ```
    * You should receive a `405 Method Not Allowed` error (or similar, like a generic error page from the LB if the function doesn't handle it explicitly, though our function does). The key is that it should *fail*, not return "Hello World!".

4.  **Test Direct Function Access (Failure):**
    * Find the `cloud_function_uri` in the Terraform output (it might be marked sensitive).
    * Try accessing this URL directly using `curl` or your browser:
        ```bash
        curl -X GET -H "Authorization: Bearer $(gcloud auth print-identity-token)" https://us-central1-smt-the-dev-brayam-ruiz-wr4j.cloudfunctions.net/hello-world-function-dev/helloWorld
        ```
    * You should receive a `403 Forbidden` error because the function's ingress settings block direct public access.

5.  **Check Cloud Armor:** (Optional) You can try simulating a basic attack (e.g., adding `?sql=SELECT%20*%20FROM%20users` to the `/helloWorld` URL) to see if Cloud Armor blocks it with a 403 error. Note that sophisticated WAF testing requires more specific tools and payloads.

## Cleanup

To destroy all the resources created by this Terraform configuration:

1.  **Navigate to the `terraform/` directory.**
2.  **Run the destroy command:**
    ```bash
    terraform destroy -var-file="terraform.tfvars" -auto-approve
    ```
3.  This will delete the Load Balancer, Cloud Function, GCS bucket, potentially the Project (if permissions allow and no liens exist), and other associated resources. Review the plan before confirming if not using `-auto-approve`.

## Design Choices & Considerations

* **Cloud Functions Gen 2:** Chosen for better integration with Cloud Run features, improved networking, and longer request timeouts compared to Gen 1.
* **Serverless NEG:** The standard way to integrate Cloud Functions/Run with the Global External HTTP(S) Load Balancer.
* **Global HTTP Load Balancer:** Provides a single global IP address and integrates well with Cloud Armor and other GCP services. HTTPS could be added with `google_compute_managed_ssl_certificate`.
* **Cloud Armor:** Basic OWASP protection is implemented using preconfigured rules. More specific rules or adaptive protection could be added.
* **Project Creation:** Managed by Terraform for full IaC lifecycle. Requires high-level org permissions.
* **Modularity:** Terraform code is structured into modules (`gcp_project`, `cloud_function`, `load_balancer`, `security_policy`) for better organization and potential reuse.
* **Environments:** Handled via the `environment` input variable, affecting resource names and the project ID. Terraform workspaces could also be used as an alternative way to manage state for different environments.
* **Security:** Focuses on network-level security (LB, Cloud Armor, Function Ingress). Secret Manager wasn't needed for this simple function but would be essential for managing API keys, database passwords, etc.
* **Scalability/HA:** Cloud Functions and the Load Balancer are inherently scalable and managed by Google for high availability. Configuration options (like `max_instance_count`) allow tuning.
* **Monitoring/Logging:** GCP Cloud Logging and Monitoring are automatically integrated to some extent. Custom metrics or detailed dashboards would require additional configuration (e.g., `google_monitoring_dashboard` resources).
