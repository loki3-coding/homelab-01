# Configuration Templates

This directory contains template files for configuring homelab services.

## Environment Templates

Environment template files (`.env.example`) are provided for each service that requires configuration. These templates document all required variables and provide guidance on secure configuration.

### Available Templates

| Template | Target Location | Service |
|----------|----------------|---------|
| `env-templates/postgres.env.example` | `platform/postgres/.env` | PostgreSQL + PgAdmin |
| `env-templates/gitea.env.example` | `platform/gitea/.env` | Gitea (Git server) |
| `env-templates/immich.env.example` | `apps/immich/.env` | Immich (Photo management) |
| `env-templates/pi-hole.env.example` | `apps/pi-hole/.env` | Pi-hole (DNS ad blocking) |

### Quick Start

1. **Copy template to target location**:
   ```bash
   cp config/env-templates/postgres.env.example platform/postgres/.env
   ```

2. **Generate secure passwords**:
   ```bash
   # Method 1: OpenSSL
   openssl rand -base64 32

   # Method 2: /dev/urandom
   head -c 32 /dev/urandom | base64

   # Method 3: pwgen (if installed)
   pwgen -s 32 1
   ```

3. **Edit the .env file**:
   ```bash
   nano platform/postgres/.env
   ```

4. **Replace all `<CHANGE_ME_*>` placeholders** with secure values

5. **Verify configuration**:
   ```bash
   # Check that all required variables are set
   grep -v '^#' platform/postgres/.env | grep '<CHANGE_ME'
   # Should return no results
   ```

## Security Best Practices

### Password Requirements

- **Minimum Length**: 20 characters
- **Complexity**: Mix of letters, numbers, and symbols
- **Uniqueness**: Different password for each service
- **Storage**: Use a password manager (Bitwarden, 1Password, etc.)

### File Permissions

Protect your `.env` files:

```bash
# Set restrictive permissions
chmod 600 platform/postgres/.env
chmod 600 platform/gitea/.env
chmod 600 apps/immich/.env
chmod 600 apps/pi-hole/.env

# Verify ownership
ls -la platform/postgres/.env
# Should show: -rw------- (only owner can read/write)
```

### Secrets Management

**Current Approach** (Simple):
- Secrets stored in `.env` files
- Files excluded from git via `.gitignore`
- Manually managed and backed up

**Future Options** (Advanced):
- **Docker Secrets**: Use with Docker Swarm mode
- **HashiCorp Vault**: External secrets manager
- **AWS Secrets Manager**: Cloud-based secrets
- **SOPS**: Encrypted secrets in git

### Backup Considerations

**What to backup**:
- ✅ Template files (`.env.example`) - committed to git
- ✅ Filled `.env` files - **encrypted backup only**
- ✅ Configuration files (nginx configs, etc.)

**How to backup secrets securely**:

```bash
# Create encrypted backup of all .env files
tar czf - \
    platform/postgres/.env \
    platform/gitea/.env \
    apps/immich/.env \
    apps/pi-hole/.env \
    | gpg -c > env-backup-$(date +%Y%m%d).tar.gz.gpg

# Restore from encrypted backup
gpg -d env-backup-20260130.tar.gz.gpg | tar xzf -
```

## Configuration Validation

### Manual Validation

Check that all variables are set:

```bash
# Function to validate .env file
validate_env() {
    local file=$1
    echo "Validating $file..."

    # Check file exists
    if [ ! -f "$file" ]; then
        echo "❌ File not found: $file"
        return 1
    fi

    # Check for placeholder values
    if grep -q '<CHANGE_ME' "$file"; then
        echo "❌ Found placeholder values - please update"
        grep '<CHANGE_ME' "$file"
        return 1
    fi

    # Check for weak passwords
    if grep -qE '(password|passwd)=(changeit|admin|password)' "$file"; then
        echo "⚠️  Warning: Weak password detected"
        return 1
    fi

    echo "✅ Validation passed"
    return 0
}

# Validate all .env files
validate_env "platform/postgres/.env"
validate_env "platform/gitea/.env"
validate_env "apps/immich/.env"
validate_env "apps/pi-hole/.env"
```

### Automated Validation

Create a validation script (future enhancement):

```bash
./scripts/maintenance/validate-config.sh
```

This would check:
- All required variables are present
- No placeholder values remain
- Password strength requirements
- File permissions are restrictive
- No duplicate passwords across services

## Troubleshooting

### Common Issues

**Issue**: Service fails to start with "missing environment variable"
```bash
# Solution: Check .env file exists and has all required variables
cat platform/postgres/.env
```

**Issue**: Database connection fails
```bash
# Solution: Verify database credentials match in both places
# 1. Check .env file
cat platform/gitea/.env | grep DB_PASSWD

# 2. Check database
docker exec -it postgres psql -U postgres -c "\du"
```

**Issue**: Permission denied when reading .env
```bash
# Solution: Check file permissions and ownership
ls -la platform/postgres/.env
sudo chown $USER:$USER platform/postgres/.env
chmod 600 platform/postgres/.env
```

### Getting Help

If you're having configuration issues:

1. Check service-specific README:
   - `platform/postgres/README.md`
   - `platform/gitea/README.md`
   - `apps/immich/README.md`

2. Review setup documentation:
   - `docs/SERVER-SETUP.md`
   - `docs/TROUBLESHOOTING.md` (future)

3. Check service logs:
   ```bash
   cd platform/postgres
   docker compose logs -f
   ```

4. Open an issue in the repository

## Related Documentation

- [SERVER-SETUP.md](../docs/SERVER-SETUP.md) - Complete server setup guide
- [SECURITY.md](../SECURITY.md) - Security policy and best practices
- [CLAUDE.md](../docs/CLAUDE.md) - Project architecture and context

---

**Last Updated**: 2026-01-30
**Maintainer**: vynguyen
