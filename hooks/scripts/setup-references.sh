#!/bin/bash
# Pilot v0.2.0: Copy universal reference files into a project
# Called by /pilot:new and /pilot:setup
# Usage: bash setup-references.sh [plugin-root] [project-root]

PLUGIN_ROOT="${1:-$(dirname "$(dirname "$(dirname "$0")")")}"
PROJECT_ROOT="${2:-.}"

echo "Setting up Pilot references..."

mkdir -p "$PROJECT_ROOT/.pilot/references/security"
mkdir -p "$PROJECT_ROOT/.pilot/references/accessibility"
mkdir -p "$PROJECT_ROOT/.pilot/references/performance"
mkdir -p "$PROJECT_ROOT/.pilot/references/production"

cp "$PLUGIN_ROOT/references/security/"*.md "$PROJECT_ROOT/.pilot/references/security/" 2>/dev/null
cp "$PLUGIN_ROOT/references/accessibility/"*.md "$PROJECT_ROOT/.pilot/references/accessibility/" 2>/dev/null
cp "$PLUGIN_ROOT/references/performance/"*.md "$PROJECT_ROOT/.pilot/references/performance/" 2>/dev/null
cp "$PLUGIN_ROOT/references/production/"*.md "$PROJECT_ROOT/.pilot/references/production/" 2>/dev/null

REF_COUNT=$(find "$PROJECT_ROOT/.pilot/references" -name "*.md" | wc -l)
echo "Copied $REF_COUNT reference files to .pilot/references/"

if [ -f "$PROJECT_ROOT/.gitignore" ]; then
  if ! grep -q "^\.pilot/$" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
    echo "" >> "$PROJECT_ROOT/.gitignore"
    echo "# Pilot standards references (plugin manages these)" >> "$PROJECT_ROOT/.gitignore"
    echo ".pilot/" >> "$PROJECT_ROOT/.gitignore"
    echo "Added .pilot/ to .gitignore"
  fi
fi

echo "Pilot setup complete."
