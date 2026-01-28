#!/bin/bash
#
# Claude Code Setup Script
#
# Creates ~/.claude with rules as a git submodule.
# Safe to run multiple times - won't overwrite existing files.
#
# Usage: ./install.sh
#

set -e

CLAUDE_DIR="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default rules repo - override with RULES_REPO env var to use your fork
RULES_REPO="${RULES_REPO:-https://github.com/dharnnie/claude-cortex.git}"

echo "Setting up Claude Code configuration..."

# Create ~/.claude if needed
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Creating $CLAUDE_DIR..."
    mkdir -p "$CLAUDE_DIR"
fi

# Initialize git repo if not already
if [ ! -d "$CLAUDE_DIR/.git" ]; then
    echo "Initializing git repository..."
    cd "$CLAUDE_DIR"
    git init
fi

# Copy example files (don't overwrite existing)
echo "Copying configuration files..."

if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md.example" "$CLAUDE_DIR/CLAUDE.md"
    echo "  Created CLAUDE.md"
else
    echo "  CLAUDE.md already exists, skipping"
fi

if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
    cp "$SCRIPT_DIR/settings.json.example" "$CLAUDE_DIR/settings.json"
    echo "  Created settings.json"
else
    echo "  settings.json already exists, skipping"
fi

if [ ! -f "$CLAUDE_DIR/.gitignore" ]; then
    cp "$SCRIPT_DIR/.gitignore.example" "$CLAUDE_DIR/.gitignore"
    echo "  Created .gitignore"
else
    echo "  .gitignore already exists, skipping"
fi

# Add rules as submodule
cd "$CLAUDE_DIR"

if [ ! -d "$CLAUDE_DIR/rules" ]; then
    echo "Adding rules submodule from $RULES_REPO..."
    git submodule add "$RULES_REPO" rules
    echo "  Added rules submodule"
else
    echo "  rules/ already exists, skipping submodule"
fi

echo ""
echo "Done! Your Claude Code config is at: $CLAUDE_DIR"
echo ""
echo "Next steps:"
echo "  1. Edit ~/.claude/CLAUDE.md to customize your preferences"
echo "  2. Install terminal-notifier for notifications (macOS):"
echo "     brew install terminal-notifier"
echo "  3. Update rules with:"
echo "     cd ~/.claude && git submodule update --remote rules"
