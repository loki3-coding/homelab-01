# Git Hooks

This directory contains recommended git hooks for the homelab-01 repository.

## What Are Git Hooks?

Git hooks are scripts that run automatically during git operations (commit, push, etc.). They help prevent common mistakes like committing secrets.

## Available Hooks

### pre-commit

**Purpose**: Prevents committing secrets, private keys, and `.env` files

**Checks for**:
- Private key files (`.pem`, `.key`, `.p12`, `.pfx`)
- Private key content (`BEGIN PRIVATE KEY`)
- Environment files (`.env`)
- API keys and tokens (warning only)

## Installation

### Manual Installation

```bash
# From the repository root
cp scripts/git-hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Verify it's working
git commit --allow-empty -m "Test hook"
```

### Automatic Installation (Recommended)

```bash
# From the repository root
./scripts/git-hooks/install-hooks.sh
```

## How to Use

After installation, the hook **runs automatically** when you commit:

```bash
git add file.txt
git commit -m "Update file"  # Hook runs here automatically
```

**Normal workflow stays the same** - no extra steps needed!

## What Happens When Secrets Are Detected

```bash
$ git commit -m "Update config"

🔍 Scanning for secrets before commit...
  → Checking for private key files...
  → Checking for .env files...

❌ ERROR: Attempting to commit .env files!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Blocked files:
  - .env
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ COMMIT BLOCKED due to security issues

# Fix by unstaging the dangerous file:
$ git reset HEAD .env
```

## Bypassing the Hook (Use with Caution!)

If you're **absolutely certain** a file is safe:

```bash
git commit --no-verify -m "message"
```

⚠️ **Only use --no-verify if you know what you're doing!**

## Uninstalling

```bash
rm .git/hooks/pre-commit
```

## Why Aren't Hooks Automatic?

Git hooks are **intentionally local** for security reasons:
- Prevents malicious code execution
- Each developer controls their own hooks
- Allows customization per developer

This is why you must manually install hooks after cloning the repository.

## Testing

Test the hook is working:

```bash
# Should succeed (safe file)
echo "test" > test.txt
git add test.txt
git commit -m "Test"
git reset --soft HEAD~1 && git reset HEAD test.txt && rm test.txt

# Should block (dangerous file)
touch test.key
git add test.key
git commit -m "This will be blocked"
git reset HEAD test.key && rm test.key
```

## Support

If you have issues with the hooks, check:
1. Hook is executable: `ls -la .git/hooks/pre-commit`
2. Hook is in the right place: `.git/hooks/pre-commit` (not `scripts/git-hooks/`)
3. Try running manually: `.git/hooks/pre-commit`

For questions, see the main [README.md](../../README.md) or [CLAUDE.md](../../CLAUDE.md).
