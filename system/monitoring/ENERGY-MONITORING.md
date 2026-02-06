# Energy Monitoring for Homelab-01

This guide explains how to monitor power consumption of your homelab server using various methods.

## Current Status

**Energy monitoring is NOT currently configured.** This document provides implementation options.

## Available Methods

### Method 1: IPMI/BMC Power Monitoring (Recommended for Servers)

If your server has IPMI/iLO/iDRAC, this is the most accurate method as it reads directly from the server's power supply unit.

**Prerequisites:**
- Server with IPMI/BMC support
- IPMI configured and accessible from the monitoring network

**Setup:**

1. **Install IPMI Exporter**

Add to `docker-compose.yml`:

```yaml
  # IPMI Exporter - Server power consumption
  ipmi-exporter:
    image: prometheuscommunity/ipmi-exporter:v1.8.0
    container_name: ipmi-exporter
    restart: unless-stopped
    command:
      - "--config.file=/config.yml"
    volumes:
      - ./ipmi-exporter/config.yml:/config.yml:ro
    ports:
      - "9290:9290"
    networks:
      - monitoring-net
    privileged: true
```

2. **Create IPMI Exporter Config**

Create `system/monitoring/ipmi-exporter/config.yml`:

```yaml
# IPMI Exporter Configuration
modules:
  default:
    user: "ADMIN"
    pass: "your-ipmi-password"
    driver: "LAN_2_0"
    privilege: "user"
    timeout: 10000
    collectors:
      - bmc
      - ipmi
      - chassis
      - dcmi
      - sel
    exclude_sensor_ids: []
```

3. **Add to Prometheus**

Add to `prometheus/prometheus.yml`:

```yaml
  # IPMI Exporter - Power consumption
  - job_name: "ipmi"
    scrape_interval: 30s
    static_configs:
      - targets: ["ipmi-exporter:9290"]
        labels:
          instance: "homelab-01"
    params:
      target: ["192.168.1.100"]  # Your server's IPMI IP
```

**Key Metrics:**
- `ipmi_dcmi_power_consumption_watts` - Current power draw in watts
- `ipmi_temperature_celsius` - Temperature sensors
- `ipmi_fan_speed_rpm` - Fan speeds

---

### Method 2: Smart Plug/PDU Monitoring (Easiest)

Use a smart plug with API access to monitor power consumption at the outlet level.

**Supported Devices:**
- **TP-Link Kasa** (HS110, HS300)
- **Shelly Plug** (Shelly Plug S, Shelly EM)
- **Tasmota** (ESP8266/ESP32 based devices)
- **Tuya/Smart Life** compatible plugs

#### Option 2A: Tasmota Devices (Recommended)

**Prerequisites:**
- Smart plug flashed with Tasmota firmware
- Device connected to your network

**Setup:**

1. **Enable Tasmota Metrics**

Access your Tasmota device web UI (e.g., `http://192.168.1.50`) and configure:

```
Configuration → Configure Other:
  Web Server: 2 (Web Admin)
  MQTT: (optional but recommended)
```

2. **Add Tasmota Integration Script**

Create `system/monitoring/scripts/tasmota-exporter.sh`:

```bash
#!/bin/bash
# Tasmota power metrics exporter for Prometheus
# Run via cron or Node Exporter textfile collector

TASMOTA_IP="192.168.1.50"  # Your Tasmota device IP
OUTPUT_FILE="/var/lib/node_exporter/textfile_collector/tasmota_power.prom"

# Fetch status from Tasmota
STATUS=$(curl -s "http://${TASMOTA_IP}/cm?cmnd=Status%208" | jq -r '.StatusSNS.ENERGY')

# Extract metrics
POWER_WATTS=$(echo "$STATUS" | jq -r '.Power')
VOLTAGE=$(echo "$STATUS" | jq -r '.Voltage')
CURRENT=$(echo "$STATUS" | jq -r '.Current')
TOTAL_KWH=$(echo "$STATUS" | jq -r '.Total')
TODAY_KWH=$(echo "$STATUS" | jq -r '.Today')

# Write Prometheus metrics
cat > "$OUTPUT_FILE" << EOF
# HELP tasmota_power_watts Current power consumption in watts
# TYPE tasmota_power_watts gauge
tasmota_power_watts{device="homelab-01"} $POWER_WATTS

# HELP tasmota_voltage_volts Current voltage
# TYPE tasmota_voltage_volts gauge
tasmota_voltage_volts{device="homelab-01"} $VOLTAGE

# HELP tasmota_current_amperes Current draw in amperes
# TYPE tasmota_current_amperes gauge
tasmota_current_amperes{device="homelab-01"} $CURRENT

# HELP tasmota_energy_total_kwh Total energy consumption in kWh
# TYPE tasmota_energy_total_kwh counter
tasmota_energy_total_kwh{device="homelab-01"} $TOTAL_KWH

# HELP tasmota_energy_today_kwh Today's energy consumption in kWh
# TYPE tasmota_energy_today_kwh gauge
tasmota_energy_today_kwh{device="homelab-01"} $TODAY_KWH
EOF
```

3. **Make Script Executable and Schedule**

```bash
chmod +x system/monitoring/scripts/tasmota-exporter.sh

# Add to crontab (run every minute)
crontab -e
# Add:
* * * * * /home/username/github/homelab-01/system/monitoring/scripts/tasmota-exporter.sh
```

4. **Update Node Exporter Volume**

Add to `docker-compose.yml` under `node-exporter` service:

```yaml
    volumes:
      # ... existing volumes ...
      - /var/lib/node_exporter/textfile_collector:/var/lib/node_exporter/textfile_collector:ro
```

**Restart Node Exporter:**
```bash
cd ~/github/homelab-01/system/monitoring
docker compose restart node-exporter
```

#### Option 2B: TP-Link Kasa

Use `tplink_exporter`:

```yaml
  # TP-Link Kasa Exporter
  tplink-exporter:
    image: fffonion/tplink-plug-exporter:latest
    container_name: tplink-exporter
    restart: unless-stopped
    environment:
      - TPLINK_DEVICES=192.168.1.50  # Your Kasa plug IP
    ports:
      - "9233:9233"
    networks:
      - monitoring-net
```

Add to Prometheus:
```yaml
  - job_name: "tplink"
    static_configs:
      - targets: ["tplink-exporter:9233"]
```

**Key Metrics:**
- `tplink_plug_power_watts`
- `tplink_plug_total_wh`
- `tplink_plug_voltage_volts`
- `tplink_plug_current_amperes`

---

### Method 3: Software-Based Power Estimation (Linux)

Use `scaphandre` to estimate power consumption based on CPU usage (requires Intel RAPL or similar).

**Prerequisites:**
- Linux kernel with RAPL support (Intel Sandy Bridge or newer, some AMD processors)
- Access to `/sys/class/powercap/intel-rapl`

**Setup:**

1. **Add Scaphandre to docker-compose.yml**

```yaml
  # Scaphandre - Software power monitoring
  scaphandre:
    image: hubblo/scaphandre:latest
    container_name: scaphandre
    restart: unless-stopped
    command: prometheus
    ports:
      - "8080:8080"
    networks:
      - monitoring-net
    privileged: true
    volumes:
      - /sys/class/powercap:/sys/class/powercap:ro
      - /proc:/proc:ro
```

2. **Add to Prometheus**

```yaml
  - job_name: "scaphandre"
    static_configs:
      - targets: ["scaphandre:8080"]
        labels:
          instance: "homelab-01"
```

**Key Metrics:**
- `scaph_host_power_microwatts` - Total host power consumption
- `scaph_process_power_consumption_microwatts` - Per-process power
- `scaph_socket_power_microwatts` - Per-CPU socket power

**Limitations:**
- Estimates only, not actual measurements
- Only tracks CPU power, not total system power
- Requires specific CPU support

---

### Method 4: UPS Monitoring (Bonus)

If you have a UPS with USB/network monitoring, use `nut-exporter`.

**Setup:**

1. **Install Network UPS Tools (NUT) on host**

```bash
sudo apt install nut nut-client
```

2. **Configure NUT** (edit `/etc/nut/ups.conf`):

```ini
[homelab-ups]
    driver = usbhid-ups
    port = auto
    desc = "Homelab UPS"
```

3. **Add NUT Exporter**

```yaml
  # NUT Exporter - UPS metrics
  nut-exporter:
    image: hon95/prometheus-nut-exporter:latest
    container_name: nut-exporter
    restart: unless-stopped
    environment:
      - NUT_SERVERS=homelab-ups@localhost
    ports:
      - "9199:9199"
    networks:
      - monitoring-net
    volumes:
      - /var/run/nut:/var/run/nut:ro
```

4. **Add to Prometheus**

```yaml
  - job_name: "ups"
    static_configs:
      - targets: ["nut-exporter:9199"]
```

**Key Metrics:**
- `ups_load_percent` - Current load percentage
- `ups_battery_charge_percent` - Battery level
- `ups_input_voltage_volts` - Input voltage
- `ups_power_watts` - Current power draw

---

## Recommended Grafana Dashboards

### Option 1: Import Community Dashboard

1. Go to Grafana: http://localhost:3002
2. Click **+ → Import**
3. Use dashboard ID:
   - **11111** - IPMI Exporter Dashboard
   - **15155** - Scaphandre Power Monitoring
   - **14371** - Smart Plug Energy Monitoring

### Option 2: Create Custom Dashboard

Create `grafana/provisioning/dashboards/json/energy-monitoring.json` with panels:

**Key Panels to Include:**
1. **Current Power Draw** (Gauge)
   ```promql
   # IPMI
   ipmi_dcmi_power_consumption_watts

   # Tasmota
   tasmota_power_watts

   # Scaphandre
   scaph_host_power_microwatts / 1000000
   ```

2. **Power Over Time** (Time Series)
   ```promql
   # Same queries as above
   ```

3. **Daily Energy Consumption** (Bar Chart)
   ```promql
   # Calculate kWh per day
   increase(tasmota_energy_total_kwh[24h])
   ```

4. **Estimated Monthly Cost** (Stat)
   ```promql
   # Assuming $0.12/kWh electricity rate
   (increase(tasmota_energy_total_kwh[30d]) * 0.12)
   ```

5. **Power Efficiency** (Time Series)
   ```promql
   # Watts per container
   tasmota_power_watts / count(container_memory_usage_bytes{id=~"/system.slice/docker-.*"})
   ```

---

## Grafana Panel Examples

### Current Power Consumption (Gauge)

```json
{
  "datasource": "prometheus",
  "targets": [
    {
      "expr": "tasmota_power_watts{device='homelab-01'}",
      "legendFormat": "Current Power (W)"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "watt",
      "thresholds": {
        "steps": [
          {"color": "green", "value": 0},
          {"color": "yellow", "value": 100},
          {"color": "red", "value": 200}
        ]
      }
    }
  }
}
```

### Daily Energy Cost (Stat)

```json
{
  "datasource": "prometheus",
  "targets": [
    {
      "expr": "(increase(tasmota_energy_total_kwh{device='homelab-01'}[24h]) * 0.12)",
      "legendFormat": "Daily Cost ($)"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "currencyUSD",
      "decimals": 2
    }
  }
}
```

---

## Implementation Checklist

- [ ] Choose monitoring method (IPMI / Smart Plug / Software)
- [ ] Set up exporter (IPMI exporter / Tasmota script / Scaphandre)
- [ ] Add scrape config to Prometheus
- [ ] Restart monitoring stack
- [ ] Verify metrics in Prometheus: http://localhost:9091/targets
- [ ] Import or create Grafana dashboard
- [ ] Configure alerts for high power consumption (optional)
- [ ] Set up cost tracking with your electricity rate

---

## Cost Estimation

**Example calculations:**

If your server draws **80W average**:
- **Daily**: 80W × 24h = 1.92 kWh × $0.12 = **$0.23/day**
- **Monthly**: 1.92 kWh × 30 = 57.6 kWh × $0.12 = **$6.91/month**
- **Yearly**: 57.6 kWh × 12 = 691.2 kWh × $0.12 = **$82.94/year**

Adjust `$0.12/kWh` to your local electricity rate.

---

## Troubleshooting

### IPMI Exporter Issues

```bash
# Test IPMI connection from Docker host
ipmitool -I lanplus -H 192.168.1.100 -U ADMIN -P password power status

# Check exporter logs
docker logs ipmi-exporter
```

### Tasmota Script Issues

```bash
# Test Tasmota API manually
curl "http://192.168.1.50/cm?cmnd=Status%208"

# Check script output
cat /var/lib/node_exporter/textfile_collector/tasmota_power.prom

# Check Node Exporter logs
docker logs node-exporter
```

### Scaphandre Issues

```bash
# Check RAPL availability
ls -la /sys/class/powercap/intel-rapl*/energy_uj

# Check container logs
docker logs scaphandre
```

---

## Next Steps

1. **Choose your method** based on available hardware
2. **Implement the exporter** using instructions above
3. **Create Grafana dashboard** to visualize power consumption
4. **Set up alerts** for abnormal power usage
5. **Track costs** over time to optimize efficiency

---

## Additional Resources

- [Prometheus IPMI Exporter](https://github.com/prometheus-community/ipmi_exporter)
- [Scaphandre Documentation](https://hubblo-org.github.io/scaphandre/)
- [Tasmota Energy Monitoring](https://tasmota.github.io/docs/Power-Monitoring/)
- [Network UPS Tools](https://networkupstools.org/)
- [Grafana Energy Dashboards](https://grafana.com/grafana/dashboards/?search=energy)
