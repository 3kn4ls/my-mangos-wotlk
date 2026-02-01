# Guía de Inicio Rápido - K3s (Kubernetes)

Esta guía te llevará paso a paso para desplegar MaNGOS WotLK en un cluster K3s (Kubernetes ligero).

## 📋 ¿Qué es K3s?

**K3s** es una distribución ligera de Kubernetes certificada por CNCF, perfecta para:
- Dispositivos edge (Raspberry Pi, SBCs)
- Clusters pequeños
- Desarrollo y testing
- Producción con recursos limitados

**Ventajas sobre Docker Compose:**
- ✅ Alta disponibilidad automática
- ✅ Auto-restart y self-healing
- ✅ Escalabilidad horizontal
- ✅ Load balancing integrado
- ✅ Rolling updates sin downtime
- ✅ Gestión declarativa de configuración

## 📋 Requisitos Previos

### Hardware Mínimo

**Un solo nodo:**
- CPU: 2 cores
- RAM: 4 GB (8 GB recomendado)
- Disco: 30 GB

**Cluster multi-nodo (opcional):**
- Master: 2 cores, 4 GB RAM, 30 GB disco
- Workers: 2 cores, 2 GB RAM, 20 GB disco cada uno

### Plataformas Soportadas

- ✅ Linux AMD64 (Ubuntu, Debian, CentOS, RHEL)
- ✅ Linux ARM64 (Raspberry Pi 4/5, ARM servers)
- ✅ macOS (vía K3d o Rancher Desktop)
- ✅ Windows WSL2 (vía K3d o Rancher Desktop)

### Software Previo

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar herramientas básicas
sudo apt install -y curl wget git nano
```

## 🚀 Instalación de K3s

### Opción 1: Nodo Único (Desarrollo/Testing)

**Instalación estándar:**

```bash
# Instalar K3s
curl -sfL https://get.k3s.io | sh -

# Verificar instalación
sudo k3s kubectl get nodes

# Configurar kubectl para usuario no-root
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config

# Verificar
kubectl get nodes
```

**Salida esperada:**
```
NAME          STATUS   ROLES                  AGE   VERSION
localhost     Ready    control-plane,master   30s   v1.28.5+k3s1
```

**Instalación sin Traefik (recomendado para MaNGOS):**

```bash
# K3s sin Traefik para ahorrar recursos
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -
```

### Opción 2: Cluster Multi-Nodo (Producción)

#### A. Configurar Nodo Master

```bash
# En el servidor master
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -

# Obtener token para workers
sudo cat /var/lib/rancher/k3s/server/node-token

# Salida ejemplo:
# K10abc123def456ghi789jkl012mno345pqr::server:678stu901vwx234yz
```

#### B. Unir Worker Nodes

```bash
# En cada nodo worker
export K3S_URL="https://MASTER_IP:6443"
export K3S_TOKEN="K10abc123def456ghi789jkl012mno345pqr::server:678stu901vwx234yz"

curl -sfL https://get.k3s.io | sh -

# Reemplazar MASTER_IP con la IP del master
# Ejemplo: export K3S_URL="https://192.168.1.100:6443"
```

#### C. Verificar Cluster

```bash
# En el master
kubectl get nodes

# Deberías ver:
# NAME       STATUS   ROLES                  AGE   VERSION
# master     Ready    control-plane,master   5m    v1.28.5+k3s1
# worker1    Ready    <none>                 2m    v1.28.5+k3s1
# worker2    Ready    <none>                 2m    v1.28.5+k3s1
```

### Opción 3: K3s en Raspberry Pi

```bash
# Deshabilitar servicios innecesarios para ahorrar RAM
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik --disable=servicelb --flannel-backend=host-gw" sh -

# Configurar kubectl
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

## 🎯 Preparar el Proyecto MaNGOS

### Paso 1: Clonar Repositorio

```bash
cd ~
git clone https://github.com/tu-usuario/my-mangos-wotlk.git
cd my-mangos-wotlk
```

### Paso 2: Construir Imágenes Docker

**Importante**: Las imágenes deben estar disponibles en todos los nodos del cluster.

#### Opción A: Registry Local (Recomendado para Cluster)

```bash
# Instalar registry local en el master
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# Construir y pushear imágenes
cd docker
./build.sh linux/amd64 true  # Para AMD64
# o
./build.sh linux/arm64 true  # Para ARM64 (Raspberry Pi)

# Tag para registry local
docker tag mangos-wotlk:realmd localhost:5000/mangos-wotlk:realmd
docker tag mangos-wotlk:mangosd localhost:5000/mangos-wotlk:mangosd

# Push al registry
docker push localhost:5000/mangos-wotlk:realmd
docker push localhost:5000/mangos-wotlk:mangosd
```

#### Opción B: Importar a K3s (Nodo Único)

```bash
# Construir imágenes
cd docker
./build.sh

# Importar a K3s
docker save mangos-wotlk:realmd | sudo k3s ctr images import -
docker save mangos-wotlk:mangosd | sudo k3s ctr images import -

# Verificar
sudo k3s crictl images | grep mangos
```

### Paso 3: Configurar Secretos

```bash
cd ~/my-mangos-wotlk/k8s

# Editar secrets.yaml
nano secrets.yaml
```

**⚠️ IMPORTANTE**: Cambiar las contraseñas por defecto:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mangos-secrets
  namespace: mangos
type: Opaque
stringData:
  mysql-root-password: "TU_PASSWORD_SEGURO_AQUI_2024!"
  mysql-user: "mangos"
  mysql-password: "MANGOS_PASSWORD_SEGURO_2024!"
  realmd-db: "realmd"
  world-db: "mangos"
  character-db: "characters"
```

**Guardar:** `Ctrl+O`, `Enter`, `Ctrl+X`

### Paso 4: Revisar Configuración

```bash
# Ver todos los manifiestos
ls -la k8s/

# namespace.yaml        - Namespace dedicado
# secrets.yaml          - Credenciales (editado arriba)
# configmap.yaml        - Configuraciones de servidor
# persistentvolumes.yaml - Storage claims
# mysql-statefulset.yaml - Base de datos
# realmd-deployment.yaml - Servidor de auth
# mangosd-deployment.yaml - Servidor del mundo
# kustomization.yaml    - Orquestación
# deploy-k3s.sh         - Script automatizado
```

## 🚀 Despliegue

### Opción 1: Despliegue Automático (Recomendado)

```bash
cd ~/my-mangos-wotlk/k8s

# Dar permisos de ejecución
chmod +x deploy-k3s.sh

# Desplegar todo
./deploy-k3s.sh deploy
```

**Proceso de despliegue:**

```
MaNGOS WotLK - K3s Deployment Script
================================================
Deploying MaNGOS to K3s cluster...

Creating namespace...
namespace/mangos created

Creating secrets...
secret/mangos-secrets created

Creating ConfigMaps...
configmap/mangos-config created
configmap/realmd-config created
configmap/mangosd-config created

Creating PersistentVolumeClaims...
persistentvolumeclaim/mysql-data-pvc created
persistentvolumeclaim/realmd-logs-pvc created
...

Deploying MySQL...
statefulset.apps/mysql created
service/mysql-service created

Waiting for MySQL to be ready...
pod/mysql-0 condition met

Deploying Realmd...
deployment.apps/realmd created
service/realmd-service created

Waiting for Realmd to be ready...
deployment.apps/realmd condition met

Deploying Mangosd...
deployment.apps/mangosd created
service/mangosd-service created

Waiting for Mangosd to be ready...
deployment.apps/mangosd condition met

Deployment completed successfully!

Get service IPs:
NAME              TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)
mysql-service     ClusterIP      None            <none>          3306/TCP
realmd-service    LoadBalancer   10.43.120.15    192.168.1.100   3724:30724/TCP
mangosd-service   LoadBalancer   10.43.87.234    192.168.1.100   8085:30085/TCP

Check pod status:
NAME                       READY   STATUS    RESTARTS   AGE
mysql-0                    1/1     Running   0          2m
realmd-5d7f8c9b-xyz        1/1     Running   0          1m
mangosd-7f9b6d8c-abc       1/1     Running   0          30s
```

### Opción 2: Despliegue Manual Paso a Paso

```bash
cd ~/my-mangos-wotlk/k8s

# 1. Crear namespace
kubectl apply -f namespace.yaml

# 2. Aplicar secretos
kubectl apply -f secrets.yaml

# 3. Aplicar ConfigMaps
kubectl apply -f configmap.yaml

# 4. Crear PVCs
kubectl apply -f persistentvolumes.yaml

# 5. Desplegar MySQL
kubectl apply -f mysql-statefulset.yaml

# 6. Esperar a que MySQL esté listo
kubectl wait --for=condition=ready pod -l app=mysql -n mangos --timeout=300s

# 7. Desplegar Realmd
kubectl apply -f realmd-deployment.yaml

# 8. Esperar a que Realmd esté listo
kubectl wait --for=condition=available deployment/realmd -n mangos --timeout=120s

# 9. Desplegar Mangosd
kubectl apply -f mangosd-deployment.yaml

# 10. Esperar a que Mangosd esté listo
kubectl wait --for=condition=available deployment/mangosd -n mangos --timeout=180s
```

### Opción 3: Usando Kustomize

```bash
cd ~/my-mangos-wotlk

# Ver preview
kubectl kustomize k8s/

# Aplicar
kubectl apply -k k8s/

# Ver recursos creados
kubectl get all -n mangos
```

## 🔍 Verificación del Despliegue

### Ver Estado de Pods

```bash
# Ver todos los pods en el namespace mangos
kubectl get pods -n mangos

# Esperar a que todos estén Running
kubectl get pods -n mangos -w

# Ver detalles de un pod
kubectl describe pod mysql-0 -n mangos
```

**Estado esperado:**
```
NAME                       READY   STATUS    RESTARTS   AGE
mysql-0                    1/1     Running   0          5m
realmd-xyz123              1/1     Running   0          4m
mangosd-abc789             1/1     Running   0          3m
```

### Ver Servicios y IPs

```bash
# Ver servicios
kubectl get svc -n mangos

# Ver IPs externas (LoadBalancer)
kubectl get svc -n mangos -o wide
```

**Salida esperada:**
```
NAME              TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)
mysql-service     ClusterIP      None            <none>          3306/TCP
realmd-service    LoadBalancer   10.43.120.15    192.168.1.100   3724:30724/TCP
mangosd-service   LoadBalancer   10.43.87.234    192.168.1.100   8085:30085/TCP
```

### Ver Logs

```bash
# Logs de MySQL
kubectl logs -f mysql-0 -n mangos

# Logs de Realmd
kubectl logs -f deployment/realmd -n mangos

# Logs de Mangosd
kubectl logs -f deployment/mangosd -n mangos

# Ver logs anteriores (si crasheó)
kubectl logs --previous deployment/mangosd -n mangos
```

### Ver Eventos

```bash
# Ver eventos recientes
kubectl get events -n mangos --sort-by='.lastTimestamp'

# Ver eventos en tiempo real
kubectl get events -n mangos -w
```

## 🗄️ Configurar Base de Datos

### Importar Esquemas SQL

#### Método 1: Desde fuera del cluster

```bash
# Copiar esquemas al pod de MySQL
kubectl cp sql/base/mangos/mangos.sql mangos/mysql-0:/tmp/
kubectl cp sql/base/realmd/realmd.sql mangos/mysql-0:/tmp/
kubectl cp sql/base/characters/characters.sql mangos/mysql-0:/tmp/

# Importar
kubectl exec -it mysql-0 -n mangos -- mysql -u root -p mangos < /tmp/mangos.sql
kubectl exec -it mysql-0 -n mangos -- mysql -u root -p realmd < /tmp/realmd.sql
kubectl exec -it mysql-0 -n mangos -- mysql -u root -p characters < /tmp/characters.sql
```

#### Método 2: Desde dentro del pod

```bash
# Abrir shell en MySQL pod
kubectl exec -it mysql-0 -n mangos -- /bin/bash

# Dentro del pod
mysql -u root -p

# En MySQL
CREATE DATABASE IF NOT EXISTS realmd;
CREATE DATABASE IF NOT EXISTS mangos;
CREATE DATABASE IF NOT EXISTS characters;

# Importar desde archivos (si los copiaste)
USE mangos;
source /tmp/mangos.sql;

USE realmd;
source /tmp/realmd.sql;

USE characters;
source /tmp/characters.sql;

exit
```

### Configurar Realm

```bash
# Conectar a MySQL
kubectl exec -it mysql-0 -n mangos -- mysql -u root -p realmd
```

```sql
-- Ver IP externa del servicio mangosd
-- (copiar de: kubectl get svc -n mangos)

-- Insertar realm con la IP externa
INSERT INTO realmlist (id, name, address, port, icon, realmflags, timezone, allowedSecurityLevel)
VALUES (1, 'Servidor K3s MaNGOS', '192.168.1.100', 8085, 1, 0, 1, 0);

-- Verificar
SELECT * FROM realmlist;

exit
```

## 🎮 Copiar Datos del Juego

### Preparar Datos (Extraer en otra PC)

Extraer datos del cliente WoW 3.3.5a siguiendo la guía Windows o Linux.

### Copiar al Cluster

```bash
# Obtener nombre del pod de mangosd
export MANGOSD_POD=$(kubectl get pod -n mangos -l app=mangosd -o jsonpath="{.items[0].metadata.name}")

# Copiar datos
kubectl cp dbc/ mangos/$MANGOSD_POD:/mangos/dbc/
kubectl cp maps/ mangos/$MANGOSD_POD:/mangos/maps/
kubectl cp vmaps/ mangos/$MANGOSD_POD:/mangos/vmaps/
kubectl cp mmaps/ mangos/$MANGOSD_POD:/mangos/mmaps/

# Reiniciar mangosd
kubectl rollout restart deployment/mangosd -n mangos
```

## 👤 Crear Cuenta GM

### Opción 1: Usando MySQL

```bash
kubectl exec -it mysql-0 -n mangos -- mysql -u root -p realmd
```

```sql
INSERT INTO account (username, sha_pass_hash, gmlevel, email)
VALUES ('admin', SHA1(CONCAT(UPPER('admin'), ':', UPPER('admin123'))), 3, 'admin@localhost');

SELECT id, username, gmlevel FROM account;
exit
```

### Opción 2: Usando consola de Mangosd (si está disponible)

```bash
# Conectar a la consola
kubectl exec -it $MANGOSD_POD -n mangos -- /mangos/bin/mangosd

# Dentro de la consola
account create admin admin123
account set gmlevel admin 3
```

## 🔧 Gestión del Cluster

### Script de Gestión (Recomendado)

```bash
cd ~/my-mangos-wotlk/k8s

# Ver estado
./deploy-k3s.sh status

# Ver logs de mangosd
./deploy-k3s.sh logs mangosd

# Ver logs de realmd
./deploy-k3s.sh logs realmd

# Reiniciar mangosd
./deploy-k3s.sh restart mangosd

# Escalar mangosd (solo si tienes configuración multi-replica)
./deploy-k3s.sh scale mangosd 2

# Abrir shell en pod de mangosd
./deploy-k3s.sh shell mangosd

# Eliminar todo (¡CUIDADO!)
./deploy-k3s.sh delete
```

### Comandos kubectl Directos

```bash
# Ver todos los recursos
kubectl get all -n mangos

# Ver pods
kubectl get pods -n mangos -o wide

# Ver servicios
kubectl get svc -n mangos

# Ver PVCs
kubectl get pvc -n mangos

# Ver configmaps
kubectl get cm -n mangos

# Ver secretos
kubectl get secrets -n mangos

# Describir un recurso
kubectl describe deployment mangosd -n mangos

# Editar deployment
kubectl edit deployment mangosd -n mangos

# Escalar deployment
kubectl scale deployment mangosd -n mangos --replicas=2

# Reiniciar deployment
kubectl rollout restart deployment/mangosd -n mangos

# Ver historial de rollouts
kubectl rollout history deployment/mangosd -n mangos

# Ver uso de recursos
kubectl top pods -n mangos
kubectl top nodes

# Abrir shell en pod
kubectl exec -it $MANGOSD_POD -n mangos -- /bin/bash

# Port-forward (para acceso local)
kubectl port-forward -n mangos svc/mangosd-service 8085:8085
```

## 📊 Monitoreo

### Logs en Tiempo Real

```bash
# Todos los pods
kubectl logs -f -n mangos --all-containers=true

# Un deployment específico
kubectl logs -f deployment/mangosd -n mangos

# Últimas 100 líneas
kubectl logs --tail=100 deployment/mangosd -n mangos

# Logs desde hace 1 hora
kubectl logs --since=1h deployment/mangosd -n mangos
```

### Eventos del Cluster

```bash
# Ver eventos
kubectl get events -n mangos --sort-by='.lastTimestamp'

# Eventos en tiempo real
kubectl get events -n mangos -w

# Eventos de un pod específico
kubectl describe pod $MANGOSD_POD -n mangos
```

### Recursos y Performance

```bash
# Uso de CPU/RAM de pods
kubectl top pods -n mangos

# Uso de nodos
kubectl top nodes

# Detalles de recursos
kubectl describe node <node-name>
```

### Instalar Prometheus y Grafana (Opcional)

```bash
# Agregar repo de Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar stack de monitoreo
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace

# Acceder a Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Usuario: admin
# Password: prom-operator (por defecto)
```

## 🔄 Actualización y Rollback

### Actualizar Imagen

```bash
# Actualizar imagen de mangosd
kubectl set image deployment/mangosd mangosd=mangos-wotlk:mangosd-v2 -n mangos

# Ver progreso
kubectl rollout status deployment/mangosd -n mangos

# Ver historial
kubectl rollout history deployment/mangosd -n mangos
```

### Rollback

```bash
# Volver a la versión anterior
kubectl rollout undo deployment/mangosd -n mangos

# Volver a una revisión específica
kubectl rollout undo deployment/mangosd -n mangos --to-revision=2

# Ver estado del rollback
kubectl rollout status deployment/mangosd -n mangos
```

## 💾 Backup y Restore

### Backup de Base de Datos

```bash
# Crear directorio de backups
mkdir -p ~/mangos-backups

# Backup completo
kubectl exec mysql-0 -n mangos -- mysqldump -u root -p --all-databases > ~/mangos-backups/backup-$(date +%Y%m%d).sql

# Backup comprimido
kubectl exec mysql-0 -n mangos -- mysqldump -u root -p --all-databases | gzip > ~/mangos-backups/backup-$(date +%Y%m%d).sql.gz
```

### Restore de Base de Datos

```bash
# Desde backup no comprimido
cat ~/mangos-backups/backup-20240124.sql | kubectl exec -i mysql-0 -n mangos -- mysql -u root -p

# Desde backup comprimido
gunzip < ~/mangos-backups/backup-20240124.sql.gz | kubectl exec -i mysql-0 -n mangos -- mysql -u root -p
```

### Backup de PVCs (Volúmenes)

```bash
# Crear job de backup
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: backup-mysql-data
  namespace: mangos
spec:
  template:
    spec:
      containers:
      - name: backup
        image: ubuntu:22.04
        command: ["/bin/bash", "-c"]
        args:
          - tar czf /backup/mysql-$(date +%Y%m%d).tar.gz /data
        volumeMounts:
        - name: mysql-data
          mountPath: /data
        - name: backup
          mountPath: /backup
      volumes:
      - name: mysql-data
        persistentVolumeClaim:
          claimName: mysql-data-pvc
      - name: backup
        hostPath:
          path: /home/pi/mangos-backups
      restartPolicy: Never
  backoffLimit: 3
EOF

# Ver progreso
kubectl logs -f job/backup-mysql-data -n mangos
```

### Backup de Manifiestos

```bash
# Exportar todos los recursos
kubectl get all,cm,secret,pvc -n mangos -o yaml > ~/mangos-backups/manifests-$(date +%Y%m%d).yaml

# Backup del namespace completo
kubectl get namespace mangos -o yaml > ~/mangos-backups/namespace-$(date +%Y%m%d).yaml
```

## 🛡️ Seguridad

### Network Policies

```bash
# Aplicar política de red para restringir acceso a MySQL
kubectl apply -f - <<EOF
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
    ports:
    - protocol: TCP
      port: 3306
EOF
```

### Resource Quotas

```bash
# Limitar recursos del namespace
kubectl apply -f - <<EOF
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
    pods: "20"
EOF

# Ver uso
kubectl describe resourcequota mangos-quota -n mangos
```

## 🐛 Solución de Problemas

### Pod en estado CrashLoopBackOff

```bash
# Ver logs del pod
kubectl logs $POD_NAME -n mangos

# Ver logs del contenedor anterior (si crasheó)
kubectl logs --previous $POD_NAME -n mangos

# Ver eventos
kubectl describe pod $POD_NAME -n mangos

# Solución común: reiniciar
kubectl delete pod $POD_NAME -n mangos
```

### ImagePullBackOff

```bash
# Ver error
kubectl describe pod $POD_NAME -n mangos

# Soluciones:
# 1. Verificar que la imagen existe
sudo k3s crictl images | grep mangos

# 2. Importar imagen si es necesario
docker save mangos-wotlk:mangosd | sudo k3s ctr images import -

# 3. Usar registry local (ver arriba)
```

### PVC Pending

```bash
# Ver estado de PVC
kubectl get pvc -n mangos
kubectl describe pvc mysql-data-pvc -n mangos

# Solución: Verificar storage class
kubectl get storageclass

# K3s usa 'local-path' por defecto
# Si no existe, reinstalar K3s
```

### Service sin EXTERNAL-IP

```bash
# Ver servicios
kubectl get svc -n mangos

# Si EXTERNAL-IP está en <pending>:
# K3s usa ServiceLB (servicelb)

# Verificar que servicelb está activo
kubectl get pods -n kube-system | grep svclb

# Si no está, reinstalar K3s sin --disable=servicelb
```

### Alta latencia o lag

```bash
# Ver uso de recursos
kubectl top nodes
kubectl top pods -n mangos

# Ver si hay throttling
kubectl describe node <node-name> | grep -i pressure

# Solución: Ajustar resource limits
kubectl edit deployment mangosd -n mangos
```

## 📈 Escalabilidad

### Escalado Vertical (Más recursos por pod)

```bash
# Editar deployment
kubectl edit deployment mangosd -n mangos

# Cambiar:
# resources:
#   requests:
#     memory: "2Gi"
#     cpu: "1000m"
#   limits:
#     memory: "8Gi"
#     cpu: "4000m"
```

### Escalado Horizontal (Más pods)

**⚠️ Nota**: MaNGOS no soporta múltiples instancias de mangosd nativamente.
Solo escalar si tienes configuración custom de load balancing.

```bash
# Escalar realmd (puede tener múltiples replicas)
kubectl scale deployment realmd -n mangos --replicas=3

# Ver pods
kubectl get pods -n mangos -l app=realmd
```

### Agregar Nodos al Cluster

```bash
# En un nuevo nodo
export K3S_URL="https://MASTER_IP:6443"
export K3S_TOKEN="<token del master>"
curl -sfL https://get.k3s.io | sh -

# Verificar en el master
kubectl get nodes
```

## 🔌 Desinstalar

### Eliminar MaNGOS

```bash
# Usando script
cd ~/my-mangos-wotlk/k8s
./deploy-k3s.sh delete

# O manualmente
kubectl delete -f mangosd-deployment.yaml
kubectl delete -f realmd-deployment.yaml
kubectl delete -f mysql-statefulset.yaml
kubectl delete -f persistentvolumes.yaml
kubectl delete -f configmap.yaml
kubectl delete -f secrets.yaml
kubectl delete -f namespace.yaml
```

### Desinstalar K3s

```bash
# En nodos worker
/usr/local/bin/k3s-agent-uninstall.sh

# En master/servidor
/usr/local/bin/k3s-uninstall.sh
```

## 📚 Recursos Adicionales

- **K3s Docs**: https://docs.k3s.io/
- **kubectl Cheat Sheet**: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- **MaNGOS**: https://getmangos.eu/
- **Documentación del proyecto**: `docs/` en este repositorio

## 🆘 Comandos Útiles de Referencia

```bash
# Cluster
kubectl cluster-info
kubectl get nodes
kubectl top nodes

# Namespace mangos
kubectl get all -n mangos
kubectl get pods -n mangos -o wide
kubectl get svc -n mangos
kubectl get pvc -n mangos

# Logs
kubectl logs -f deployment/mangosd -n mangos
kubectl logs --previous $POD -n mangos

# Ejecución
kubectl exec -it $POD -n mangos -- /bin/bash
kubectl port-forward -n mangos svc/mangosd-service 8085:8085

# Gestión
kubectl describe pod $POD -n mangos
kubectl delete pod $POD -n mangos
kubectl rollout restart deployment/mangosd -n mangos

# Recursos
kubectl top pods -n mangos
kubectl describe node <node-name>

# Eventos
kubectl get events -n mangos --sort-by='.lastTimestamp'
```

---

**¡Felicidades! Tu servidor MaNGOS WotLK está corriendo en K3s** 🎉☸️
