#!/usr/bin/env bash
set -e

# Variables
P4_DEPOTS=${P4_DEPOTS:-/opt/perforce/depots}
P4SSLDIR=${P4SSLDIR:-/opt/perforce/ssl}
P4_PORT=${P4_PORT:-1666}
P4_USER="perforce"
P4ROOT=${P4ROOT:-/opt/perforce/server}
PUID=${UID:-1028}
PGID=${GID:-50}
SSL_ENABLED=${SSL_ENABLED:-false}

# Functions
map_ids() {
    echo "Configuring user '${P4_USER}' to UID ${PUID} and GID ${PGID}..."

    # Check if a group with this GID already exists
    EXISTING_GROUP=$(getent group "${PGID}" | cut -d: -f1)
    if [ -n "${EXISTING_GROUP}" ]; then
        echo "GID ${PGID} already assigned to group: ${EXISTING_GROUP}. Mapping '$P4_USER' to it."
        usermod -g "${PGID}" "$P4_USER"
    else
        groupmod -g "${PGID}" "${P4_USER}"
    fi

    # Update User UID
    usermod -u "${PUID}" "${P4_USER}"
}

create_dirs() {
    mkdir -p "${P4ROOT}" "${P4_DEPOTS}" "${P4SSLDIR}"

    echo "Adjusting permissions..."
    chown "${P4_USER}:${PGID}" "${P4ROOT}" "${P4_DEPOTS}" "${P4SSLDIR}"
}

prefix_ssl()
{
    if [[ "${P4_PORT}" != ssl:* ]]; then
        export P4_PORT="ssl:${P4_PORT}"
        echo "SSL enabled - using port: ${P4_PORT}"
    fi
}

configure_ssl() {
    if [ "${SSL_ENABLED}" = "true" ]; then
        if [ -f "${P4SSLDIR}/certificate.txt" ]; then
            echo "Using existing certificates found in ${P4SSLDIR}..."
            prefix_ssl
        else
            echo "Generating self-signed SSL certificates..."
            cd "${P4SSLDIR}"
            gosu "${P4_USER}" /usr/sbin/p4d -Gc
            echo "Self-signed certificates generated in ${P4SSLDIR}"
            prefix_ssl
        fi
    fi
}

initialize() {
    if [ ! -f "${P4ROOT}/db.counters" ]; then
        echo "Initializing new Perforce Server..."
        gosu "${P4_USER}" /usr/sbin/p4d -r "${P4ROOT}" -p "${P4_PORT}" -C1 -xi
    fi
}

info() {
    echo ""
    echo "=========================================="
    echo "  Perforce P4D Server"
    echo "=========================================="
    echo "P4ROOT:      ${P4ROOT}"
    echo "P4PORT:      ${P4_PORT}"
    echo "P4_DEPOTS:   ${P4_DEPOTS}"
    echo "P4SSLDIR:    ${P4SSLDIR}"
    echo "User:        ${P4_USER} (UID=${PUID}, GID=${PGID})"
    echo "SSL:         ${SSL_ENABLED}"
    
    if [ "${SSL_ENABLED}" = "true" ]; then
        if [ -f "${P4SSLDIR}/certificate.txt" ]; then
            echo "Certificate: ${P4SSLDIR}/certificate.txt"
        fi
    fi
    
    echo ""
    echo "Client Connection:"
    if [ "${SSL_ENABLED}" = "true" ]; then
        echo "  p4 -p ${P4_PORT} trust -y"
        echo "  p4 -p ${P4_PORT} info"
    else
        echo "  p4 -p ${P4_PORT} info"
    fi
    echo "=========================================="
    echo ""
}

# Logic
map_ids
create_dirs
configure_ssl
initialize
info

echo "Starting Perforce Server on $P4_PORT..."
exec gosu "$P4_USER" /usr/sbin/p4d -r "${P4ROOT}" -p "$P4_PORT" -L "${P4_LOG:-${P4ROOT}/p4d.log}" -v server=3
