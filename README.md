# kubernetes-node-creation
Code to create nodes from a golden image and configure each one in order to create a cluster with from a single command

## How to run
Run only on initial setup:
- Connect to HCP:
    ```sh
    export TF_TOKEN_app_terraform_io="<token>"
    ```
- Download plugins:
    ```sh
    terraform init
    ```
Validate the code:
```sh
terraform fmt
terraform validate
```
Run the code:
```sh
terraform apply
```