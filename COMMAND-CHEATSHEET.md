# 🧰 Command Cheatsheet

## 🔹 kubectl (Kubernetes CLI)

### 1. Get cluster resources

```bash
kubectl get pods -n default
```

Lists all pods in the `default` namespace.

---

### 2. Describe a resource

```bash
kubectl describe pod redis-master-0 -n default
```

Shows detailed info about a pod (events, image, env vars, etc.).

---

### 3. View logs

```bash
kubectl logs redis-master-0 -n default
```

Prints logs from the container inside the pod.  
Add `--previous` to see logs from the last crashed container.

---

### 4. Delete resources

```bash
kubectl delete pod redis-replicas-0 -n default
```

Deletes a pod. The controller (Deployment/StatefulSet) will usually recreate it.

---

### 5. Restart workloads

```bash
kubectl rollout restart deployment iot-app -n default
```

Restarts all pods in a Deployment (rolling restart).

---

### 6. Check rollout status

```bash
kubectl rollout status deployment iot-app -n default
```

Waits until a Deployment has finished updating pods.

---

### 7. Apply manifests

```bash
kubectl apply -f k8s/deployment.yaml
```

Applies a manifest file to the cluster. Creates or updates resources.

---

### 8. Port-forward to access a service

```bash
kubectl port-forward svc/iot-app 8080:80 -n default
```

Forwards local port `8080` → service port `80`.  
Lets you test apps locally without exposing them externally.

---

### 9. Check container image of a pod

```bash
kubectl get pod redis-master-0 -n default \
  -o jsonpath='{.spec.containers[*].image}'
```

Prints the image(s) used by a pod.

---

## 🔹 flux (Flux CLI)

### 1. Install Flux into a cluster

```bash
flux install
```

Installs Flux controllers (`source-controller`, `kustomize-controller`, etc.) into the cluster.

---

### 2. Bootstrap Flux with GitHub

```bash
flux bootstrap github \
  --owner=my-username \
  --repository=mini-iot \
  --branch=main \
  --path=clusters/my-iot-cluster
```

Connects Flux to a GitHub repo.  
Creates a `GitRepository` + `Kustomization` in the cluster.  
Ensures the cluster syncs with manifests in that repo.

---

### 3. Force reconciliation

```bash
flux reconcile kustomization flux-system --with-source
```

Forces Flux to immediately pull the latest Git commit and apply manifests.

---

### 4. Check Git sources

```bash
flux get sources git
```

Shows which Git repos Flux is watching and the last commit revision applied.

---

### 5. Check Kustomizations

```bash
flux get kustomizations
```

Shows the status of Kustomizations (groups of manifests).

---

### 6. Check HelmReleases

```bash
flux get helmreleases -n default
```

Shows the status of Helm releases managed by Flux.

---

## 🔹 multipass (VM Management)

### 1. Launch a VM

```bash
multipass launch --name k3s-vm --mem 2G --disk 20G --cpus 2
```

Creates a new Ubuntu VM with given resources.

---

### 2. Shell into a VM

```bash
multipass shell k3s-vm
```

Opens a shell inside the VM.

---

### 3. Get VM info

```bash
multipass info k3s-vm
```

Shows IP address, resources, and status of the VM.

---

### 4. Stop/start a VM

```bash
multipass stop k3s-vm
multipass start k3s-vm
```

Stops or starts the VM (like powering off/on).

---

### 5. Delete and purge a VM

```bash
multipass delete k3s-vm
multipass purge
```

Deletes the VM and frees disk space.

---

## 🔹 aws (AWS CLI for ECR)

### 1. Login to ECR

```bash
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

Logs Docker into your ECR registry.

---

### 2. Create Kubernetes secret for ECR

```bash
aws ecr get-login-password --region us-east-1 \
  | kubectl create secret docker-registry ecr-creds \
    --docker-server=<account-id>.dkr.ecr.us-east-1.amazonaws.com \
    --docker-username=AWS \
    --docker-password-stdin
```

Creates a Kubernetes secret so pods can pull private images from ECR.
