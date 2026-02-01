# MaNGOS WotLK - Module Reference

Complete reference guide for all modules in the MaNGOS WotLK project.

## Table of Contents

- [Core Modules](#core-modules)
- [Game Logic Modules](#game-logic-modules)
- [Content Systems](#content-systems)
- [Social Systems](#social-systems)
- [Optional Modules](#optional-modules)
- [Shared Libraries](#shared-libraries)

## Core Modules

### World (`src/game/World/`)

**Purpose**: Global world state management

**Key Components**:
- `World.cpp/h`: Main world singleton managing global state
- `WorldState.cpp/h`: World state variables and conditions
- `Weather.cpp/h`: Weather system for different zones
- `WorldSocket.cpp/h`: Client socket handling

**Responsibilities**:
- Server tick management (~100ms updates)
- Global time and calendar
- Weather simulation
- Server uptime tracking
- Player session management
- Configuration loading

**Configuration Keys**:
- `WorldServerPort`: Server port (default: 8085)
- `MapUpdateInterval`: Update frequency in ms
- `Motd`: Message of the day

---

### Maps (`src/game/Maps/`)

**Purpose**: Map loading and grid management

**Key Components**:
- `Map.cpp/h`: Base map class
- `MapManager.cpp/h`: Manages all active maps
- `MapPersistentStateMgr.cpp/h`: Persistent instance states
- `GridMap.cpp/h`: Terrain height maps
- `InstanceData.cpp/h`: Instance-specific data

**Map Types**:
- **Normal Maps**: Azeroth, Kalimdor, Outland, Northrend
- **Instance Maps**: Dungeons, raids
- **Battleground Maps**: PvP instances

**Grid System**:
- 64x64 grids per map
- Dynamic loading/unloading
- ~533 yards per grid
- Visibility ranges: 333 yards (ground), 533 yards (flying)

---

### Entities (`src/game/Entities/`)

**Purpose**: Game object representations

**Entity Hierarchy**:
```
Object
├── WorldObject
│   ├── Unit
│   │   ├── Creature
│   │   ├── Pet
│   │   └── Player
│   ├── GameObject
│   ├── DynamicObject
│   └── Corpse
└── Item
```

**Key Classes**:
- `Player.cpp/h`: Player character (3000+ lines)
- `Creature.cpp/h`: NPCs and monsters
- `GameObject.cpp/h`: Interactive objects
- `Unit.cpp/h`: Base combat entity
- `Item.cpp/h`: Inventory items

---

### Movement (`src/game/Movement/`)

**Purpose**: Motion generation and pathfinding

**Components**:
- `MotionMaster.cpp/h`: Movement state machine
- `MoveSpline.cpp/h`: Smooth spline-based movement
- `PathFinder.cpp/h`: A* pathfinding
- `Waypoint Manager.cpp/h`: NPC patrol paths

**Movement Types**:
- Idle, Random, Waypoint
- Chase, Flee, Follow
- Point, Home, Spline
- Flight paths

**Integration**:
- Uses Recast/Detour for navmesh pathfinding
- Supports water, air, and ground movement
- Anti-cheat movement validation

---

## Game Logic Modules

### Combat (`src/game/Combat/`)

**Purpose**: Combat calculations and damage

**Components**:
- `ThreatManager.cpp/h`: Aggro/threat management
- `HostileRefManager.cpp/h`: Enemy tracking
- `CombatManager.cpp/h`: Combat state

**Damage Types**:
- Physical (melee, ranged)
- Spell damage
- Environmental (fall, lava, drowning)

**Combat Mechanics**:
- Hit/miss/dodge/parry/block calculations
- Critical strikes
- Armor mitigation
- Resistance calculations

---

### Spells (`src/game/Spells/`)

**Purpose**: Spell casting and effects

**Key Components**:
- `Spell.cpp/h`: Main spell class (4000+ lines)
- `SpellAuras.cpp/h`: Aura (buff/debuff) system
- `SpellEffects.cpp/h`: Individual spell effects
- `SpellMgr.cpp/h`: Spell template manager

**Spell System**:
- 100+ spell effects (damage, heal, summon, teleport, etc.)
- Aura stacking rules
- Spell targeting (single, AOE, cone, chain)
- Cast time, cooldowns, GCD
- Power costs (mana, rage, energy, runes)

**Script Hooks**:
- `OnCast`, `OnHit`, `OnEffect`
- Spell-specific scripts in ScriptDev

---

### Skills (`src/game/Skills/`)

**Purpose**: Character skill progression

**Skill Types**:
- **Weapon Skills**: Swords, Axes, Maces, etc.
- **Professions**: Mining, Herbalism, Alchemy, etc.
- **Secondary**: Cooking, Fishing, First Aid
- **Class Skills**: Depends on class

**Progression**:
- Skill points (1-450 in WotLK)
- Skill difficulty (grey, green, yellow, orange)
- Skill-up chance based on difficulty

---

### Quests (`src/game/Quests/`)

**Purpose**: Quest system

**Components**:
- `QuestDef.cpp/h`: Quest definitions
- `QuestHandler.cpp/h`: Client packet handlers

**Quest Types**:
- Kill quests
- Collection quests
- Exploration/discovery
- Escort quests
- Delivery quests

**Quest Chains**:
- Prerequisites
- Exclusivity groups
- Reputation requirements
- Level requirements

---

### Loot (`src/game/Loot/`)

**Purpose**: Loot generation and distribution

**Components**:
- `LootMgr.cpp/h`: Loot table manager
- `LootHandler.cpp/h`: Loot packet handling

**Loot Sources**:
- Creatures (regular, elite, boss)
- Gameobjects (chests, herbs, ore)
- Fishing
- Disenchanting, Milling, Prospecting

**Loot Distribution**:
- Free-for-all
- Round robin
- Master loot
- Group loot (need/greed)

---

## Content Systems

### BattleGround (`src/game/BattleGround/`)

**Purpose**: PvP battleground system

**Supported Battlegrounds**:
- **Warsong Gulch** (WSG): Capture the flag
- **Arathi Basin** (AB): Resource control
- **Alterac Valley** (AV): Large-scale PvP
- **Eye of the Storm** (EOTS): Flag + resource hybrid
- **Strand of the Ancients** (SOTA): Siege warfare
- **Isle of Conquest** (IOC): Large-scale siege

**Components**:
- `BattleGround.cpp/h`: Base BG class
- `BattleGroundMgr.cpp/h`: BG queue and matchmaking
- `BattleGroundAV.cpp/h`, `BattleGroundWS.cpp/h`, etc.: Specific BGs

**Features**:
- Queue system with level brackets
- Team balancing
- Honor points rewards
- Scoreboards and statistics

---

### Arena (`src/game/Arena/`)

**Purpose**: Arena PvP system

**Arena Types**:
- 2v2, 3v3, 5v5

**Components**:
- `ArenaTeam.cpp/h`: Team management
- Arena point calculation
- Rating system (similar to Elo)

**Arenas**:
- Blade's Edge Arena
- Nagrand Arena
- Ruins of Lordaeron
- Dalaran Sewers
- Ring of Valor

---

### Achievements (`src/game/Achievements/`)

**Purpose**: Achievement system (introduced in WotLK)

**Components**:
- `AchievementMgr.cpp/h`: Achievement tracking

**Achievement Types**:
- Kills, deaths
- Quest completion
- Exploration
- Reputation
- Dungeons/raids
- Professions
- World events

**Features**:
- Progress tracking
- Criteria updates
- Title rewards
- Mount rewards

---

### OutdoorPvP (`src/game/OutdoorPvP/`)

**Purpose**: World PvP objectives

**Zones**:
- Wintergrasp (WotLK)
- Hellfire Peninsula
- Zangarmarsh
- Terokkar Forest
- Nagrand
- Silithus (legacy)
- Eastern Plaguelands (legacy)

**Components**:
- `OutdoorPvP.cpp/h`: Base class
- `OutdoorPvPWG.cpp/h`: Wintergrasp
- Zone-specific implementations

---

## Social Systems

### Groups (`src/game/Groups/`)

**Purpose**: Party management

**Components**:
- `Group.cpp/h`: Group management
- `GroupHandler.cpp/h`: Packet handlers

**Features**:
- 5-player parties
- Raid groups (up to 40 players)
- Loot distribution settings
- Role assignment (tank, healer, DPS)
- Ready checks
- Group leader controls

---

### Guilds (`src/game/Guilds/`)

**Purpose**: Guild system

**Components**:
- `Guild.cpp/h`: Guild management
- `GuildHandler.cpp/h`: Packet handlers

**Features**:
- Ranks and permissions
- Guild bank (7 tabs)
- Message of the day
- Guild info
- Member notes
- Promotion/demotion

---

### Social (`src/game/Social/`)

**Purpose**: Friends and ignore lists

**Components**:
- `SocialMgr.cpp/h`: Social relationships

**Features**:
- Friend list
- Ignore list
- Online status
- Cross-faction restrictions

---

### Chat (`src/game/Chat/`)

**Purpose**: Chat system and GM commands

**Components**:
- `Chat.cpp/h`: Chat handler
- `ChatHandler.cpp/h`: GM commands
- `Channel.cpp/h`: Chat channels

**Chat Types**:
- Say (local)
- Yell (wide range)
- Whisper (private)
- Party, Raid, Guild
- General, Trade, LocalDefense channels

**GM Commands** (300+ commands):
- `.help` - Command list
- `.gm on/off` - GM mode
- `.ticket` - Ticket management
- `.teleport` - Teleportation
- `.modify` - Character modification
- `.npc` - NPC manipulation
- `.go` - Navigation commands

---

### Mail (`src/game/Mails/`)

**Purpose**: In-game mail system

**Components**:
- `Mail.cpp/h`: Mail management

**Features**:
- Item attachments
- Gold transfers
- Auction house mail
- System mail (from NPCs)
- 30-day retention
- COD (Cash on Delivery)

---

## Optional Modules

### PlayerBot (`src/game/PlayerBot/`)

**Purpose**: AI-controlled player characters

**Features**:
- Automated questing
- Combat AI (class-specific)
- Random bots to populate server
- Following player masters
- Guild participation
- Battleground participation

**Configuration**: `playerbot.conf`

**Use Cases**:
- Testing
- Single-player mode
- Server population

---

### AuctionHouseBot (`src/game/AuctionHouseBot/`)

**Purpose**: Automated auction house population

**Components**:
- `AuctionHouseBot.cpp/h`: Main bot logic

**Features**:
- Auto-buy underpriced items
- Auto-sell items by quality/class
- Configurable ratios per faction
- Price calculations

**Configuration**: `ahbot.conf`

---

### Anticheat (`src/game/Anticheat/`)

**Purpose**: Cheat detection

**Detections**:
- Speed hacking
- Teleport hacking
- Fly hacking
- Walk on water
- Climb hacking
- Exploration exploits

**Actions**:
- Logging
- Warnings
- Kicks
- Automatic bans

**Configuration**: `anticheat.conf`

---

### Metrics (`src/game/Metrics/`)

**Purpose**: Prometheus/Grafana metrics export

**Metrics**:
- Online players
- Database query times
- Update loop performance
- Memory usage
- Creature/gameobject counts

**Integration**:
- Prometheus exporter
- Grafana dashboards
- Real-time monitoring

---

## Shared Libraries

### Database (`src/shared/Database/`)

**Purpose**: Database abstraction layer

**Supported Databases**:
- MySQL/MariaDB (primary)
- PostgreSQL
- SQLite (experimental)

**Components**:
- `Database.cpp/h`: Base database class
- `DatabaseMysql.cpp/h`: MySQL implementation
- `QueryResult.cpp/h`: Query result handling

**Features**:
- Connection pooling
- Async queries
- Prepared statements
- Transaction support

---

### Network (`src/shared/Network/`)

**Purpose**: Network socket handling

**Components**:
- `Socket.cpp/h`: Base socket class
- `SocketHandler.cpp/h`: Socket event loop

**Features**:
- Asynchronous I/O
- Packet encryption (after auth)
- Connection pooling
- Rate limiting

---

### Auth (`src/shared/Auth/`)

**Purpose**: Authentication cryptography

**Components**:
- `Sha1.cpp/h`: SHA-1 hashing
- `BigNumber.cpp/h`: Large number arithmetic
- `HMAC.cpp/h`: HMAC calculation

**Protocol**:
- SRP6 (Secure Remote Password)
- Session key generation
- Packet encryption keys

---

### Config (`src/shared/Config/`)

**Purpose**: Configuration file parsing

**Components**:
- `Config.cpp/h`: INI-style config parser

**Features**:
- Key-value pairs
- Environment variable overrides
- Default values
- Type conversion (int, float, string, bool)

**Environment Override Pattern**:
```
Config: Rate.XP.Kill = 1.0
Env: Mangosd_Rate_XP_Kill=2.0
Result: 2.0 (env override)
```

---

### Log (`src/shared/Log/`)

**Purpose**: Logging framework

**Components**:
- `Log.cpp/h`: Main logging class

**Log Levels**:
- 0: Minimal
- 1: Error
- 2: Detail
- 3: Full/Debug

**Outputs**:
- Console (with colors)
- File
- Database (optional)

**Filters**:
- Creature moves
- Transport moves
- Visibility changes
- Weather
- DB strict checks

---

## Module Dependencies

### Dependency Graph

```
World
 ├─> MapManager
 │    ├─> Map
 │    │    ├─> GridLoader
 │    │    └─> ObjectMgr
 │    └─> InstanceSaveMgr
 ├─> ObjectMgr (central registry)
 │    ├─> Creature/Player/GameObject templates
 │    └─> Quest/Spell/Item definitions
 ├─> ScriptMgr
 ├─> AccountMgr
 └─> BattleGroundMgr

Player
 ├─> Unit (combat, spells)
 ├─> Object (base entity)
 ├─> Inventory (items, bags)
 ├─> QuestStatus
 ├─> ReputationMgr
 ├─> AchievementMgr
 ├─> Group
 ├─> Guild
 └─> Social
```

## Performance Notes

### Hot Paths

Most performance-critical modules:

1. **World Update Loop**: Runs every ~100ms
2. **Map Updates**: Per-map entity updates
3. **Spell System**: Complex calculations
4. **Pathfinding**: CPU-intensive
5. **Database Queries**: I/O bound

### Optimization Tips

- Enable PCH (Precompiled Headers)
- Use `GridUnload = 1` to free memory
- Tune `*DatabaseConnections` for your load
- Use `LoadAllGridsOnMaps = ""` (empty) unless you have lots of RAM
- Adjust `MapUpdateInterval` for tick rate

---

## AI Reference

This document covers game modules. For details about agent architecture and task planning, see:
- [Architecture Documentation](ARCHITECTURE.md)
- [Deployment Guide](../DEPLOYMENT.md)

## Contributing

When extending modules:

1. Follow existing code style
2. Add appropriate comments
3. Update this documentation
4. Add unit tests if possible
5. Use ScriptDev for content-specific logic (don't modify core)

## See Also

- [Architecture](ARCHITECTURE.md)
- [Docker Deployment](DOCKER_DEPLOYMENT.md)
- [K8s Deployment](K8S_DEPLOYMENT.md)
- [CMaNGOS Wiki](https://github.com/cmangos/issues/wiki)
