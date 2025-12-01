#!/usr/bin/env bash
set -e

# Variables
FQDN="${FQDN:-perforce.local}"
P4_DEPOTS="${P4_DEPOTS:-/opt/perforce/depots}"
P4_LOG="${P4_LOG:-/opt/perforce/server/p4d.log}"
P4_PORT="${P4_PORT:-1666}"
P4_USER="perforce"

## P4 variables
P4ROOT="${P4ROOT:-/opt/perforce/server}"
P4PORT="ssl:${FQDN}:${P4_PORT}"

# Functions
## Create and manage directories
create_dirs()
{
    # Create directories if they don't exist
    mkdir -p "$P4ROOT" "$P4_DEPOTS"

    # Ensure permissions are correct
    echo "Ensuring file permissions for P4ROOT and P4_DEPOTS to match user '$P4_USER' ($(id -u $P4_USER)/$(id -g $P4_USER))..."
    chown -R $P4_USER:$P4_USER "$P4ROOT"
    chown -R $P4_USER:$P4_USER "$P4_DEPOTS"
}

## Check if this is a fresh install and intialize if necessary
initialize()
{
    # Check if this is a fresh install (no db.counters file)
    if [ ! -f "$P4ROOT/db.counters" ]; then
        echo "Initializing new Perforce Server..."
        
        # Run server initialization as the 'perforce' user
        su - $P4_USER -c "/usr/sbin/p4d -r '$P4ROOT' -p $P4_PORT -C1 -xi"
    fi
}

## Map IDs for the P4 user
map_ids()
{
    # If UID is provided and it differs from the default 'perforce' user's current UID, update it
    if [ -n "$UID" ] && [ "$UID" != "$(id -u $P4_USER)" ]; then
        echo "Modifying user '$P4_USER' UID to $UID..."
        usermod -u "$UID" "$P4_USER"
    fi

    # If GID is provided and it differs from the 'perforce' user's current primary GID, update it
    if [ -n "$GID" ] && [ "$GID" != "$(id -g $P4_USER)" ]; then
        echo "Modifying group '$P4_USER' GID to $GID..."
        groupmod -g "$GID" "$P4_USER"
        # Also update the primary group ID for the user
        usermod -g "$GID" "$P4_USER"
    fi
}

# Logic
map_ids
create_dirs
initialize

echo "Starting Perforce Server on $P4_PORT..."
# Exec into p4d as the perforce user
exec su - $P4_USER -c "/usr/sbin/p4d -r '$P4ROOT' -p $P4_PORT -L '$P4_LOG' -v server=3"