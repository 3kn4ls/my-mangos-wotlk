# MaNGOS WotLK - Kubernetes (K3s) Deployment Guide

Complete guide for deploying MaNGOS WotLK on Kubernetes, optimized for K3s clusters.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [K3s Setup](#k3s-setup)
- [Architecture](#architecture)
- [Deployment](#deployment)
- [Configuration](#configuration)
- [Scaling](#scaling)
- [Storage](#storage)
- [Networking](#networking)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Production Considerations](#production-considerations)

## Overview

Kubernetes deployment provides:

- **High Availability**: Automatic pod restart and health monitoring
- **Scalability**: Horizontal and vertical scaling
- **Resource Management**: CPU/memory limits and requests
- **Rolling Updates**: Zero-downtime deployments
- **Storage Orchestration**: Persistent volume management
- **Load Balancing**: Built-in service load balancing

### Why K3s?

**K3s** is a lightweight Kubernetes distribution perfect for:
- Edge computing
- IoT devices
- ARM devices (Raspberry Pi)
- Development environments
- Resource-constrained environments

**K3s Benefits**:
- Single binary (~70 MB)
- Low memory footprint (~512 MB)
- Built-in load balancer (ServiceLB)
- Built-in storage provider (local-path)
- Production-ready

## Prerequisites

### Hardware Requirements

**Minimum**:
- 2 CPU cores
- 4 GB RAM
- 20 GB disk space

**Recommended**:
- 4+ CPU cores
- 8 GB RAM
- 50 GB SSD

**For ARM (Raspberry Pi 5)**:
- 8 GB RAM model recommended
- Fast MicroSD (UHS-I) or USB SSD
- Active cooling

### Software Requirements

- **K3s**: v1.27+ ([Install Guide](https://docs.k3s.io/quick-start))
- **kubectl**: v1.27+
- **Docker** (for image building)
- **Optional**: Helm 3.x

### Supported Platforms

- Linux AMD64
- Linux ARM64 (Raspberry Pi, ARM servers)
- macOS (via K3d or Rancher Desktop)
- Windows WSL2 (via K3d or Rancher Desktop)

## K3s Setup

### Install K3s (Single Node)

**Linux**:

```bash
# Install K3s
curl -sfL https://get.k3s.io | sh -

# Check installation
sudo k3s kubectl get nodes

# Setup kubectl for non-root user
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER ~/.kube/config
chmod 600 ~/.kube/config

# Verify
kubectl cluster-info
kubectl get nodes
```

**Raspberry Pi** (ARM64):

```bash
# Install K3s on ARM64
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -

# Disable Traefik if not needed
# --disable=traefik frees ~100 MB RAM

# Verify
sudo k3s kubectl get nodes
```

### Install K3s (Multi-Node Cluster)

**Master Node**:

```bash
# Install with token
curl -sfL https://get.k3s.io | sh -s - server \
  --token=my-secret-token \
  --write-kubeconfig-mode=644

# Get node token
sudo cat /var/lib/rancher/k3s/server/node-token
```

**Worker Nodes**:

```bash
# Join cluster
curl -sfL https://get.k3s.io | K3S_URL=https://master-ip:6443 \
  K3S_TOKEN=<node-token> sh -

# Verify nodes
kubectl get nodes
```

### Configure kubectl

```bash
# K3s kubeconfig location
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Or copy to standard location
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER ~/.kube/config
```

## Architecture

### Kubernetes Resources

```
Namespace: mangos
├── ConfigMaps
│   ├── mangos-config (env variables)
│   ├── realmd-config (realmd.conf)
│   ├── mangosd-config (mangosd.conf, ahbot.conf, playerbot.conf)
│   └── mysql-init-scripts (DB initialization)
│
├── Secrets
│   └── mangos-secrets (credentials)
│
├── PersistentVolumeClaims
│   ├── mysql-data-pvc (10 Gi)
│   ├── realmd-logs-pvc (1 Gi)
│   ├── mangosd-logs-pvc (5 Gi)
│   ├── game-data-dbc-pvc (500 Mi)
│   ├── game-data-maps-pvc (5 Gi)
│   ├── game-data-mmaps-pvc (10 Gi)
│   └── game-data-vmaps-pvc (5 Gi)
│
├── StatefulSet
│   └── mysql (1 replica)
│
├── Deployments
│   ├── realmd (1 replica)
│   └── mangosd (1 replica)
│
└── Services
    ├── mysql-service (ClusterIP)
    ├── realmd-service (LoadBalancer)
    └── mangosd-service (LoadBalancer)
```

### Pod Architecture

```
┌─────────────────────────────────────────────────────┐
│              K3s Node                                │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ Namespace: mangos                              │ │
│  │                                                │ │
│  │  ┌──────────────┐  ┌──────────────────────┐   │ │
│  │  │ mysql-0      │  │ realmd-xxx           │   │ │
│  │  │ StatefulSet  │  │ Deployment           │   │ │
│  │  │              │  │                      │   │ │
│  │  │ Init:        │  │ Init:                │   │ │
│  │  │  - Create DBs│  │  - Wait for MySQL    │   │ │
│  │  │              │  │                      │   │ │
│  │  │ Container:   │  │ Container:           │   │ │
│  │  │  - MySQL 8.0 │  │  - realmd            │   │ │
│  │  │  - Port 3306 │  │  - Port 3724         │   │ │
│  │  │              │  │                      │   │ │
│  │  │ Probes:      │  │ Probes:              │   │ │
│  │  │  - Liveness  │  │  - Liveness (TCP)    │   │ │
│  │  │  - Readiness │  │  - Readiness (TCP)   │   │ │
│  │  └──────────────┘  └──────────────────────┘   │ │
│  │                                                │ │
│  │  ┌──────────────────────────────────────────┐ │ │
│  │  │ mangosd-xxx                              │ │ │
│  │  │ Deployment                               │ │ │
│  │  │                                          │ │ │
│  │  │ Init:                                    │ │ │
│  │  │  - Wait for MySQL                        │ │ │
│  │  │  - Wait for Realmd                       │ │ │
│  │  │                                          │ │ │
│  │  │ Container:                               │ │ │
│  │  │  - mangosd                               │ │ │
│  │  │  - Port 8085 (game)                      │ │ │
│  │  │  - Port 7878 (SOAP)                      │ │ │
│  │  │                                          │ │ │
│  │  │ Volumes:                                 │ │ │
│  │  │  - game-data-{dbc,maps,mmaps,vmaps}     │ │ │
│  │  │  - logs                                  │ │ │
│  │  │  - configs                               │ │ │
│  │  │                                          │ │ │
│  │  │ Probes:                                  │ │ │
│  │  │  - Liveness (TCP:8085)                   │ │ │
│  │  │  - Readiness (TCP:8085)                  │ │ │
│  │  └──────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## Deployment

### Quick Deployment

```bash
# Navigate to k8s directory
cd k8s

# Deploy using script
./deploy-k3s.sh deploy

# This will:
# 1. Create namespace
# 2. Apply secrets
# 3. Apply configmaps
# 4. Create PVCs
# 5. Deploy MySQL StatefulSet
# 6. Deploy Realmd
# 7. Deploy Mangosd
```

### Manual Deployment

```bash
# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Create secrets (edit first!)
kubectl apply -f secrets.yaml

# 3. Create configmaps
kubectl apply -f configmap.yaml

# 4. Create PVCs
kubectl apply -f persistentvolumes.yaml

# 5. Deploy MySQL
kubectl apply -f mysql-statefulset.yaml

# Wait for MySQL to be ready
kubectl wait --for=condition=ready pod -l app=mysql -n mangos --timeout=300s

# 6. Deploy Realmd
kubectl apply -f realmd-deployment.yaml

# Wait for Realmd
kubectl wait --for=condition=available deployment/realmd -n mangos --timeout=120s

# 7. Deploy Mangosd
kubectl apply -f mangosd-deployment.yaml

# Wait for Mangosd
kubectl wait --for=condition=available deployment/mangosd -n mangos --timeout=180s

# 8. Check status
kubectl get all -n mangos
```

### Using Kustomize

```bash
# Build and preview
kubectl kustomize k8s/

# Apply with kustomize
kubectl apply -k k8s/

# Delete with kustomize
kubectl delete -k k8s/
```

## Configuration

### Secrets Management

**Edit secrets before deployment**:

```bash
# Edit secrets.yaml
vim k8s/secrets.yaml
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mangos-secrets
  namespace: mangos
type: Opaque
stringData:
  mysql-root-password: "YOUR_SECURE_PASSWORD_HERE"
  mysql-user: "mangos"
  mysql-password: "YOUR_MANGOS_PASSWORD_HERE"
  realmd-db: "realmd"
  world-db: "mangos"
  character-db: "characters"
```

**Create secrets from files** (recommended for production):

```bash
# Create password files
echo -n "my-secure-password" > mysql-root-password.txt
echo -n "mangos-password" > mysql-password.txt

# Create secret from files
kubectl create secret generic mangos-secrets \
  --from-file=mysql-root-password=mysql-root-password.txt \
  --from-file=mysql-password=mysql-password.txt \
  --from-literal=mysql-user=mangos \
  --from-literal=realmd-db=realmd \
  --from-literal=world-db=mangos \
  --from-literal=character-db=characters \
  -n mangos

# Clean up password files
rm mysql-root-password.txt mysql-password.txt
```

### ConfigMaps

**Update server configuration**:

```bash
# Edit configmap
kubectl edit configmap mangosd-config -n mangos

# Or edit file and reapply
vim k8s/configmap.yaml
kubectl apply -f k8s/configmap.yaml

# Restart pods to pick up changes
kubectl rollout restart deployment/mangosd -n mangos
```

**Update via script**:

```bash
# Update specific value
kubectl patch configmap mangos-config -n mangos \
  --type merge \
  -p '{"data":{"REALM_ID":"2"}}'
```

### Resource Limits

**Adjust CPU/Memory**:

```yaml
# mangosd-deployment.yaml
spec:
  template:
    spec:
      containers:
      - name: mangosd
        resources:
          requests:
            memory: "2Gi"      # Guaranteed memory
            cpu: "1000m"       # 1 CPU core
          limits:
            memory: "8Gi"      # Max memory
            cpu: "4000m"       # Max 4 CPU cores
```

**Apply changes**:

```bash
kubectl apply -f k8s/mangosd-deployment.yaml
```

## Scaling

### Vertical Scaling (More Resources)

**Increase pod resources**:

```bash
# Edit deployment
kubectl edit deployment mangosd -n mangos

# Update resources section
# Then save and exit

# Or use kubectl set
kubectl set resources deployment mangosd -n mangos \
  --limits=cpu=4,memory=8Gi \
  --requests=cpu=2,memory=4Gi
```

### Horizontal Scaling (More Replicas)

**Note**: Mangosd and Realmd typically run as single instances.
Only scale if you have a custom setup with load balancing.

```bash
# Scale deployment
kubectl scale deployment mangosd -n mangos --replicas=2

# Using script
./deploy-k3s.sh scale mangosd 2

# Autoscaling (advanced)
kubectl autoscale deployment mangosd -n mangos \
  --min=1 --max=3 \
  --cpu-percent=80
```

### Node Scaling (Cluster Expansion)

**Add worker node**:

```bash
# On worker node
curl -sfL https://get.k3s.io | K3S_URL=https://master-ip:6443 \
  K3S_TOKEN=<token> sh -

# Verify
kubectl get nodes
```

**Assign pods to specific nodes**:

```yaml
spec:
  template:
    spec:
      nodeSelector:
        kubernetes.io/hostname: rpi5-node1
```

## Storage

### Storage Classes

K3s includes `local-path` storage class by default:

```bash
# List storage classes
kubectl get storageclass

# NAME         PROVISIONER
# local-path   rancher.io/local-path
```

### Persistent Volumes

**List PVCs**:

```bash
kubectl get pvc -n mangos

# Expected output:
# NAME                  STATUS   VOLUME              CAPACITY
# mysql-data-pvc        Bound    pvc-xxxxx           10Gi
# mangosd-logs-pvc      Bound    pvc-xxxxx           5Gi
# game-data-maps-pvc    Bound    pvc-xxxxx           5Gi
```

**PVC Details**:

```bash
kubectl describe pvc mysql-data-pvc -n mangos
```

### Backup Volumes

**Using kubectl cp**:

```bash
# Create backup pod
kubectl run backup -n mangos --image=busybox --command -- sleep 3600

# Mount volume to backup pod
kubectl set volumes pod/backup -n mangos \
  --add --name=data --type=pvc --claim-name=mysql-data-pvc \
  --mount-path=/data

# Copy data out
kubectl cp mangos/backup:/data ./backups/mysql-data

# Cleanup
kubectl delete pod backup -n mangos
```

**Using dedicated backup job**:

```yaml
# backup-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: backup-mysql
  namespace: mangos
spec:
  template:
    spec:
      containers:
      - name: backup
        image: busybox
        command: ["/bin/sh", "-c"]
        args:
          - tar czf /backup/mysql-$(date +%Y%m%d).tar.gz /data
        volumeMounts:
        - name: data
          mountPath: /data
        - name: backup
          mountPath: /backup
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: mysql-data-pvc
      - name: backup
        hostPath:
          path: /backups
      restartPolicy: Never
```

### Resize PVCs

```bash
# Edit PVC size
kubectl edit pvc mysql-data-pvc -n mangos

# Change spec.resources.requests.storage to new size
# Example: 10Gi → 20Gi

# Note: Requires storage class to support volume expansion
```

## Networking

### Service Types

**ClusterIP** (internal only):
```yaml
spec:
  type: ClusterIP
  ports:
    - port: 3306
```

**LoadBalancer** (external access):
```yaml
spec:
  type: LoadBalancer  # K3s uses ServiceLB
  ports:
    - port: 3724
```

**NodePort** (specific port):
```yaml
spec:
  type: NodePort
  ports:
    - port: 3724
      nodePort: 30724  # 30000-32767 range
```

### Get Service IPs

```bash
# List services
kubectl get svc -n mangos

# NAME               TYPE           EXTERNAL-IP      PORT(S)
# mysql-service      ClusterIP      None             3306/TCP
# realmd-service     LoadBalancer   192.168.1.100    3724:31234/TCP
# mangosd-service    LoadBalancer   192.168.1.101    8085:31235/TCP

# Get LoadBalancer IP
export REALMD_IP=$(kubectl get svc realmd-service -n mangos -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Realmd IP: $REALMD_IP"
```

### Ingress (Advanced)

**Install Traefik** (if disabled):

```bash
helm repo add traefik https://helm.traefik.io/traefik
helm install traefik traefik/traefik -n kube-system
```

**Create Ingress** (for SOAP admin):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mangos-soap
  namespace: mangos
spec:
  rules:
  - host: admin.mangos.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mangosd-service
            port:
              number: 7878
```

### Network Policies (Security)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mangos-netpol
  namespace: mangos
spec:
  podSelector:
    matchLabels:
      app: mangosd
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}  # Same namespace
    ports:
    - protocol: TCP
      port: 8085
  - from:
    - namespaceSelector: {}  # External access
    ports:
    - protocol: TCP
      port: 8085
```

## Monitoring

### Built-in Monitoring

**Pod Status**:

```bash
# All pods
kubectl get pods -n mangos -w

# Pod details
kubectl describe pod mangosd-xxx -n mangos

# Pod logs
kubectl logs -f mangosd-xxx -n mangos

# Previous pod logs (after crash)
kubectl logs --previous mangosd-xxx -n mangos
```

**Resource Usage**:

```bash
# Top pods
kubectl top pods -n mangos

# Top nodes
kubectl top nodes
```

**Events**:

```bash
# Recent events
kubectl get events -n mangos --sort-by='.lastTimestamp'

# Watch events
kubectl get events -n mangos -w
```

### Prometheus & Grafana

**Install Prometheus Operator**:

```bash
# Add helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**ServiceMonitor for MaNGOS**:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: mangos-metrics
  namespace: mangos
spec:
  selector:
    matchLabels:
      app: mangosd
  endpoints:
  - port: metrics
    interval: 30s
```

## Troubleshooting

### Pod Won't Start

**Check pod status**:

```bash
kubectl get pods -n mangos
kubectl describe pod <pod-name> -n mangos
```

**Common issues**:

1. **ImagePullBackOff**:
   - Image not found locally
   - Build images first or use registry

```bash
# Build and import to K3s
docker build -t mangos-wotlk:mangosd --target mangosd .
docker save mangos-wotlk:mangosd | sudo k3s ctr images import -
```

2. **Pending (PVC)**:
   - PVC not bound
   - Insufficient storage

```bash
kubectl get pvc -n mangos
kubectl describe pvc <pvc-name> -n mangos
```

3. **CrashLoopBackOff**:
   - Application crashing
   - Check logs

```bash
kubectl logs <pod-name> -n mangos
kubectl logs --previous <pod-name> -n mangos
```

### Database Issues

**Cannot connect to MySQL**:

```bash
# Check MySQL pod
kubectl get pod -l app=mysql -n mangos

# MySQL logs
kubectl logs -l app=mysql -n mangos

# Test connection from realmd pod
kubectl exec -it <realmd-pod> -n mangos -- /bin/bash
nc -zv mysql-service 3306

# Access MySQL console
kubectl exec -it mysql-0 -n mangos -- mysql -u root -p
```

### Networking Issues

**Cannot access services**:

```bash
# Check service endpoints
kubectl get endpoints -n mangos

# Test from another pod
kubectl run -it --rm debug --image=busybox -n mangos -- /bin/sh
nc -zv realmd-service 3724
nc -zv mangosd-service 8085

# Check firewall (host)
sudo iptables -L -n | grep 3724
```

### Performance Issues

**High CPU usage**:

```bash
# Check resource limits
kubectl describe pod <pod-name> -n mangos | grep -A 5 "Limits:"

# Top pods
kubectl top pods -n mangos
```

**Out of Memory**:

```bash
# Check memory usage
kubectl top pods -n mangos

# Increase limits
kubectl set resources deployment mangosd -n mangos \
  --limits=memory=8Gi
```

**Slow database**:

```bash
# Check MySQL performance
kubectl exec -it mysql-0 -n mangos -- mysql -u root -p -e "SHOW PROCESSLIST;"

# Tune MySQL config in configmap
kubectl edit configmap mysql-init-scripts -n mangos
```

## Production Considerations

### High Availability

**Multi-replica Realmd** (requires session sharing):

```yaml
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

**MySQL Replication** (master-slave):

Use MySQL Operator or Percona XtraDB Cluster.

### Security

**Use secrets for sensitive data**:

```bash
# Never commit secrets to git
echo "k8s/secrets.yaml" >> .gitignore

# Use sealed-secrets or external secrets operator
```

**Network policies**:

```yaml
# Restrict database access
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mysql-netpol
  namespace: mangos
spec:
  podSelector:
    matchLabels:
      app: mysql
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: realmd
    - podSelector:
        matchLabels:
          app: mangosd
```

**Resource quotas**:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: mangos-quota
  namespace: mangos
spec:
  hard:
    requests.cpu: "8"
    requests.memory: "16Gi"
    limits.cpu: "16"
    limits.memory: "32Gi"
    persistentvolumeclaims: "10"
```

### Backup Strategy

**Automated backup CronJob**:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: mysql-backup
  namespace: mangos
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: mysql:8.0
            command:
            - /bin/sh
            - -c
            - |
              mysqldump -h mysql-service -u root -p$MYSQL_ROOT_PASSWORD \
                --all-databases > /backup/dump-$(date +%Y%m%d).sql
            env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mangos-secrets
                  key: mysql-root-password
            volumeMounts:
            - name: backup
              mountPath: /backup
          volumes:
          - name: backup
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```

### Disaster Recovery

**Backup critical resources**:

```bash
# Export all manifests
kubectl get all,cm,secret,pvc -n mangos -o yaml > mangos-backup.yaml

# Backup PVCs (see Storage section)
```

**Restore procedure**:

```bash
# 1. Restore PVCs first
kubectl apply -f pvc-backups/

# 2. Restore configs and secrets
kubectl apply -f configmaps.yaml
kubectl apply -f secrets.yaml

# 3. Restore workloads
kubectl apply -f deployments.yaml
kubectl apply -f statefulsets.yaml
```

## See Also

- [Main Deployment Guide](../DEPLOYMENT.md)
- [Docker Deployment](DOCKER_DEPLOYMENT.md)
- [Architecture](ARCHITECTURE.md)
- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
