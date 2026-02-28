virtual_machines = {
  "host01" = {
    ip                = "172.16.3.11"
    memory_minimum_mb = 1024
    memory_maximum_mb = 2048
    runcmd = [
      # Enable HA
      "systemctl enable --now haproxy",
      "systemctl enable --now keepalived",
      # Wait for balooning ram to initialize
      "while [ $(free -m | awk '/^Mem:/{print $2}') -lt 1700 ]; do echo \"Waiting for RAM to initialize...\"; sleep 2; done",
# Bootstrap cluster
      "/usr/bin/kubeadm init --skip-token-print --skip-certificate-key-print --upload-certs --token $KUBERNETES_TOKEN --certificate-key $KUBERNETES_CERTIFICATE_KEY --control-plane-endpoint 172.16.3.10:8443"
    ]
  }
  "host02" = {
    ip                = "172.16.3.12"
    memory_minimum_mb = 1024
    memory_maximum_mb = 2048
    runcmd = [
      "systemctl enable --now haproxy",
      "systemctl enable --now keepalived",
      "while [ $(free -m | awk '/^Mem:/{print $2}') -lt 1700 ]; do echo \"Waiting for RAM to initialize...\"; sleep 2; done",
      "/usr/bin/kubeadm join --control-plane --discovery-token-unsafe-skip-ca-verification --token $KUBERNETES_TOKEN --certificate-key $KUBERNETES_CERTIFICATE_KEY 172.16.3.10:8443"
    ]
  }
  "host03" = {
    ip                = "172.16.3.13"
    memory_minimum_mb = 1024
    memory_maximum_mb = 2048
    runcmd = [
      "systemctl enable --now haproxy",
      "systemctl enable --now keepalived",
      "while [ $(free -m | awk '/^Mem:/{print $2}') -lt 1700 ]; do echo \"Waiting for RAM to initialize...\"; sleep 2; done",
      "/usr/bin/kubeadm join --control-plane --discovery-token-unsafe-skip-ca-verification --token $KUBERNETES_TOKEN --certificate-key $KUBERNETES_CERTIFICATE_KEY 172.16.3.10:8443"
    ]
  }
  "host04" = {
    ip = "172.16.3.14"
    runcmd = [
      "while [ $(free -m | awk '/^Mem:/{print $2}') -lt 1700 ]; do echo \"Waiting for RAM to initialize...\"; sleep 2; done",
      "/usr/bin/kubeadm join --discovery-token-unsafe-skip-ca-verification --token $KUBERNETES_TOKEN 172.16.3.10:8443"
    ]
  }
  "host05" = {
    ip = "172.16.3.15"
    runcmd = [
      "while [ $(free -m | awk '/^Mem:/{print $2}') -lt 1700 ]; do echo \"Waiting for RAM to initialize...\"; sleep 2; done",
      "/usr/bin/kubeadm join --discovery-token-unsafe-skip-ca-verification --token $KUBERNETES_TOKEN 172.16.3.10:8443"
    ]
  }
}