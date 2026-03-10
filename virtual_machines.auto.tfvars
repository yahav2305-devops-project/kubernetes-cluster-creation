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
      "bash -c \"kubectl label nodes host0{1..6} topology.kubernetes.io/region=MyCluster\"",
      "bash -c \"kubectl label nodes host0{1..6} topology.kubernetes.io/zone=pve\"",
      "kubectl create ns csi",
      "kubectl label ns csi pod-security.kubernetes.io/enforce=privileged",
      "bash -c \"kubectl --namespace csi create secret generic proxmox-csi-plugin --from-file=config.yaml=<(envsubst < /etc/kubernetes/thirdparty/proxmox-csi-plugin/config.yaml)\"",
      "helm install csi-proxmox oci://ghcr.io/sergelogvinov/charts/proxmox-csi-plugin --version 0.5.5 --namespace csi --values /etc/kubernetes/thirdparty/proxmox-csi-plugin/values.yaml --wait",
      "kubectl annotate storageclass proxmox storageclass.kubernetes.io/is-default-class=true --overwrite"
      # TODO: Then setup a teardown script to delete the namespaces before deleting the VMs, otherwise the proxmox virtual disks will stay
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