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

### Option 1: Automated Install

```bash
# Clone this repo
git clone https://github.com/YOUR_USERNAME/claude-code-rules.git
cd claude-code-rules/starter

# Set your fork URL (or use the default)
export RULES_REPO="https://github.com/YOUR_USERNAME/claude-code-rules.git"

# Run install script
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

# Add rules as submodule
git submodule add https://github.com/YOUR_USERNAME/claude-code-rules.git rules
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
