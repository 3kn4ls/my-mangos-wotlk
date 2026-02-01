# MaNGOS WotLK - Docker Deployment Guide

Comprehensive Docker deployment guide for MaNGOS WotLK server.

## Table of Contents

- [Overview](#overview)
- [Docker Architecture](#docker-architecture)
- [Multi-Architecture Support](#multi-architecture-support)
- [Build Process](#build-process)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Data Management](#data-management)
- [Networking](#networking)
- [Troubleshooting](#troubleshooting)
- [Advanced Topics](#advanced-topics)

## Overview

The Docker deployment provides:

- **Multi-stage builds**: Optimized image sizes
- **Multi-architecture**: AMD64 and ARM64 support
- **Container orchestration**: Docker Compose
- **Persistent storage**: Volumes for databases and logs
- **Health checks**: Automated service monitoring
- **Easy scaling**: Configuration via environment variables

### Container Architecture

```
┌──────────────────────────────────────────────────────┐
│              Docker Host                              │
│                                                       │
│  ┌────────────────┐  ┌──────────────┐  ┌──────────┐ │
│  │  realmd        │  │  mangosd     │  │ database │ │
│  │  (auth)        │  │  (world)     │  │ (mysql)  │ │
│  │  Port: 3724    │  │  Port: 8085  │  │ Port:    │ │
│  └───────┬────────┘  └──────┬───────┘  │ 3306     │ │
│          │                  │          └────┬─────┘ │
│          └──────────────────┴───────────────┘       │
│                      │                               │
│              ┌───────▼────────┐                      │
│              │ mangos-network │                      │
│              │ (bridge)       │                      │
│              └────────────────┘                      │
└──────────────────────────────────────────────────────┘
```

## Docker Architecture

### Multi-Stage Dockerfile

The `Dockerfile` uses multi-stage builds for efficiency:

#### Stage 1: Builder

```dockerfile
FROM ubuntu:22.04 as builder
# Install build dependencies
# Copy source code
# Build binaries
```

**Purpose**: Compile C++ code with all build tools

**Output**: Compiled binaries in `/mangos/install/`

#### Stage 2: Realmd Runtime

```dockerfile
FROM ubuntu:22.04 as realmd
# Install runtime dependencies only
# Copy realmd binary from builder
# Setup user and permissions
```

**Purpose**: Minimal runtime for authentication server

**Size**: ~200 MB (vs ~2 GB with build tools)

#### Stage 3: Mangosd Runtime

```dockerfile
FROM ubuntu:22.04 as mangosd
# Install runtime dependencies
# Copy mangosd binary from builder
# Setup directories and permissions
```

**Purpose**: Minimal runtime for world server

**Size**: ~250 MB

#### Stage 4: Extractors (Optional)

```dockerfile
FROM ubuntu:22.04 as extractors
# Copy extraction tools
```

**Purpose**: Extract game data from WoW client

## Multi-Architecture Support

### Supported Platforms

| Architecture | Description | Use Case |
|--------------|-------------|----------|
| `linux/amd64` | x86_64 Intel/AMD | Standard servers, desktops |
| `linux/arm64` | ARM 64-bit | Raspberry Pi 5, ARM servers |

### Building Multi-Arch Images

**Using buildx (recommended)**:

```bash
# Create builder instance
docker buildx create --name mangos-builder --use

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --target mangosd \
  -t mangos-wotlk:mangosd \
  .

# Build and push to registry
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --target mangosd \
  -t your-registry/mangos-wotlk:mangosd \
  --push \
  .
```

**Platform-specific builds**:

```bash
# AMD64 only
docker build --platform linux/amd64 -t mangos-wotlk:mangosd .

# ARM64 only (for Raspberry Pi 5)
docker build --platform linux/arm64 -t mangos-wotlk:mangosd .
```

### Cross-Platform Considerations

**ARM64 Performance**:
- Raspberry Pi 5 can handle 10-50 concurrent players
- Use SSD for database (not SD card)
- Allocate at least 4GB RAM
- Consider disabling optional modules (PlayerBot, AHBot)

**Build Times**:
- AMD64: ~10-15 minutes
- ARM64: ~30-45 minutes (native), ~20 minutes (emulated on AMD64)

## Build Process

### Automated Build Script

**Linux/Mac**:

```bash
cd docker
./build.sh [platform] [push]

# Examples:
./build.sh                                    # Default: amd64,arm64
./build.sh linux/amd64                       # AMD64 only
./build.sh linux/arm64                       # ARM64 only
./build.sh linux/amd64,linux/arm64 true     # Build and push
```

**Windows**:

```powershell
cd docker
.\build.ps1 -Platform "linux/amd64,linux/arm64"

# With push
.\build.ps1 -Platform "linux/amd64" -Push
```

### Manual Build Steps

```bash
# 1. Build all stages
docker build -t mangos-wotlk:builder --target builder .
docker build -t mangos-wotlk:realmd --target realmd .
docker build -t mangos-wotlk:mangosd --target mangosd .
docker build -t mangos-wotlk:extractors --target extractors .

# 2. Verify images
docker images | grep mangos-wotlk

# 3. Test a container
docker run --rm mangos-wotlk:mangosd /mangos/bin/mangosd --version
```

### Build Arguments

Customize builds with `--build-arg`:

```bash
docker build \
  --build-arg BASE_IMAGE=ubuntu:22.04 \
  --target mangosd \
  -t mangos-wotlk:mangosd .
```

Available build args:
- `BASE_IMAGE`: Base Ubuntu image (default: `ubuntu:22.04`)

## Configuration

### Environment Variables

Create `.env` file from template:

```bash
cp .env.example .env
nano .env
```

#### Database Configuration

```env
MYSQL_ROOT_PASSWORD=secure_root_password_here
MYSQL_USER=mangos
MYSQL_PASSWORD=secure_mangos_password
MYSQL_DATABASE=mangos
MYSQL_PORT=3306

# Database names
REALMD_DB=realmd
WORLD_DB=mangos
CHARACTER_DB=characters
```

#### Server Configuration

```env
TZ=America/New_York
REALM_ID=1
REALMD_PORT=3724
MANGOSD_PORT=8085
SOAP_PORT=7878
```

#### Optional Services

```env
PHPMYADMIN_PORT=8080  # Web database management
```

### Configuration Files

Located in `docker/configs/`:

- `realmd.conf`: Auth server settings
- `mangosd.conf`: World server settings
- `ahbot.conf`: Auction House Bot settings
- `playerbot.conf`: PlayerBot settings

**Mounting custom configs**:

```yaml
# docker-compose.yml
services:
  mangosd:
    volumes:
      - ./my-custom-config.conf:/mangos/etc/mangosd.conf:ro
```

### Config Override via Environment

Override any config setting:

```bash
# Pattern: {Service}_{Section}_{Key}=value
# Dots (.) become underscores (_)

# Example: Override Rate.XP.Kill in mangosd.conf
export Mangosd_Rate_XP_Kill=2.0

# Example: Override WrongPass.MaxCount in realmd.conf
export Realmd_WrongPass_MaxCount=5
```

## Deployment

### Quick Start

```bash
# 1. Configure environment
cp .env.example .env
vim .env  # Edit settings

# 2. Build images
cd docker
./build.sh

# 3. Start services
./deploy.sh up

# 4. Check status
./deploy.sh status

# 5. View logs
./deploy.sh logs
```

### Docker Compose Commands

**Start all services**:

```bash
docker-compose up -d

# With specific compose file
docker-compose -f docker-compose.windows.yml up -d
```

**Stop services**:

```bash
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v
```

**Restart services**:

```bash
docker-compose restart

# Restart specific service
docker-compose restart mangosd
```

**View logs**:

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f mangosd

# Last 100 lines
docker-compose logs --tail=100 mangosd
```

**Scale services** (not recommended for realmd/mangosd):

```bash
# Only scale stateless services
docker-compose up -d --scale phpmyadmin=2
```

### Service Dependencies

Services start in order:

```
1. database (MySQL)
   └─> Wait for health check
       └─> 2. realmd (depends on database)
           └─> Wait for health check
               └─> 3. mangosd (depends on database + realmd)
```

Health checks ensure services are ready before dependents start.

## Data Management

### Persistent Volumes

Docker Compose creates named volumes:

```yaml
volumes:
  mysql_data:          # Database files
  realmd_logs:         # Realmd logs
  mangosd_logs:        # Mangosd logs
  game_data_dbc:       # DBC files
  game_data_maps:      # Map files
  game_data_mmaps:     # Movement maps
  game_data_vmaps:     # Visual maps
```

### Volume Operations

**List volumes**:

```bash
docker volume ls | grep mangos
```

**Inspect volume**:

```bash
docker volume inspect my-mangos-wotlk_mysql_data
```

**Backup volume**:

```bash
# Create backup directory
mkdir -p backups

# Backup MySQL data
docker run --rm \
  -v my-mangos-wotlk_mysql_data:/data \
  -v $(pwd)/backups:/backup \
  ubuntu:22.04 \
  tar czf /backup/mysql-$(date +%Y%m%d).tar.gz /data
```

**Restore volume**:

```bash
docker run --rm \
  -v my-mangos-wotlk_mysql_data:/data \
  -v $(pwd)/backups:/backup \
  ubuntu:22.04 \
  tar xzf /backup/mysql-20240101.tar.gz -C /
```

**Remove volumes** (WARNING: deletes data):

```bash
docker-compose down -v
```

### Database Management

**Access MySQL console**:

```bash
# Method 1: Via docker exec
docker exec -it mangos-database mysql -u root -p

# Method 2: From host (if port exposed)
mysql -h 127.0.0.1 -P 3306 -u mangos -p
```

**Import SQL files**:

```bash
# Import world database
docker exec -i mangos-database mysql -u root -p mangos < sql/base/mangos/mangos.sql

# Import using script
docker cp sql/base/mangos/. mangos-database:/tmp/sql/
docker exec mangos-database bash -c "cat /tmp/sql/*.sql | mysql -u root -p mangos"
```

**Backup databases**:

```bash
# Backup all databases
docker exec mangos-database mysqldump -u root -p --all-databases > backup-all.sql

# Backup specific database
docker exec mangos-database mysqldump -u root -p mangos > backup-mangos.sql
```

### Game Data Extraction

Extract data from WoW 3.3.5a client:

```bash
# 1. Extract DBC files
docker run --rm \
  -v /path/to/wow/Data:/data \
  -v game_data_dbc:/output \
  mangos-wotlk:extractors \
  /mangos/tools/map-extractor -i /data -o /output

# 2. Extract maps
docker run --rm \
  -v /path/to/wow:/data \
  -v game_data_maps:/output \
  mangos-wotlk:extractors \
  /mangos/tools/map-extractor -i /data -o /output -e

# 3. Extract VMaps
docker run --rm \
  -v /path/to/wow:/data \
  -v game_data_vmaps:/output \
  mangos-wotlk:extractors \
  /mangos/tools/vmap-extractor -i /data -o /output

# 4. Extract MMaps (slowest, can take hours)
docker run --rm \
  -v /path/to/wow:/data \
  -v game_data_mmaps:/output \
  mangos-wotlk:extractors \
  /mangos/tools/mmap-generator -i /data -o /output
```

## Networking

### Network Topology

```
┌─────────────────────────────────────┐
│     Host Network (172.17.0.0/16)    │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  mangos-network (bridge)       │ │
│  │  Subnet: 172.20.0.0/16         │ │
│  │                                │ │
│  │  realmd:       172.20.0.10     │ │
│  │  mangosd:      172.20.0.11     │ │
│  │  database:     172.20.0.12     │ │
│  └────────────────────────────────┘ │
│                                      │
└─────────────────────────────────────┘
```

### Port Mappings

| Service | Internal Port | External Port | Protocol | Purpose |
|---------|---------------|---------------|----------|---------|
| realmd | 3724 | 3724 | TCP | Authentication |
| mangosd | 8085 | 8085 | TCP | Game server |
| mangosd | 7878 | 7878 | TCP | SOAP (optional) |
| database | 3306 | 3306 | TCP | MySQL |
| phpmyadmin | 80 | 8080 | TCP | Web UI |

### Custom Network Configuration

**Change subnet**:

```yaml
# docker-compose.yml
networks:
  mangos-network:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.100.0/24
```

**Assign static IPs**:

```yaml
services:
  database:
    networks:
      mangos-network:
        ipv4_address: 192.168.100.10
```

### Firewall Configuration

**Allow access from external clients**:

```bash
# Linux (iptables)
sudo iptables -A INPUT -p tcp --dport 3724 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8085 -j ACCEPT

# Linux (firewalld)
sudo firewall-cmd --permanent --add-port=3724/tcp
sudo firewall-cmd --permanent --add-port=8085/tcp
sudo firewall-cmd --reload

# Linux (ufw)
sudo ufw allow 3724/tcp
sudo ufw allow 8085/tcp
```

**Windows Firewall**:

```powershell
# PowerShell (Run as Administrator)
New-NetFirewallRule -DisplayName "MaNGOS Realmd" -Direction Inbound -LocalPort 3724 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "MaNGOS Mangosd" -Direction Inbound -LocalPort 8085 -Protocol TCP -Action Allow
```

## Troubleshooting

### Common Issues

#### Database Connection Failed

**Symptoms**:
- Realmd/Mangosd cannot connect to database
- Error: "Can't connect to MySQL server"

**Solutions**:

```bash
# 1. Check database is running
docker-compose ps database

# 2. Check database logs
docker-compose logs database

# 3. Verify credentials in .env match configs

# 4. Test database connection
docker exec -it mangos-database mysql -u mangos -p -e "SHOW DATABASES;"

# 5. Restart services in order
docker-compose restart database
sleep 10
docker-compose restart realmd mangosd
```

#### Realmd Won't Start

**Check logs**:

```bash
docker-compose logs realmd

# Common errors:
# - "Port already in use" → Change REALMD_PORT
# - "Config file not found" → Check volume mount
# - "Database error" → Fix database connection
```

**Verify configuration**:

```bash
# Check config file exists
docker exec mangos-realmd ls -l /mangos/etc/realmd.conf

# Test manually
docker exec -it mangos-realmd /mangos/bin/realmd -c /mangos/etc/realmd.conf
```

#### Mangosd Missing Game Data

**Symptoms**:
- Error: "Map file './maps/xxx.map' does not exist!"
- Cannot enter world

**Solutions**:

```bash
# 1. Check data volumes
docker volume inspect my-mangos-wotlk_game_data_maps

# 2. Extract game data (see Data Management section)

# 3. Verify data is accessible
docker exec mangos-mangosd ls -l /mangos/maps/
docker exec mangos-mangosd ls -l /mangos/dbc/
docker exec mangos-mangosd ls -l /mangos/mmaps/
docker exec mangos-mangosd ls -l /mangos/vmaps/
```

#### Performance Issues

**Check resource usage**:

```bash
# Container stats
docker stats

# Identify resource hogs
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

**Optimize**:

```yaml
# docker-compose.yml
services:
  mangosd:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          memory: 2G
```

**Database tuning**:

```yaml
# docker-compose.yml
services:
  database:
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --max_allowed_packet=256M
      - --innodb_buffer_pool_size=1G       # Tune based on RAM
      - --innodb_log_file_size=256M
      - --query_cache_size=64M
```

### Health Check Failures

**Check health status**:

```bash
docker-compose ps

# Example output:
# NAME              STATUS
# mangos-database   Up (healthy)
# mangos-realmd     Up (unhealthy)
# mangos-mangosd    Up (starting)
```

**Debug health check**:

```bash
# Manually run health check command
docker exec mangos-realmd netstat -an | grep 3724

# Inspect health check logs
docker inspect mangos-realmd | jq '.[].State.Health'
```

### Log Analysis

**Enable debug logging**:

```conf
# mangosd.conf
LogLevel = 3
LogFileLevel = 3
```

**Common log locations**:

```bash
# Container logs
docker logs mangos-mangosd

# Mounted log volumes
ls -l /var/lib/docker/volumes/my-mangos-wotlk_mangosd_logs/_data/

# Copy logs from container
docker cp mangos-mangosd:/mangos/logs/. ./logs/
```

## Advanced Topics

### Custom Builds

**Enable optional modules**:

```dockerfile
# Dockerfile (modify build stage)
RUN cd build && \
    cmake .. \
    -DBUILD_PLAYERBOTS=ON \
    -DBUILD_AHBOT=ON \
    -DBUILD_METRICS=ON
```

**Use different base image**:

```dockerfile
# Use Alpine for smaller images
ARG BASE_IMAGE=alpine:3.18
FROM ${BASE_IMAGE} as builder
# Note: Requires different package names
```

### CI/CD Integration

**GitHub Actions example**:

```yaml
# .github/workflows/docker.yml
name: Docker Build

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Build images
        run: |
          docker buildx build --platform linux/amd64,linux/arm64 -t myregistry/mangos:latest .
```

### Production Deployment

**Use secrets instead of .env**:

```yaml
# docker-compose.prod.yml
services:
  database:
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
    secrets:
      - db_root_password

secrets:
  db_root_password:
    file: ./secrets/db_root_password.txt
```

**Resource limits**:

```yaml
services:
  mangosd:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
```

**Monitoring**:

```yaml
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
```

## See Also

- [Main Deployment Guide](../DEPLOYMENT.md)
- [Kubernetes Deployment](K8S_DEPLOYMENT.md)
- [Architecture](ARCHITECTURE.md)
- [Module Reference](MODULES.md)
