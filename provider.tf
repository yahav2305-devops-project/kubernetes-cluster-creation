terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "2.3.5"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.94.0"
    }
  }

  required_version = "~> 1.14.5"
}

provider "proxmox" {
  # Configuration options
  endpoint      = local.bws_secrets["proxmox-api-endpoint"]
  api_token     = "${local.bws_secrets["proxmox-root-api-token-id"]}=${local.bws_secrets["proxmox-root-api-token-secret"]}"
  insecure      = true
  random_vm_ids = true

  ssh {
    username    = var.proxmox_ssh_username
    private_key = local.bws_secrets["proxmox-root-ssh-private-key"]
  }
}
