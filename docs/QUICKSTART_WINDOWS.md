# Guía de Inicio Rápido - Windows 11

Esta guía te llevará paso a paso para instalar y ejecutar MaNGOS WotLK en Windows 11 usando Docker Desktop.

## 📋 Requisitos Previos

### Hardware Mínimo
- CPU: 4 núcleos (Intel i5/i7 o AMD Ryzen)
- RAM: 8 GB (16 GB recomendado)
- Disco: 50 GB libres en SSD
- Conexión a Internet

### Software Requerido

#### 1. Windows 11 Pro, Enterprise o Education
- **Versión**: 21H2 o superior
- **Build**: 22000 o superior
- Verifica tu versión: `Win + R` → `winver`

#### 2. WSL2 (Windows Subsystem for Linux 2)

**Instalación de WSL2:**

```powershell
# Abrir PowerShell como Administrador
wsl --install

# Reiniciar el PC cuando se solicite

# Después del reinicio, verificar
wsl --status
```

**Configurar WSL2 como predeterminado:**

```powershell
wsl --set-default-version 2
```

#### 3. Docker Desktop para Windows

**Descargar e instalar:**

1. Ir a: https://www.docker.com/products/docker-desktop
2. Descargar "Docker Desktop for Windows"
3. Ejecutar el instalador
4. **Importante**: Marcar "Use WSL 2 instead of Hyper-V"
5. Reiniciar el PC

**Verificar instalación:**

```powershell
docker --version
docker-compose --version
```

Deberías ver algo como:
```
Docker version 24.0.x
Docker Compose version v2.x.x
```

## 🚀 Instalación de MaNGOS WotLK

### Paso 1: Obtener el Código

**Opción A: Clonar desde Git**

```powershell
# Abrir PowerShell o Terminal de Windows
cd C:\
mkdir Proyectos
cd Proyectos

git clone https://github.com/tu-usuario/my-mangos-wotlk.git
cd my-mangos-wotlk
```

**Opción B: Descargar ZIP**

1. Ir al repositorio en GitHub
2. Click en "Code" → "Download ZIP"
3. Extraer en `C:\Proyectos\my-mangos-wotlk`

### Paso 2: Configurar Variables de Entorno

```powershell
# Copiar el archivo de ejemplo
Copy-Item .env.example .env

# Editar con Notepad
notepad .env
```

**Configuración recomendada para Windows:**

```env
# Zona horaria (ajustar a tu ubicación)
TZ=Europe/Madrid

# Contraseñas (CAMBIAR ESTAS)
MYSQL_ROOT_PASSWORD=TuPasswordSeguro2024!
MYSQL_USER=mangos
MYSQL_PASSWORD=MangosPassword2024!
MYSQL_DATABASE=mangos
MYSQL_PORT=3306

# Bases de datos
REALMD_DB=realmd
WORLD_DB=mangos
CHARACTER_DB=characters

# Puertos del servidor
REALMD_PORT=3724
MANGOSD_PORT=8085
SOAP_PORT=7878
REALM_ID=1

# phpMyAdmin (opcional)
PHPMYADMIN_PORT=8080

# Configuración de build
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1
```

**Guardar y cerrar** (`Ctrl+S`, luego cerrar Notepad)

### Paso 3: Configurar Docker Desktop

#### Asignar Recursos

1. Abrir Docker Desktop
2. Ir a **Settings** (⚙️)
3. **Resources** → **WSL Integration**
   - Activar integración con tu distribución WSL
4. **Resources** → **Advanced**
   - **CPUs**: 4 (mínimo 2)
   - **Memory**: 8 GB (mínimo 4 GB)
   - **Disk image size**: 50 GB
5. Click **Apply & Restart**

#### Compartir Unidades

1. **Settings** → **Resources** → **File Sharing**
2. Añadir `C:\Proyectos` si no está
3. Click **Apply & Restart**

### Paso 4: Construir las Imágenes Docker

```powershell
# Navegar al directorio del proyecto
cd C:\Proyectos\my-mangos-wotlk

# Ir a la carpeta docker
cd docker

# Ejecutar el script de build (puede tomar 15-30 minutos)
.\build.ps1
```

**Proceso de build:**
```
MaNGOS WotLK - Docker Build Script
================================================
Build configuration:
  Platform: linux/amd64,linux/arm64
  Push to registry: False

Building realmd image...
[+] Building 450.2s
✓ Building realmd image... DONE

Building mangosd image...
[+] Building 680.5s
✓ Building mangosd image... DONE

Building extractors image...
[+] Building 120.1s
✓ Building extractors image... DONE

Build completed successfully!
```

**Verificar imágenes creadas:**

```powershell
docker images | Select-String mangos
```

Deberías ver:
```
mangos-wotlk   realmd      latest   ...   200MB
mangos-wotlk   mangosd     latest   ...   250MB
mangos-wotlk   extractors  latest   ...   180MB
```

### Paso 5: Desplegar los Servicios

```powershell
# Volver al directorio raíz del proyecto
cd ..

# Iniciar todos los servicios
docker-compose -f docker-compose.windows.yml up -d
```

**Salida esperada:**
```
[+] Running 4/4
 ✓ Network my-mangos-wotlk_mangos-network  Created
 ✓ Container mangos-database               Started
 ✓ Container mangos-realmd                 Started
 ✓ Container mangos-mangosd                Started
```

**Verificar que los contenedores estén corriendo:**

```powershell
docker-compose -f docker-compose.windows.yml ps
```

Deberías ver todos los servicios con estado `Up (healthy)`:
```
NAME                STATUS
mangos-database     Up (healthy)
mangos-realmd       Up (healthy)
mangos-mangosd      Up (healthy)
```

### Paso 6: Verificar Logs

**Ver logs de todos los servicios:**

```powershell
docker-compose -f docker-compose.windows.yml logs -f
```

**Ver logs de un servicio específico:**

```powershell
# Realmd
docker-compose -f docker-compose.windows.yml logs -f realmd

# Mangosd
docker-compose -f docker-compose.windows.yml logs -f mangosd

# Base de datos
docker-compose -f docker-compose.windows.yml logs -f database
```

**Salir de los logs:** `Ctrl+C`

## 🗄️ Configuración de Base de Datos

### Paso 1: Importar Esquemas SQL

Los esquemas SQL deben estar en la carpeta `sql/base/` de tu proyecto.

```powershell
# Copiar esquemas al contenedor de base de datos
docker cp sql/base/mangos/. mangos-database:/tmp/mangos/
docker cp sql/base/realmd/. mangos-database:/tmp/realmd/
docker cp sql/base/characters/. mangos-database:/tmp/characters/

# Importar esquemas
docker exec -i mangos-database mysql -u root -pTuPasswordSeguro2024! mangos < sql/base/mangos/mangos.sql
docker exec -i mangos-database mysql -u root -pTuPasswordSeguro2024! realmd < sql/base/realmd/realmd.sql
docker exec -i mangos-database mysql -u root -pTuPasswordSeguro2024! characters < sql/base/characters/characters.sql
```

**Nota:** Reemplaza `TuPasswordSeguro2024!` con tu contraseña de `MYSQL_ROOT_PASSWORD`

### Paso 2: Verificar Bases de Datos

```powershell
# Conectar a MySQL
docker exec -it mangos-database mysql -u root -p

# Dentro de MySQL (contraseña cuando la pida)
SHOW DATABASES;
```

Deberías ver:
```
+--------------------+
| Database           |
+--------------------+
| characters         |
| information_schema |
| mangos             |
| mysql              |
| performance_schema |
| realmd             |
| sys                |
+--------------------+
```

**Salir de MySQL:** `exit`

### Paso 3: Configurar Realm en la Base de Datos

```powershell
docker exec -it mangos-database mysql -u root -p realmd
```

**Dentro de MySQL:**

```sql
-- Verificar si ya existe un realm
SELECT * FROM realmlist;

-- Si está vacío, insertar un nuevo realm
INSERT INTO realmlist (id, name, address, port, icon, realmflags, timezone, allowedSecurityLevel)
VALUES (1, 'Mi Servidor MaNGOS', '127.0.0.1', 8085, 1, 0, 1, 0);

-- Para acceso desde LAN (opcional)
-- Reemplazar 127.0.0.1 con tu IP local (ej: 192.168.1.100)
UPDATE realmlist SET address = '192.168.1.100' WHERE id = 1;

-- Salir
exit
```

## 🎮 Extraer Datos del Cliente de WoW

Para que el servidor funcione, necesitas extraer datos del cliente de WoW 3.3.5a.

### Requisito: Cliente de WoW 3.3.5a

Debes tener una instalación legal de World of Warcraft 3.3.5a.

### Paso 1: Copiar Herramientas de Extracción

```powershell
# Crear carpeta para extractores
mkdir C:\WoW_Extractors
cd C:\WoW_Extractors

# Copiar extractores desde el contenedor
docker cp mangos-extractors:/mangos/tools/. .
```

### Paso 2: Ejecutar Extractores

```powershell
# Navegar a la carpeta del cliente de WoW
cd "C:\Program Files (x86)\World of Warcraft"

# Copiar extractores aquí
Copy-Item C:\WoW_Extractors\*.exe .

# Extraer DBC y Maps (tarda ~10 minutos)
.\map-extractor.exe

# Extraer VMaps (tarda ~30 minutos)
.\vmap-extractor.exe
.\vmap-assembler.exe Buildings vmaps

# Extraer MMaps (tarda VARIAS HORAS - opcional al inicio)
.\mmap-generator.exe
```

### Paso 3: Copiar Datos Extraídos al Servidor

```powershell
# Copiar DBC
docker cp "C:\Program Files (x86)\World of Warcraft\dbc\." mangos-mangosd:/mangos/dbc/

# Copiar Maps
docker cp "C:\Program Files (x86)\World of Warcraft\maps\." mangos-mangosd:/mangos/maps/

# Copiar VMaps
docker cp "C:\Program Files (x86)\World of Warcraft\vmaps\." mangos-mangosd:/mangos/vmaps/

# Copiar MMaps (si los generaste)
docker cp "C:\Program Files (x86)\World of Warcraft\mmaps\." mangos-mangosd:/mangos/mmaps/

# Reiniciar mangosd
docker-compose -f docker-compose.windows.yml restart mangosd
```

## 👤 Crear Cuenta de Administrador (GM)

```powershell
# Acceder a la consola de mangosd
docker exec -it mangos-mangosd /mangos/bin/mangosd

# Dentro de la consola, crear cuenta
account create mi_usuario mi_password

# Establecer nivel GM (3 = Administrador)
account set gmlevel mi_usuario 3

# Salir
Ctrl+C
```

**Alternativa usando MySQL:**

```powershell
docker exec -it mangos-database mysql -u root -p realmd
```

```sql
-- Crear cuenta
INSERT INTO account (username, sha_pass_hash, gmlevel, email)
VALUES ('mi_usuario', SHA1(CONCAT(UPPER('mi_usuario'), ':', UPPER('mi_password'))), 3, 'admin@localhost');

exit
```

## 🌐 Conectar con el Cliente

### Paso 1: Modificar realmlist.wtf

Ubicación: `C:\Program Files (x86)\World of Warcraft\Data\enUS\realmlist.wtf`

```
set realmlist 127.0.0.1
```

Para conectar desde otra PC en la misma red:
```
set realmlist 192.168.1.100
```

### Paso 2: Iniciar el Cliente

1. Ejecutar `Wow.exe`
2. Ingresar credenciales creadas anteriormente
3. Seleccionar el realm
4. ¡Jugar!

## 🛠️ Gestión de Servicios

### Script de Deployment (Recomendado)

```powershell
cd C:\Proyectos\my-mangos-wotlk\docker

# Iniciar servicios
.\deploy.ps1 up

# Ver estado
.\deploy.ps1 status

# Ver logs
.\deploy.ps1 logs

# Reiniciar servicios
.\deploy.ps1 restart

# Detener servicios
.\deploy.ps1 down

# Limpiar todo (¡CUIDADO! Borra datos)
.\deploy.ps1 clean
```

### Comandos Docker Compose Directos

```powershell
cd C:\Proyectos\my-mangos-wotlk

# Iniciar
docker-compose -f docker-compose.windows.yml up -d

# Detener
docker-compose -f docker-compose.windows.yml down

# Reiniciar un servicio
docker-compose -f docker-compose.windows.yml restart mangosd

# Ver logs en tiempo real
docker-compose -f docker-compose.windows.yml logs -f mangosd

# Ver estado
docker-compose -f docker-compose.windows.yml ps
```

## 🔧 Herramientas Opcionales

### phpMyAdmin (Gestión Web de BD)

```powershell
# Iniciar con phpMyAdmin
docker-compose -f docker-compose.windows.yml --profile tools up -d

# Acceder vía navegador
http://localhost:8080

# Credenciales:
# Server: database
# Username: root
# Password: (tu MYSQL_ROOT_PASSWORD)
```

## 🐛 Solución de Problemas

### Problema: "Docker daemon is not running"

**Solución:**
1. Abrir Docker Desktop
2. Esperar a que inicie completamente
3. Verificar que el ícono de Docker en la bandeja del sistema esté verde

### Problema: Contenedor se reinicia constantemente

```powershell
# Ver logs del contenedor problemático
docker logs mangos-mangosd

# Verificar que la base de datos esté lista
docker-compose -f docker-compose.windows.yml ps
```

### Problema: "Port already in use"

```powershell
# Ver qué está usando el puerto
netstat -ano | findstr :3724
netstat -ano | findstr :8085

# Detener el proceso (reemplazar PID)
taskkill /PID <número_pid> /F

# O cambiar el puerto en .env
```

### Problema: Poco espacio en disco

```powershell
# Limpiar imágenes y contenedores no usados
docker system prune -a

# Ver uso de espacio
docker system df
```

### Problema: Rendimiento lento

**Docker Desktop → Settings:**
1. Resources → Advanced
2. Aumentar CPUs y Memory
3. Apply & Restart

### Problema: WSL2 consume mucha RAM

Crear archivo: `C:\Users\TuUsuario\.wslconfig`

```ini
[wsl2]
memory=6GB
processors=4
swap=2GB
```

Reiniciar WSL:
```powershell
wsl --shutdown
```

## 📊 Monitoreo

### Ver Uso de Recursos

```powershell
# Estadísticas en tiempo real
docker stats

# Ver uso de recursos de un contenedor
docker stats mangos-mangosd
```

### Ver Puertos Abiertos

```powershell
netstat -ano | findstr :3724
netstat -ano | findstr :8085
netstat -ano | findstr :3306
```

## 🔒 Seguridad

### Firewall de Windows

```powershell
# Abrir PowerShell como Administrador

# Permitir puerto de Realmd
New-NetFirewallRule -DisplayName "MaNGOS Realmd" -Direction Inbound -LocalPort 3724 -Protocol TCP -Action Allow

# Permitir puerto de Mangosd
New-NetFirewallRule -DisplayName "MaNGOS Mangosd" -Direction Inbound -LocalPort 8085 -Protocol TCP -Action Allow
```

### Cambiar Contraseñas

1. Editar `.env`
2. Cambiar `MYSQL_ROOT_PASSWORD` y `MYSQL_PASSWORD`
3. Reiniciar servicios:

```powershell
docker-compose -f docker-compose.windows.yml down
docker-compose -f docker-compose.windows.yml up -d
```

## 📦 Backup y Restore

### Backup de Base de Datos

```powershell
# Crear carpeta de backups
mkdir C:\MangosBackups

# Backup de todas las bases de datos
docker exec mangos-database mysqldump -u root -pTuPasswordSeguro2024! --all-databases > C:\MangosBackups\backup-$(Get-Date -Format "yyyyMMdd").sql

# Backup de una base específica
docker exec mangos-database mysqldump -u root -pTuPasswordSeguro2024! mangos > C:\MangosBackups\mangos-$(Get-Date -Format "yyyyMMdd").sql
```

### Restore de Base de Datos

```powershell
# Restaurar desde backup
Get-Content C:\MangosBackups\backup-20240124.sql | docker exec -i mangos-database mysql -u root -pTuPasswordSeguro2024!
```

### Backup de Volúmenes Docker

```powershell
# Listar volúmenes
docker volume ls | Select-String mangos

# Backup de volumen MySQL
docker run --rm -v my-mangos-wotlk_mysql_data:/data -v C:\MangosBackups:/backup ubuntu tar czf /backup/mysql-data-$(Get-Date -Format "yyyyMMdd").tar.gz /data
```

## 🚀 Siguiente Nivel

### Acceso desde Internet

1. Configurar port forwarding en tu router:
   - Puerto 3724 → IP de tu PC
   - Puerto 8085 → IP de tu PC
2. Obtener tu IP pública: https://whatismyipaddress.com/
3. Actualizar `realmlist` en la base de datos con tu IP pública

### Optimización de Rendimiento

**En `.env`:**
```env
# Configuración para servidor dedicado
MANGOSD_PLAYER_LIMIT=100
MANGOSD_THREADS=4
```

**En `docker-compose.windows.yml`:**
```yaml
services:
  mangosd:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
```

## 📚 Recursos Adicionales

- **Documentación Completa**: Ver `docs/` en el proyecto
- **Arquitectura**: `docs/ARCHITECTURE.md`
- **Módulos**: `docs/MODULES.md`
- **Guía Docker**: `docs/DOCKER_DEPLOYMENT.md`
- **Comunidad**: https://discord.gg/cmangos

## 🆘 Soporte

Si encuentras problemas:

1. Revisar logs: `docker-compose -f docker-compose.windows.yml logs`
2. Consultar: `docs/DOCKER_DEPLOYMENT.md#troubleshooting`
3. Buscar en: https://github.com/cmangos/mangos-wotlk/issues
4. Preguntar en Discord: https://discord.gg/cmangos

---

**¡Felicidades! Tu servidor MaNGOS WotLK está corriendo en Windows 11** 🎉
