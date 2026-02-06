# Monitoring Scripts

This directory contains utility scripts for the monitoring stack.

## Available Scripts

1. **[Container Name Exporter](#container-name-exporter)** - Maps Docker container IDs to names for Grafana
2. **[Tasmota Power Exporter](#tasmota-power-exporter)** - Exports energy metrics from Tasmota smart plugs

---

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

---

## Tasmota Power Exporter

The `tasmota-exporter.sh` script exports power consumption metrics from Tasmota-based smart plugs to Prometheus.

**Status**: ❌ Not configured (requires Tasmota device)

### Prerequisites

- Tasmota smart plug with power monitoring (Shelly Plug S, Sonoff S31, etc.)
- Device connected to your network
- `jq` installed: `sudo apt install jq`

### Quick Setup

See **[Quick Start Guide](../QUICK-START-ENERGY.md)** for step-by-step instructions.

### Manual Setup

1. **Configure the script**:
   ```bash
   nano tasmota-exporter.sh

   # Edit these variables:
   TASMOTA_IP="192.168.1.50"  # Your device IP
   DEVICE_NAME="homelab-01"    # Device label
   ```

2. **Make executable**:
   ```bash
   chmod +x tasmota-exporter.sh
   ```

3. **Test it**:
   ```bash
   ./tasmota-exporter.sh
   cat /var/lib/node_exporter/textfile_collector/tasmota_power.prom
   ```

4. **Add to crontab** (run every minute):
   ```bash
   crontab -e
   # Add:
   * * * * * /home/username/github/homelab-01/system/monitoring/scripts/tasmota-exporter.sh
   ```

5. **Update Node Exporter** to mount the textfile collector directory (see Quick Start Guide)

### Exported Metrics

| Metric | Description | Type |
|--------|-------------|------|
| `tasmota_power_watts` | Current power consumption in watts | gauge |
| `tasmota_voltage_volts` | Current voltage | gauge |
| `tasmota_current_amperes` | Current draw in amperes | gauge |
| `tasmota_energy_total_kwh` | Total energy consumption (lifetime) | counter |
| `tasmota_energy_today_kwh` | Today's energy consumption | gauge |
| `tasmota_energy_yesterday_kwh` | Yesterday's energy consumption | gauge |
| `tasmota_apparent_power_va` | Apparent power (VA) | gauge |
| `tasmota_reactive_power_var` | Reactive power (VAR) | gauge |
| `tasmota_power_factor` | Power factor (0-1) | gauge |

### Example Grafana Queries

**Current power consumption**:
```promql
tasmota_power_watts{device="homelab-01"}
```

**Today's energy usage**:
```promql
tasmota_energy_today_kwh{device="homelab-01"}
```

**Estimated monthly cost** (at $0.12/kWh):
```promql
increase(tasmota_energy_total_kwh{device="homelab-01"}[30d]) * 0.12
```

### Troubleshooting

**Script failing**:
```bash
# Check the log
cat /tmp/tasmota-exporter.log

# Test Tasmota API directly
curl "http://YOUR-TASMOTA-IP/cm?cmnd=Status%208" | jq .
```

**No metrics in Prometheus**:
```bash
# Check file was created
ls -la /var/lib/node_exporter/textfile_collector/tasmota_power.prom

# Check Node Exporter can access it
docker exec node-exporter cat /var/lib/node_exporter/textfile_collector/tasmota_power.prom

# Check if exposed by Node Exporter
curl http://localhost:9100/metrics | grep tasmota_power_watts
```

### Additional Resources

- **[Full Energy Monitoring Guide](../ENERGY-MONITORING.md)** - Alternative methods (IPMI, Scaphandre, UPS)
- **[Tasmota Documentation](https://tasmota.github.io/docs/Power-Monitoring/)** - Official Tasmota power monitoring docs
