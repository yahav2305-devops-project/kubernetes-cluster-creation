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

  env_vars = {
    "KUBERNETES_TOKEN"           = local.bws_secrets["kubernetes-token"]
    "KUBERNETES_CERTIFICATE_KEY" = local.bws_secrets["kubernetes-certificate-key"]
    "CSI_PROXMOX_TOKEN_ID"       = local.bws_secrets["proxmox-csi-api-token-id"]
    "CSI_PROXMOX_TOKEN_SECRET"   = local.bws_secrets["proxmox-csi-api-token-secret"]
  }

  nodes = {
    for hostname, config in var.virtual_machines : hostname => {
      name              = hostname
      ip                = config.ip
      vmid              = config.vmid
      memory_maximum_mb = config.memory_maximum_mb
      memory_minimum_mb = config.memory_minimum_mb
      user_password     = local.bws_secrets["vm-${hostname}-user-password"]
      root_password     = local.bws_secrets["vm-${hostname}-root-password"]
      user_ssh_pubkey   = local.bws_secrets["vm-${hostname}-user-ssh-public-key"]
      runcmd            = config.runcmd
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

    runcmd:
      %{for key, value in local.env_vars}
      - export ${key}=${jsonencode(value)}
      %{endfor}
      %{for command in each.value.runcmd}
      - ${command}
      %{endfor}
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
  vm_id     = each.value.vmid

  smbios {
    serial = "h=pve;i=${each.value.vmid}"
  }

  memory {
    dedicated = tonumber("${each.value.memory_maximum_mb}")
    floating  = tonumber("${each.value.memory_minimum_mb}")
  }

  clone {
    vm_id = 103
    full  = false
  }

  initialization {
    user_data_file_id    = proxmox_virtual_environment_file.user_data_cloud_config[each.value.name].id
    network_data_file_id = proxmox_virtual_environment_file.network_data_cloud_config[each.value.name].id
  }
}

resource "null_resource" "k8s_cleanup" {
  triggers = {
    private_key = sensitive(local.bws_secrets["vm-host01-user-ssh-private-key"])
    host        = var.virtual_machines["host01"].ip
    password    = sensitive(local.bws_secrets["vm-host01-user-password"])
  }

  depends_on = [
    proxmox_virtual_environment_vm.node
  ]

  provisioner "remote-exec" {
    when = destroy

    connection {
      type        = "ssh"
      user        = "user"
      private_key = self.triggers.private_key
      host        = self.triggers.host
      script_path = "/home/user/terraform_%RAND%.sh"
    }

    inline = [
      "chmod +x /home/user/cleanup.sh",
      "echo '${self.triggers.password}' | sudo -S /home/user/cleanup.sh",
    ]
  }
}
