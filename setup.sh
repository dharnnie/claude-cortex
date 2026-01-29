#!/usr/bin/env bash
# setup.sh — Detect project languages and generate a CLAUDE.md with relevant @rules/ references.
# Compatible with Bash 3.2+ (macOS default).

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
DRY_RUN=false
FORCE=false
OUTPUT="./CLAUDE.md"
RULES_PATH=""

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<'EOF'
Usage: setup.sh [OPTIONS]

Detect project languages and generate a CLAUDE.md referencing the
appropriate coding-convention rules.

Options:
  --dry-run         Print generated CLAUDE.md to stdout without writing
  --output PATH     Override output path (default: ./CLAUDE.md)
  --force           Overwrite existing CLAUDE.md
  --rules-path DIR  Path to the rules repository
  --help            Show this message
EOF
  exit 0
}

# ── Parse args ────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)    DRY_RUN=true; shift ;;
    --force)      FORCE=true; shift ;;
    --output)     OUTPUT="$2"; shift 2 ;;
    --rules-path) RULES_PATH="$2"; shift 2 ;;
    --help)       usage ;;
    *)            echo "Unknown option: $1" >&2; usage ;;
  esac
done

# ── Resolve rules path ───────────────────────────────────────────────────────
resolve_rules_path() {
  if [ -n "$RULES_PATH" ]; then
    echo "$RULES_PATH"
    return
  fi

  # Script's own directory (works even when invoked via a symlink)
  local script_dir
  script_dir="$(cd "$(dirname "$0")" && pwd)"

  # If the script lives inside the rules repo, use that directory
  if [ -d "$script_dir/general" ]; then
    echo "$script_dir"
    return
  fi

  # Fall back to ~/.claude/rules/
  if [ -d "$HOME/.claude/rules" ]; then
    echo "$HOME/.claude/rules"
    return
  fi

  echo ""
}

RULES_PATH="$(resolve_rules_path)"

if [ -z "$RULES_PATH" ] || [ ! -d "$RULES_PATH" ]; then
  echo "Error: could not locate the rules directory." >&2
  echo "Provide --rules-path or ensure ~/.claude/rules/ exists." >&2
  exit 1
fi

# ── Guard: refuse to run inside the rules repo itself ─────────────────────────
current_dir="$(pwd)"
rules_real="$(cd "$RULES_PATH" && pwd)"
if [ "$current_dir" = "$rules_real" ]; then
  echo "Error: setup.sh should not be run inside the rules repository itself." >&2
  echo "Run it from your project directory instead." >&2
  exit 1
fi

# ── Guard: refuse to overwrite without --force ────────────────────────────────
if [ "$DRY_RUN" = false ] && [ "$FORCE" = false ] && [ -f "$OUTPUT" ]; then
  echo "Error: $OUTPUT already exists. Use --force to overwrite." >&2
  exit 1
fi

# ── Language detection ────────────────────────────────────────────────────────
# Indexed arrays for Bash 3.2 compatibility (no associative arrays).
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

# Detected languages (unique). We use a flat list and check for duplicates.
detected_langs=""    # "Go Ruby ..."
detected_dirs=""     # "golang ruby ..."

for entry in "${LANG_MARKERS[@]}"; do
  marker="${entry%%:*}"
  rest="${entry#*:}"
  lang="${rest%%:*}"
  dir="${rest#*:}"

  if [ -f "$marker" ]; then
    # Skip if already detected
    case " $detected_langs " in
      *" $lang "*) continue ;;
    esac
    detected_langs="$detected_langs $lang"
    detected_dirs="$detected_dirs $dir"
  fi
done

# Trim leading space
detected_langs="${detected_langs# }"
detected_dirs="${detected_dirs# }"

if [ -z "$detected_langs" ]; then
  echo "Info: no language marker files detected in the current directory."
  echo "      Generated CLAUDE.md will include only general rules."
fi

# ── Helper: extract description from a rule file ─────────────────────────────
# Reads the first "# Heading" line, skipping any YAML frontmatter.
extract_description() {
  local file="$1"
  local in_frontmatter=false
  while IFS= read -r line; do
    # Detect frontmatter boundaries
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

    # Match first # heading
    case "$line" in
      "# "*)
        echo "${line#\# }"
        return
        ;;
    esac
  done < "$file"
  # Fallback: filename without extension
  local base
  base="$(basename "$file" .md)"
  echo "$base"
}

# ── Build the rules section ──────────────────────────────────────────────────
build_section() {
  local dir_name="$1"
  local heading="$2"
  local full_dir="$RULES_PATH/$dir_name"

  if [ ! -d "$full_dir" ]; then
    return
  fi

  echo ""
  echo "### $heading"

  for file in "$full_dir"/*.md; do
    [ -f "$file" ] || continue
    local desc
    desc="$(extract_description "$file")"
    local rel="$dir_name/$(basename "$file")"
    echo "- @rules/$rel - $desc"
  done
}

# ── Generate output ──────────────────────────────────────────────────────────
generate() {
  local detected_list="$1"

  echo "# Project Coding Conventions"
  echo ""
  echo "> Auto-generated by claude-cortex setup.sh"
  if [ -n "$detected_list" ]; then
    echo "> Detected: $detected_list"
  else
    echo "> Detected: (none)"
  fi
  echo ""
  echo "## Rules Reference"

  # General rules are always included
  build_section "general" "General (All Languages)"

  # Language-specific sections
  for dir in $detected_dirs; do
    if [ ! -d "$RULES_PATH/$dir" ]; then
      echo "Info: rules directory '$dir' not found in $RULES_PATH — skipping." >&2
      continue
    fi

    # Derive a display label from detected_langs/detected_dirs
    local label="$dir"
    # Walk parallel lists to find the label
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

    build_section "$dir" "$label"
  done

  echo ""
  echo "## Project-Specific Notes"
  echo ""
  echo "<!-- Add project-specific conventions below -->"
}

output="$(generate "$detected_langs")"

if [ "$DRY_RUN" = true ]; then
  echo "$output"
else
  echo "$output" > "$OUTPUT"
  echo "Created $OUTPUT with rules for: ${detected_langs:-general only}"
fi
