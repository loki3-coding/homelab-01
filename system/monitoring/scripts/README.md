# Monitoring Scripts

## Container Name Exporter

The `export-container-names.sh` script exports Docker container ID to name mappings as Prometheus metrics.

### Setup

1. Make the script executable:
   ```bash
   chmod +x export-container-names.sh
   ```

2. Run it once to generate initial metrics:
   ```bash
   ./export-container-names.sh
   ```

3. Add to crontab to run every minute (keeps container names updated):
   ```bash
   crontab -e
   ```

   Add this line:
   ```
   * * * * * /home/username/github/homelab/system/monitoring/scripts/export-container-names.sh
   ```

   Or use the one-liner:
   ```bash
   (crontab -l 2>/dev/null; echo "* * * * * $(pwd)/export-container-names.sh") | crontab -
   ```

### How It Works

1. The script queries Docker for running containers
2. Generates a Prometheus textfile with `container_name_info` metrics
3. Node Exporter scrapes this textfile
4. Prometheus ingests the metrics
5. Grafana dashboards join container metrics with name info using the `container_id` label

### Troubleshooting

Check if metrics are being generated:
```bash
cat ../textfile-collector/container_names.prom
```

Check if Node Exporter is exposing them:
```bash
curl -s http://localhost:9100/metrics | grep container_name_info
```

Check if Prometheus has them:
```bash
curl -s 'http://localhost:9091/api/v1/query?query=container_name_info' | python3 -m json.tool
```
