# oba należą do service account
variable "client_id" {} # potrzebujemy do tego nasz subscription ID (na stronie azure mamy info)
variable "client_secret" {}

variable "ssh_public_key" {}

variable "environment" {
  default = "dev"
}

variable "location" {
  default = "westeurope"
}

variable "node_count" {
  default = 2
}



variable "dns_prefix" {
  default = "k8stest"
}

variable "cluster_name" {
  default = "k8stest"
}

variable "resource_group" {
  default = "kubernetes"
}
