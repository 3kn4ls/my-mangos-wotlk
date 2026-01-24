#!/bin/bash
# MaNGOS WotLK - Docker Build Script
# Builds multi-architecture images for AMD64 and ARM64

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}MaNGOS WotLK - Docker Build Script${NC}"
echo "================================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

# Check if buildx is available
if ! docker buildx version &> /dev/null; then
    echo -e "${RED}Error: Docker Buildx is not available${NC}"
    exit 1
fi

# Parse arguments
PLATFORM="${1:-linux/amd64,linux/arm64}"
PUSH="${2:-false}"

echo "Build configuration:"
echo "  Platform: ${PLATFORM}"
echo "  Push to registry: ${PUSH}"
echo ""

# Create builder if it doesn't exist
if ! docker buildx inspect mangos-builder &> /dev/null; then
    echo -e "${YELLOW}Creating new buildx builder...${NC}"
    docker buildx create --name mangos-builder --use
    docker buildx inspect --bootstrap
else
    echo -e "${GREEN}Using existing buildx builder${NC}"
    docker buildx use mangos-builder
fi

# Build realmd
echo -e "\n${GREEN}Building realmd image...${NC}"
docker buildx build \
    --platform "${PLATFORM}" \
    --target realmd \
    --tag mangos-wotlk:realmd \
    ${PUSH:+--push} \
    ${PUSH:+--tag your-registry/mangos-wotlk:realmd} \
    -f ../Dockerfile \
    ..

# Build mangosd
echo -e "\n${GREEN}Building mangosd image...${NC}"
docker buildx build \
    --platform "${PLATFORM}" \
    --target mangosd \
    --tag mangos-wotlk:mangosd \
    ${PUSH:+--push} \
    ${PUSH:+--tag your-registry/mangos-wotlk:mangosd} \
    -f ../Dockerfile \
    ..

# Build extractors (optional)
echo -e "\n${GREEN}Building extractors image...${NC}"
docker buildx build \
    --platform "${PLATFORM}" \
    --target extractors \
    --tag mangos-wotlk:extractors \
    ${PUSH:+--push} \
    ${PUSH:+--tag your-registry/mangos-wotlk:extractors} \
    -f ../Dockerfile \
    ..

echo -e "\n${GREEN}Build completed successfully!${NC}"
echo ""
echo "Available images:"
echo "  - mangos-wotlk:realmd"
echo "  - mangos-wotlk:mangosd"
echo "  - mangos-wotlk:extractors"
echo ""
echo "To run the stack, use: docker-compose up -d"
