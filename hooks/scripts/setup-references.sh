#!/bin/bash
# Pilot: Copy reference files and scripts into a project
# Called by /pilot:new after generating CLAUDE.md
# Usage: bash setup-references.sh [plugin-root] [project-root]

PLUGIN_ROOT="${1:-$(dirname "$(dirname "$(dirname "$0")")")}"
PROJECT_ROOT="${2:-.}"

echo "Setting up Pilot references..."

# Create .pilot directory structure
mkdir -p "$PROJECT_ROOT/.pilot/references/security"
mkdir -p "$PROJECT_ROOT/.pilot/references/accessibility"
mkdir -p "$PROJECT_ROOT/.pilot/references/performance"
mkdir -p "$PROJECT_ROOT/.pilot/references/production"
mkdir -p "$PROJECT_ROOT/.pilot/scripts"

# Copy reference files
cp "$PLUGIN_ROOT/references/security/"*.md "$PROJECT_ROOT/.pilot/references/security/" 2>/dev/null
cp "$PLUGIN_ROOT/references/accessibility/"*.md "$PROJECT_ROOT/.pilot/references/accessibility/" 2>/dev/null
cp "$PLUGIN_ROOT/references/performance/"*.md "$PROJECT_ROOT/.pilot/references/performance/" 2>/dev/null
cp "$PLUGIN_ROOT/references/production/"*.md "$PROJECT_ROOT/.pilot/references/production/" 2>/dev/null

# Copy critic detection scripts
cp "$PLUGIN_ROOT/hooks/scripts/critic-checks.sh" "$PROJECT_ROOT/.pilot/scripts/" 2>/dev/null
chmod +x "$PROJECT_ROOT/.pilot/scripts/critic-checks.sh" 2>/dev/null

# Count what was copied
REF_COUNT=$(find "$PROJECT_ROOT/.pilot/references" -name "*.md" | wc -l)
echo "Copied $REF_COUNT reference files to .pilot/references/"
echo "Copied critic detection scripts to .pilot/scripts/"

# Add .pilot to .gitignore if not already there
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
  if ! grep -q "^\.pilot/$" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
    echo "" >> "$PROJECT_ROOT/.gitignore"
    echo "# Pilot standards references (plugin manages these)" >> "$PROJECT_ROOT/.gitignore"
    echo ".pilot/" >> "$PROJECT_ROOT/.gitignore"
    echo "Added .pilot/ to .gitignore"
  fi
fi

echo "Pilot setup complete."
