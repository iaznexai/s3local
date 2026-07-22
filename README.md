# s3local

A lightweight SSH/Rsync archive server for Kubernetes (K3S), backed by persistent storage.

`s3local` provides a simple, secure file archive service using OpenSSH and `rsync`, making it ideal for backups, large file transfers, AI/ML datasets, media archives, and other long-term storage workloads.

---

# Features

- Lightweight OpenSSH server
- rsync support
- Public key authentication only
- Persistent storage using Kubernetes PVCs
- Compatible with K3S and standard Kubernetes
- Supports **amd64** and **arm64**
- Docker Hub image deployment
- Easy key rotation
- Simple disaster recovery
- Environment-based configuration

---

# Architecture

```text
                    +----------------------+
                    |    Client Machines   |
                    |----------------------|
                    | Machine 1            |
                    | Machine 2            |
                    | Machine N            |
                    +----------+-----------+
                               |
                          SSH / rsync
                               |
                               |
                    +----------v-----------+
                    |     Kubernetes       |
                    |----------------------|
                    | Deployment           |
                    | OpenSSH + rsync      |
                    | LoadBalancer Service |
                    +----------+-----------+
                               |
                               |
                               v
                     Persistent Volume
                          (/archive)
```

---

# Repository Layout

```text
.
├── .env
├── .env.example
├── .gitignore
├── Dockerfile
├── README.md
├── deploy.sh
├── namespace.yaml
├── deployment.yaml
├── service.yaml
├── secret-example.yaml
└── ssh/
    ├── authorized_keys
    └── README.md
```

---

# Prerequisites

The Kubernetes cluster should provide:

- Kubernetes or K3S
- A Persistent Volume provisioner (for example Longhorn)
- A LoadBalancer implementation (MetalLB, kube-vip, cloud provider, etc.)
- kubectl
- Docker (or Podman)

Verify your cluster:

```bash
kubectl get nodes
kubectl get storageclass
kubectl get pvc
```

---

# Docker Image

The image is based on the LinuxServer OpenSSH image with `rsync` installed.

```dockerfile
FROM lscr.io/linuxserver/openssh-server:latest

RUN apk add --no-cache rsync
```

---

# Supported Architectures

This project works on:

- amd64
- arm64

Verify your build:

```bash
docker image inspect openssh-rsync:1.0 \
    --format '{{.Os}}/{{.Architecture}}'
```

Example output:

```text
linux/amd64
```

or

```text
linux/arm64
```

---

# Build the Image

```bash
docker build \
    -t openssh-rsync:1.0 .
```

---

# Publish to Docker Hub

Login:

```bash
docker login
```

Tag:

```bash
docker tag openssh-rsync:1.0 \
    YOUR_DOCKERHUB_USERNAME/openssh-rsync:1.0
```

Push:

```bash
docker push \
    YOUR_DOCKERHUB_USERNAME/openssh-rsync:1.0
```

Update the `.env` file with your Docker Hub username and image tag.

---

# Configuration

All deployment-specific settings are stored in `.env`.

Example:

```text
NAMESPACE=s3local

DOCKERHUB_USER=YOUR_DOCKERHUB_USERNAME
IMAGE_NAME=openssh-rsync
IMAGE_TAG=1.0

LOADBALANCER_IP=192.168.100.10

SERVICE_PORT=2222
CONTAINER_PORT=2222

ARCHIVE_USER=archive

ARCHIVE_PVC=archive-storage

AUTHORIZED_KEYS_SECRET=sftp-authorized-key

TIMEZONE=UTC

REPLICAS=1
```

Adjust these values to match your environment.

---

# Persistent Storage

The deployment expects an existing PersistentVolumeClaim.

Example:

```text
Name: archive-storage
AccessMode: ReadWriteOnce
```

The project intentionally does **not** create the PVC automatically to avoid accidental data loss.

---

# SSH Key Management

Each client machine must generate its own SSH key pair.

Generate a key:

```bash
ssh-keygen \
    -t ed25519 \
    -a 100 \
    -f ~/.ssh/k3s-archive
```

This creates:

```text
~/.ssh/k3s-archive
~/.ssh/k3s-archive.pub
```

Never distribute or commit the private key.

---

# Multiple Client Machines

Every machine should have its own key pair.

Example:

```text
Machine 1
Machine 2
Machine 3
Machine N
```

Collect the **public** keys into:

```text
ssh/authorized_keys
```

Example:

```text
ssh-ed25519 AAAA.... machine-1
ssh-ed25519 AAAA.... machine-2
ssh-ed25519 AAAA.... machine-3
```

---

# Create / Update Kubernetes Secret

```bash
kubectl create secret generic sftp-authorized-key \
    --namespace s3local \
    --from-file=id_ed25519.pub=ssh/authorized_keys \
    --dry-run=client -o yaml | kubectl apply -f -
```

Restart the deployment:

```bash
kubectl rollout restart deployment/rsync-target \
    -n s3local
```

---

# Deploy

Deploy using the helper script:

```bash
./deploy.sh
```

Equivalent commands:

```bash
envsubst < namespace.yaml | kubectl apply -f -

envsubst < deployment.yaml | kubectl apply -f -

envsubst < service.yaml | kubectl apply -f -
```

---

# Verify Deployment

```bash
kubectl get deployment
```

```bash
kubectl get pods
```

```bash
kubectl get svc
```

```bash
kubectl get pvc
```

View logs:

```bash
kubectl logs deployment/rsync-target
```

---

# SSH Client Configuration

Create or update:

```text
~/.ssh/config
```

Example:

```text
Host archive-server
    HostName <LOADBALANCER_IP>
    User archive
    Port 2222
    IdentityFile ~/.ssh/k3s-archive
    IdentitiesOnly yes
```

Connect:

```bash
ssh archive-server
```

---

# Test SSH Connectivity

```bash
ssh archive-server
```

If the connection succeeds, the SSH configuration is working correctly.

---

# Test File Transfer

Create a test file:

```bash
echo "Hello World" > test.txt
```

Transfer it:

```bash
rsync -av \
    test.txt \
    archive-server:/archive/
```

Verify:

```bash
ssh archive-server

ls -l /archive
```

---

# Recommended rsync Options

For large files:

```bash
rsync \
    -av \
    --partial \
    --append-verify \
    --progress \
    large-file.iso \
    archive-server:/archive/
```

Benefits:

- Resume interrupted transfers
- Verify resumed data
- Preserve partial files
- Efficient handling of large files

---

# Adding Another Client Machine

1. Generate a new SSH key.

```bash
ssh-keygen \
    -t ed25519 \
    -a 100 \
    -f ~/.ssh/k3s-archive
```

2. Append the public key to:

```text
ssh/authorized_keys
```

3. Update the Kubernetes Secret.

```bash
kubectl create secret generic sftp-authorized-key \
    --namespace s3local \
    --from-file=id_ed25519.pub=ssh/authorized_keys \
    --dry-run=client -o yaml | kubectl apply -f -
```

4. Restart the deployment.

```bash
kubectl rollout restart deployment/rsync-target
```

No Docker image rebuild is required.

---

# Rotating SSH Keys

When replacing or revoking keys:

1. Generate a new key pair.
2. Remove obsolete public keys from `ssh/authorized_keys`.
3. Add the new public keys.
4. Update the Kubernetes Secret.
5. Restart the Deployment.
6. Remove stale server entries from client `known_hosts` if the server host key has changed.

---

# Recovery Procedure

If the deployment is removed accidentally:

1. Verify the PVC still exists.

```bash
kubectl get pvc
```

2. Verify the Kubernetes Secret.

```bash
kubectl get secret
```

3. Rebuild or pull the Docker image.

4. Deploy the manifests.

```bash
./deploy.sh
```

5. Verify SSH connectivity.

6. Verify rsync transfers.

As long as the PVC is preserved, archived data remains intact.

---

# Troubleshooting

### Permission denied (publickey)

- Verify the correct private key is configured.
- Check `~/.ssh/config`.
- Confirm the Kubernetes Secret contains the expected public keys.
- Restart the Deployment after updating the Secret.

---

### Host identification has changed

Remove the stale server key:

```bash
ssh-keygen -R "[<LOADBALANCER_IP>]:2222"
```

Reconnect and verify the new fingerprint.

---

### Pod will not start

Inspect logs:

```bash
kubectl logs deployment/rsync-target
```

Describe the pod:

```bash
kubectl describe pod <pod-name>
```

---

### Verify mounted public keys

```bash
kubectl exec deployment/rsync-target -- \
cat /config/id_ed25519.pub
```

---

# Future Improvements

Potential enhancements include:

- Persistent `/config` volume to preserve SSH host keys
- Multi-architecture image publishing
- GitHub Actions CI/CD
- Health and readiness probes
- NetworkPolicies
- Automated backups
- Scheduled Longhorn snapshots
- Prometheus metrics

---

# License

Licensed under the **Apache License 2.0**.

See the `LICENSE` file for details.
