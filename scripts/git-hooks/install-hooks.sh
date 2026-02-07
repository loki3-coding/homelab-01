#!/bin/bash
# Install git hooks for homelab-01 repository
# Run this after cloning the repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔧 Installing git hooks for homelab-01..."
echo ""

# Check we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Error: Not in a git repository root${NC}"
    echo "   Run this script from the repository root: ./scripts/git-hooks/install-hooks.sh"
    exit 1
fi

# Check hooks directory exists
if [ ! -d "scripts/git-hooks" ]; then
    echo -e "${RED}❌ Error: scripts/git-hooks directory not found${NC}"
    echo "   Make sure you're in the homelab-01 repository root"
    exit 1
fi

# Install pre-commit hook
if [ -f "scripts/git-hooks/pre-commit" ]; then
    echo "📋 Installing pre-commit hook..."

    # Backup existing hook if it exists
    if [ -f ".git/hooks/pre-commit" ]; then
        echo -e "${YELLOW}⚠️  Existing pre-commit hook found, backing up...${NC}"
        cp .git/hooks/pre-commit .git/hooks/pre-commit.backup
        echo "   Backup saved to: .git/hooks/pre-commit.backup"
    fi

    # Copy and make executable
    cp scripts/git-hooks/pre-commit .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit

    echo -e "${GREEN}✅ pre-commit hook installed${NC}"
else
    echo -e "${RED}❌ pre-commit hook not found in scripts/git-hooks/${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Git hooks successfully installed!${NC}"
echo ""
echo "The pre-commit hook will now run automatically when you commit."
echo "It will check for:"
echo "  • Private keys (.pem, .key, etc.)"
echo "  • Private key content (BEGIN PRIVATE KEY)"
echo "  • Environment files (.env)"
echo "  • API keys and tokens"
echo ""
echo "Your normal git workflow stays the same:"
echo "  git add <files>"
echo "  git commit -m 'message'  ← Hook runs here automatically"
echo "  git push"
echo ""
echo "To test it's working, try: git commit --allow-empty -m 'Test hook'"
echo ""
