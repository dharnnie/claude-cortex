#!/usr/bin/env bash
# install.sh — Curl-fetchable installer for claude-cortex.
# Copies coding-convention rules into your project's .claude/rules/ directory.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash -s -- --update
#   curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash -s -- --dry-run
#
# Compatible with Bash 3.2+ (macOS default).

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
DRY_RUN=false
FORCE=false
UPDATE=false
GLOBAL=false
REPO_URL="${CLAUDE_CORTEX_REPO:-https://github.com/dharnnie/claude-cortex.git}"
TARGET_DIR=""

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<'EOF'
Usage: install.sh [OPTIONS]

Install claude-cortex coding convention rules into your project.

Options:
  --update          Update existing installation (preserves local edits)
  --dry-run         Preview what would be installed without writing files
  --force           Overwrite CLAUDE.md even if it exists
  --global          Install to ~/.claude instead of current project
  --repo URL        Use a custom repo URL (e.g., your fork)
  --help            Show this message

Examples:
  # Fresh install in current project
  curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash

  # Update existing rules
  curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash -s -- --update

  # Install globally
  curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash -s -- --global
EOF
  exit 0
}

# ── Parse args ────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)  DRY_RUN=true; shift ;;
    --force)    FORCE=true; shift ;;
    --update)   UPDATE=true; shift ;;
    --global)   GLOBAL=true; shift ;;
    --repo)     REPO_URL="$2"; shift 2 ;;
    --help)     usage ;;
    *)          echo "Unknown option: $1" >&2; usage ;;
  esac
done

# ── Determine target directory ────────────────────────────────────────────────
if [ "$GLOBAL" = true ]; then
  TARGET_DIR="$HOME/.claude"
else
  TARGET_DIR="$(pwd)"
fi

RULES_DIR="$TARGET_DIR/.claude/rules"
CHECKSUMS_FILE="$RULES_DIR/.checksums"
CLAUDE_MD="$TARGET_DIR/CLAUDE.md"

if [ "$GLOBAL" = true ]; then
  RULES_DIR="$TARGET_DIR/rules"
  CHECKSUMS_FILE="$RULES_DIR/.checksums"
  CLAUDE_MD="$TARGET_DIR/CLAUDE.md"
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
info()  { echo "  $*"; }
warn()  { echo "  [warn] $*" >&2; }
error() { echo "  [error] $*" >&2; exit 1; }

# Compute SHA-256 checksum (works on macOS and Linux)
compute_checksum() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d' ' -f1
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    error "Neither shasum nor sha256sum found. Cannot compute checksums."
  fi
}

# Read a stored checksum for a given relative path from .checksums
stored_checksum() {
  local rel_path="$1"
  if [ ! -f "$CHECKSUMS_FILE" ]; then
    echo ""
    return
  fi
  local line
  line="$(grep "  ${rel_path}$" "$CHECKSUMS_FILE" 2>/dev/null || true)"
  if [ -n "$line" ]; then
    echo "$line" | cut -d' ' -f1
  else
    echo ""
  fi
}

# ── Language detection ────────────────────────────────────────────────────────
# Each entry: "marker_file:language_label:rules_dir"
LANG_MARKERS=(
  "go.mod:Go:golang"
  "go.sum:Go:golang"
  "Gemfile:Ruby:ruby"
  "Rakefile:Ruby:ruby"
  ".ruby-version:Ruby:ruby"
  "package.json:JavaScript:javascript"
  "tsconfig.json:TypeScript:typescript"
  "requirements.txt:Python:python"
  "pyproject.toml:Python:python"
  "setup.py:Python:python"
  "Pipfile:Python:python"
  "Cargo.toml:Rust:rust"
  "pom.xml:Java:java"
  "build.gradle:Java:java"
)

detect_languages() {
  local scan_dir="$1"
  detected_langs=""
  detected_dirs=""

  for entry in "${LANG_MARKERS[@]}"; do
    local marker="${entry%%:*}"
    local rest="${entry#*:}"
    local lang="${rest%%:*}"
    local dir="${rest#*:}"

    if [ -f "$scan_dir/$marker" ]; then
      case " $detected_langs " in
        *" $lang "*) continue ;;
      esac
      detected_langs="$detected_langs $lang"
      detected_dirs="$detected_dirs $dir"
    fi
  done

  detected_langs="${detected_langs# }"
  detected_dirs="${detected_dirs# }"
}

# ── Extract description from a rule file ──────────────────────────────────────
extract_description() {
  local file="$1"
  local in_frontmatter=false
  while IFS= read -r line; do
    if [ "$line" = "---" ]; then
      if [ "$in_frontmatter" = true ]; then
        in_frontmatter=false
        continue
      else
        in_frontmatter=true
        continue
      fi
    fi
    [ "$in_frontmatter" = true ] && continue
    case "$line" in
      "# "*)
        echo "${line#\# }"
        return
        ;;
    esac
  done < "$file"
  local base
  base="$(basename "$file" .md)"
  echo "$base"
}

# ── Generate CLAUDE.md content ────────────────────────────────────────────────
generate_claude_md() {
  local rules_prefix="$1"

  echo "# Project Coding Conventions"
  echo ""
  echo "> Auto-generated by claude-cortex install.sh"
  if [ -n "$detected_langs" ]; then
    echo "> Detected: $detected_langs"
  else
    echo "> Detected: (none)"
  fi
  echo ""
  echo "## Rules Reference"

  # General rules (always included)
  if [ -d "$RULES_DIR/general" ]; then
    echo ""
    echo "### General (All Languages)"
    for file in "$RULES_DIR/general"/*.md; do
      [ -f "$file" ] || continue
      local desc
      desc="$(extract_description "$file")"
      echo "- @${rules_prefix}general/$(basename "$file") - $desc"
    done
  fi

  # Language-specific sections
  for dir in $detected_dirs; do
    if [ ! -d "$RULES_DIR/$dir" ]; then
      continue
    fi

    # Find the label for this dir
    local label="$dir"
    local i=0
    for d in $detected_dirs; do
      local j=0
      for l in $detected_langs; do
        if [ "$j" -eq "$i" ]; then
          if [ "$d" = "$dir" ]; then
            label="$l"
          fi
          break
        fi
        j=$((j + 1))
      done
      i=$((i + 1))
    done

    echo ""
    echo "### $label"
    for file in "$RULES_DIR/$dir"/*.md; do
      [ -f "$file" ] || continue
      local desc
      desc="$(extract_description "$file")"
      echo "- @${rules_prefix}${dir}/$(basename "$file") - $desc"
    done
  done

  echo ""
  echo "## Project-Specific Notes"
  echo ""
  echo "<!-- Add project-specific conventions below -->"
}

# ── Clone repo to temp directory ──────────────────────────────────────────────
clone_repo() {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  echo "Fetching claude-cortex from $REPO_URL ..."
  if ! git clone --quiet --depth 1 "$REPO_URL" "$tmp_dir/claude-cortex" 2>/dev/null; then
    error "Failed to clone $REPO_URL. Check your network connection and repo URL."
  fi

  CLONE_DIR="$tmp_dir/claude-cortex"
}

# ── Write checksums file ─────────────────────────────────────────────────────
write_checksums() {
  local checksums_content=""
  checksums_content="# claude-cortex checksums — do not edit manually
# Used to detect local modifications during --update"

  for file in "$RULES_DIR"/*/*.md; do
    [ -f "$file" ] || continue
    local rel_path="${file#$RULES_DIR/}"
    local checksum
    checksum="$(compute_checksum "$file")"
    checksums_content="$checksums_content
$checksum  $rel_path"
  done

  if [ "$DRY_RUN" = true ]; then
    info "[dry-run] Would write .checksums"
  else
    echo "$checksums_content" > "$CHECKSUMS_FILE"
  fi
}

# ── Copy rule files from clone ────────────────────────────────────────────────
# Copies files from a source language dir in the clone to the target rules dir
copy_rules_dir() {
  local src_dir="$1"
  local dir_name="$2"
  local dest_dir="$RULES_DIR/$dir_name"

  if [ ! -d "$src_dir" ]; then
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    info "[dry-run] Would create $dest_dir/"
  else
    mkdir -p "$dest_dir"
  fi

  for file in "$src_dir"/*.md; do
    [ -f "$file" ] || continue
    local basename
    basename="$(basename "$file")"
    if [ "$DRY_RUN" = true ]; then
      info "[dry-run] Would copy $dir_name/$basename"
    else
      cp "$file" "$dest_dir/$basename"
      info "Copied $dir_name/$basename"
    fi
  done
}

# ── Fresh install ─────────────────────────────────────────────────────────────
do_install() {
  local scan_dir="$TARGET_DIR"
  if [ "$GLOBAL" = true ]; then
    scan_dir="$(pwd)"
  fi

  # Check if already installed
  if [ -d "$RULES_DIR" ] && [ -f "$CHECKSUMS_FILE" ] && [ "$UPDATE" = false ] && [ "$FORCE" = false ]; then
    echo "claude-cortex is already installed at $RULES_DIR"
    echo "Use --update to pull upstream changes, or --force to reinstall."
    exit 0
  fi

  clone_repo

  detect_languages "$scan_dir"

  if [ -n "$detected_langs" ]; then
    echo "Detected languages: $detected_langs"
  else
    echo "No language markers detected — installing general rules only."
  fi

  # Create rules directory
  if [ "$DRY_RUN" = true ]; then
    info "[dry-run] Would create $RULES_DIR/"
  else
    mkdir -p "$RULES_DIR"
  fi

  # Always copy general rules
  copy_rules_dir "$CLONE_DIR/general" "general"

  # Copy detected language rules
  for dir in $detected_dirs; do
    copy_rules_dir "$CLONE_DIR/$dir" "$dir"
  done

  # Write checksums
  if [ "$DRY_RUN" = false ]; then
    write_checksums
  else
    info "[dry-run] Would write .checksums"
  fi

  # Generate CLAUDE.md
  local rules_prefix=".claude/rules/"
  if [ "$GLOBAL" = true ]; then
    rules_prefix="rules/"
  fi

  if [ "$DRY_RUN" = true ]; then
    info "[dry-run] Would generate CLAUDE.md:"
    echo "---"
    generate_claude_md "$rules_prefix"
    echo "---"
  elif [ -f "$CLAUDE_MD" ] && [ "$FORCE" = false ]; then
    info "CLAUDE.md already exists — skipping (use --force to overwrite)"
  else
    generate_claude_md "$rules_prefix" > "$CLAUDE_MD"
    info "Generated CLAUDE.md"
  fi

  # Global-only extras
  if [ "$GLOBAL" = true ]; then
    if [ "$DRY_RUN" = true ]; then
      info "[dry-run] Would create settings.json and .gitignore in $TARGET_DIR"
    else
      mkdir -p "$TARGET_DIR"

      if [ ! -f "$TARGET_DIR/settings.json" ]; then
        cp "$CLONE_DIR/starter/settings.json.example" "$TARGET_DIR/settings.json"
        info "Created settings.json"
      else
        info "settings.json already exists — skipping"
      fi

      if [ ! -f "$TARGET_DIR/.gitignore" ]; then
        cp "$CLONE_DIR/starter/.gitignore.example" "$TARGET_DIR/.gitignore"
        info "Created .gitignore"
      else
        info ".gitignore already exists — skipping"
      fi
    fi
  fi

  echo ""
  if [ "$DRY_RUN" = true ]; then
    echo "Dry run complete — no files were written."
  else
    echo "claude-cortex installed successfully!"
    echo "Rules are in: $RULES_DIR"
    echo "Run with --update to pull upstream changes later."
  fi
}

# ── Update existing install ───────────────────────────────────────────────────
do_update() {
  if [ ! -d "$RULES_DIR" ]; then
    error "No existing installation found at $RULES_DIR. Run without --update first."
  fi

  clone_repo

  local scan_dir="$TARGET_DIR"
  if [ "$GLOBAL" = true ]; then
    scan_dir="$(pwd)"
  fi
  detect_languages "$scan_dir"

  echo "Updating claude-cortex rules..."

  local updated=0
  local skipped=0
  local added=0

  # Collect directories to process: general + detected
  local dirs_to_process="general"
  for dir in $detected_dirs; do
    dirs_to_process="$dirs_to_process $dir"
  done

  # Also process any dirs already installed but not detected
  # (user may have manually added rules for a language)
  for existing_dir in "$RULES_DIR"/*/; do
    [ -d "$existing_dir" ] || continue
    local dir_name
    dir_name="$(basename "$existing_dir")"
    case " $dirs_to_process " in
      *" $dir_name "*) ;;
      *) dirs_to_process="$dirs_to_process $dir_name" ;;
    esac
  done

  for dir in $dirs_to_process; do
    local src_dir="$CLONE_DIR/$dir"
    local dest_dir="$RULES_DIR/$dir"

    [ -d "$src_dir" ] || continue

    if [ "$DRY_RUN" = false ]; then
      mkdir -p "$dest_dir"
    fi

    for src_file in "$src_dir"/*.md; do
      [ -f "$src_file" ] || continue
      local basename
      basename="$(basename "$src_file")"
      local rel_path="$dir/$basename"
      local dest_file="$dest_dir/$basename"

      if [ ! -f "$dest_file" ]; then
        # New file — not in local install
        if [ "$DRY_RUN" = true ]; then
          info "[dry-run] Would add new: $rel_path"
        else
          cp "$src_file" "$dest_file"
          info "Added: $rel_path"
        fi
        added=$((added + 1))
      else
        local stored
        stored="$(stored_checksum "$rel_path")"
        local current
        current="$(compute_checksum "$dest_file")"

        if [ -z "$stored" ]; then
          # No stored checksum — treat as locally managed, skip
          if [ "$FORCE" = true ]; then
            if [ "$DRY_RUN" = true ]; then
              info "[dry-run] Would overwrite (--force): $rel_path"
            else
              cp "$src_file" "$dest_file"
              info "Overwritten (--force): $rel_path"
            fi
            updated=$((updated + 1))
          else
            info "Skipped (no checksum record): $rel_path"
            skipped=$((skipped + 1))
          fi
        elif [ "$current" = "$stored" ]; then
          # Unmodified — safe to overwrite
          if [ "$DRY_RUN" = true ]; then
            info "[dry-run] Would update: $rel_path"
          else
            cp "$src_file" "$dest_file"
            info "Updated: $rel_path"
          fi
          updated=$((updated + 1))
        else
          # Locally modified — skip
          info "Skipped (locally modified): $rel_path"
          skipped=$((skipped + 1))
        fi
      fi
    done
  done

  # Regenerate checksums
  if [ "$DRY_RUN" = false ]; then
    write_checksums
  fi

  # Update CLAUDE.md if unmodified
  local rules_prefix=".claude/rules/"
  if [ "$GLOBAL" = true ]; then
    rules_prefix="rules/"
  fi

  if [ -f "$CLAUDE_MD" ]; then
    local stored_md
    stored_md="$(stored_checksum "CLAUDE.md")"
    local current_md=""
    if [ -f "$CLAUDE_MD" ]; then
      current_md="$(compute_checksum "$CLAUDE_MD")"
    fi

    if [ -n "$stored_md" ] && [ "$current_md" = "$stored_md" ]; then
      if [ "$DRY_RUN" = true ]; then
        info "[dry-run] Would regenerate CLAUDE.md"
      else
        generate_claude_md "$rules_prefix" > "$CLAUDE_MD"
        info "Regenerated CLAUDE.md"
      fi
    elif [ "$FORCE" = true ]; then
      if [ "$DRY_RUN" = true ]; then
        info "[dry-run] Would regenerate CLAUDE.md (--force)"
      else
        generate_claude_md "$rules_prefix" > "$CLAUDE_MD"
        info "Regenerated CLAUDE.md (--force)"
      fi
    else
      info "CLAUDE.md has local changes — skipping regeneration"
    fi
  fi

  echo ""
  if [ "$DRY_RUN" = true ]; then
    echo "Dry run complete — no files were written."
  else
    echo "Update complete! Added: $added, Updated: $updated, Skipped: $skipped"
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo ""
echo "claude-cortex installer"
echo "======================="
echo ""

if [ "$UPDATE" = true ]; then
  do_update
else
  do_install
fi
