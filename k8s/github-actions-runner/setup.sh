#!/usr/bin/env bash
# GitHub Actions Runner Controller Setup Script for k3s

set -e

echo "🚀 Setting up GitHub Actions Runner Controller on k3s"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please ensure k3s is running."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ helm not found. Installing helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Check if k3s is running
if ! kubectl get nodes &> /dev/null; then
    echo "❌ k3s is not running or kubeconfig is not set"
    echo "Set KUBECONFIG=/etc/rancher/k3s/k3s.yaml"
    exit 1
fi

echo "✅ k3s is running"
kubectl get nodes

# Add Actions Runner Controller Helm repo
echo ""
echo "📦 Adding Actions Runner Controller Helm repository..."
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update

# Create namespace for controller
echo ""
echo "🏗️  Creating actions-runner-system namespace..."
kubectl create namespace actions-runner-system --dry-run=client -o yaml | kubectl apply -f -

# Install Actions Runner Controller
echo ""
echo "⚙️  Installing Actions Runner Controller..."
helm upgrade --install actions-runner-controller \
  actions-runner-controller/actions-runner-controller \
  --namespace actions-runner-system \
  --set syncPeriod=1m \
  --wait

echo ""
echo "✅ Actions Runner Controller installed successfully"

# Create namespace for runners
echo ""
echo "🏗️  Creating github-runners namespace..."
kubectl create namespace github-runners --dry-run=client -o yaml | kubectl apply -f -

# Check if GitHub PAT secret exists
echo ""
if kubectl get secret github-pat -n github-runners &> /dev/null; then
    echo "✅ GitHub PAT secret already exists"
else
    echo "⚠️  GitHub PAT secret not found"
    echo ""
    echo "Please create a GitHub Personal Access Token with the following scopes:"
    echo "  - repo (full control)"
    echo "  - workflow"
    echo "  - admin:org (if using organization)"
    echo ""
    echo "Then run:"
    echo "  kubectl create secret generic github-pat \\"
    echo "    --namespace=github-runners \\"
    echo "    --from-literal=github_token=YOUR_GITHUB_PAT_HERE"
    echo ""
    read -p "Do you want to create the secret now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -sp "Enter your GitHub Personal Access Token: " GITHUB_PAT
        echo ""
        kubectl create secret generic github-pat \
          --namespace=github-runners \
          --from-literal=github_token=$GITHUB_PAT
        echo "✅ GitHub PAT secret created"
    else
        echo "⏭️  Skipping secret creation"
        echo "⚠️  You must create the secret before deploying runners"
        exit 0
    fi
fi

# Deploy runners
echo ""
echo "🏃 Deploying GitHub Actions runners..."
kubectl apply -f runner-deployment.yaml

echo ""
echo "✅ Setup complete!"
echo ""
echo "Check runner status with:"
echo "  kubectl get runners -n github-runners"
echo "  kubectl get pods -n github-runners"
echo ""
echo "View logs with:"
echo "  kubectl logs -n github-runners -l app=github-runner -f"
