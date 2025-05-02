# modules/load_balancer/outputs.tf

output "lb_ip_address" {
  description = "The static external IP address assigned to the Load Balancer."
  value       = google_compute_global_address.lb_ip.address
}

output "backend_service_name" {
  description = "The name of the Load Balancer Backend Service."
  value       = google_compute_backend_service.function_backend.name
}

output "url_map_name" {
  description = "The name of the Load Balancer URL Map."
  value       = google_compute_url_map.lb_url_map.name
}

output "neg_name" {
  description = "The name of the Serverless Network Endpoint Group."
  value       = google_compute_region_network_endpoint_group.serverless_neg.name
}