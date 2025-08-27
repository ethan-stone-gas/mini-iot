# 🚀 Mini IoT GitOps with k3s, Flux, and ECR

This project demonstrates how to run a lightweight Kubernetes cluster (**k3s**) inside a Multipass VM on macOS, deploy an IoT-style app, and manage updates using **Flux GitOps** with container images stored in **Amazon ECR**.

EraserIO: https://app.eraser.io/workspace/HCmY3y8qNW8LyfNCYI9n

---

## 🧰 Tools Overview

Here’s what each tool does in this system:

- **Multipass**

  - Purpose: Creates and manages lightweight Ubuntu VMs on macOS.
  - Why: Simulates an IoT device environment where k3s runs.

- **k3s**

  - Purpose: A lightweight Kubernetes distribution optimized for edge/IoT.
  - Why: Runs inside the VM to orchestrate workloads (pods, services, etc.).

- **kubectl**

  - Purpose: Command-line tool to interact with Kubernetes clusters.
  - Why: Lets you manage the k3s cluster from your Mac using the kubeconfig.

- **kubeconfig**

  - Purpose: A YAML file with cluster connection info (API server address, certs, user).
  - Why: Allows `kubectl` and `flux` on your Mac to talk to the k3s cluster inside the VM.

- **Docker (or Colima)**

  - Purpose: Builds container images locally.
  - Why: Packages your IoT app into an image that can be pushed to ECR and run in k3s.

- **Amazon ECR (Elastic Container Registry)**

  - Purpose: Private container registry service from AWS.
  - Why: Stores your built images (`iot-app:v0.0.1`, `v0.0.2`, etc.) for k3s to pull.

- **Flux**

  - Purpose: GitOps operator for Kubernetes.
  - Why: Watches your GitHub repo and ensures the cluster matches what’s in Git.
  - Components:
    - `source-controller`: pulls manifests from GitHub
    - `kustomize-controller`: applies manifests to the cluster
    - `image-automation-controller` (optional): updates GitHub when new images appear

- **GitHub**

  - Purpose: Stores your Kubernetes manifests (Deployment, Service, etc.).
  - Why: Acts as the **source of truth** for what should run in the cluster.

- **GitHub CLI (`gh`)**

  - Purpose: Authenticates your Mac with GitHub.
  - Why: Allows Flux bootstrap to create/update repos and push manifests.

- **AWS CLI**
  - Purpose: Command-line tool for AWS services.
  - Why: Used to log in to ECR and create Kubernetes secrets for pulling images.

---

## 🖥️ Prerequisites

- macOS with [Homebrew](https://brew.sh/)
- [Multipass](https://multipass.run/) for VM management
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) or [Colima](https://github.com/abiosoft/colima) for local image builds
- [AWS CLI](https://docs.aws.amazon.com/cli/) configured with ECR access
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- [Flux CLI](https://fluxcd.io/docs/installation/) installed:
  ```bash
  brew install fluxcd/tap/flux
  ```
- [GitHub CLI](https://cli.github.com/) (`gh`) authenticated:
  ```bash
  gh auth login
  ```

---

## 🛠️ Setup Steps

### 1. Create a Multipass VM

```bash
multipass launch --name k3s-vm --mem 2G --disk 20G --cpus 2
```

### 2. Install k3s inside the VM

```bash
multipass shell k3s-vm
curl -sfL https://get.k3s.io | sh -
exit
```

### 3. Copy kubeconfig to Mac

```bash
multipass exec k3s-vm -- sudo cat /etc/rancher/k3s/k3s.yaml > kubeconfig.yaml
```

Edit `kubeconfig.yaml` → replace `127.0.0.1` with the VM’s IP (from `multipass info k3s-vm`).

Export it:

```bash
export KUBECONFIG=$PWD/kubeconfig.yaml
kubectl get nodes
```

✅ You should see your k3s node.

---

### 4. Push App Image to ECR

Build and push your app image:

```bash
docker build -t <account-id>.dkr.ecr.<region>.amazonaws.com/iot-app:v0.0.1 .
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/iot-app:v0.0.1
```

---

### 5. Create ECR Pull Secret in k3s

```bash
aws ecr get-login-password --region <region> \
  | kubectl create secret docker-registry ecr-creds \
    --docker-server=<account-id>.dkr.ecr.<region>.amazonaws.com \
    --docker-username=AWS \
    --docker-password-stdin
```

---

### 6. Bootstrap Flux with GitHub

```bash
flux bootstrap github \
  --owner=<your-github-username> \
  --repository=mini-iot \
  --branch=main \
  --path=clusters/my-iot-cluster
```

This creates a GitHub repo and installs Flux controllers into your cluster.

---

### 7. Add App Manifests to GitHub Repo

Inside your repo (`clusters/my-iot-cluster/iot-app/`):

**deployment.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iot-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: iot-app
  template:
    metadata:
      labels:
        app: iot-app
    spec:
      imagePullSecrets:
        - name: ecr-creds
      containers:
        - name: iot-app
          image: <account-id>.dkr.ecr.<region>.amazonaws.com/iot-app:v0.0.1
          ports:
            - containerPort: 8080
```

**service.yaml**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: iot-app
  namespace: default
spec:
  selector:
    app: iot-app
  ports:
    - port: 80
      targetPort: 8080
```

**kustomization.yaml**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: default
resources:
  - deployment.yaml
  - service.yaml
```

Commit & push:

```bash
git add clusters/my-iot-cluster/iot-app
git commit -m "Add iot-app deployment"
git push origin main
```

---

### 8. Reconcile Flux

```bash
flux reconcile kustomization flux-system --with-source
```

Check pods:

```bash
kubectl get pods -n default
```

✅ You should see `iot-app` pods running.

---

## 🔄 Updating the App

1. Build & push a new image:

   ```bash
   docker build -t <account-id>.dkr.ecr.<region>.amazonaws.com/iot-app:v0.0.2 .
   docker push <account-id>.dkr.ecr.<region>.amazonaws.com/iot-app:v0.0.2
   ```

2. Update `deployment.yaml` in GitHub to use `v0.0.2`.

3. Commit & push:

   ```bash
   git commit -am "Update iot-app to v0.0.2"
   git push origin main
   ```

4. Flux syncs automatically (or force it):

   ```bash
   flux reconcile kustomization flux-system --with-source
   ```

5. Verify rollout:
   ```bash
   kubectl rollout status deployment/iot-app -n default
   ```

---

## ✅ Summary

- **Mac**: Dev environment (VS Code, Docker, kubectl, flux CLI).
- **Multipass VM**: Runs k3s cluster + Flux controllers.
- **GitHub**: Source of truth for manifests.
- **ECR**: Stores container images.
- **Flux**: Keeps cluster in sync with GitHub.

Workflow:  
**Code → Build Image → Push to ECR → Update GitHub YAML → Flux Sync → k3s Rollout**
