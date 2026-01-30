# Security Policy

## Supported Versions

This homelab is a personal project and receives security updates on a best-effort basis. The main branch is considered the actively maintained version.

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| older commits | :x: |

## Security Best Practices

This homelab implementation follows security best practices:

### Network Security
- ✅ **Firewall enabled** - UFW configured with restrictive rules
- ✅ **LAN-only access** - Services not exposed to public internet
- ✅ **VPN access** - Tailscale for secure remote access
- ✅ **Network segregation** - Docker networks isolate services

### Authentication & Access
- ✅ **SSH key authentication only** - Password authentication disabled
- ✅ **No root login** - Root SSH access disabled
- ✅ **Strong passwords** - 20+ character passwords recommended
- ✅ **Unique credentials** - Different passwords per service
- ✅ **LAN-restricted SSH** - SSH only accessible on LAN interface

### Service Security
- ✅ **Minimal attack surface** - Only required ports exposed
- ✅ **Service isolation** - Docker containers with separate networks
- ✅ **Regular updates** - Unattended security updates enabled
- ✅ **No public exposure** - Services behind firewall/VPN

### Data Protection
- ⚠️ **Backups** - Manual backup process (automation recommended)
- ✅ **Encrypted credentials** - Secrets in `.env` files (gitignored)
- ✅ **Access logging** - System and service logs maintained

## Reporting a Vulnerability

### For Security Researchers

If you discover a security vulnerability in this homelab configuration, please report it responsibly:

**Do:**
- ✅ Report security issues privately
- ✅ Allow reasonable time for a fix (90 days)
- ✅ Provide detailed reproduction steps
- ✅ Suggest a fix if possible

**Don't:**
- ❌ Publicly disclose before a fix is available
- ❌ Exploit the vulnerability beyond proof-of-concept
- ❌ Access or modify data without permission

### How to Report

**Email**: Create an issue in the repository marked as "Security" and use the following template:

```
Title: [SECURITY] Brief description

## Vulnerability Description
Detailed description of the vulnerability

## Affected Components
- Service name
- Version/commit hash
- Configuration file

## Reproduction Steps
1. Step 1
2. Step 2
3. ...

## Impact Assessment
- Severity: [Critical/High/Medium/Low]
- Attack Vector: [Network/Local/Physical]
- Privileges Required: [None/Low/High]

## Suggested Fix
Your recommendations for fixing the issue

## References
Any relevant CVEs, articles, or documentation
```

### Response Timeline

We aim to respond to security reports within:

- **24 hours** - Initial acknowledgment
- **7 days** - Impact assessment and response plan
- **30 days** - Fix development and testing
- **90 days** - Public disclosure (coordinated)

## Known Security Considerations

### Current Security Posture

**Strong**:
- SSH hardening implemented
- Firewall configured correctly
- VPN for remote access
- No public-facing services
- Service isolation via Docker

**Needs Improvement**:
- No SSL/TLS on internal services (HTTP only)
- No intrusion detection system (Fail2ban recommended)
- No automated security scanning
- Manual backup process
- No audit logging centralization

### Intentional Design Decisions

#### HTTP (not HTTPS) for Internal Services

**Decision**: Internal services use HTTP, not HTTPS

**Rationale**:
- Services only accessible on trusted LAN
- Tailscale provides encryption for remote access
- Simplifies certificate management
- Self-signed certs cause browser warnings

**Mitigation**:
- Network is physically secured
- Firewall prevents external access
- VPN encrypts remote traffic

**Future**: May implement internal CA for HTTPS if needed

#### No Public Exposure

**Decision**: All services are LAN-only, accessed via VPN

**Rationale**:
- Reduces attack surface significantly
- Home ISP dynamic IP not suitable for public hosting
- Tailscale provides secure remote access
- Compliance with ISP terms of service

**Result**: Very strong security posture

## Security Checklist

### Initial Setup
- [ ] SSH password authentication disabled
- [ ] SSH root login disabled
- [ ] Firewall (UFW) enabled and configured
- [ ] Tailscale VPN installed and configured
- [ ] Strong passwords for all services (20+ characters)
- [ ] `.env` files protected (chmod 600)
- [ ] Unattended security updates enabled
- [ ] System fully updated

### Ongoing Security
- [ ] Review firewall rules monthly
- [ ] Update system packages weekly
- [ ] Rotate passwords quarterly
- [ ] Review service logs monthly
- [ ] Test backups quarterly
- [ ] Update Docker images monthly
- [ ] Review Tailscale ACLs quarterly

### Service-Specific Security
- [ ] PostgreSQL: Strong admin password
- [ ] Gitea: SSH key authentication configured
- [ ] Immich: Admin account secured
- [ ] Pi-hole: Admin password set
- [ ] PgAdmin: Access restricted to LAN

## Security Updates

### Update Process

**System Updates** (Automated):
```bash
# Unattended upgrades configured during setup
sudo systemctl status unattended-upgrades
```

**Docker Images** (Manual):
```bash
# Update all services
cd ~/homelab-01
docker compose -f platform/postgres/docker-compose.yml pull
docker compose -f platform/gitea/docker-compose.yml pull
docker compose -f apps/immich/docker-compose.yml pull
docker compose -f apps/pi-hole/docker-compose.yml pull
docker compose -f apps/homepage/docker-compose.yml pull
docker compose -f system/nginx/docker-compose.yml pull

# Restart with new images
./scripts/stop-all-services.sh
./scripts/start-all-services.sh
```

**Security Patches** (Immediate):
```bash
# Apply critical security updates immediately
sudo apt update
sudo apt upgrade -y
sudo reboot
```

## Incident Response

### If You Suspect a Breach

1. **Isolate** - Disconnect affected systems from network
2. **Assess** - Identify scope and impact
3. **Contain** - Stop the breach from spreading
4. **Eradicate** - Remove malicious access/software
5. **Recover** - Restore from clean backups
6. **Learn** - Document and improve security

### Emergency Contacts

- **Primary**: Repository owner
- **Secondary**: Tailscale support (for VPN issues)
- **ISP**: Contact if DDoS or network-level attack

### Incident Checklist

- [ ] Document timeline of events
- [ ] Capture logs before they're rotated
- [ ] Change all passwords
- [ ] Review firewall and access logs
- [ ] Scan for malware/rootkits
- [ ] Restore from known-good backups
- [ ] Report to relevant parties
- [ ] Update security measures to prevent recurrence

## Compliance & Standards

This homelab follows industry security standards where applicable:

- **CIS Docker Benchmarks** - Container security
- **OWASP Top 10** - Web application security
- **SSH Hardening Guide** - SSH security best practices
- **UFW Best Practices** - Firewall configuration

## Security Resources

### Documentation
- [SERVER-SETUP.md](docs/SERVER-SETUP.md) - Security configuration steps
- [ARCHITECTURE-REVIEW.md](docs/ARCHITECTURE-REVIEW.md) - Security assessment

### External Resources
- [SSH Hardening](https://www.ssh.com/academy/ssh/sshd_config)
- [Docker Security](https://docs.docker.com/engine/security/)
- [Tailscale Security](https://tailscale.com/security/)
- [UFW Configuration](https://help.ubuntu.com/community/UFW)

### Security Tools

**Recommended Tools**:
- `fail2ban` - Intrusion prevention
- `rkhunter` - Rootkit detection
- `lynis` - Security auditing
- `docker-bench-security` - Docker security scan

**Installation**:
```bash
# Security audit tools
sudo apt install fail2ban rkhunter lynis

# Docker security scanner
git clone https://github.com/docker/docker-bench-security.git
cd docker-bench-security
sudo sh docker-bench-security.sh
```

## Security Audit Log

Document security-related changes:

| Date | Change | Reason | Impact |
|------|--------|--------|--------|
| 2026-01-30 | Initial security configuration | Repository setup | Baseline security |
| TBD | Add SSL/TLS | Encrypt internal traffic | Enhanced privacy |
| TBD | Add Fail2ban | Intrusion prevention | Automated defense |

## Acknowledgments

Security best practices in this homelab are based on:
- CIS Benchmarks
- Docker Security Documentation
- Tailscale Security Whitepaper
- Ubuntu Security Guide
- Community recommendations

---

**Last Updated**: 2026-01-30
**Next Security Review**: 2026-02-28
**Security Contact**: Create an issue in this repository

**Remember**: Security is a continuous process, not a one-time configuration.
