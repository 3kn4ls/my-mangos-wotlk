# Guía de Inicio Rápido - Raspberry Pi 5

Esta guía te llevará paso a paso para instalar y ejecutar MaNGOS WotLK en Raspberry Pi 5 usando Docker.

## 📋 Requisitos Previos

### Hardware Requerido

#### Raspberry Pi 5
- **Modelo**: Raspberry Pi 5 (8 GB RAM recomendado, mínimo 4 GB)
- **Almacenamiento**:
  - ⚠️ **NO USAR tarjeta microSD** para la base de datos (demasiado lento)
  - ✅ **SSD NVMe** vía HAT M.2 (recomendado) o
  - ✅ **SSD USB 3.0** (mínimo aceptable)
  - Espacio: 64 GB mínimo, 128 GB recomendado
- **Refrigeración**:
  - ✅ Active Cooler oficial de Raspberry Pi (recomendado)
  - o disipador pasivo + ventilador
- **Alimentación**:
  - Fuente oficial 27W USB-C de Raspberry Pi
  - o equivalente de calidad (5V 5A)
- **Red**: Cable Ethernet (mejor rendimiento que WiFi)

#### Capacidad Esperada
- **Jugadores simultáneos**: 10-50 (dependiendo de configuración)
- **Rendimiento**: Adecuado para servidor privado o pruebas
- **Limitación**: CPU, no escala para cientos de jugadores

### Software Base

#### 1. Raspberry Pi OS (64-bit)

**Descargar e instalar:**

1. Descargar **Raspberry Pi Imager**: https://www.raspberrypi.com/software/
2. Seleccionar:
   - **OS**: Raspberry Pi OS (64-bit) - Lite o Desktop
   - **Storage**: Tu SSD/USB
3. Configurar (⚙️):
   - Hostname: `mangos-server`
   - Usuario: `pi` (o tu preferencia)
   - Password: (contraseña segura)
   - WiFi: (opcional, Ethernet recomendado)
   - SSH: ✅ Habilitar
4. Escribir la imagen
5. Bootear la Raspberry Pi desde el SSD

**Primera configuración:**

```bash
# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Configurar booteo desde SSD (si usas SSD USB)
sudo raspi-config
# Advanced Options → Boot Order → USB Boot

# Reiniciar
sudo reboot
```

#### 2. Verificar Arquitectura

```bash
uname -m
# Debe mostrar: aarch64 (ARM 64-bit)

cat /proc/cpuinfo | grep "Model"
# Debe mostrar: Raspberry Pi 5
```

## 🐳 Instalación de Docker

### Método 1: Script Oficial (Recomendado)

```bash
# Instalar Docker usando el script oficial
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Reiniciar sesión (o reiniciar Pi)
sudo reboot

# Después del reinicio, verificar
docker --version
docker compose version
```

Deberías ver:
```
Docker version 24.0.x
Docker Compose version v2.x.x
```

### Método 2: Manual (Alternativa)

```bash
# Instalar dependencias
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# Agregar clave GPG de Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Agregar repositorio
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Agregar usuario a grupo docker
sudo usermod -aG docker $USER
newgrp docker
```

### Configurar Docker para ARM64

```bash
# Verificar que Docker reconoce ARM64
docker version | grep Architecture
# Debe mostrar: Architecture: arm64

# Habilitar experimental features (para builds multi-arch)
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "experimental": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# Reiniciar Docker
sudo systemctl restart docker
```

## 🚀 Instalación de MaNGOS WotLK

### Paso 1: Obtener el Código

```bash
# Instalar git si no está
sudo apt install -y git

# Clonar repositorio
cd ~
git clone https://github.com/tu-usuario/my-mangos-wotlk.git
cd my-mangos-wotlk
```

### Paso 2: Configurar Variables de Entorno

```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Editar con nano
nano .env
```

**Configuración optimizada para Raspberry Pi 5:**

```env
# Zona horaria
TZ=Europe/Madrid

# Contraseñas (CAMBIAR ESTAS)
MYSQL_ROOT_PASSWORD=RpiSecurePass2024!
MYSQL_USER=mangos
MYSQL_PASSWORD=MangosRpi2024!
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

# phpMyAdmin (puede deshabilitarse para ahorrar recursos)
PHPMYADMIN_PORT=8080

# Build config
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1

# Forzar plataforma ARM64
DOCKER_DEFAULT_PLATFORM=linux/arm64
```

**Guardar:** `Ctrl+O`, `Enter`, `Ctrl+X`

### Paso 3: Optimizar docker-compose.yml para Raspberry Pi

```bash
# Editar docker-compose.yml
nano docker-compose.yml
```

**Ajustar límites de recursos:**

```yaml
services:
  database:
    # ... configuración existente ...
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          memory: 512M

  realmd:
    # ... configuración existente ...
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M

  mangosd:
    # ... configuración existente ...
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 3G
        reservations:
          memory: 1G
```

**Guardar:** `Ctrl+O`, `Enter`, `Ctrl+X`

### Paso 4: Construir Imágenes Docker (ARM64)

⚠️ **IMPORTANTE**: Este proceso tomará **1-2 HORAS** en Raspberry Pi 5.

```bash
# Ir a la carpeta docker
cd docker

# Iniciar build para ARM64
./build.sh linux/arm64
```

**Proceso esperado:**
```
MaNGOS WotLK - Docker Build Script
================================================
Build configuration:
  Platform: linux/arm64

Building realmd image...
[+] Building 1200.5s (ARM64 es más lento)
...

Building mangosd image...
[+] Building 2100.8s
...

Build completed successfully!
```

**💡 Consejo**: Ejecuta esto de noche o mientras haces otras cosas. Puedes usar `screen` para dejar el proceso corriendo:

```bash
# Instalar screen
sudo apt install -y screen

# Iniciar sesión screen
screen -S mangos-build

# Ejecutar build
./build.sh linux/arm64

# Detach: Ctrl+A, luego D
# Reattach: screen -r mangos-build
```

**Verificar imágenes:**

```bash
docker images | grep mangos
```

### Paso 5: Desplegar Servicios

```bash
# Volver al directorio raíz
cd ..

# Iniciar servicios
docker-compose up -d
```

**Salida esperada:**
```
[+] Running 4/4
 ✓ Network my-mangos-wotlk_mangos-network  Created
 ✓ Container mangos-database               Started
 ✓ Container mangos-realmd                 Started
 ✓ Container mangos-mangosd                Started
```

**Verificar estado:**

```bash
docker-compose ps
```

Espera a que todos estén `Up (healthy)`:
```
NAME                STATUS
mangos-database     Up (healthy)
mangos-realmd       Up (healthy)
mangos-mangosd      Up (healthy)
```

### Paso 6: Monitorear Temperatura y Recursos

```bash
# Ver temperatura
vcgencmd measure_temp

# Temperatura recomendada: < 70°C
# Si supera 80°C, mejorar refrigeración

# Ver uso de CPU/RAM
htop
# o
docker stats
```

**Instalar herramientas de monitoreo:**

```bash
sudo apt install -y htop iotop
```

## 🗄️ Configuración de Base de Datos

### Importar Esquemas SQL

```bash
# Si tienes los esquemas SQL en tu repositorio
docker exec -i mangos-database mysql -u root -pRpiSecurePass2024! mangos < sql/base/mangos/mangos.sql
docker exec -i mangos-database mysql -u root -pRpiSecurePass2024! realmd < sql/base/realmd/realmd.sql
docker exec -i mangos-database mysql -u root -pRpiSecurePass2024! characters < sql/base/characters/characters.sql
```

### Configurar Realm

```bash
# Conectar a MySQL
docker exec -it mangos-database mysql -u root -p

# Dentro de MySQL
USE realmd;

-- Insertar realm (usar IP de la Raspberry Pi)
INSERT INTO realmlist (id, name, address, port, icon, realmflags, timezone, allowedSecurityLevel)
VALUES (1, 'Servidor Raspberry Pi', '192.168.1.100', 8085, 1, 0, 1, 0);

-- Verificar
SELECT * FROM realmlist;

exit
```

**Obtener IP de la Raspberry Pi:**

```bash
# IP local
hostname -I

# Ejemplo: 192.168.1.100
```

## 🎮 Extraer Datos del Cliente (En otra PC)

⚠️ **NO extraer datos en la Raspberry Pi** - toma MUCHAS HORAS y sobrecarga el CPU.

### Opción 1: Usar PC con Windows (Recomendado)

1. Seguir la guía de extracción en `QUICKSTART_WINDOWS.md`
2. Extraer DBC, Maps, VMaps, MMaps
3. Copiar a Raspberry Pi vía SCP o red

**Desde Windows (PowerShell):**

```powershell
# Instalar WinSCP o usar SCP de PowerShell
scp -r "C:\Program Files (x86)\World of Warcraft\dbc" pi@192.168.1.100:~/mangos-data/
scp -r "C:\Program Files (x86)\World of Warcraft\maps" pi@192.168.1.100:~/mangos-data/
scp -r "C:\Program Files (x86)\World of Warcraft\vmaps" pi@192.168.1.100:~/mangos-data/
scp -r "C:\Program Files (x86)\World of Warcraft\mmaps" pi@192.168.1.100:~/mangos-data/
```

### Opción 2: Desde Linux

```bash
# En tu PC Linux (después de extraer datos)
scp -r /path/to/wow/dbc pi@192.168.1.100:~/mangos-data/
scp -r /path/to/wow/maps pi@192.168.1.100:~/mangos-data/
scp -r /path/to/wow/vmaps pi@192.168.1.100:~/mangos-data/
scp -r /path/to/wow/mmaps pi@192.168.1.100:~/mangos-data/
```

### Copiar Datos al Contenedor

```bash
# En la Raspberry Pi
cd ~/mangos-data

# Copiar al contenedor mangosd
docker cp dbc/. mangos-mangosd:/mangos/dbc/
docker cp maps/. mangos-mangosd:/mangos/maps/
docker cp vmaps/. mangos-mangosd:/mangos/vmaps/
docker cp mmaps/. mangos-mangosd:/mangos/mmaps/

# Reiniciar mangosd
docker-compose restart mangosd
```

## 👤 Crear Cuenta GM

```bash
# Conectar a MySQL
docker exec -it mangos-database mysql -u root -p realmd
```

```sql
-- Crear cuenta GM
INSERT INTO account (username, sha_pass_hash, gmlevel, email)
VALUES ('admin', SHA1(CONCAT(UPPER('admin'), ':', UPPER('admin123'))), 3, 'admin@localhost');

-- Verificar
SELECT id, username, gmlevel FROM account;

exit
```

## 🌐 Conectar desde Cliente

### En el Cliente de WoW

Editar `realmlist.wtf`:
```
set realmlist 192.168.1.100
```

(Usar la IP de tu Raspberry Pi)

## 🔧 Optimización para Raspberry Pi

### 1. Deshabilitar Módulos Opcionales

```bash
nano docker/configs/mangosd.conf
```

```ini
# Deshabilitar para ahorrar recursos
[AhbotConf]
AuctionHouseBot.Enabled = 0

[PlayerbotConf]
AiPlayerbot.Enabled = 0
```

### 2. Reducir Rates para Mejor Rendimiento

```ini
# En mangosd.conf
Rate.Creature.Aggro = 0.5  # Menos aggro = menos carga CPU
GridUnload = 1              # Descargar grids no usados
MapUpdateInterval = 100     # Intervalo de actualización
```

### 3. Optimizar MySQL

```bash
nano docker/configs/my.cnf
```

```ini
[mysqld]
innodb_buffer_pool_size = 512M   # Ajustar según RAM disponible
innodb_log_file_size = 64M
query_cache_size = 32M
max_connections = 50
```

### 4. Limitar Jugadores Simultáneos

```ini
# En mangosd.conf
PlayerLimit = 20  # Límite conservador para RPi5
```

### 5. Configurar Swap (si tienes 4GB RAM)

```bash
# Ver swap actual
free -h

# Si no tienes swap o es pequeño, crear swap de 4GB
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Cambiar: CONF_SWAPSIZE=4096

sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

## 🛠️ Gestión de Servicios

### Scripts de Gestión

```bash
cd ~/my-mangos-wotlk/docker

# Iniciar servicios
./deploy.sh up

# Ver estado
./deploy.sh status

# Ver logs
./deploy.sh logs

# Reiniciar
./deploy.sh restart

# Detener
./deploy.sh down
```

### Comandos Docker Compose

```bash
# Iniciar
docker-compose up -d

# Detener
docker-compose down

# Ver logs en tiempo real
docker-compose logs -f mangosd

# Reiniciar un servicio
docker-compose restart mangosd

# Ver uso de recursos
docker stats
```

### Auto-inicio en Boot

```bash
# Crear servicio systemd
sudo nano /etc/systemd/system/mangos.service
```

```ini
[Unit]
Description=MaNGOS WotLK Server
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/pi/my-mangos-wotlk
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
User=pi

[Install]
WantedBy=multi-user.target
```

```bash
# Habilitar servicio
sudo systemctl enable mangos.service
sudo systemctl start mangos.service

# Ver estado
sudo systemctl status mangos.service
```

## 📊 Monitoreo y Rendimiento

### Monitorear Temperatura Continuamente

```bash
# Instalar herramienta de monitoreo
sudo apt install -y lm-sensors

# Ver temperatura cada 2 segundos
watch -n 2 vcgencmd measure_temp

# Script de alerta de temperatura
cat > ~/temp_monitor.sh << 'EOF'
#!/bin/bash
TEMP=$(vcgencmd measure_temp | cut -d= -f2 | cut -d\' -f1)
if (( $(echo "$TEMP > 75" | bc -l) )); then
    echo "⚠️ ALERTA: Temperatura alta: ${TEMP}°C"
    # Opcional: enviar notificación o reducir carga
fi
EOF

chmod +x ~/temp_monitor.sh

# Ejecutar cada 5 minutos (añadir a crontab)
crontab -e
# Añadir: */5 * * * * /home/pi/temp_monitor.sh
```

### Dashboard de Recursos

```bash
# Instalar Glances (alternativa a htop)
sudo apt install -y glances

# Ejecutar
glances

# O con interfaz web
glances -w
# Acceder desde: http://192.168.1.100:61208
```

### Logs del Sistema

```bash
# Ver logs del kernel (útil para ver throttling)
dmesg | grep -i thermal

# Ver si hay throttling (undervoltage/overheating)
vcgencmd get_throttled
# 0x0 = Sin throttling (OK)
# Otros valores = Hay problemas
```

## 🐛 Solución de Problemas Específicos de Raspberry Pi

### Problema: Servidor muy lento / Lag

**Causas y soluciones:**

1. **Temperatura alta (>80°C)**
   ```bash
   vcgencmd measure_temp
   # Solución: Mejorar refrigeración
   ```

2. **Usando microSD en vez de SSD**
   ```bash
   df -h
   # Solución: Migrar a SSD NVMe o USB 3.0
   ```

3. **Muchos jugadores para la capacidad**
   ```bash
   # Reducir PlayerLimit en mangosd.conf
   PlayerLimit = 10
   ```

4. **RAM insuficiente**
   ```bash
   free -h
   # Solución: Reducir límites de Docker, activar swap
   ```

### Problema: Contenedor se reinicia

```bash
# Ver logs
docker logs mangos-mangosd

# Verificar memoria OOM (Out of Memory)
dmesg | grep -i oom

# Solución: Reducir límites de memoria en docker-compose.yml
```

### Problema: Build falla

```bash
# Limpiar y reintentar
docker system prune -a
docker-compose down -v
./build.sh linux/arm64

# Si sigue fallando, verificar espacio en disco
df -h
```

### Problema: Base de datos corrupta después de apagado incorrecto

```bash
# Reparar tablas MySQL
docker exec -it mangos-database mysqlcheck -u root -p --auto-repair --all-databases
```

### Problema: Undervoltage (⚡ ícono parpadeando)

```bash
# Verificar
vcgencmd get_throttled

# Solución: Usar fuente de alimentación oficial de 27W
# NO usar cables adaptadores ni fuentes genéricas
```

## 💾 Backup

### Backup Automático

```bash
# Crear script de backup
nano ~/backup_mangos.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/home/pi/mangos-backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup de base de datos
docker exec mangos-database mysqldump -u root -pRpiSecurePass2024! --all-databases > $BACKUP_DIR/db-$DATE.sql

# Comprimir
gzip $BACKUP_DIR/db-$DATE.sql

# Mantener solo últimos 7 backups
ls -t $BACKUP_DIR/db-*.sql.gz | tail -n +8 | xargs rm -f

echo "Backup completado: $BACKUP_DIR/db-$DATE.sql.gz"
```

```bash
chmod +x ~/backup_mangos.sh

# Programar backup diario a las 3 AM
crontab -e
# Añadir: 0 3 * * * /home/pi/backup_mangos.sh
```

## 🔌 Ahorro de Energía

```bash
# Configurar para reducir consumo cuando está inactivo
sudo nano /boot/firmware/config.txt

# Añadir:
# Reducir voltaje GPU (si no usas monitor)
gpu_mem=16

# Deshabilitar Bluetooth si no lo usas
dtoverlay=disable-bt

# Guardar y reiniciar
sudo reboot
```

## 📈 Escalabilidad

### Cluster de Raspberry Pi (Avanzado)

Si tienes múltiples Raspberry Pi, puedes crear un cluster K3s. Ver `QUICKSTART_K3S.md` para detalles.

```bash
# En el nodo master
curl -sfL https://get.k3s.io | sh -

# En nodos workers
curl -sfL https://get.k3s.io | K3S_URL=https://master-ip:6443 K3S_TOKEN=<token> sh -
```

## 🌡️ Benchmarks Esperados

**Raspberry Pi 5 (8GB + SSD NVMe):**
- Jugadores simultáneos: 20-50
- Temperatura en carga: 60-75°C (con Active Cooler)
- Uso de RAM: 3-5 GB
- Uso de CPU: 40-80%
- Latencia: <50ms en LAN

**Raspberry Pi 5 (4GB + USB SSD):**
- Jugadores simultáneos: 10-30
- Temperatura en carga: 65-80°C
- Uso de RAM: 80-95%
- Requiere swap activo

## 📚 Recursos Adicionales

- **Documentación**: `docs/` en el proyecto
- **Foro Raspberry Pi**: https://forums.raspberrypi.com/
- **MaNGOS**: https://getmangos.eu/
- **Discord**: https://discord.gg/cmangos

## 🆘 Comandos Útiles

```bash
# Estado del sistema
htop                          # Monitor de recursos
vcgencmd measure_temp         # Temperatura
vcgencmd get_throttled        # Throttling
df -h                         # Espacio en disco
free -h                       # Uso de RAM

# Docker
docker ps                     # Contenedores activos
docker stats                  # Uso de recursos
docker logs -f mangos-mangosd # Logs en tiempo real

# Red
ip addr show                  # Ver IPs
ping 8.8.8.8                 # Test conectividad
ss -tulpn | grep :8085       # Ver puertos abiertos

# Servicios
sudo systemctl status mangos  # Estado del servicio
journalctl -u mangos -f      # Logs del servicio
```

---

**¡Felicidades! Tu servidor MaNGOS WotLK está corriendo en Raspberry Pi 5** 🎉🥧
