variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Hetzner Cloud location"
  type        = string
  default     = "nbg1"
}

variable "server_type" {
  description = "Server type for RKE2 masters"
  type        = string
  default     = "cax21"
}

variable "image" {
  description = "Server image"
  type        = string
  default     = "ubuntu-22.04"
}

variable "network_zone" {
  description = "Network zone"
  type        = string
  default     = "eu-central"
}

variable "ssh_key_name" {
  description = "Name of the SSH key in Hetzner Cloud"
  type        = string
  default     = "my-ssh-key"
}