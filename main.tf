terraform {
  cloud {
    organization = "yahav2305"

    workspaces {
      name = "KubeMite"
    }
  }
}

data "external" "bws_secrets" {
  program = ["bash", "./scripts/get_bws_secrets.sh"]
  query = {
    access_token = var.bws_token
    project_id   = var.bws_project_id
  }
}

locals {
  bws_secrets = sensitive(data.external.bws_secrets.result)

  nodes = {
    for hostname, config in var.virtual_machines : hostname => {
      name              = hostname
      ip                = config.ip
      memory_maximum_mb = config.memory_maximum_mb
      memory_minimum_mb = config.memory_minimum_mb
      user_password     = local.bws_secrets["vm-${hostname}-user-password"]
      root_password     = local.bws_secrets["vm-${hostname}-root-password"]
      user_ssh_pubkey   = local.bws_secrets["vm-${hostname}-user-ssh-public-key"]
    }
  }
}

resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  for_each     = local.nodes
  content_type = "snippets"
  datastore_id = var.proxmox_datastore
  node_name    = var.proxmox_node_name

  source_raw {
    data = <<-EOF
    #cloud-config

    manage_etc_hosts: true
    hostname: ${each.value.name}

    users:
      - name: user
        plain_text_passwd: "${each.value.user_password}"
        lock_passwd: false
        ssh_authorized_keys:
          - ${each.value.user_ssh_pubkey}
      - name: root
        plain_text_passwd: "${each.value.root_password}"
        lock_passwd: false
    EOF

    file_name = "user-config-${each.value.name}.yaml"
  }
}

resource "proxmox_virtual_environment_file" "network_data_cloud_config" {
  for_each     = local.nodes
  content_type = "snippets"
  datastore_id = var.proxmox_datastore
  node_name    = var.proxmox_node_name

  source_raw {
    data = <<-EOF
    network:
      version: 1
      config:
        - type: physical
          name: "${var.vm_network_interface}"
          subnets:
            - type: static
              address: ${each.value.ip}/${var.vm_network_netmask}
              gateway: "${var.vm_network_gateway}"
              dns_nameservers:
                - "${var.vm_network_dns}"
              dns_search:
                - "${var.vm_dns_search_domain}"
    EOF

    file_name = "network-config-${each.value.name}.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "node" {
  for_each  = local.nodes
  node_name = var.proxmox_node_name
  name      = each.key
  memory {
    dedicated = tonumber("${each.value.memory_maximum_mb}")
    floating  = tonumber("${each.value.memory_minimum_mb}")
  }

  clone {
    vm_id = 102
    full  = false
  }

  initialization {
    user_data_file_id    = proxmox_virtual_environment_file.user_data_cloud_config[each.value.name].id
    network_data_file_id = proxmox_virtual_environment_file.network_data_cloud_config[each.value.name].id
  }
}
