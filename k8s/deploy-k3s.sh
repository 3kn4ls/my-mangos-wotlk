#!/bin/bash
# MaNGOS WotLK - K3s Deployment Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}MaNGOS WotLK - K3s Deployment Script${NC}"
echo "================================================"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if k3s is running
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    echo "Make sure K3s is installed and running"
    exit 1
fi

# Parse command
COMMAND="${1:-deploy}"

case "$COMMAND" in
    deploy)
        echo -e "${BLUE}Deploying MaNGOS to K3s cluster...${NC}"

        # Apply manifests in order
        echo "Creating namespace..."
        kubectl apply -f namespace.yaml

        echo "Creating secrets..."
        kubectl apply -f secrets.yaml

        echo "Creating ConfigMaps..."
        kubectl apply -f configmap.yaml

        echo "Creating PersistentVolumeClaims..."
        kubectl apply -f persistentvolumes.yaml

        echo "Deploying MySQL..."
        kubectl apply -f mysql-statefulset.yaml

        echo "Waiting for MySQL to be ready..."
        kubectl wait --for=condition=ready pod -l app=mysql -n mangos --timeout=300s

        echo "Deploying Realmd..."
        kubectl apply -f realmd-deployment.yaml

        echo "Waiting for Realmd to be ready..."
        kubectl wait --for=condition=available deployment/realmd -n mangos --timeout=120s

        echo "Deploying Mangosd..."
        kubectl apply -f mangosd-deployment.yaml

        echo "Waiting for Mangosd to be ready..."
        kubectl wait --for=condition=available deployment/mangosd -n mangos --timeout=180s

        echo ""
        echo -e "${GREEN}Deployment completed successfully!${NC}"
        echo ""
        echo "Get service IPs:"
        kubectl get services -n mangos
        echo ""
        echo "Check pod status:"
        kubectl get pods -n mangos
        ;;

    status)
        echo -e "${BLUE}MaNGOS Service Status:${NC}"
        echo ""
        echo "Pods:"
        kubectl get pods -n mangos
        echo ""
        echo "Services:"
        kubectl get services -n mangos
        echo ""
        echo "PVCs:"
        kubectl get pvc -n mangos
        ;;

    logs)
        SERVICE="${2:-mangosd}"
        echo -e "${BLUE}Showing logs for ${SERVICE}...${NC}"
        kubectl logs -n mangos -l app=${SERVICE} -f
        ;;

    restart)
        SERVICE="${2:-all}"
        if [ "$SERVICE" == "all" ]; then
            echo -e "${BLUE}Restarting all services...${NC}"
            kubectl rollout restart deployment -n mangos
        else
            echo -e "${BLUE}Restarting ${SERVICE}...${NC}"
            kubectl rollout restart deployment/${SERVICE} -n mangos
        fi
        ;;

    scale)
        SERVICE="${2:-mangosd}"
        REPLICAS="${3:-1}"
        echo -e "${BLUE}Scaling ${SERVICE} to ${REPLICAS} replicas...${NC}"
        kubectl scale deployment/${SERVICE} -n mangos --replicas=${REPLICAS}
        ;;

    delete)
        echo -e "${RED}Warning: This will delete all MaNGOS resources!${NC}"
        read -p "Are you sure? (yes/no): " -r
        if [[ $REPLY == "yes" ]]; then
            echo -e "${BLUE}Deleting all resources...${NC}"
            kubectl delete -f mangosd-deployment.yaml
            kubectl delete -f realmd-deployment.yaml
            kubectl delete -f mysql-statefulset.yaml
            kubectl delete -f persistentvolumes.yaml
            kubectl delete -f configmap.yaml
            kubectl delete -f secrets.yaml
            kubectl delete -f namespace.yaml
            echo -e "${GREEN}All resources deleted${NC}"
        else
            echo "Cancelled"
        fi
        ;;

    shell)
        SERVICE="${2:-mangosd}"
        echo -e "${BLUE}Opening shell in ${SERVICE} pod...${NC}"
        POD=$(kubectl get pod -n mangos -l app=${SERVICE} -o jsonpath="{.items[0].metadata.name}")
        kubectl exec -it -n mangos ${POD} -- /bin/bash
        ;;

    *)
        echo "Usage: $0 {deploy|status|logs|restart|scale|delete|shell} [options]"
        echo ""
        echo "Commands:"
        echo "  deploy               - Deploy all MaNGOS components to K3s"
        echo "  status               - Show status of all components"
        echo "  logs [service]       - Show logs (default: mangosd)"
        echo "  restart [service]    - Restart service (default: all)"
        echo "  scale [service] [n]  - Scale service to n replicas"
        echo "  delete               - Delete all MaNGOS resources"
        echo "  shell [service]      - Open shell in service pod"
        echo ""
        echo "Examples:"
        echo "  $0 deploy"
        echo "  $0 logs realmd"
        echo "  $0 restart mangosd"
        echo "  $0 scale mangosd 2"
        exit 1
        ;;
esac
