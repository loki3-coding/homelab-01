#!/bin/bash
# Script to generate container ID to name mapping for Grafana dashboard
# This script queries Docker to get current container IDs and names,
# then outputs a mapping that can be used in Grafana transformations

docker ps --format '{"id": "{{.ID}}", "name": "{{.Names}}"}' | \
  python3 -c '
import sys, json
containers = [json.loads(line) for line in sys.stdin]
print("Container ID to Name Mapping:")
print("=" * 50)
for c in containers:
    print(f"  {c[\"id\"]}: {c[\"name\"]}")
print("\nGrafana Transformation Config:")
print("=" * 50)
for c in containers:
    print(f"{{\"id\": \"renameByRegex\", \"options\": {{\"regex\": \"{c[\"id\"]}\", \"renamePattern\": \"{c[\"name\"]}\"}}}},")'
