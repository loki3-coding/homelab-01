#!/bin/bash
# Tasmota Power Metrics Exporter for Prometheus
# Exports power consumption metrics from Tasmota devices via Node Exporter textfile collector
#
# Prerequisites:
# - Tasmota device with power monitoring (e.g., Shelly Plug S, Sonoff S31)
# - Node Exporter with textfile collector enabled
# - jq installed: sudo apt install jq
#
# Setup:
# 1. Edit TASMOTA_IP and DEVICE_NAME below
# 2. Make executable: chmod +x tasmota-exporter.sh
# 3. Test manually: ./tasmota-exporter.sh
# 4. Add to crontab: * * * * * /path/to/tasmota-exporter.sh
#
# Author: Homelab-01 Monitoring Stack
# Date: 2026-02-06

# Configuration
TASMOTA_IP="192.168.1.50"  # CHANGE THIS: Your Tasmota device IP
DEVICE_NAME="homelab-01"   # CHANGE THIS: Device label for Prometheus
OUTPUT_DIR="/var/lib/node_exporter/textfile_collector"
OUTPUT_FILE="${OUTPUT_DIR}/tasmota_power.prom"
TEMP_FILE="${OUTPUT_FILE}.$$"
LOG_FILE="/tmp/tasmota-exporter.log"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR" 2>/dev/null

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to fetch Tasmota status
fetch_tasmota_status() {
    curl -s --connect-timeout 5 --max-time 10 "http://${TASMOTA_IP}/cm?cmnd=Status%208"
}

# Main execution
log "Starting Tasmota metrics export for ${DEVICE_NAME} (${TASMOTA_IP})"

# Fetch status from Tasmota
RESPONSE=$(fetch_tasmota_status)

# Check if response is valid
if [ -z "$RESPONSE" ] || ! echo "$RESPONSE" | jq -e . >/dev/null 2>&1; then
    log "ERROR: Failed to fetch valid JSON from Tasmota device at ${TASMOTA_IP}"
    log "Response: $RESPONSE"
    exit 1
fi

# Check if ENERGY data exists
if ! echo "$RESPONSE" | jq -e '.StatusSNS.ENERGY' >/dev/null 2>&1; then
    log "ERROR: No ENERGY data in Tasmota response. Is power monitoring enabled?"
    exit 1
fi

# Extract metrics
POWER_WATTS=$(echo "$RESPONSE" | jq -r '.StatusSNS.ENERGY.Power // 0')
VOLTAGE=$(echo "$RESPONSE" | jq -r '.StatusSNS.ENERGY.Voltage // 0')
CURRENT=$(echo "$RESPONSE" | jq -r '.StatusSNS.ENERGY.Current // 0')
TOTAL_KWH=$(echo "$RESPONSE" | jq -r '.StatusSNS.ENERGY.Total // 0')
TODAY_KWH=$(echo "$RESPONSE" | jq -r '.StatusSNS.ENERGY.Today // 0')
YESTERDAY_KWH=$(echo "$RESPONSE" | jq -r '.StatusSNS.ENERGY.Yesterday // 0')
APPARENT_POWER=$(echo "$RESPONSE" | jq -r '.StatusSNS.ENERGY.ApparentPower // 0')
REACTIVE_POWER=$(echo "$RESPONSE" | jq -r '.StatusSNS.ENERGY.ReactivePower // 0')
POWER_FACTOR=$(echo "$RESPONSE" | jq -r '.StatusSNS.ENERGY.Factor // 0')

log "Successfully fetched metrics: Power=${POWER_WATTS}W, Voltage=${VOLTAGE}V, Current=${CURRENT}A"

# Write Prometheus metrics to temp file
cat > "$TEMP_FILE" << EOF
# HELP tasmota_power_watts Current power consumption in watts
# TYPE tasmota_power_watts gauge
tasmota_power_watts{device="$DEVICE_NAME",type="server"} $POWER_WATTS

# HELP tasmota_voltage_volts Current voltage in volts
# TYPE tasmota_voltage_volts gauge
tasmota_voltage_volts{device="$DEVICE_NAME",type="server"} $VOLTAGE

# HELP tasmota_current_amperes Current draw in amperes
# TYPE tasmota_current_amperes gauge
tasmota_current_amperes{device="$DEVICE_NAME",type="server"} $CURRENT

# HELP tasmota_energy_total_kwh Total energy consumption in kWh
# TYPE tasmota_energy_total_kwh counter
tasmota_energy_total_kwh{device="$DEVICE_NAME",type="server"} $TOTAL_KWH

# HELP tasmota_energy_today_kwh Today's energy consumption in kWh
# TYPE tasmota_energy_today_kwh gauge
tasmota_energy_today_kwh{device="$DEVICE_NAME",type="server"} $TODAY_KWH

# HELP tasmota_energy_yesterday_kwh Yesterday's energy consumption in kWh
# TYPE tasmota_energy_yesterday_kwh gauge
tasmota_energy_yesterday_kwh{device="$DEVICE_NAME",type="server"} $YESTERDAY_KWH

# HELP tasmota_apparent_power_va Apparent power in VA
# TYPE tasmota_apparent_power_va gauge
tasmota_apparent_power_va{device="$DEVICE_NAME",type="server"} $APPARENT_POWER

# HELP tasmota_reactive_power_var Reactive power in VAR
# TYPE tasmota_reactive_power_var gauge
tasmota_reactive_power_var{device="$DEVICE_NAME",type="server"} $REACTIVE_POWER

# HELP tasmota_power_factor Power factor (0-1)
# TYPE tasmota_power_factor gauge
tasmota_power_factor{device="$DEVICE_NAME",type="server"} $POWER_FACTOR

# HELP tasmota_scrape_success Whether the scrape was successful
# TYPE tasmota_scrape_success gauge
tasmota_scrape_success{device="$DEVICE_NAME",type="server"} 1

# HELP tasmota_scrape_timestamp_seconds Timestamp of last successful scrape
# TYPE tasmota_scrape_timestamp_seconds gauge
tasmota_scrape_timestamp_seconds{device="$DEVICE_NAME",type="server"} $(date +%s)
EOF

# Atomically move temp file to final location
mv "$TEMP_FILE" "$OUTPUT_FILE"

log "Metrics exported successfully to $OUTPUT_FILE"

# Clean up old log entries (keep last 1000 lines)
if [ -f "$LOG_FILE" ]; then
    tail -n 1000 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi

exit 0
