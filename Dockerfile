FROM ubuntu:24.04

LABEL maintainer="FrozenFOXX <frozenfoxx@cultoffoxx.net>"

# Environment variables
## P4_VERSION refers to the Perforce release (e.g., r23.2, r24.1)
ENV APP_DEPS=" \
    ca-certificates \
    vim \
    wget" \
    DEBIAN_FRONTEND=noninteractive \
    P4_BINARY_ARCH="bin.linux26x86_64" \
    P4_BINARY_URL_PREFIX="https://cdist2.perforce.com/perforce/" \
    P4_DEPOTS="/opt/perforce/depots" \
    P4_PORT=1666 \
    P4_VERSION="r23.2" \
    P4ROOT="/opt/perforce/server"

# Install dependencies, Create User, and Download Binary
RUN apt-get update && apt-get install -y \
    ${APP_DEPS} \
    && groupadd perforce \
    && useradd -g perforce -d /opt/perforce -s /bin/bash perforce \
    && wget -qO /usr/sbin/p4 ${P4_BINARY_URL_PREFIX}/${P4_VERSION}/${P4_BINARY_ARCH}/p4 \
    && wget -qO /usr/sbin/p4d ${P4_BINARY_URL_PREFIX}/${P4_VERSION}/${P4_BINARY_ARCH}/p4d \
    && chmod +x /usr/sbin/p4 \
    && chmod +x /usr/sbin/p4d \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Ensure directories exist and ownership is correct
RUN mkdir -p $P4ROOT $P4_DEPOTS \
    && chown -R perforce:perforce /opt/perforce

# Copy entrypoint script
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the Perforce port
EXPOSE 1666

# Volumes for persistence
VOLUME ["$P4ROOT", "$P4_DEPOTS"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]