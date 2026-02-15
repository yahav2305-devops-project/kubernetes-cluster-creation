variable "bws_token" {
  type        = string
  sensitive   = true
  description = "API token for bitwarden secret manager authentication"
}

variable "bws_project_id" {
  type        = string
  sensitive   = true
  description = "UUID of the bitwarden secret manager project to list secrets from"
}

variable "proxmox_ssh_username" {
  type        = string
  description = "SSH user for Proxmox access, e.g. root"
  sensitive   = false
  default     = "root"
}

variable "proxmox_datastore" {
  type        = string
  description = "proxmox datastore name for the created resources"
  sensitive   = false
  default     = "local"
}

variable "proxmox_node_name" {
  type        = string
  description = "Name of the Proxmox node on which the resources will be created"
  default     = "pve"
}

variable "virtual_machines" {
  description = "Map of virtual machines to create. The key is the hostname. Passwords and SSH keys are fetched from Bitwarden."
  type = map(object({
    ip                = string
    memory_maximum_mb = optional(number, 4096)
    memory_minimum_mb = optional(number, 2048)
  }))
}

variable "vm_network_interface" {
  type        = string
  description = "Name of the VM interface on which network settings will apply, e.g. eth0"
  sensitive   = false
  default     = "ens18"
}

variable "vm_network_netmask" {
  type        = number
  description = "Netmask of the VM network, e.g. 16, 24"
  sensitive   = false
  default     = 24
}

variable "vm_network_gateway" {
  type        = string
  description = "Gateway of the VM network, e.g. 192.168.1.1"
  sensitive   = false
  default     = "172.16.3.1"
}

variable "vm_network_dns" {
  type        = string
  description = "DNS address of the VM network, e.g. 10.0.0.1"
  sensitive   = false
  default     = "172.16.3.1"
}

variable "vm_dns_search_domain" {
  type        = string
  description = "Search domain of the VM network, e.g. mynetwork.internal"
  sensitive   = false
  default     = "network.internal"
}
