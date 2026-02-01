# MaNGOS WotLK - Documentation Index

Welcome to the MaNGOS WotLK documentation. This directory contains comprehensive guides for understanding, deploying, and managing the MaNGOS World of Warcraft: Wrath of the Lich King server.

## Quick Start

New to MaNGOS? Choose your platform and follow the step-by-step guide:

### 🚀 Platform-Specific Quick Start Guides

- **[Windows 11](QUICKSTART_WINDOWS.md)** - Complete guide for Docker on Windows 11 with WSL2
- **[Raspberry Pi 5](QUICKSTART_RASPBERRY_PI.md)** - Optimized guide for ARM64 deployment on Raspberry Pi 5
- **[K3s (Kubernetes)](QUICKSTART_K3S.md)** - Production-ready Kubernetes cluster deployment

### 📚 General Documentation

1. **[Deployment Guide](../DEPLOYMENT.md)** - Overview of all deployment options
2. **[Architecture Overview](ARCHITECTURE.md)** - Understand the system architecture
3. **[Docker Deployment](DOCKER_DEPLOYMENT.md)** or **[K8s Deployment](K8S_DEPLOYMENT.md)** - Detailed deployment guides

## Documentation Structure

### Core Documentation

#### [ARCHITECTURE.md](ARCHITECTURE.md)
Complete architectural overview of MaNGOS WotLK.

**Contents**:
- System architecture diagrams
- Core components (Realmd, Mangosd, Game Library)
- Data flow and communication patterns
- Directory structure
- Build system (CMake)
- Database schema overview
- Performance characteristics
- Extension points

**Audience**: Developers, system architects, AI assistants

---

#### [MODULES.md](MODULES.md)
Detailed reference for all 45+ game modules.

**Contents**:
- Core systems (World, Maps, Entities, Movement)
- Game logic modules (Combat, Spells, Skills, Quests, Loot)
- Content systems (BattleGrounds, Arenas, Achievements)
- Social systems (Groups, Guilds, Chat, Mail)
- Optional modules (PlayerBot, AuctionHouseBot, AntiCheat, Metrics)
- Shared libraries (Database, Network, Auth, Config, Log)
- Module dependencies and performance notes

**Audience**: Developers, contributors, AI code assistants

---

### Quick Start Guides

#### [QUICKSTART_WINDOWS.md](QUICKSTART_WINDOWS.md)
Step-by-step guide for Windows 11 deployment.

**Contents**:
- Prerequisites (WSL2, Docker Desktop)
- Environment configuration
- Building multi-architecture images
- Deploying with Docker Compose
- Database setup and game data extraction
- Creating GM accounts
- Troubleshooting Windows-specific issues

**Audience**: Windows users, beginners

**Time to deploy**: ~1-2 hours (including build time)

---

#### [QUICKSTART_RASPBERRY_PI.md](QUICKSTART_RASPBERRY_PI.md)
Optimized guide for Raspberry Pi 5 (ARM64).

**Contents**:
- Hardware requirements and recommendations
- Raspberry Pi OS setup
- Docker installation for ARM64
- Performance optimization for limited resources
- Temperature monitoring and thermal management
- SSD/NVMe configuration
- Resource limits and player capacity

**Audience**: Raspberry Pi users, ARM64 platforms

**Time to deploy**: ~2-3 hours (ARM64 builds are slower)

**Expected capacity**: 10-50 concurrent players

---

#### [QUICKSTART_K3S.md](QUICKSTART_K3S.md)
Production-ready Kubernetes (K3s) deployment.

**Contents**:
- K3s installation (single-node and multi-node)
- Kubernetes manifests explanation
- Automated deployment scripts
- Scaling strategies
- High availability setup
- Monitoring with Prometheus/Grafana
- Backup and disaster recovery

**Audience**: DevOps engineers, production deployments

**Time to deploy**: ~1-2 hours

**Best for**: Production servers, high availability, scalability

---

### Deployment Documentation

#### [DEPLOYMENT.md](../DEPLOYMENT.md)
Main deployment guide with quick start for all platforms.

**Contents**:
- Overview and prerequisites
- Docker Compose deployment (Linux/ARM64 and Windows)
- Kubernetes (K3s) deployment
- Post-deployment setup
- Database initialization
- Game data extraction
- Troubleshooting

**Audience**: Server administrators, DevOps, general users

---

#### [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)
Comprehensive Docker deployment guide.

**Contents**:
- Docker architecture and multi-stage builds
- Multi-architecture support (AMD64, ARM64)
- Build process and automation
- Configuration management
- Docker Compose orchestration
- Data management and volumes
- Networking configuration
- Advanced topics (CI/CD, production deployment)
- Troubleshooting

**Audience**: Docker users, DevOps engineers

---

#### [K8S_DEPLOYMENT.md](K8S_DEPLOYMENT.md)
Complete Kubernetes (K3s) deployment guide.

**Contents**:
- K3s setup and configuration
- Kubernetes resource architecture
- Deployment procedures
- ConfigMaps and Secrets management
- Scaling (vertical and horizontal)
- Storage and persistent volumes
- Networking and ingress
- Monitoring with Prometheus/Grafana
- Production considerations
- High availability and disaster recovery

**Audience**: Kubernetes administrators, DevOps engineers

---

## Documentation for AI Assistants

This documentation is specifically designed to help AI assistants understand and work with the MaNGOS WotLK project:

### Understanding the Project

1. **Start with [ARCHITECTURE.md](ARCHITECTURE.md)**
   - Understand the high-level architecture
   - Learn about the core components
   - See data flow diagrams
   - Understand the threading model

2. **Deep dive into [MODULES.md](MODULES.md)**
   - Learn about each game system module
   - Understand module dependencies
   - See module responsibilities and key classes

### Helping with Deployment

1. **For Docker questions**: Use [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)
   - Multi-arch builds
   - Configuration
   - Troubleshooting

2. **For Kubernetes questions**: Use [K8S_DEPLOYMENT.md](K8S_DEPLOYMENT.md)
   - Resource manifests
   - Scaling strategies
   - Storage management

### Helping with Development

1. **Module Location**: See directory structure in [ARCHITECTURE.md](ARCHITECTURE.md)
2. **Build System**: CMake configuration explained in [ARCHITECTURE.md](ARCHITECTURE.md)
3. **Module APIs**: Class and responsibility information in [MODULES.md](MODULES.md)

### Quick Reference Tables

#### File Locations

| Type | Location | Documentation |
|------|----------|---------------|
| Source Code | `src/` | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Game Modules | `src/game/` | [MODULES.md](MODULES.md) |
| Database Schemas | `sql/base/` | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Docker Files | `docker/`, `Dockerfile` | [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md) |
| K8s Manifests | `k8s/` | [K8S_DEPLOYMENT.md](K8S_DEPLOYMENT.md) |
| Configuration | `docker/configs/` | [DEPLOYMENT.md](../DEPLOYMENT.md) |

#### Key Ports

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Realmd | 3724 | TCP | Authentication |
| Mangosd | 8085 | TCP | Game/World Server |
| SOAP | 7878 | TCP | Remote Admin (optional) |
| MySQL | 3306 | TCP | Database |

#### Key Components

| Component | Location | Purpose | Documentation |
|-----------|----------|---------|---------------|
| Realmd | `src/realmd/` | Authentication server | [ARCHITECTURE.md](ARCHITECTURE.md#1-realmd-authentication-server) |
| Mangosd | `src/mangosd/` | World/game server | [ARCHITECTURE.md](ARCHITECTURE.md#2-mangosd-world-server) |
| Game Library | `src/game/` | 45+ game modules | [MODULES.md](MODULES.md) |
| Shared | `src/shared/` | Common utilities | [ARCHITECTURE.md](ARCHITECTURE.md#4-shared-libraries) |
| Framework | `src/framework/` | Core framework | [ARCHITECTURE.md](ARCHITECTURE.md#5-framework) |

## Project Structure

```
my-mangos-wotlk/
├── docs/                       # Documentation (you are here)
│   ├── README.md              # This file
│   ├── ARCHITECTURE.md        # System architecture
│   ├── MODULES.md             # Module reference
│   ├── DOCKER_DEPLOYMENT.md   # Docker guide
│   └── K8S_DEPLOYMENT.md      # Kubernetes guide
│
├── DEPLOYMENT.md              # Main deployment guide
│
├── src/                       # Source code
│   ├── realmd/               # Auth server
│   ├── mangosd/              # World server
│   ├── game/                 # Game modules
│   ├── shared/               # Shared libraries
│   └── framework/            # Core framework
│
├── docker/                    # Docker deployment
│   ├── Dockerfile            # Multi-stage build
│   ├── docker-compose.yml    # Linux/ARM compose
│   ├── docker-compose.windows.yml
│   ├── build.sh / build.ps1  # Build scripts
│   ├── deploy.sh / deploy.ps1 # Deployment scripts
│   └── configs/              # Server configs
│
├── k8s/                       # Kubernetes deployment
│   ├── *.yaml                # K8s manifests
│   ├── deploy-k3s.sh         # K3s deployment script
│   └── kustomization.yaml    # Kustomize config
│
├── sql/                       # Database schemas
│   ├── base/                 # Base schemas
│   └── updates/              # Incremental updates
│
└── contrib/                   # Utility tools
    ├── extractor/            # Data extraction
    ├── vmap_extractor/
    └── mmap/
```

## Common Tasks

### For Administrators

| Task | Documentation |
|------|---------------|
| Deploy on Docker | [DEPLOYMENT.md](../DEPLOYMENT.md#docker-compose-linuxarm64) |
| Deploy on Windows | [DEPLOYMENT.md](../DEPLOYMENT.md#docker-compose-windows) |
| Deploy on K3s | [DEPLOYMENT.md](../DEPLOYMENT.md#kubernetes-k3s) |
| Configure server | [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md#configuration) |
| Manage databases | [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md#database-management) |
| Extract game data | [DEPLOYMENT.md](../DEPLOYMENT.md#2-game-data-extraction) |
| Troubleshoot issues | [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md#troubleshooting) |

### For Developers

| Task | Documentation |
|------|---------------|
| Understand architecture | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Learn about modules | [MODULES.md](MODULES.md) |
| Build from source | [ARCHITECTURE.md](ARCHITECTURE.md#build-system) |
| Extend with scripts | [ARCHITECTURE.md](ARCHITECTURE.md#extension-points) |
| Add custom modules | [MODULES.md](MODULES.md#module-dependencies) |

### For DevOps

| Task | Documentation |
|------|---------------|
| Multi-arch builds | [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md#multi-architecture-support) |
| CI/CD integration | [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md#cicd-integration) |
| K8s scaling | [K8S_DEPLOYMENT.md](K8S_DEPLOYMENT.md#scaling) |
| Monitoring setup | [K8S_DEPLOYMENT.md](K8S_DEPLOYMENT.md#monitoring) |
| Backup strategy | [K8S_DEPLOYMENT.md](K8S_DEPLOYMENT.md#backup-strategy) |

## Platform-Specific Guides

### Docker

- **Linux/ARM64**: [DEPLOYMENT.md](../DEPLOYMENT.md#docker-compose-linuxarm64) → [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)
- **Windows**: [DEPLOYMENT.md](../DEPLOYMENT.md#docker-compose-windows) → [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)
- **Raspberry Pi 5**: [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md#cross-platform-considerations)

### Kubernetes

- **K3s on Linux**: [K8S_DEPLOYMENT.md](K8S_DEPLOYMENT.md#install-k3s-single-node)
- **K3s on Raspberry Pi**: [K8S_DEPLOYMENT.md](K8S_DEPLOYMENT.md#install-k3s-single-node)
- **Multi-node cluster**: [K8S_DEPLOYMENT.md](K8S_DEPLOYMENT.md#install-k3s-multi-node-cluster)

## Contributing

When contributing to MaNGOS WotLK:

1. Read [ARCHITECTURE.md](ARCHITECTURE.md) to understand the system
2. Check [MODULES.md](MODULES.md) to find the right module
3. Follow existing code style
4. Update documentation for your changes
5. Test with Docker before submitting

## External Resources

- **MaNGOS Project**: https://getmangos.eu/
- **CMaNGOS GitHub**: https://github.com/cmangos/mangos-wotlk
- **Discord Community**: https://discord.gg/cmangos
- **Wiki**: https://github.com/cmangos/issues/wiki

## License

MaNGOS is licensed under the GNU General Public License v2.0. See [LICENSE.md](../LICENSE.md) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/cmangos/mangos-wotlk/issues)
- **Discussions**: [GitHub Discussions](https://github.com/cmangos/mangos-wotlk/discussions)
- **Discord**: [CMaNGOS Community](https://discord.gg/cmangos)

---

**Last Updated**: 2026-01-24
**MaNGOS Version**: WotLK (3.3.5a)
**Documentation Version**: 1.0
