# Hardware Specifications

## Homelab Server

### Machine: Acer Aspire V3-572G

**Basic Specifications:**
- **Model**: Acer Aspire V3-572G
- **Form Factor**: Laptop (15.6" display)
- **CPU**: Intel Core i5-5200U (5th gen, Broadwell)
  - Dual-core, 4 threads
  - Base: 2.2GHz, Turbo: 2.7GHz
  - TDP: 15W
- **RAM**: 8GB DDR3L-1600
  - Single/Dual channel configuration
  - Expandable (check specific model)
- **Graphics**:
  - Intel HD Graphics 5500 (integrated)
  - NVIDIA GeForce 840M (dedicated, 2GB)

### Storage Configuration

**Primary Storage (OS & Docker):**
- **Type**: 128GB SSD
- **Purpose**:
  - Ubuntu Server 24.04 LTS installation
  - Docker images and containers
  - System services
  - PostgreSQL database
  - Gitea repositories
- **Mount**: `/` (root filesystem)

**Secondary Storage (Data):**
- **Type**: 500GB HDD (7200 RPM)
- **Purpose**:
  - Immich photo/video uploads
  - Large file storage
  - Backups
  - Media files
- **Mount**: `/home/loki3/immich`

### Network

- **Ethernet**: Gigabit Ethernet (1000Mbps)
- **WiFi**: 802.11ac (not used for server)
- **Connection**: Wired Ethernet to router
- **Static IP**: 192.168.100.200

### Power & Cooling

- **Power Supply**: AC adapter (65W typical)
- **UPS**: Not configured (recommended for data protection)
- **Cooling**: Laptop cooling system
  - Monitor temps with `sensors` command
  - Ensure adequate ventilation

## Performance Considerations

### RAM (8GB)

With 8GB RAM, the homelab can comfortably run:
- ✓ PostgreSQL (shared database)
- ✓ Gitea (Git server)
- ✓ Immich (photo management)
- ✓ Nginx (reverse proxy)
- ✓ Pi-hole (DNS ad blocking)
- ✓ Homepage (dashboard)
- ✓ Portainer (Docker management)
- ✓ Grafana + Prometheus (monitoring)

**Current Usage:**
```
Total RAM: 8GB
Typical Usage: ~5-6GB (with all services running)
Buffer/Cache: ~1-2GB
Available: ~1GB
```

**Tips:**
- Monitor memory with `free -h` and Grafana
- Docker uses memory efficiently with shared layers
- Avoid running memory-intensive builds on server
- Use MacBook for development/compilation

### Storage Strategy

**128GB SSD (Fast Storage):**
- OS and essential system files: ~10GB
- Docker images and containers: ~20-30GB
- PostgreSQL database: ~5-10GB
- Gitea repositories: ~5GB
- Free space buffer: ~60GB
- **Total Used**: ~60-70GB typical

**500GB HDD (Bulk Storage):**
- Immich photos/videos: Grows over time
- Future: Backups, media libraries
- **Current Usage**: Varies based on photo uploads

### CPU Performance

The Intel Core i5-5200U is sufficient for:
- Multiple simultaneous Docker containers
- Web service requests (Nginx, Gitea, Immich)
- Database queries (PostgreSQL)
- Image processing (Immich thumbnails)

**Notes:**
- CPU is not heavily loaded most of the time
- Peak usage during Immich photo uploads/processing
- Background tasks scheduled during off-hours

### Network Performance

Gigabit Ethernet provides:
- Fast file transfers to/from Immich
- Quick Docker image pulls
- Responsive web interface access
- LAN-only access (no public exposure)

## Why This Hardware Works

### Laptop as Server

**Advantages:**
- Built-in UPS (battery backup during power outages)
- Compact form factor
- Low power consumption
- Quiet operation
- Integrated display for console access

**Considerations:**
- Keep laptop open or configure lid-close behavior
- Ensure good ventilation
- Monitor temperatures
- Battery acts as short-term UPS

### Cost Efficiency

This laptop was repurposed hardware (not new purchase):
- **Total Investment**: ~950k VND for SSD + accessories
- **Reused**: Existing laptop hardware
- **Result**: Full-featured homelab for minimal cost

### Upgrade Path

**Possible Future Upgrades:**
- RAM: Upgrade to 16GB if needed (check compatibility)
- Storage: Replace HDD with larger SSD
- Network: Add second NIC for network segregation
- UPS: Add external UPS for better power protection

## Monitoring

### Temperature Monitoring

```bash
# Install sensors
sudo apt install lm-sensors

# Detect sensors
sudo sensors-detect

# View temperatures
sensors
```

**Normal Operating Temps:**
- CPU: 40-60°C idle, 60-80°C under load
- HDD: 30-45°C
- SSD: 30-50°C

### Resource Monitoring

**Via Grafana:**
- Access: http://homelab-01:3002
- Real-time CPU, RAM, disk, network graphs
- Container metrics via cAdvisor
- System metrics via Node Exporter
- Service status

**Via Command Line:**
```bash
# CPU usage
htop

# Memory usage
free -h

# Disk usage
df -h

# Network stats
ifconfig
netstat -i
```

## Power Management

### Sleep/Suspend Disabled

The server is configured to never sleep:
```bash
# Prevent sleep when lid is closed
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

### Power Consumption

**Estimated:**
- Idle: ~15-20W
- Under load: ~30-40W
- Monthly cost: Varies by electricity rate

**Optimization:**
- Laptop CPUs are power-efficient
- No dedicated GPU active for server tasks
- Minimal display power (can be turned off)

## Physical Setup

### Location

- Server room / dedicated space
- Good ventilation required
- Away from moisture/heat
- Wired ethernet connection
- Access to power outlet

### Maintenance

- **Weekly**: Check temperatures and disk usage
- **Monthly**: Update system packages
- **Quarterly**: Clean dust from vents
- **Yearly**: Check battery health

## Backup Strategy

### Critical Data

**Should be backed up:**
- PostgreSQL databases (`platform/postgres/data/`)
- Gitea repositories (Docker volumes)
- Immich photos (`/home/loki3/immich/`)
- Service configuration files (`.env` files)
- Nginx configs (`system/nginx/conf.d/`)

**Backup Methods:**
- External USB drive
- Network-attached storage (NAS)
- Cloud backup (encrypted)
- Regular snapshots

### Recovery

In case of hardware failure:
- OS reinstall on new hardware
- Restore Docker volumes
- Restore data from HDD/backups
- Run `./scripts/start-all-services.sh`

---

**Last Updated**: 2026-01-30
**Machine**: Acer Aspire V3-572G
**Configuration**: 8GB RAM, 128GB SSD, 500GB HDD
