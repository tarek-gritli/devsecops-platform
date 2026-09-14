variable "cluster_name" {
  description = "Name of the k3d cluster"
  type        = string
  default     = "devsecops-platform"
}

variable "servers" {
  description = "Number of servers in the k3d cluster"
  type        = number
  default     = 1
}

variable "agents" {
  description = "Number of agents in the k3d cluster"
  type        = number
  default     = 2
}

variable "http_port" {
  description = "Host port mapped to the Traefik loadbalancer's port 80"
  type        = number
  default     = 8080
}

variable "https_port" {
  description = "Host port mapped to the Traefik loadbalancer's port 443"
  type        = number
  default     = 8443
}