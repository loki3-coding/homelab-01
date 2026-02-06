# Quick Start: Energy Monitoring with Tasmota

This is the fastest way to get energy monitoring working in your homelab using a Tasmota-based smart plug.

## What You Need

- **Tasmota Smart Plug** (Shelly Plug S, Sonoff S31, or any Tasmota-flashed device with power monitoring)
- **5 minutes** of setup time
- The plug should be connected to your local network

## Step 1: Find Your Tasmota Device IP

Access your router or use a network scanner to find the Tasmota device IP address.

Test it works:
```bash
# Replace 192.168.1.50 with your device's IP
curl "http://192.168.1.50/cm?cmnd=Status%208"
```

You should see JSON output with power data.

## Step 2: Configure the Exporter Script

SSH to your homelab server:
```bash
ssh username@homelab-01
cd ~/github/homelab-01/system/monitoring/scripts
```

Edit the script and set your device IP:
```bash
nano tasmota-exporter.sh

# Change these lines:
TASMOTA_IP="192.168.1.50"  # YOUR DEVICE IP HERE
DEVICE_NAME="homelab-01"    # Can leave as-is
```

Make it executable:
```bash
chmod +x tasmota-exporter.sh
```

## Step 3: Test the Script

```bash
# Install jq if not already installed
sudo apt install jq -y

# Run the script manually
./tasmota-exporter.sh

# Check if it worked
cat /var/lib/node_exporter/textfile_collector/tasmota_power.prom
```

You should see Prometheus metrics like:
```
tasmota_power_watts{device="homelab-01",type="server"} 85.2
tasmota_voltage_volts{device="homelab-01",type="server"} 120.1
tasmota_current_amperes{device="homelab-01",type="server"} 0.71
...
```

## Step 4: Set Up Automatic Collection

Add the script to cron to run every minute:

```bash
crontab -e

# Add this line at the end:
* * * * * /home/username/github/homelab-01/system/monitoring/scripts/tasmota-exporter.sh
```

## Step 5: Update Node Exporter

Add the textfile collector volume to Node Exporter.

On your homelab server:
```bash
cd ~/github/homelab-01/system/monitoring

# Create the directory if it doesn't exist
sudo mkdir -p /var/lib/node_exporter/textfile_collector
sudo chown -R 1000:1000 /var/lib/node_exporter/textfile_collector
```

Edit `docker-compose.yml` and add the volume to `node-exporter`:

```yaml
  node-exporter:
    # ... existing configuration ...
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/host:ro
      - ./textfile-collector:/textfile-collector:ro
      - /var/lib/node_exporter/textfile_collector:/var/lib/node_exporter/textfile_collector:ro  # ADD THIS LINE
```

Restart Node Exporter:
```bash
docker compose restart node-exporter
```

## Step 6: Verify in Prometheus

1. Open Prometheus: http://localhost:9091 (or https://prometheus.homelab.com via Caddy)
2. Go to **Status → Targets**
3. Check that `node-exporter` is UP
4. Go to **Graph** and query:
   ```promql
   tasmota_power_watts
   ```
5. You should see your current power consumption!

## Step 7: Create Grafana Dashboard

1. Open Grafana: http://localhost:3002 (or https://grafana.homelab.com)
2. Click **+ → Create → Dashboard**
3. Click **Add visualization**
4. Select **Prometheus** datasource

### Panel 1: Current Power Draw (Gauge)

**Query:**
```promql
tasmota_power_watts{device="homelab-01"}
```

**Settings:**
- Visualization: **Gauge**
- Unit: **Watt (W)**
- Thresholds:
  - Green: 0-100W
  - Yellow: 100-150W
  - Red: 150W+

### Panel 2: Power Over Time (Time Series)

**Query:**
```promql
tasmota_power_watts{device="homelab-01"}
```

**Settings:**
- Visualization: **Time series**
- Unit: **Watt (W)**

### Panel 3: Today's Energy Consumption (Stat)

**Query:**
```promql
tasmota_energy_today_kwh{device="homelab-01"}
```

**Settings:**
- Visualization: **Stat**
- Unit: **kWh**

### Panel 4: Estimated Daily Cost (Stat)

**Query (adjust $0.12 to your electricity rate):**
```promql
tasmota_energy_today_kwh{device="homelab-01"} * 0.12
```

**Settings:**
- Visualization: **Stat**
- Unit: **USD ($)**
- Decimals: 2

### Panel 5: Monthly Projection (Stat)

**Query:**
```promql
(increase(tasmota_energy_total_kwh{device="homelab-01"}[30d]) * 0.12)
```

**Settings:**
- Visualization: **Stat**
- Unit: **USD ($)**
- Decimals: 2

Save your dashboard!

## Troubleshooting

### Script not working?

```bash
# Check the log
cat /tmp/tasmota-exporter.log

# Test the Tasmota device directly
curl "http://YOUR-TASMOTA-IP/cm?cmnd=Status%208" | jq .
```

### No metrics in Prometheus?

```bash
# Check if the file exists
ls -la /var/lib/node_exporter/textfile_collector/tasmota_power.prom

# Check Node Exporter logs
docker logs node-exporter

# Verify Node Exporter can read the file
docker exec node-exporter cat /var/lib/node_exporter/textfile_collector/tasmota_power.prom
```

### Cron not running?

```bash
# Check cron service
sudo systemctl status cron

# Check cron logs
grep tasmota /var/log/syslog
```

## Next Steps

- **Set up alerts** for high power usage
- **Create more dashboards** showing power efficiency
- **Track historical trends** to optimize your homelab
- **Add more devices** (just edit the script to scrape multiple IPs)

For more advanced setups, see the full [Energy Monitoring Guide](ENERGY-MONITORING.md).
