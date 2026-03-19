virtual_machines = {
  "host01" = {
    ip   = "172.16.3.11"
    vmid = 10001
    runcmd = [
      # Enable HA
      "systemctl enable --now haproxy",
      "systemctl enable --now keepalived",
      # Wait for balooning ram to initialize
      "while [ $(free -m | awk '/^Mem:/{print $2}') -lt 1700 ]; do echo \"Waiting for RAM to initialize...\"; sleep 2; done",
      # Bootstrap cluster
      "/usr/bin/kubeadm init --skip-phases=addon/kube-proxy --skip-token-print --skip-certificate-key-print --upload-certs --token $KUBERNETES_TOKEN --certificate-key $KUBERNETES_CERTIFICATE_KEY --control-plane-endpoint 172.16.3.10:8443",
      # Check that cluster is up
      "export KUBECONFIG=/etc/kubernetes/admin.conf",
      "until kubectl cluster-info > /dev/null 2>&1; do echo -n 'Waiting for API server to respond'; sleep 2; done",
      "echo API Server is up!",
      "inactive_pods=$(kubectl get pods -n kube-system -l tier=control-plane --no-headers | grep -v 'Running' | wc -l)",
      "while [ \"$inactive_pods\" -gt 0 ] || [ -z \"$(kubectl get pods -n kube-system -l tier=control-plane --no-headers)\" ]; do echo \"Waiting for $(kubectl get pods -n kube-system -l tier=control-plane --no-headers | grep -v \"Running\" | wc -l) control-plane component(s)...\"; sleep 3; inactive_pods=\"$(kubectl get pods -n kube-system -l tier=control-plane --no-headers | grep -v \"Running\" | wc -l)\"; done",
      "echo All control-plane pods are up",
      # Install gateway API CRD
      "for item in /etc/kubernetes/thirdparty/gatewayapi/*; do kubectl apply -f \"$item\"; done",
      # Install Prometheus operator (required for cilium)
      "kubectl apply -f /etc/kubernetes/thirdparty/prometheus/prometheus.yaml --server-side=true",
      # Install CNI
      "helm install cilium oci://quay.io/cilium/charts/cilium --version 1.19.1 --namespace kube-system --values /etc/kubernetes/thirdparty/cilium/values.yaml --wait",
      # Install CSI
      "helm install local-path-provisioner oci://ghcr.io/rancher/local-path-provisioner/charts/local-path-provisioner --version 0.0.35 --create-namespace --namespace local-path-provisioner --values /etc/kubernetes/thirdparty/localpath-csi/values.yaml --wait",
      "helm repo add seaweedfs https://seaweedfs.github.io/seaweedfs/helm",
      "helm repo update",
      "kubectl create ns seaweedfs",
      "export SEAWEEDFS_ADMIN_UI_USERNAME_BASE64=$(echo -n \"$SEAWEEDFS_ADMIN_UI_USERNAME\" | base64)",
      "export SEAWEEDFS_ADMIN_UI_PASSWORD_BASE64=$(echo -n \"$SEAWEEDFS_ADMIN_UI_PASSWORD\" | base64)",
      "envsubst < /etc/kubernetes/thirdparty/seaweedfs/admin-ui-credentials.yaml | kubectl apply -f -",
      "export SEAWEEDFS_S3_ADMIN_ACCESS_KEY_ID_BASE64=$(echo -n \"$SEAWEEDFS_S3_ADMIN_ACCESS_KEY_ID\" | base64)",
      "export SEAWEEDFS_S3_ADMIN_SECRET_ACCESS_KEY_BASE64=$(echo -n \"$SEAWEEDFS_S3_ADMIN_SECRET_ACCESS_KEY\" | base64)",
      "export SEAWEEDFS_S3_READ_ACCESS_KEY_ID_BASE64=$(echo -n \"$SEAWEEDFS_S3_READ_ACCESS_KEY_ID\" | base64)",
      "export SEAWEEDFS_S3_READ_SECRET_ACCESS_KEY_BASE64=$(echo -n \"$SEAWEEDFS_S3_READ_SECRET_ACCESS_KEY\" | base64)",
      "export SEAWEEDFS_S3_CONFIG_BASE64=$(jq -cn --arg admin_access_key_id \"$SEAWEEDFS_S3_ADMIN_ACCESS_KEY_ID\" --arg admin_secret_access_key \"$SEAWEEDFS_S3_ADMIN_SECRET_ACCESS_KEY\" --arg read_access_key_id \"$SEAWEEDFS_S3_READ_ACCESS_KEY_ID\" --arg read_secret_access_key \"$SEAWEEDFS_S3_READ_SECRET_ACCESS_KEY\" '{\"identities\":[{\"name\":\"anvAdmin\",\"credentials\":[{\"accessKey\":$admin_access_key_id,\"secretKey\":$admin_secret_access_key}],\"actions\":[\"Admin\",\"Read\",\"Write\"]},{\"name\":\"anvReadOnly\",\"credentials\":[{\"accessKey\":$read_access_key_id,\"secretKey\":$read_secret_access_key}],\"actions\":[\"Read\"]}]}' | base64 -w 0)",
      "envsubst < /etc/kubernetes/thirdparty/seaweedfs/s3-credentials.yaml | kubectl apply -f -",
      "helm install seaweedfs seaweedfs/seaweedfs --version 4.17.0 --namespace seaweedfs --values /etc/kubernetes/thirdparty/seaweedfs/values.yaml --wait",
      "helm install seaweedfs-csi-driver seaweedfs-csi-driver/seaweedfs-csi-driver --version 0.2.11 --namespace seaweedfs --values /etc/kubernetes/thirdparty/seaweedfs-csi-driver/values.yaml --wait"
    ]
  }
  "host02" = {
    ip   = "172.16.3.12"
    vmid = 10002
    runcmd = [
      "systemctl enable --now haproxy",
      "systemctl enable --now keepalived",
      "while [ $(free -m | awk '/^Mem:/{print $2}') -lt 1700 ]; do echo \"Waiting for RAM to initialize...\"; sleep 2; done",
      "/usr/bin/kubeadm join --control-plane --discovery-token-unsafe-skip-ca-verification --token $KUBERNETES_TOKEN --certificate-key $KUBERNETES_CERTIFICATE_KEY 172.16.3.10:8443"
    ]
  }
  "host03" = {
    ip   = "172.16.3.13"
    vmid = 10003
    runcmd = [
      "systemctl enable --now haproxy",
      "systemctl enable --now keepalived",
      "while [ $(free -m | awk '/^Mem:/{print $2}') -lt 1700 ]; do echo \"Waiting for RAM to initialize...\"; sleep 2; done",
      "/usr/bin/kubeadm join --control-plane --discovery-token-unsafe-skip-ca-verification --token $KUBERNETES_TOKEN --certificate-key $KUBERNETES_CERTIFICATE_KEY 172.16.3.10:8443"
    ]
  }
  "host04" = {
    ip   = "172.16.3.14"
    vmid = 10004
    runcmd = [
      "systemctl disable --now haproxy",
      "systemctl disable --now keepalived",
      "while [ $(free -m | awk '/^Mem:/{print $2}') -lt 1700 ]; do echo \"Waiting for RAM to initialize...\"; sleep 2; done",
      "/usr/bin/kubeadm join --discovery-token-unsafe-skip-ca-verification --token $KUBERNETES_TOKEN 172.16.3.10:8443"
    ]
  }
  "host05" = {
    ip   = "172.16.3.15"
    vmid = 10005
    runcmd = [
      "systemctl disable --now haproxy",
      "systemctl disable --now keepalived",
      "while [ $(free -m | awk '/^Mem:/{print $2}') -lt 1700 ]; do echo \"Waiting for RAM to initialize...\"; sleep 2; done",
      "/usr/bin/kubeadm join --discovery-token-unsafe-skip-ca-verification --token $KUBERNETES_TOKEN 172.16.3.10:8443"
    ]
  }
  "host06" = {
    ip   = "172.16.3.16"
    vmid = 10006
    runcmd = [
      "systemctl disable --now haproxy",
      "systemctl disable --now keepalived",
      "while [ $(free -m | awk '/^Mem:/{print $2}') -lt 1700 ]; do echo \"Waiting for RAM to initialize...\"; sleep 2; done",
      "/usr/bin/kubeadm join --discovery-token-unsafe-skip-ca-verification --token $KUBERNETES_TOKEN 172.16.3.10:8443"
    ]
  }
}