#!/bin/bash
# Pilot: Critic detection scripts
# Run by the critic agent during /pilot:evaluate
# Each function outputs findings in file:line format

set -euo pipefail

check_security() {
  echo "=== Security Checks ==="

  # Hardcoded secrets
  echo "--- Potential hardcoded secrets ---"
  grep -rn "sk_live\|sk_test\|password\s*=\s*[\"']\|secret\s*=\s*[\"']" \
    --include="*.ts" --include="*.tsx" --include="*.js" \
    --exclude-dir=node_modules --exclude-dir=.next . 2>/dev/null || echo "None found"

  # Missing auth on API routes
  echo "--- API routes without auth checks ---"
  for f in $(find . -path "*/api/*/route.ts" -o -path "*/api/*/route.tsx" 2>/dev/null | grep -v node_modules); do
    if ! grep -q "auth()\|getAuth\|currentUser\|getServerSession" "$f" 2>/dev/null; then
      echo "$f: No auth check found"
    fi
  done

  # Console.log in production code
  echo "--- console.log statements ---"
  grep -rn "console\.log\|console\.warn\|console\.error" \
    --include="*.ts" --include="*.tsx" \
    --exclude-dir=node_modules --exclude-dir=.next . 2>/dev/null | head -20 || echo "None found"

  # Env validation
  echo "--- Environment variable handling ---"
  if [ ! -f "src/lib/env.ts" ] && [ ! -f "src/env.ts" ] && [ ! -f "lib/env.ts" ]; then
    echo "WARNING: No env validation file found. Create src/lib/env.ts with Zod schema."
  else
    echo "Env validation file exists"
  fi
}

check_accessibility() {
  echo "=== Accessibility Checks ==="

  # Images without alt text
  echo "--- Images missing alt text ---"
  grep -rn "<img\|<Image" --include="*.tsx" --exclude-dir=node_modules . 2>/dev/null | \
    grep -v "alt=" | head -10 || echo "None found"

  # Divs with onClick (should be buttons)
  echo "--- Divs with onClick (should be button) ---"
  grep -rn "<div.*onClick\|<span.*onClick" --include="*.tsx" --exclude-dir=node_modules . 2>/dev/null | \
    head -10 || echo "None found"

  # Missing htmlFor on labels
  echo "--- Labels without htmlFor ---"
  grep -rn "<label" --include="*.tsx" --exclude-dir=node_modules . 2>/dev/null | \
    grep -v "htmlFor" | head -10 || echo "None found"

  # Missing lang attribute
  echo "--- HTML lang attribute ---"
  if grep -rq 'lang=' app/layout.tsx src/app/layout.tsx 2>/dev/null; then
    echo "Language attribute set"
  else
    echo "WARNING: No lang attribute on <html> element"
  fi

  # Heading hierarchy
  echo "--- Heading usage ---"
  grep -rn "<h[1-6]" --include="*.tsx" --exclude-dir=node_modules . 2>/dev/null | \
    sed 's/.*<h\([1-6]\).*/\1/' | sort | uniq -c | sort -rn || echo "No headings found"
}

check_performance() {
  echo "=== Performance Checks ==="

  # Barrel file imports
  echo "--- Potential barrel file imports ---"
  grep -rn "from ['\"]@/components['\"]" --include="*.ts" --include="*.tsx" \
    --exclude-dir=node_modules . 2>/dev/null | head -10 || echo "None found"

  # Sequential awaits (potential waterfalls)
  echo "--- Sequential awaits (potential waterfalls) ---"
  grep -rn "await " --include="*.ts" --include="*.tsx" \
    --exclude-dir=node_modules --exclude-dir=.next . 2>/dev/null | \
    awk -F: '{file=$1; line=$2} prev_file==file && line-prev_line<=2 {print prev_file":"prev_line" and "file":"line" — sequential awaits"} {prev_file=file; prev_line=line}' | \
    head -10 || echo "None found"

  # Missing next/image
  echo "--- Raw img tags (should use next/image) ---"
  grep -rn "<img " --include="*.tsx" --exclude-dir=node_modules . 2>/dev/null | \
    head -10 || echo "None found"
}

check_production_readiness() {
  echo "=== Production Readiness ==="

  # Error boundary
  echo "--- Error handling ---"
  if [ -f "app/error.tsx" ] || [ -f "src/app/error.tsx" ]; then
    echo "Global error.tsx: EXISTS"
  else
    echo "WARNING: No global error.tsx — users will see raw errors"
  fi

  # Not found page
  if [ -f "app/not-found.tsx" ] || [ -f "src/app/not-found.tsx" ]; then
    echo "Custom not-found.tsx: EXISTS"
  else
    echo "WARNING: No custom not-found.tsx — users will see default 404"
  fi

  # Loading states
  echo "--- Loading states ---"
  LOADING_COUNT=$(find . -name "loading.tsx" -not -path "*/node_modules/*" 2>/dev/null | wc -l)
  echo "loading.tsx files found: $LOADING_COUNT"

  SUSPENSE_COUNT=$(grep -rn "Suspense" --include="*.tsx" --exclude-dir=node_modules . 2>/dev/null | wc -l)
  echo "Suspense boundaries found: $SUSPENSE_COUNT"

  if [ "$LOADING_COUNT" -eq 0 ] && [ "$SUSPENSE_COUNT" -eq 0 ]; then
    echo "WARNING: No loading states found — users will see blank screens during data fetching"
  fi

  # TypeScript errors
  echo "--- TypeScript health ---"
  if [ -f "tsconfig.json" ]; then
    npx tsc --noEmit --pretty false 2>&1 | tail -5 || echo "tsc not available"
  fi

  # Build check
  echo "--- Build health ---"
  if [ -f "package.json" ]; then
    npm run build 2>&1 | tail -10 || echo "Build command not found"
  fi
}

# Run all checks or specific one based on argument
case "${1:-all}" in
  security) check_security ;;
  accessibility) check_accessibility ;;
  performance) check_performance ;;
  production) check_production_readiness ;;
  all)
    check_security
    echo ""
    check_accessibility
    echo ""
    check_performance
    echo ""
    check_production_readiness
    ;;
esac
