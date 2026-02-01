#!/bin/bash
# MaNGOS WotLK - Docker Deployment Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}MaNGOS WotLK - Deployment Script${NC}"
echo "================================================"

# Check for .env file
if [ ! -f "../.env" ]; then
    echo -e "${YELLOW}Warning: .env file not found${NC}"
    echo "Creating .env from .env.example..."
    cp ../.env.example ../.env
    echo -e "${YELLOW}Please edit .env file with your configuration${NC}"
    read -p "Press Enter to continue or Ctrl+C to abort..."
fi

# Parse command
COMMAND="${1:-up}"

case "$COMMAND" in
    up)
        echo -e "${BLUE}Starting MaNGOS services...${NC}"
        cd ..
        docker-compose up -d
        echo ""
        echo -e "${GREEN}Services started successfully!${NC}"
        echo ""
        echo "Access points:"
        echo "  - Realmd: localhost:3724"
        echo "  - Mangosd: localhost:8085"
        echo "  - MySQL: localhost:3306"
        echo "  - phpMyAdmin: http://localhost:8080 (use --profile tools)"
        echo ""
        echo "Check logs with: docker-compose logs -f"
        ;;

    down)
        echo -e "${BLUE}Stopping MaNGOS services...${NC}"
        cd ..
        docker-compose down
        echo -e "${GREEN}Services stopped${NC}"
        ;;

    restart)
        echo -e "${BLUE}Restarting MaNGOS services...${NC}"
        cd ..
        docker-compose restart
        echo -e "${GREEN}Services restarted${NC}"
        ;;

    logs)
        echo -e "${BLUE}Showing logs...${NC}"
        cd ..
        docker-compose logs -f
        ;;

    status)
        echo -e "${BLUE}Service status:${NC}"
        cd ..
        docker-compose ps
        ;;

    clean)
        echo -e "${RED}Warning: This will remove all containers, volumes, and data!${NC}"
        read -p "Are you sure? (yes/no): " -r
        if [[ $REPLY == "yes" ]]; then
            echo -e "${BLUE}Cleaning up...${NC}"
            cd ..
            docker-compose down -v
            echo -e "${GREEN}Cleanup complete${NC}"
        else
            echo "Cancelled"
        fi
        ;;

    build)
        echo -e "${BLUE}Building images...${NC}"
        ./build.sh
        ;;

    *)
        echo "Usage: $0 {up|down|restart|logs|status|clean|build}"
        echo ""
        echo "Commands:"
        echo "  up      - Start all services"
        echo "  down    - Stop all services"
        echo "  restart - Restart all services"
        echo "  logs    - Show service logs"
        echo "  status  - Show service status"
        echo "  clean   - Remove all containers and volumes"
        echo "  build   - Build Docker images"
        exit 1
        ;;
esac
