# MaNGOS WotLK - Deployment Guide

This guide provides comprehensive instructions for deploying MaNGOS WotLK (World of Warcraft: Wrath of the Lich King) server using Docker and Kubernetes (K3s).

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deployment Options](#deployment-options)
  - [Docker Compose (Linux/ARM64)](#docker-compose-linuxarm64)
  - [Docker Compose (Windows)](#docker-compose-windows)
  - [Kubernetes (K3s)](#kubernetes-k3s)
- [Post-Deployment](#post-deployment)
- [Troubleshooting](#troubleshooting)

## Overview

MaNGOS (Massive Network Game Object Server) is an open-source MMORPG server for World of Warcraft. This deployment setup supports:

- **Multi-architecture**: AMD64 and ARM64 (including Raspberry Pi 5)
- **Multiple platforms**: Linux, Windows (via Docker Desktop), Kubernetes/K3s
- **Containerized**: All services run in isolated containers
- **Scalable**: Can be deployed on single machines or clusters

### Architecture Components

1. **Realmd (Authentication Server)**: Handles player authentication and realm list
2. **Mangosd (World Server)**: Manages the game world, NPCs, quests, and player interactions
3. **MySQL Database**: Stores all game data (3 databases: realmd, mangos, characters)

## Prerequisites

### For Docker Deployment

**Linux/ARM64:**
- Docker Engine 20.10+ ([Install Docker](https://docs.docker.com/engine/install/))
- Docker Compose v2.0+ ([Install Compose](https://docs.docker.com/compose/install/))
- 4GB RAM minimum (8GB recommended)
- 20GB disk space

**Windows:**
- Docker Desktop for Windows ([Download](https://www.docker.com/products/docker-desktop))
- WSL2 enabled
- 4GB RAM minimum (8GB recommended)
- 20GB disk space

### For Kubernetes (K3s) Deployment

- K3s installed ([K3s Quick-Start](https://docs.k3s.io/quick-start))
- kubectl configured
- 4GB RAM minimum (8GB recommended)
- 30GB disk space

### Game Client Data

You'll need to extract game data from a WoW WotLK (3.3.5a) client:
- DBC files
- Maps
- VMaps (Visual Maps)
- MMaps (Movement Maps)

See [Game Data Extraction](#game-data-extraction) section for details.

## Deployment Options

### Docker Compose (Linux/ARM64)

Perfect for single-server deployments on Linux or Raspberry Pi.

#### Quick Start

```bash
# 1. Clone the repository
git clone <repository-url>
cd my-mangos-wotlk

# 2. Create environment file
cp .env.example .env
nano .env  # Edit with your settings

# 3. Build images
cd docker
./build.sh

# 4. Deploy
./deploy.sh up

# 5. Check status
./deploy.sh status
```

#### Detailed Steps

1. **Configure Environment**

Edit `.env` file:
```env
MYSQL_ROOT_PASSWORD=your_secure_password
MYSQL_PASSWORD=your_mangos_password
TZ=America/New_York
```

2. **Build Multi-Architecture Images**

```bash
# Build for current architecture
./docker/build.sh

# Build for specific architecture
./docker/build.sh linux/arm64

# Build for multiple architectures
./docker/build.sh linux/amd64,linux/arm64
```

3. **Deploy Services**

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

4. **Access Services**

- Realmd: `localhost:3724`
- Mangosd: `localhost:8085`
- MySQL: `localhost:3306`
- phpMyAdmin: `http://localhost:8080` (optional, use `--profile tools`)

### Docker Compose (Windows)

Optimized for Docker Desktop on Windows.

#### Quick Start

```powershell
# 1. Clone the repository
git clone <repository-url>
cd my-mangos-wotlk

# 2. Create environment file
Copy-Item .env.example .env
notepad .env  # Edit with your settings

# 3. Build images
cd docker
.\build.ps1

# 4. Deploy
.\deploy.ps1 up

# 5. Check status
.\deploy.ps1 status
```

#### Windows-Specific Configuration

**Docker Desktop Settings:**
- Enable WSL2 backend
- Allocate at least 4GB RAM
- Enable file sharing for project directory

**Using Windows Compose File:**

```powershell
# Use Windows-specific compose file
docker-compose -f docker-compose.windows.yml up -d

# Or use the deploy script (automatically uses Windows config)
.\docker\deploy.ps1 up
```

### Kubernetes (K3s)

Best for production deployments, clusters, or high-availability setups.

#### Quick Start

```bash
# 1. Install K3s (if not already installed)
curl -sfL https://get.k3s.io | sh -

# 2. Verify K3s is running
sudo kubectl cluster-info

# 3. Deploy MaNGOS
cd k8s
./deploy-k3s.sh deploy

# 4. Check status
./deploy-k3s.sh status
```

#### Detailed K3s Deployment

1. **Review Configuration**

Edit `k8s/secrets.yaml` with secure credentials:
```yaml
stringData:
  mysql-root-password: "change_me_secure_password"
  mysql-password: "change_me_mangos_password"
```

2. **Deploy Components**

```bash
# Deploy all components
./k8s/deploy-k3s.sh deploy

# This will:
# - Create namespace
# - Deploy MySQL StatefulSet
# - Deploy Realmd
# - Deploy Mangosd
# - Create LoadBalancer services
```

3. **Access Services**

```bash
# Get service IPs
kubectl get services -n mangos

# Expected output:
# NAME              TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)
# mysql-service     ClusterIP      None            <none>         3306/TCP
# realmd-service    LoadBalancer   10.43.x.x       <external-ip>  3724:xxxxx/TCP
# mangosd-service   LoadBalancer   10.43.x.x       <external-ip>  8085:xxxxx/TCP
```

4. **Manage Deployment**

```bash
# View logs
./deploy-k3s.sh logs mangosd

# Restart service
./deploy-k3s.sh restart mangosd

# Scale service
./deploy-k3s.sh scale mangosd 2

# Shell access
./deploy-k3s.sh shell mangosd

# Delete deployment
./deploy-k3s.sh delete
```

## Post-Deployment

### 1. Initialize Databases

Import SQL schemas:

**Docker:**
```bash
# Copy SQL files to database container
docker cp sql/base/mangos/ mangos-database:/tmp/
docker cp sql/base/realmd/ mangos-database:/tmp/
docker cp sql/base/characters/ mangos-database:/tmp/

# Import schemas
docker exec -i mangos-database mysql -u root -p mangos < /tmp/mangos/*.sql
docker exec -i mangos-database mysql -u root -p realmd < /tmp/realmd/*.sql
docker exec -i mangos-database mysql -u root -p characters < /tmp/characters/*.sql
```

**Kubernetes:**
```bash
# Get MySQL pod name
POD=$(kubectl get pod -n mangos -l app=mysql -o jsonpath="{.items[0].metadata.name}")

# Copy and import
kubectl cp sql/base mangos/$POD:/tmp/
kubectl exec -n mangos $POD -- mysql -u root -p mangos < /tmp/base/mangos/*.sql
```

### 2. Game Data Extraction

Extract game data from WoW client:

```bash
# Using extractor container (Docker)
docker run --rm -v /path/to/wow/client:/data mangos-wotlk:extractors /mangos/tools/map-extractor
docker run --rm -v /path/to/wow/client:/data mangos-wotlk:extractors /mangos/tools/vmap-extractor
docker run --rm -v /path/to/wow/client:/data mangos-wotlk:extractors /mangos/tools/mmap-generator

# Copy extracted data to volumes
docker cp /path/to/extracted/dbc/. mangos-mangosd:/mangos/dbc/
docker cp /path/to/extracted/maps/. mangos-mangosd:/mangos/maps/
docker cp /path/to/extracted/vmaps/. mangos-mangosd:/mangos/vmaps/
docker cp /path/to/extracted/mmaps/. mangos-mangosd:/mangos/mmaps/
```

### 3. Create Realm

Add realm to database:

```sql
-- Connect to realmd database
USE realmd;

-- Insert realm
INSERT INTO realmlist (id, name, address, port, icon, realmflags, timezone, allowedSecurityLevel)
VALUES (1, 'My MaNGOS Realm', '127.0.0.1', 8085, 1, 0, 1, 0);
```

### 4. Create GM Account

```bash
# Access mangosd console (Docker)
docker exec -it mangos-mangosd /mangos/bin/mangosd

# In console:
account create <username> <password>
account set gmlevel <username> 3
```

## Troubleshooting

### Common Issues

**Database Connection Failed**
```bash
# Check database is running
docker-compose ps database
kubectl get pods -n mangos -l app=mysql

# Check database logs
docker-compose logs database
kubectl logs -n mangos -l app=mysql
```

**Realmd Cannot Connect**
- Verify database credentials in config
- Check firewall rules (port 3724)
- Ensure MySQL is healthy before realmd starts

**Mangosd Missing Game Data**
- Verify game data volumes are mounted
- Check file permissions
- Re-extract data from client

**ARM64 Build Issues**
```bash
# Use buildx with correct platform
docker buildx build --platform linux/arm64 -t mangos-wotlk:mangosd .
```

### Logs

**Docker:**
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f mangosd
```

**Kubernetes:**
```bash
# All pods
kubectl logs -n mangos -l app.kubernetes.io/name=mangos-wotlk --tail=100

# Specific service
kubectl logs -n mangos -l app=mangosd -f
```

### Performance Tuning

**Docker Compose:**
Edit `docker-compose.yml` resource limits:
```yaml
services:
  mangosd:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
```

**Kubernetes:**
Edit deployment resource requests/limits in `k8s/mangosd-deployment.yaml`.

## Next Steps

- [Architecture Documentation](docs/ARCHITECTURE.md)
- [Module Reference](docs/MODULES.md)
- [Docker Deployment Guide](docs/DOCKER_DEPLOYMENT.md)
- [Kubernetes Deployment Guide](docs/K8S_DEPLOYMENT.md)

## Support

- Issues: [GitHub Issues](https://github.com/cmangos/mangos-wotlk/issues)
- Discord: [CMaNGOS Community](https://discord.gg/cmangos)
- Documentation: [docs/](docs/)
