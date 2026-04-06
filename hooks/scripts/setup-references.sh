#!/bin/bash
# STP v0.2.0: Copy universal reference files into a project
# Called by /stp:new-project and /stp:onboard-existing
# Usage: bash setup-references.sh [plugin-root] [project-root]

PLUGIN_ROOT="${1:-$(dirname "$(dirname "$(dirname "$0")")")}"
PROJECT_ROOT="${2:-.}"

echo "Setting up STP references..."

mkdir -p "$PROJECT_ROOT/.stp/docs"
mkdir -p "$PROJECT_ROOT/.stp/state"
mkdir -p "$PROJECT_ROOT/.stp/references/security"
mkdir -p "$PROJECT_ROOT/.stp/references/accessibility"
mkdir -p "$PROJECT_ROOT/.stp/references/performance"
mkdir -p "$PROJECT_ROOT/.stp/references/production"

cp "$PLUGIN_ROOT/references/security/"*.md "$PROJECT_ROOT/.stp/references/security/" 2>/dev/null
cp "$PLUGIN_ROOT/references/accessibility/"*.md "$PROJECT_ROOT/.stp/references/accessibility/" 2>/dev/null
cp "$PLUGIN_ROOT/references/performance/"*.md "$PROJECT_ROOT/.stp/references/performance/" 2>/dev/null
cp "$PLUGIN_ROOT/references/production/"*.md "$PROJECT_ROOT/.stp/references/production/" 2>/dev/null

# Root-level reference files (not in subdirectories)
cp "$PLUGIN_ROOT/references/cli-output-format.md" "$PROJECT_ROOT/.stp/references/" 2>/dev/null

REF_COUNT=$(find "$PROJECT_ROOT/.stp/references" -name "*.md" | wc -l)
echo "Copied $REF_COUNT reference files to .stp/references/"

if [ -f "$PROJECT_ROOT/.gitignore" ]; then
  if ! grep -q "^\.stp/$" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
    echo "" >> "$PROJECT_ROOT/.gitignore"
    echo "# STP — Ship To Production standards references (plugin manages these)" >> "$PROJECT_ROOT/.gitignore"
    echo ".stp/" >> "$PROJECT_ROOT/.gitignore"
    echo "Added .stp/ to .gitignore"
  fi
fi

echo "STP setup complete."
