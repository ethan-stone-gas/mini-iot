#!/usr/bin/env bash
set -euo pipefail

# === Inputs ===
if [[ $# -lt 1 ]]; then
  echo "❌ Usage: $0 <VM_NAME>"
  exit 1
fi

VM_NAME=$1
VM_MEM="2G"
VM_DISK="20G"
VM_CPUS="2"
REGION="us-east-1"
ACCOUNT_ID="914165346309"
GITHUB_OWNER="ethan-stone-gas"
GITHUB_REPO="mini-iot-gitops"
GITHUB_BRANCH="main"

echo "🚀 Launching Multipass VM: $VM_NAME ..."
multipass launch --name $VM_NAME --memory $VM_MEM --disk $VM_DISK --cpus $VM_CPUS

echo "📥 Installing k3s..."
multipass exec $VM_NAME -- bash -c "curl -sfL https://get.k3s.io | sh -"

echo "📤 Copying kubeconfig to host..."
multipass exec $VM_NAME -- sudo cat /etc/rancher/k3s/k3s.yaml > kubeconfig.yaml
VM_IP=$(multipass info $VM_NAME | grep IPv4 | awk '{print $2}')
sed -i.bak "s/127.0.0.1/$VM_IP/" kubeconfig.yaml
export KUBECONFIG=$PWD/kubeconfig.yaml

echo "✅ Testing cluster..."
kubectl get nodes

echo "🔑 Creating ECR pull secret..."
kubectl create secret docker-registry ecr-creds \
  --docker-server=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com \
  --docker-username=AWS \
  --docker-password="$(aws ecr get-login-password --region $REGION --profile niacin-personal)"

echo "📦 Installing Flux CLI..."
brew install fluxcd/tap/flux || true

echo "🔗 Bootstrapping Flux with GitHub repo..."
# Requires GITHUB_TOKEN env var set
flux bootstrap github \
  --owner=$GITHUB_OWNER \
  --repository=$GITHUB_REPO \
  --branch=$GITHUB_BRANCH \
  --path=clusters/iot-cluster 

echo "✅ Host setup complete. Flux will now deploy your GitOps manifests (iot-app, Fluent Bit, Redis, etc)."