# MaNGOS WotLK - Multi-architecture Dockerfile
# Supports: linux/amd64, linux/arm64
# Build stage for compiling the server binaries

ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE} as builder

# Install build dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    libboost-all-dev \
    libssl-dev \
    default-libmysqlclient-dev \
    libreadline-dev \
    zlib1g-dev \
    libbz2-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /mangos

# Copy source code
COPY . .

# Create build directory and configure
RUN mkdir build && cd build && \
    cmake .. \
    -DCMAKE_INSTALL_PREFIX=/mangos/install \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_GAME_SERVER=ON \
    -DBUILD_LOGIN_SERVER=ON \
    -DBUILD_EXTRACTORS=OFF \
    -DBUILD_SCRIPTDEV=ON \
    -DBUILD_PLAYERBOTS=ON \
    -DBUILD_AHBOT=ON \
    -DPCH=ON

# Build the project
RUN cd build && \
    make -j$(nproc) && \
    make install

# Runtime stage for realmd (authentication server)
FROM ${BASE_IMAGE} as realmd

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    libboost-system1.74.0 \
    libboost-program-options1.74.0 \
    libboost-thread1.74.0 \
    libboost-filesystem1.74.0 \
    libssl3 \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Create mangos user
RUN useradd -m -d /mangos -s /bin/bash mangos

WORKDIR /mangos

# Copy realmd binary and configuration
COPY --from=builder /mangos/install/bin/realmd /mangos/bin/realmd
COPY --from=builder /mangos/install/etc/realmd.conf.dist /mangos/etc/realmd.conf.dist

# Create necessary directories
RUN mkdir -p /mangos/etc /mangos/logs && \
    chown -R mangos:mangos /mangos

USER mangos

# Expose realmd port (default 3724)
EXPOSE 3724

# Use configuration from environment or default
CMD ["/mangos/bin/realmd", "-c", "/mangos/etc/realmd.conf"]

# Runtime stage for mangosd (world/game server)
FROM ${BASE_IMAGE} as mangosd

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    libboost-system1.74.0 \
    libboost-program-options1.74.0 \
    libboost-thread1.74.0 \
    libboost-filesystem1.74.0 \
    libboost-regex1.74.0 \
    libssl3 \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Create mangos user
RUN useradd -m -d /mangos -s /bin/bash mangos

WORKDIR /mangos

# Copy mangosd binary and configuration
COPY --from=builder /mangos/install/bin/mangosd /mangos/bin/mangosd
COPY --from=builder /mangos/install/etc/mangosd.conf.dist /mangos/etc/mangosd.conf.dist
COPY --from=builder /mangos/install/etc/ahbot.conf.dist /mangos/etc/ahbot.conf.dist
COPY --from=builder /mangos/install/etc/playerbot.conf.dist /mangos/etc/playerbot.conf.dist

# Create necessary directories
RUN mkdir -p /mangos/etc /mangos/logs /mangos/data /mangos/mmaps /mangos/vmaps /mangos/maps /mangos/dbc && \
    chown -R mangos:mangos /mangos

USER mangos

# Expose mangosd ports
# 8085: World server port
# 7878: Remote access/SOAP
EXPOSE 8085 7878

# Use configuration from environment or default
CMD ["/mangos/bin/mangosd", "-c", "/mangos/etc/mangosd.conf"]

# Extractor tools stage (optional, for game data extraction)
FROM ${BASE_IMAGE} as extractors

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    libboost-system1.74.0 \
    libboost-filesystem1.74.0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /mangos/tools

# Copy extractor binaries if built
COPY --from=builder /mangos/install/bin/tools/* /mangos/tools/ || true

# This stage is for extracting game data from WoW client
# Usage: docker run --rm -v /path/to/wow:/data mangos:extractors
CMD ["/bin/bash"]
