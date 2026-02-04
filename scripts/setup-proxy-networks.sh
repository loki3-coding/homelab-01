#!/bin/bash

# Setup Docker networks required for Caddy reverse proxy
# This script creates all necessary Docker networks for service communication

set -e

echo "========================================="
echo "Setting up Docker networks for Caddy"
echo "========================================="
echo

# Function to create network if it doesn't exist
create_network_if_not_exists() {
    local network_name=$1
    if docker network ls | grep -q "$network_name"; then
        echo "✓ Network '$network_name' already exists"
    else
        echo "→ Creating network '$network_name'..."
        docker network create "$network_name"
        echo "✓ Network '$network_name' created"
    fi
}

# Create required networks
echo "Creating required networks..."
echo

create_network_if_not_exists "proxy"
create_network_if_not_exists "db-net"
create_network_if_not_exists "monitoring-net"
create_network_if_not_exists "immich-net"
create_network_if_not_exists "gitea-net"

echo
echo "========================================="
echo "Network setup complete!"
echo "========================================="
echo
echo "Existing networks:"
docker network ls | grep -E "NETWORK ID|proxy|db-net|monitoring-net|immich-net|gitea-net"
echo
echo "You can now start Caddy with:"
echo "  cd ~/github/homelab-01/platform/caddy && docker compose up -d"
