# MaNGOS WotLK - Architecture Documentation

This document provides a comprehensive overview of the MaNGOS WotLK (World of Warcraft: Wrath of the Lich King) server architecture.

## Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Core Components](#core-components)
- [Data Flow](#data-flow)
- [Directory Structure](#directory-structure)
- [Build System](#build-system)
- [Database Schema](#database-schema)

## Overview

**MaNGOS** (Massive Network Game Object Server) is a free, open-source MMORPG server implementation written in C++20. This project targets the Wrath of the Lich King (WotLK) expansion, patch 3.3.5a.

### Key Features

- **Open Source**: GPL v2 licensed
- **C++20**: Modern C++ with high performance
- **Cross-Platform**: Linux, Windows, macOS support
- **Multi-Database**: MySQL, PostgreSQL, SQLite
- **Modular Design**: Pluggable components and scripts
- **Multi-Architecture**: AMD64 and ARM64 support

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        WoW Client                            │
│                      (3.3.5a Build)                          │
└────────────┬────────────────────────────────────┬───────────┘
             │                                    │
             │ Auth Request                       │ Game Traffic
             │ (Port 3724)                        │ (Port 8085)
             ▼                                    ▼
    ┌────────────────┐                   ┌─────────────────┐
    │    Realmd      │◄──────────────────┤    Mangosd      │
    │   (Auth Server)│  Realm Info       │  (World Server)  │
    └────────┬───────┘                   └────────┬────────┘
             │                                    │
             │ DB Query                           │ DB Query
             ▼                                    ▼
    ┌────────────────────────────────────────────────────────┐
    │                   MySQL Database                        │
    │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐    │
    │  │ Realmd   │  │ Mangos   │  │ Characters       │    │
    │  │ (Auth &  │  │ (World   │  │ (Player Data)    │    │
    │  │ Realms)  │  │  Data)   │  │                  │    │
    │  └──────────┘  └──────────┘  └──────────────────┘    │
    └────────────────────────────────────────────────────────┘
```

### Component Communication

```
Client ──[TCP/3724]──> Realmd ──[MySQL]──> LoginDB
                          │
                          └──> Returns realm list

Client ──[TCP/8085]──> Mangosd ──[MySQL]──> WorldDB
                          │                  CharacterDB
                          │                  LoginDB (realm info)
                          │
                          └──> Game Logic Processing
                                   │
                                   ├──> AI Systems
                                   ├──> Combat Systems
                                   ├──> Quest Systems
                                   ├──> Social Systems
                                   └──> Event Systems
```

## Core Components

### 1. Realmd (Authentication Server)

**Location**: `src/realmd/`

**Purpose**: Handles player authentication and realm listing

**Responsibilities**:
- Player login authentication (SRP6 protocol)
- Account security validation
- Realm list management
- Session token generation
- Wrong password protection

**Key Classes**:
- `AuthSocket`: Manages client authentication connections
- `RealmList`: Maintains available realms
- `PatchHandler`: Handles client patching (if enabled)

**Configuration**: `realmd.conf`

**Default Port**: 3724

### 2. Mangosd (World Server)

**Location**: `src/mangosd/`

**Purpose**: Core game server handling all world simulation

**Responsibilities**:
- World state management
- Player character handling
- NPC AI and behavior
- Combat calculations
- Quest progression
- Loot generation
- Instance management
- Guild/group systems
- Chat and social features

**Key Classes**:
- `World`: Global world state manager
- `MapManager`: Manages all game maps
- `ObjectMgr`: Object registry and factory
- `ScriptMgr`: Script system manager

**Configuration**: `mangosd.conf`, `ahbot.conf`, `playerbot.conf`

**Default Ports**:
- 8085: Game traffic
- 7878: SOAP remote access (optional)

### 3. Game Library

**Location**: `src/game/`

The game library contains 45+ specialized modules:

#### Core Systems

| Module | Purpose | Location |
|--------|---------|----------|
| **World** | Global world state, time, weather | `src/game/World/` |
| **Maps** | Map loading, grid management | `src/game/Maps/` |
| **Entities** | Players, creatures, gameobjects | `src/game/Entities/` |
| **Movement** | Motion generation, pathfinding | `src/game/Movement/` |
| **Grids** | Dynamic grid loading/unloading | `src/game/Grids/` |

#### Combat & Skills

| Module | Purpose |
|--------|---------|
| **Combat** | Melee/ranged combat calculations |
| **Spells** | Spell casting, auras, effects |
| **Skills** | Skill progression, professions |
| **Loot** | Drop tables, loot generation |

#### Content Systems

| Module | Purpose |
|--------|---------|
| **Quests** | Quest tracking, objectives |
| **BattleGround** | PvP battlegrounds (WSG, AB, etc.) |
| **Arena** | Arena system (2v2, 3v3, 5v5) |
| **Dungeons** | Instance management |
| **Raids** | Raid encounters |
| **Achievements** | Achievement system |

#### Social Systems

| Module | Purpose |
|--------|---------|
| **Groups** | Party management |
| **Guilds** | Guild system |
| **Social** | Friends, ignore lists |
| **Chat** | Chat channels, commands |
| **Mail** | In-game mail system |

#### Economy

| Module | Purpose |
|--------|---------|
| **AuctionHouse** | Auction house system |
| **Trade** | Player-to-player trading |
| **Vendors** | NPC vendor interactions |

#### AI & Automation

| Module | Purpose |
|--------|---------|
| **AI** | Creature AI framework |
| **PlayerBot** | Automated player bots (optional) |
| **AuctionHouseBot** | AH population bot (optional) |

#### Advanced Systems

| Module | Purpose |
|--------|---------|
| **AntiCheat** | Cheat detection |
| **Metrics** | Grafana metrics export |
| **VoiceChat** | Voice communication (experimental) |

### 4. Shared Libraries

**Location**: `src/shared/`

Common utilities shared across all components:

- **Auth**: SRP6 authentication, cryptography
- **Config**: Configuration file parsing
- **Database**: MySQL/PostgreSQL/SQLite abstraction
- **Log**: Logging framework
- **Network**: Network socket handling
- **Threading**: Multi-threading utilities
- **Platform**: OS-specific abstractions

### 5. Framework

**Location**: `src/framework/`

Core framework providing:

- **Grid System**: Spatial partitioning for game world
- **Object Registry**: Fast object lookup and management
- **Policies**: Design pattern implementations
- **Callbacks**: Event callback system

### 6. Dependencies

**Location**: `dep/`

Bundled third-party libraries:

- **g3dlite**: 3D math library (vectors, matrices, quaternions)
- **recastnavigation**: Pathfinding and navigation meshes
- **libmpq**: MPQ archive reading (WoW data files)
- **gsoap**: SOAP protocol (remote admin)
- **bzip2**: Compression
- **utf8cpp**: UTF-8 string handling
- **json**: JSON parsing

## Data Flow

### Player Login Flow

```
1. Client connects to Realmd (port 3724)
   ↓
2. Realmd validates credentials against LoginDB
   ↓
3. Realmd sends realm list to client
   ↓
4. Client selects realm and receives session token
   ↓
5. Client disconnects from Realmd
   ↓
6. Client connects to Mangosd (port 8085) with token
   ↓
7. Mangosd validates token with LoginDB
   ↓
8. Mangosd loads character data from CharacterDB
   ↓
9. Mangosd loads world data from WorldDB
   ↓
10. Client enters game world
```

### Game Update Loop

```
┌─────────────────────────────────────┐
│      Mangosd Main Loop              │
│  (runs continuously, ~100ms/tick)   │
└──────────────┬──────────────────────┘
               │
               ▼
      ┌────────────────┐
      │ Update Timer   │
      └────────┬───────┘
               │
               ├──> Update World State
               │     ├─> Weather
               │     ├─> Time
               │     └─> Global Events
               │
               ├──> Update All Maps
               │     └─> For each active map:
               │          ├─> Update Grids
               │          ├─> Update Players
               │          ├─> Update Creatures
               │          └─> Update GameObjects
               │
               ├──> Update Sessions
               │     └─> Process player packets
               │          ├─> Movement
               │          ├─> Combat
               │          ├─> Chat
               │          └─> Other actions
               │
               ├──> Update Database
               │     └─> Commit async transactions
               │
               └──> Send Updates to Clients
                     └─> Object updates, chat, etc.
```

## Directory Structure

```
my-mangos-wotlk/
├── CMakeLists.txt          # Root build configuration
├── Dockerfile              # Multi-stage Docker build
├── docker-compose.yml      # Docker Compose for Linux/ARM
├── .env.example            # Environment variables template
│
├── src/                    # Source code
│   ├── realmd/            # Authentication server
│   ├── mangosd/           # World server
│   ├── game/              # Game library (45+ modules)
│   ├── shared/            # Shared utilities
│   └── framework/         # Core framework
│
├── dep/                    # Dependencies
│   ├── g3dlite/
│   ├── recastnavigation/
│   ├── libmpq/
│   └── ...
│
├── sql/                    # Database schemas
│   ├── base/              # Base schemas
│   │   ├── mangos/        # World database
│   │   ├── realmd/        # Auth database
│   │   └── characters/    # Character database
│   └── updates/           # Incremental updates
│
├── contrib/                # Utility tools
│   ├── extractor/         # Data extraction tools
│   ├── vmap_extractor/    # Visual map extractor
│   └── mmap/              # Movement map generator
│
├── cmake/                  # CMake modules
│   └── options.cmake      # Build options
│
├── docker/                 # Docker deployment files
│   ├── build.sh           # Multi-arch build script
│   ├── deploy.sh          # Deployment script
│   ├── configs/           # Server configurations
│   └── init-databases.sh  # DB initialization
│
├── k8s/                    # Kubernetes manifests
│   ├── namespace.yaml
│   ├── secrets.yaml
│   ├── configmap.yaml
│   ├── mysql-statefulset.yaml
│   ├── realmd-deployment.yaml
│   ├── mangosd-deployment.yaml
│   └── deploy-k3s.sh      # K3s deployment script
│
└── docs/                   # Documentation
    ├── ARCHITECTURE.md     # This file
    ├── MODULES.md          # Module reference
    ├── DOCKER_DEPLOYMENT.md
    └── K8S_DEPLOYMENT.md
```

## Build System

### CMake Configuration

**Root**: `CMakeLists.txt`

**Key Options** (defined in `cmake/options.cmake`):

```cmake
CMAKE_INSTALL_PREFIX        # Installation directory
DEBUG                       # Enable debug code
PCH                        # Precompiled headers (ON by default)
BUILD_GAME_SERVER          # Build mangosd (ON)
BUILD_LOGIN_SERVER         # Build realmd (ON)
BUILD_SCRIPTDEV            # Script library (ON)
BUILD_PLAYERBOTS           # PlayerBot module (OFF)
BUILD_AHBOT                # Auction House Bot (OFF)
BUILD_METRICS              # Grafana metrics (OFF)
```

### Build Process

```bash
# Standard build
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
make install

# Docker build (automated)
docker build --target mangosd -t mangos-wotlk:mangosd .
```

### Multi-Architecture Support

The project supports:
- **AMD64** (x86_64): Standard Intel/AMD processors
- **ARM64** (aarch64): ARM processors (Raspberry Pi 5, Apple Silicon)

Docker builds use buildx for multi-platform support:
```bash
docker buildx build --platform linux/amd64,linux/arm64 .
```

## Database Schema

### Three Database System

#### 1. Realmd Database (Authentication)

**Tables**:
- `account`: Player accounts
- `realmlist`: Available realms
- `realmcharacters`: Character counts per realm
- `account_banned`: Ban records
- `ip_banned`: IP bans

#### 2. Mangos Database (World Data)

**Categories**:
- **Creatures**: `creature_template`, `creature`, `creature_loot_template`
- **Items**: `item_template`, `gameobject_template`
- **Quests**: `quest_template`, `quest_relations`
- **Spells**: `spell_template`, `spell_area`
- **Loot**: Various `*_loot_template` tables
- **Scripts**: `dbscripts_on_*` tables
- **Game Events**: `game_event`, `game_event_creature`

**Approximate Size**: 200+ tables

#### 3. Characters Database (Player Data)

**Tables**:
- `characters`: Player character data
- `character_inventory`: Inventory items
- `character_skills`: Skill levels
- `character_spell`: Known spells
- `character_reputation`: Faction standings
- `guild`: Guild data
- `arena_team`: Arena teams
- `mail`: Player mail

### Database Connections

Each component uses multiple connection pools:

- **Realmd**: 1 connection to LoginDB
- **Mangosd**:
  - 1-2 connections to LoginDB (realm info)
  - 2-4 connections to WorldDB (game data)
  - 1-2 connections to CharacterDB (player data)

Connections are configurable via `*DatabaseConnections` settings.

## Performance Characteristics

### Threading Model

- **Main Thread**: World update loop
- **Network Threads**: Packet handling (configurable)
- **Database Threads**: Async queries per database
- **Map Threads**: Optional per-map threading

### Memory Usage

Typical memory footprint:

- **Realmd**: 50-100 MB
- **Mangosd** (no players): 500MB - 1GB
- **Mangosd** (100 players): 2-4 GB
- **MySQL**: 512MB - 2GB

### Scalability

- **Single Realm**: 100-500 concurrent players (depends on hardware)
- **Grid System**: Dynamic loading reduces memory for large worlds
- **Instancing**: Separate map copies for dungeons/raids

## Extension Points

### 1. ScriptDev2 (SD2)

Custom C++ scripts for:
- Boss encounters
- Special NPCs
- Quest events
- World events

**Location**: `src/game/AI/ScriptDevAI/`

### 2. Database Scripts

SQL-based scripting:
- `dbscripts_on_creature_death`
- `dbscripts_on_go_use`
- `dbscripts_on_quest_start`
- `dbscripts_on_spell`

### 3. Optional Modules

- **PlayerBot**: AI-controlled player bots
- **AuctionHouseBot**: Auto-populate auction house
- **AntiCheat**: Movement/speed hack detection
- **Metrics**: Prometheus/Grafana integration

## See Also

- [Module Reference](MODULES.md) - Detailed module documentation
- [Docker Deployment](DOCKER_DEPLOYMENT.md) - Docker setup guide
- [K8s Deployment](K8S_DEPLOYMENT.md) - Kubernetes guide
- [MaNGOS Project](https://getmangos.eu/) - Official website
