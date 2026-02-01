#!/bin/bash
# Export container ID to name mapping as Prometheus metrics
# This script generates a textfile for Prometheus Node Exporter to scrape
# Run this script periodically (e.g., via cron every minute) to keep mappings updated

# Determine the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/../textfile-collector"
OUTPUT_FILE="${OUTPUT_DIR}/container_names.prom"
TEMP_FILE="${OUTPUT_FILE}.tmp"

# Create directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Generate metrics
{
    echo "# HELP container_name_info Container ID to name mapping"
    echo "# TYPE container_name_info gauge"

    # Get all running containers and their info
    docker ps --format '{{.ID}}|{{.Names}}|{{.Image}}' | while IFS='|' read -r id name image; do
        # Get the 12-character short ID
        short_id="${id:0:12}"
        # Output metric with labels
        echo "container_name_info{container_id=\"${short_id}\",container_name=\"${name}\",image=\"${image}\"} 1"
    done
} > "$TEMP_FILE"

# Atomic move to prevent partial reads
mv "$TEMP_FILE" "$OUTPUT_FILE"
