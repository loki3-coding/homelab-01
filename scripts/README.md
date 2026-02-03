# Scripts - Automation & Management

Collection of automation scripts for backup, service management, and system maintenance.

---

##  Documentation Navigation

- **[← Back to Main README](../README.md)**

---

##  Available Scripts

### Service Management

#### `start-all-services.sh`
Starts all homelab services in correct dependency order.

**Usage:**
```bash
ssh username@homelab-01
cd ~/github/homelab-01
./scripts/start-all-services.sh
```

**What it does:**
1. Checks Docker is running
2. Creates required networks
3. Starts Postgres first
4. Waits for Postgres health check
5. Starts dependent services (Gitea, Immich)
6. Starts remaining services

**Note:** pgAdmin is excluded from automatic startup. Start manually when needed.

#### `stop-all-services.sh`
Stops all homelab services gracefully.

**Usage:**
```bash
ssh username@homelab-01
cd ~/github/homelab-01
./scripts/stop-all-services.sh
```
