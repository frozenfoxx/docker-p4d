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
    # Check if both directories exist. 
    # If either is missing, we proceed with creation and permission setting.
    if [ ! -d "$P4ROOT" ] || [ ! -d "$P4_DEPOTS" ]; then
        echo "One or more directories missing. Initializing setup..."

        # Create directories if they don't exist
        mkdir -p "$P4ROOT" "$P4_DEPOTS"

        # Ensure permissions are correct
        echo "Ensuring file permissions for P4ROOT and P4_DEPOTS to match user '$P4_USER' ($(id -u $P4_USER)/$(id -g $P4_USER))..."
        chown $P4_USER:$P4_USER "$P4ROOT"
        chown $P4_USER:$P4_USER "$P4_DEPOTS"
    else
        echo "Directories P4ROOT and P4_DEPOTS already exist. Skipping creation and chown."
    fi
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
        # Check if a group with this GID already exists
        if getent group "$GID" >/dev/null 2>&1; then
            EXISTING_GROUP=$(getent group "$GID" | cut -d: -f1)
            echo "Group with GID $GID already exists ($EXISTING_GROUP). Adding user '$P4_USER' to this group..."
            usermod -g "$GID" "$P4_USER"
        else
            echo "Modifying group '$P4_USER' GID to $GID..."
            groupmod -g "$GID" "$P4_USER"
            usermod -g "$GID" "$P4_USER"
        fi
    fi
}

# Logic
map_ids
create_dirs
initialize

echo "Starting Perforce Server on $P4_PORT..."
# Exec into p4d as the perforce user
exec su - $P4_USER -c "/usr/sbin/p4d -r '$P4ROOT' -p $P4_PORT -L '$P4_LOG' -v server=3"