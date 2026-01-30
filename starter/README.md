# Claude Code Starter

Quick setup for your `~/.claude` configuration with rules as a git submodule.

## What's Included

| File | Purpose |
|------|---------|
| `CLAUDE.md.example` | Template for global AI preferences |
| `settings.json.example` | Notifications when Claude needs attention |
| `.gitignore.example` | Ignore runtime files |
| `install.sh` | Automated setup script |

## Quick Setup

### Choose Your Approach

| Approach | When to Use | URL |
|----------|-------------|-----|
| **Use directly** | You want the rules as-is | `https://github.com/dharnnie/claude-cortex.git` |
| **Fork first** | You want to customize rules for your team | `https://github.com/YOUR_USERNAME/claude-cortex.git` |

### Option 1: Automated Install

```bash
# Clone the repo (or your fork)
git clone https://github.com/dharnnie/claude-cortex.git
cd claude-cortex/starter

# Run install script (uses original repo by default)
./install.sh

# OR: Use your fork instead
export RULES_REPO="https://github.com/YOUR_USERNAME/claude-cortex.git"
./install.sh
```

### Option 2: Manual Setup

```bash
# Create ~/.claude
mkdir -p ~/.claude
cd ~/.claude
git init

# Copy files
cp /path/to/starter/CLAUDE.md.example CLAUDE.md
cp /path/to/starter/settings.json.example settings.json
cp /path/to/starter/.gitignore.example .gitignore

# Add rules as submodule (use original repo or your fork)
git submodule add https://github.com/dharnnie/claude-cortex.git rules
# OR: git submodule add https://github.com/YOUR_USERNAME/claude-cortex.git rules
```

## After Setup

### Edit Your Preferences

```bash
# Customize your global CLAUDE.md
vim ~/.claude/CLAUDE.md
```

### Install Notifications (macOS)

```bash
brew install terminal-notifier
```

### Update Rules

```bash
cd ~/.claude
git submodule update --remote rules
git add rules
git commit -m "chore: update rules submodule"
```

## File Structure

After installation, your `~/.claude` will look like:

```
~/.claude/
├── .git/
├── .gitignore
├── CLAUDE.md           # Your global preferences
├── settings.json       # Notifications config
└── rules/              # Submodule → rules repo
    ├── general/
    ├── golang/
    └── ruby/
```

## Global vs Project Setup

This starter configures your **global** `~/.claude` directory. For **project-level** `CLAUDE.md` generation that auto-detects languages and includes only relevant rules, use `setup.sh` from the repo root instead:

```bash
cd your-project/
/path/to/claude-cortex/setup.sh
```

See the main [README](../README.md#project-level-setup) for details.

## Customization

### Change Notification Sound

Edit `~/.claude/settings.json` and replace `Submarine` with:
- `Glass`, `Ping`, `Pop`, `Purr`, `Funk`, `Hero`, `Morse`, `Sosumi`, `Tink`

### Add Pre-approved Commands

```json
{
  "permissions": {
    "allow": [
      "Bash(go test ./...)",
      "Bash(make *)"
    ]
  }
}
```
