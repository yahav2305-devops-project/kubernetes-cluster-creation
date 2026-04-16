# Kubernetes Cluster Creation

This repository contains the Terraform code necessary to provision nodes from a golden image and automatically configure them to create a fully functioning cluster via a single command.

## Usage Instructions

Run the following steps only during the initial setup:

1. **Authenticate with HashiCorp Cloud Platform (HCP):**

    ```sh
    export TF_TOKEN_app_terraform_io="<token>"
    ```

1. **Download required plugins:**

    ```sh
    terraform init
    ```

Run the following steps for each cluster provisioning:

1. **Format and validate the code:**

    ```sh
    terraform fmt
    terraform validate
    ```

1. **Apply the configuration:** Run the following command to provision the cluster, forcing the replacement of specific nodes and the kubeconfig data:

    ```sh
    terraform apply -auto-approve \
        -replace="terraform_data.fetch_kubeconfig" \
        -replace="proxmox_virtual_environment_vm.node[\"host01\"]" \
        -replace="proxmox_virtual_environment_vm.node[\"host02\"]" \
        -replace="proxmox_virtual_environment_vm.node[\"host03\"]" \
        -replace="proxmox_virtual_environment_vm.node[\"host04\"]" \
        -replace="proxmox_virtual_environment_vm.node[\"host05\"]" \
        -replace="proxmox_virtual_environment_vm.node[\"host06\"]"
    ```
