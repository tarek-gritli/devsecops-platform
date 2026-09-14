output "cluster_name" {
  description = "Name of the k3d cluster"
  value       = var.cluster_name
}

output "servers" {
  description = "Number of servers in the k3d cluster"
  value       = var.servers
}

output "agents" {
  description = "Number of agents in the k3d cluster"
  value       = var.agents
}

output "http_port" {
  description = "Host port mapped to the Traefik loadbalancer's port 80"
  value       = var.http_port
}

output "https_port" {
  description = "Host port mapped to the Traefik loadbalancer's port 443"
  value       = var.https_port
}

output "api_port" {
  description = "Host port for the Kubernetes API server"
  value       = var.api_port
}