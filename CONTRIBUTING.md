# Contributing to Homelab-01

Thank you for your interest in contributing to this homelab project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Contribution Guidelines](#contribution-guidelines)
- [Pull Request Process](#pull-request-process)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive experience for everyone. We expect all contributors to:

- Be respectful and considerate
- Accept constructive criticism gracefully
- Focus on what is best for the project
- Show empathy towards other contributors

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or insulting comments
- Spam or off-topic discussions
- Sharing private information without permission

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- Git installed and configured
- Docker and Docker Compose v2
- Basic understanding of Docker and Linux
- Text editor or IDE
- (Optional) Ubuntu/Debian system for testing

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/homelab-01.git
   cd homelab-01
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/loki3-coding/homelab-01.git
   ```

## How to Contribute

### Types of Contributions

We welcome various types of contributions:

#### 🐛 Bug Reports

Found a bug? Please create an issue with:

- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Docker version, etc.)
- Relevant logs or error messages

#### 💡 Feature Requests

Have an idea? Create an issue with:

- Clear description of the feature
- Use case and benefits
- Potential implementation approach
- Any relevant examples or references

#### 📚 Documentation

Improve documentation by:

- Fixing typos or unclear instructions
- Adding examples or clarifications
- Creating guides or tutorials
- Translating documentation (if multilingual support added)

#### 🔧 Code Contributions

Contribute code by:

- Fixing bugs
- Implementing features
- Improving scripts
- Optimizing configurations
- Adding new services

## Development Setup

### Local Development Environment

1. **Clone and navigate to repo**:
   ```bash
   cd homelab-01
   ```

2. **Create configuration files**:
   ```bash
   # Copy environment templates
   cp config/env-templates/postgres.env.example platform/postgres/.env
   cp config/env-templates/gitea.env.example platform/gitea/.env
   cp config/env-templates/immich.env.example apps/immich/.env
   cp config/env-templates/pi-hole.env.example apps/pi-hole/.env

   # Edit and fill in values
   nano platform/postgres/.env
   # ... repeat for other .env files
   ```

3. **Start services**:
   ```bash
   ./scripts/start-all-services.sh
   ```

4. **Verify services**:
   ```bash
   docker ps
   ```

### Testing Changes

Before submitting changes:

1. **Test locally** - Verify your changes work
2. **Check syntax** - Validate scripts and configs
3. **Test services** - Ensure services start correctly
4. **Review logs** - Check for errors or warnings

## Contribution Guidelines

### Code Style

#### Shell Scripts

- Use `#!/bin/bash` shebang
- Add descriptive comments
- Use meaningful variable names
- Include error handling (`set -e`)
- Add usage documentation at the top

**Example**:
```bash
#!/bin/bash

################################################################################
# Script Name: example-script.sh
#
# Description: Brief description of what this script does
#
# Usage: ./example-script.sh [options]
#
# Options:
#   -h, --help     Show this help message
#   -v, --verbose  Enable verbose output
################################################################################

set -e  # Exit on error

# Your code here
```

#### Docker Compose

- Use YAML syntax
- Include comments for complex configurations
- Follow service naming conventions
- Use environment variables for secrets
- Specify restart policies

**Example**:
```yaml
version: "3.9"

services:
  service-name:
    image: image:tag
    container_name: service-name
    restart: unless-stopped
    environment:
      - VAR_NAME=${VAR_NAME}
    volumes:
      - ./data:/data
    networks:
      - network-name

networks:
  network-name:
    external: true
```

#### Documentation

- Use Markdown format
- Include code examples
- Add table of contents for long docs
- Use headings appropriately (H1 → H6)
- Include links to related docs

### Directory Structure

When adding new services:

```
category/service-name/
├── docker-compose.yml    # Service definition
├── .env                  # Secrets (gitignored)
├── README.md            # Service documentation
└── config/              # Service-specific config
```

Place services in appropriate categories:
- `platform/` - Core infrastructure (databases, version control)
- `apps/` - User-facing applications
- `system/` - System-level services (proxies, DNS)
- `monitoring/` - Monitoring and observability

### Environment Variables

1. **Never commit secrets** - Use `.gitignore`
2. **Provide templates** - Create `.env.example` in `config/env-templates/`
3. **Document variables** - Add comments explaining each variable
4. **Use strong defaults** - Suggest secure configurations

## Pull Request Process

### Before Submitting

1. **Update from upstream**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Test your changes**:
   ```bash
   # Validate shell scripts
   shellcheck scripts/**/*.sh

   # Test Docker Compose files
   docker-compose -f <your-file> config

   # Test service startup
   cd <service-dir>
   docker compose up
   ```

3. **Update documentation**:
   - Update README.md if adding/changing services
   - Update relevant docs in `docs/`
   - Add/update comments in code

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

### Creating the Pull Request

1. **Push to your fork**:
   ```bash
   git push origin your-branch-name
   ```

2. **Open Pull Request on GitHub**:
   - Go to your fork on GitHub
   - Click "New Pull Request"
   - Fill in the template

3. **PR Title Format**:
   ```
   [Category] Brief description

   Examples:
   [Docs] Update SERVER-SETUP.md with SSL instructions
   [Script] Add automated backup script
   [Service] Add Jellyfin media server
   [Fix] Correct Immich environment variables
   ```

4. **PR Description Template**:
   ```markdown
   ## Description
   Brief description of changes

   ## Motivation
   Why is this change needed?

   ## Changes Made
   - Change 1
   - Change 2
   - Change 3

   ## Testing
   - [ ] Tested locally
   - [ ] Services start correctly
   - [ ] Documentation updated
   - [ ] No breaking changes

   ## Screenshots (if applicable)
   Add screenshots showing the changes

   ## Related Issues
   Closes #123
   ```

### Review Process

1. **Automated Checks** - CI/CD runs automatically (when implemented)
2. **Manual Review** - Maintainer reviews code and documentation
3. **Feedback** - Address any requested changes
4. **Approval** - Once approved, PR will be merged

### After Merge

1. **Delete your branch**:
   ```bash
   git branch -d your-branch-name
   git push origin --delete your-branch-name
   ```

2. **Update your fork**:
   ```bash
   git checkout main
   git pull upstream main
   git push origin main
   ```

## Commit Message Guidelines

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `security`: Security improvements

### Examples

```bash
# Feature
feat(monitoring): add Prometheus and Grafana stack

# Bug fix
fix(scripts): correct path in start-all-services.sh

# Documentation
docs(readme): update service access URLs

# Chore
chore(deps): update Docker images to latest versions
```

### Best Practices

- Use imperative mood ("add" not "added")
- Keep subject line under 72 characters
- Capitalize subject line
- No period at the end of subject
- Separate subject from body with blank line
- Explain *what* and *why* in body, not *how*

### Co-Authoring

When collaborating with AI or others:

```bash
git commit -m "feat(service): add new service

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

## Testing

### Manual Testing

Before submitting changes:

1. **Syntax validation**:
   ```bash
   # Shell scripts
   bash -n scripts/your-script.sh

   # Docker Compose
   docker-compose -f service/docker-compose.yml config
   ```

2. **Service testing**:
   ```bash
   # Start service
   cd service-directory
   docker compose up -d

   # Check logs
   docker compose logs -f

   # Verify functionality
   # (access web UI, run commands, etc.)

   # Stop service
   docker compose down
   ```

3. **Integration testing**:
   ```bash
   # Start all services
   ./scripts/start-all-services.sh

   # Verify all running
   docker ps

   # Test inter-service communication
   # (e.g., Gitea → Postgres)
   ```

### Automated Testing

(Future implementation)

```bash
# Run all tests
./scripts/test/run-tests.sh

# Run specific test suite
./scripts/test/test-services.sh
./scripts/test/test-scripts.sh
```

## Documentation

### Documentation Standards

- **Clarity**: Write for users with varying skill levels
- **Completeness**: Include all necessary information
- **Examples**: Provide code examples and screenshots
- **Structure**: Use clear headings and sections
- **Links**: Reference related documentation

### Types of Documentation

#### README.md Updates

When adding services:
- Update service table
- Add to appropriate category
- Include brief description
- Link to detailed docs

#### Service Documentation

Create `service-name/README.md`:

```markdown
# Service Name

Brief description

## Prerequisites
- Requirement 1
- Requirement 2

## Configuration
How to configure

## Starting the Service
Commands to start

## Access
- URL: http://...
- Credentials: ...

## Troubleshooting
Common issues and solutions
```

#### Technical Documentation

For complex changes:
- Architecture diagrams
- Sequence diagrams
- Configuration examples
- Troubleshooting guides

## Questions?

Need help? You can:

- 📖 Read existing documentation in `docs/`
- 💬 Open an issue for questions
- 🐛 Report bugs with detailed info
- 💡 Suggest features with use cases

## Recognition

Contributors will be recognized in:
- Git commit history
- Pull request mentions
- Future CONTRIBUTORS.md file

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (to be determined).

---

**Thank you for contributing to homelab-01!**

Last Updated: 2026-01-30
