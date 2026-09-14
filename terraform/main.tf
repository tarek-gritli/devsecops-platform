resource "terraform_data" "k3d_cluster" {
  input = var.cluster_name

  triggers_replace = {
    cluster_name = var.cluster_name
    servers      = var.servers
    agents       = var.agents
    api_port     = var.api_port
    http_port    = var.http_port
    https_port   = var.https_port
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-cluster.sh ${var.cluster_name} ${var.servers} ${var.agents} ${var.api_port} ${var.http_port} ${var.https_port}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/delete-cluster.sh ${self.input}"
  }
}