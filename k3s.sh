#!/bin/sh

# Check if kubectl is installed and install it if necessary
if ! command -v kubectl > /dev/null 2>&1; then
  echo "kubectl is not installed, installing..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/$(uname | tr '[:upper:]' '[:lower:]')/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
  echo "kubectl installed"
fi

# Check if helm is installed and install it if necessary
if ! command -v helm > /dev/null 2>&1; then
  echo "helm is not installed, installing..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  echo "helm installed"
fi

# Install K3s
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_VERSION="v1.24.10+k3s1" sh -s - server

cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

chmod 600 ~/.kube/config

kubectl get nodes
kubectl get pods --all-namespaces
# Install cert-manager
kubectl create namespace cert-manager
helm repo add cert-manager https://charts.jetstack.io
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.11.0/cert-manager.crds.yaml
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.11.0

# Install Rancher
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
kubectl create namespace cattle-system
helm install rancher rancher-latest/rancher --namespace cattle-system --set hostname=rancher.cluster.local --set replicas=1 --set bootstrapPassword=admin

# Verify Rancher deployment
kubectl -n cattle-system rollout status deploy/rancher
