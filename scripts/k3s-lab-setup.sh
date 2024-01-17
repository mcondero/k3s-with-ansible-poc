#!/bin/bash

set -e

function HelmInstall () {
  if command -v helm &>/dev/null; then
    echo " - - - - - - - - - - - - - - - - - - - - - - -"
    echo ""
    echo "Helm is already installed. Skipping... ⏭️"
    echo ""
    echo " - - - - - - - - - - - - - - - - - - - - - - -"
  else
    wget https://get.helm.sh/helm-v3.13.3-linux-amd64.tar.gz
    tar xzvf helm-v3.13.3-linux-amd64.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/
    rm helm-v3.13.3-linux-amd64.tar.gz
    rm -rf linux-amd64/
    echo "Helm installed successfully!"
  fi
}

function K3sInstall () {
  if [ ! -f /usr/local/bin/k3s-uninstall.sh ]; then
    echo " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
    echo ""
    echo "/usr/local/bin/k3s-uninstall.sh not found. Skipping... ⏭️"
    echo ""
    echo " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  else
    /usr/local/bin/k3s-uninstall.sh
  fi
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --write-kubeconfig-mode=644 --disable-network-policy --flannel-backend=none
}

function CiliumAndHubbleHelmInstall () {
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  API_SERVER_IP=127.0.0.1
  API_SERVER_PORT=6443
  helm repo add cilium https://helm.cilium.io/
  helm install cilium cilium/cilium --version 1.14.5 \
    --namespace kube-system \
    --set operator.replicas=1 \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=$API_SERVER_IP \
    --set k8sServicePort=$API_SERVER_PORT \
    --set externalTrafficPolicy=Cluster \
    --set internalTrafficPolicy=Cluster \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true 
}

function CiliumCLIDownload () {
  CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)

  CLI_ARCH=amd64
  if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi

  curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
  sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
  sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
  rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
}

function HubbleCLIInstall () {
  HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
  HUBBLE_ARCH=amd64
  if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
  curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
  sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
  sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
  rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
}

HelmInstall
K3sInstall
CiliumAndHubbleHelmInstall
CiliumCLIDownload
HubbleCLIInstall
