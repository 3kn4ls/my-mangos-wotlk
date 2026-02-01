# C(ontinued)-MaNGOS -- README
[![Windows](../../actions/workflows/windows.yml/badge.svg)](../../actions/workflows/windows.yml) [![Ubuntu](../../actions/workflows/ubuntu.yml/badge.svg)](../../actions/workflows/ubuntu.yml) [![MacOS](../../actions/workflows/macos.yml/badge.svg)](../../actions/workflows/macos.yml)

This file is part of the CMaNGOS Project. See [AUTHORS](AUTHORS.md) and [COPYRIGHT](COPYRIGHT.md) files for Copyright information

## Welcome to C(ontinued)-MaNGOS

CMaNGOS is a free project with the following goal:

  **Doing Emulation Right!**

This means, we want to focus on:

* Doing
  * This project is focused on developing software!
  * Also there are many other aspects that need to be done and are
    considered equally important.
  * Anyone who wants to do stuff is very welcome to do so!

* Emulation
  * This project is about developing a server software that is able to
    emulate a well known MMORPG service.

* Right
  * Our goal must always be to provide the best code that we can.
  * Being 'right' is defined by the behaviour of the system
    we want to emulate.
  * Developing things right also includes documenting and discussing
    _how_ to do things better, hence...
  * Learning and teaching are very important in our view, and must
    always be a part of what we do.

To be able to accomplish these goals, we support and promote:

* Freedom
  * of our work: Our work - including our code - is released under the GPL.
    So everybody is free to use and contribute to this open source project.
  * for our developers and contributors on things that interest them.
    No one here is telling anybody _what_ to do.
    If you want somebody to do something for you, pay them,
    but we are here to enjoy.
  * to have FUN with developing.

* A friendly environment
  * We try to leave personal issues behind us.
  * We only argue about content and not about thin air!
  * We follow the [Netiquette](http://tools.ietf.org/html/rfc1855).

-- The C(ontinued)-MaNGOS Team!

---

## 🚀 Quick Start - Docker & Kubernetes Deployment

This repository now includes **production-ready containerized deployment** options with comprehensive documentation:

### Choose Your Platform

#### 🪟 [Windows 11](docs/QUICKSTART_WINDOWS.md)
Complete step-by-step guide for Docker Desktop on Windows with WSL2
- **Time to deploy**: 1-2 hours
- **Best for**: Development, testing, personal servers
- **Difficulty**: Beginner-friendly

#### 🥧 [Raspberry Pi 5](docs/QUICKSTART_RASPBERRY_PI.md)
Optimized deployment for ARM64 (Raspberry Pi 5, 8GB recommended)
- **Time to deploy**: 2-3 hours (ARM builds are slower)
- **Capacity**: 10-50 concurrent players
- **Best for**: Home servers, low-power deployments
- **Difficulty**: Intermediate

#### ☸️ [K3s (Kubernetes)](docs/QUICKSTART_K3S.md)
Production-ready Kubernetes cluster deployment
- **Time to deploy**: 1-2 hours
- **Best for**: Production, high availability, scalability
- **Features**: Auto-scaling, self-healing, load balancing
- **Difficulty**: Advanced

### 📦 What's Included

✅ **Multi-architecture Docker images** (AMD64, ARM64)
✅ **Docker Compose** for Linux, Windows, Raspberry Pi
✅ **Kubernetes/K3s** manifests with automated deployment
✅ **Persistent storage** configuration
✅ **Health checks** and auto-restart
✅ **Comprehensive documentation** (56KB+ of guides)

### 📚 Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Overview of all deployment options
- **[docs/](docs/)** - Complete documentation index
  - [Architecture](docs/ARCHITECTURE.md) - System architecture overview
  - [Modules](docs/MODULES.md) - Detailed module reference (45+ modules)
  - [Docker Guide](docs/DOCKER_DEPLOYMENT.md) - Advanced Docker deployment
  - [K8s Guide](docs/K8S_DEPLOYMENT.md) - Kubernetes deployment details

### ⚡ Quick Deploy (Example)

**Docker on Linux/Raspberry Pi:**
```bash
# Configure environment
cp .env.example .env
nano .env  # Edit passwords and settings

# Build and deploy
cd docker
./build.sh
./deploy.sh up
```

**K3s Cluster:**
```bash
# Install K3s
curl -sfL https://get.k3s.io | sh -

# Deploy MaNGOS
cd k8s
./deploy-k3s.sh deploy
```

**Docker on Windows:**
```powershell
# Configure environment
Copy-Item .env.example .env
notepad .env  # Edit passwords and settings

# Build and deploy
cd docker
.\build.ps1
.\deploy.ps1 up
```

### 🎯 Traditional Installation

For traditional build-from-source installation, see:
- [Installation Wiki](https://github.com/cmangos/issues/wiki)
- [Contributing Guidelines](CONTRIBUTING.md)

---

## Further information

  You can find further information about CMaNGOS at the following places:
  * [CMaNGOS Discord](https://discord.gg/Dgzerzb)
  * [GitHub repositories](https://github.com/cmangos/)
  * [Issue tracker](https://github.com/cmangos/issues/issues)
  * [Pull Requests](https://github.com/cmangos/mangos-wotlk/pulls)
  * [Wiki](https://github.com/cmangos/issues/wiki) with additional information on installation
  * [Contributing Guidelines](CONTRIBUTING.md)
  * Documentation can be found in the doc/ subdirectory and on the GitHub wiki

## License

  CMaNGOS is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


  You can find the full license text in the file [COPYING](COPYING) delivered with this package.

### Exceptions to GPL

  World of Warcraft® ©2004 Blizzard Entertainment, Inc. All rights reserved.
  World of Warcraft® content and materials mentioned or referenced are copyrighted by
  Blizzard Entertainment, Inc. or its licensors.
  World of Warcraft, WoW, Warcraft, The Frozen Throne, The Burning Crusade, Wrath of the Lich King,
  Cataclysm, Mists of Pandaria, Ashbringer, Dark Portal, Darkmoon Faire, Frostmourne, Onyxia's Lair,
  Diablo, Hearthstone, Heroes of Azeroth, Reaper of Souls, Starcraft, Battle Net, Blizzcon, Glider,
  Blizzard and Blizzard Entertainment are trademarks or registered trademarks of
  Blizzard Entertainment, Inc. in the U.S. and/or other countries.

  Any World of Warcraft® content and materials mentioned or referenced are copyrighted by
  Blizzard Entertainment, Inc. or its licensors.
  CMaNGOS project is not affiliated with Blizzard Entertainment, Inc. or its licensors.

  Some third-party libraries CMaNGOS uses have other licenses, that must be
  upheld.  These libraries are located within the dep/ directory

  In addition, as a special exception, the CMaNGOS project
  gives permission to link the code of its release of MaNGOS with the
  OpenSSL project's "OpenSSL" library (or with modified versions of it
  that use the same license as the "OpenSSL" library), and distribute
  the linked executables.  You must obey the GNU General Public License
  in all respects for all of the code used other than "OpenSSL".  If you
  modify this file, you may extend this exception to your version of the
  file, but you are not obligated to do so.  If you do not wish to do
  so, delete this exception statement from your version.
