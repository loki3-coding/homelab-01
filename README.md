# homelab-01

A compact, Docker Compose–driven personal homelab repository for local/home server services and configuration.

---

## 🚀 Overview

This repository collects docker-compose stacks and configuration for the services I run at home. It groups each service in its own directory so you can run, update, and manage them independently.

My local homepage is available at: [http://homelab-01/](http://homelab-01/)

**Included services:** Gitea (self-hosted Git), a static homepage, Immich (photo & video management), Nginx reverse proxy (with TLS certs), Pi-hole, and a Postgres instance for service data.

**Note:** This repo is actively expanded — more services will be added over time (for example: monitoring, backups, home automation, metrics, etc.). Check the repository issues or the (planned) `ROADMAP.md` for planned additions, or open an issue to suggest a service.

---

## Repository structure

| Service | Description | Directory |
| --- | --- | --- |
| [Gitea](https://about.gitea.com/) | Self-hosted Git service (repositories, issues, web UI) | [`gitea/`](gitea/) |
| [Homepage](https://gethomepage.dev/) | Static homepage and site settings (`homepage/config/`) | [`homepage/`](homepage/) |
| [Immich](https://immich.app/) | Self-hosted photo & video backup solution | [`immich/`](immich/) |
| [Nginx](https://nginx.org/) | Reverse proxy, TLS termination and vhost configs (`conf.d/`, `certs/`) | [`nginx/`](nginx/) |
| [Pi-hole](https://pi-hole.net/) | Network-level ad and tracker blocking | [`pi-hole/`](pi-hole/) |
| [Postgres](https://www.postgresql.org/) | Dedicated PostgreSQL instance for service data | [`postgres/`](postgres/) |
| Planned / future | Monitoring, backups, home automation, metrics, etc. (tracked in `ROADMAP.md`) | — |

---

## Quick start

Requirements: Docker Engine and Docker Compose (v2) installed on your macOS host.

Start a single service:

```bash
cd nginx && docker compose up -d
```

Start multiple services at once (example combining files):

```bash
docker compose -f nginx/docker-compose.yml -f gitea/docker-compose.yml -f homepage/docker-compose.yml -f immich/docker-compose.yml -f pi-hole/docker-compose.yml -f postgres/docker-compose.yml up -d
```

**Important:** Start `postgres` before `gitea` and `immich`. Both require a reachable Postgres database at startup; if Postgres isn't available, they may fail to initialize and exit.

Recommended ways to start in order:

```bash
# start Postgres first, then Gitea and Immich
docker compose -f postgres/docker-compose.yml up -d && docker compose -f gitea/docker-compose.yml -f immich/docker-compose.yml up -d

# or start Postgres first followed by the rest
docker compose -f postgres/docker-compose.yml up -d && docker compose -f nginx/docker-compose.yml -f gitea/docker-compose.yml -f homepage/docker-compose.yml -f immich/docker-compose.yml -f pi-hole/docker-compose.yml up -d
```

Notes:
- Each service is self-contained; you can `cd` into the service folder and use `docker compose` there to manage it.
- Check service-specific directories for additional README or config instructions.
- If you prefer starting all services in one command, consider ensuring Postgres has a healthcheck and that Gitea is configured to retry DB connections on startup.

---

## Local machine vs homeserver

I use a MacBook Pro (Apple M1) with **16GB RAM**. To avoid overloading the laptop, services that can run independently (Docker stacks, Gitea, home services, etc.) are hosted on a separate **homeserver**, which reduces CPU/RAM usage on the Mac.

**Short:** MacBook is reserved for editor / AI cursor / browser; long-running services run on the homeserver.


---

## 🔧 Common tasks

- View logs: `docker compose logs -f` (run from the service folder)
- Update images: `docker compose pull && docker compose up -d`
- Stop service: `docker compose down`

---

## Configuration & data

Service configuration files can be found inside each service folder (e.g., `homepage/config/`). Docker volumes are used to persist data (database files, service configs). If you need to migrate data, inspect the `volumes:` section of the service's `docker-compose.yml`.

---

## License & contact

No license file is included in this repository.

For questions or help, open an issue in this repository.

---
