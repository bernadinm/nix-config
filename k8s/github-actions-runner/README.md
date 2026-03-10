# GitHub Actions Runner on k3s

This directory contains Kubernetes manifests to deploy GitHub Actions self-hosted runners using Actions Runner Controller (ARC).

## Setup Instructions

### 1. Install Actions Runner Controller

```bash
# Add Helm repo
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update

# Create namespace
kubectl create namespace actions-runner-system

# Install the controller
helm install actions-runner-controller \
  actions-runner-controller/actions-runner-controller \
  --namespace actions-runner-system \
  --set syncPeriod=1m
```

### 2. Create GitHub Personal Access Token (PAT)

Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)

Required scopes:
- `repo` (full control)
- `workflow`
- `admin:org` (if using organization)

### 3. Create Kubernetes Secret with PAT

```bash
kubectl create namespace github-runners

kubectl create secret generic github-pat \
  --namespace=github-runners \
  --from-literal=github_token=YOUR_GITHUB_PAT_HERE
```

### 4. Deploy Runner

```bash
# Apply the runner deployment
kubectl apply -f runner-deployment.yaml

# Check status
kubectl get runners -n github-runners
kubectl get pods -n github-runners
```

## Scaling

The HorizontalRunnerAutoscaler will automatically scale runners based on queued jobs:
- Minimum: 1 runner
- Maximum: 5 runners
- Scales up when jobs are queued
- Scales down when idle

## Monitoring

```bash
# Watch runner pods
kubectl get pods -n github-runners -w

# View logs
kubectl logs -n github-runners -l app=github-runner -f

# Check runner status
kubectl describe runner -n github-runners
```

## Updating

To update the runner image or configuration:

```bash
# Edit runner-deployment.yaml
# Then apply changes
kubectl apply -f runner-deployment.yaml

# Or delete and recreate
kubectl delete -f runner-deployment.yaml
kubectl apply -f runner-deployment.yaml
```
