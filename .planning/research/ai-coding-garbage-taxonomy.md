# AI Coding Garbage Taxonomy

> Comprehensive catalog of every type of garbage, mess, and pollution that AI coding assistants leave behind in projects. Each entry includes: what it looks like, how to detect it, how to prevent it, and how to clean it.
>
> Sources: OX Security "Army of Juniors" report (300+ repos analyzed), GitClear code quality data (2020-2024), SlopCodeBench research, arxiv empirical studies, CodeRabbit analysis (470 PRs), Cursor/Claude Code community reports, Reddit r/ExperiencedDevs + r/ClaudeAI + r/ChatGPTCoding + r/iOSProgramming + r/vibecoding, InfoQ, Tembo.io, Augment Code, SecurityWeek, Software Engineering research papers.

---

## The OX Security 10 Critical Anti-Patterns

OX Security analyzed 300+ open-source repositories and identified 10 systematic anti-patterns in AI-generated code. These are NOT random errors -- they are predictable, recurring behaviors that compound.

| # | Anti-Pattern | Occurrence Rate | Description |
|---|-------------|----------------|-------------|
| 1 | Comments Everywhere | 90-100% (Critical) | Excessive inline comments that increase cognitive load, ironically making code HARDER to review |
| 2 | By-The-Book Fixation | 80-90% (High) | Rigidly follows textbook patterns rather than tailoring solutions to the specific context |
| 3 | Over-Specification | 80-90% (High) | Creates hyper-specific, single-use solutions instead of reusable components |
| 4 | Avoidance of Refactors | 80-90% (High) | Generates new code but never improves or restructures existing implementations |
| 5 | Bugs Deja-Vu | 70-80% (High) | Identical bugs appear repeatedly because code reuse principles are violated |
| 6 | "Worked on My Machine" | 60-70% (Medium) | Code runs in dev but fails in production -- no awareness of deployment environments |
| 7 | Return of Monoliths | 40-50% (Medium) | Defaults to tightly-coupled monolithic architectures |
| 8 | Fake Test Coverage | 40-50% (Medium) | Inflates coverage metrics with meaningless tests that validate nothing |
| 9 | Vanilla Style | 40-50% (Medium) | Reimplements functionality from scratch instead of using proven libraries/SDKs |
| 10 | Phantom Bugs | 20-30% (Low) | Over-engineers for improbable edge cases, causing performance degradation |

**Key stat**: 15-28.7% of AI-authored commits introduce at least one issue. AI introduces nearly twice as many security issues as it fixes (arxiv large-scale study).

**Compounding effect**: Under repeated editing, agent-generated code deteriorates -- each multi-turn edit preserves and extends the anti-patterns of prior turns. Pass rates remain stable while the underlying code becomes increasingly difficult to extend (SlopCodeBench).

---

## 1. FILE POLLUTION

### 1.1 Markdown File Galore

**What it looks like:**
- README.md copies, PLAN.md, SPEC.md, ANALYSIS.md, ARCHITECTURE.md, MIGRATION.md scattered everywhere
- Claude/Cursor generating 500+ line README.md files after EVERY code change
- Documentation files created and then deleted in the same session (token waste)
- Multiple competing README files at different directory levels

**Community reports (Cursor forums):**
> "EVERY SINGLE TIME I generate a new migration with the agent, it drops a README.md that is at least 500 lines long!!"
> "I have a rule to NEVER automatically create .md files. Just got 5 .md files created on just 1 request."

**Detect:**
```bash
# Find .md files not in expected locations
find . -name "*.md" -not -path "./.planning/*" -not -path "./node_modules/*" -not -path "./.git/*" | grep -v "^./README.md$" | grep -v "^./CHANGELOG.md$" | grep -v "^./LICENSE.md$" | grep -v "^./CONTRIBUTING.md$"

# Find recently created .md files (last 7 days)
find . -name "*.md" -mtime -7 -not -path "./node_modules/*" -not -path "./.git/*"

# Count .md files -- more than 5-6 in root is suspicious
find . -maxdepth 2 -name "*.md" -not -path "./node_modules/*" | wc -l
```

**Prevent:**
- Rule in CLAUDE.md / .cursorrules: "NEVER create .md documentation files unless explicitly requested by the user"
- Git hook: reject commits adding new .md files without explicit flag
- `.gitignore` pattern for known AI doc patterns: `**/AI-ANALYSIS*.md`, `**/PLAN-*.md`

**Clean:**
```bash
# List all non-standard .md files for review
git ls-files "*.md" | grep -v -E "^(README|CHANGELOG|LICENSE|CONTRIBUTING|CODE_OF_CONDUCT)\.md$"
# Remove after review
git rm <files>
```

### 1.2 Duplicate Files

**What it looks like:**
- `utils.ts` AND `helpers.ts` with overlapping functions
- `formatDate()` in 3 different files
- Same component in `/components/Button.tsx` and `/shared/Button.tsx`
- Copy-pasted code rose from 8.3% to 12.3% of all changed lines (GitClear 2020-2024)

**Detect:**
```bash
# Find files with similar names suggesting duplication
find . -name "utils.*" -o -name "helpers.*" -o -name "common.*" -o -name "shared.*" | grep -v node_modules

# Use jscpd for copy-paste detection
npx jscpd --min-lines 5 --min-tokens 50 ./src

# Find duplicate function names across files
grep -rn "^export function\|^export const.*=" src/ | awk -F'[ (=]' '{print $NF, $1}' | sort | uniq -d -f0

# Knip finds unused exports which often indicate duplication
npx knip
```

**Prevent:**
- Rule: "Before creating a new utility function, search the codebase for existing implementations"
- ESLint plugin `eslint-plugin-import` with `no-duplicates` rule
- Enforce barrel file review or ban barrel files entirely

**Clean:**
```bash
# jscpd with JSON output for automation
npx jscpd --min-lines 5 --reporters json --output ./reports ./src
# Review report, consolidate duplicates, update imports
```

### 1.3 Temp/Backup Files

**What it looks like:**
- `.bak`, `.old`, `.copy`, `.tmp`, `.orig` files
- `component.tsx.backup`, `config.old.json`
- AI creates temporary files during multi-step operations and forgets to clean up

**Detect:**
```bash
# Find backup/temp files
find . -name "*.bak" -o -name "*.old" -o -name "*.copy" -o -name "*.tmp" -o -name "*.orig" -o -name "*~" | grep -v node_modules
git ls-files | grep -E "\.(bak|old|copy|tmp|orig)$"
```

**Prevent:**
- `.gitignore`: `*.bak`, `*.old`, `*.copy`, `*.tmp`, `*.orig`, `*~`
- Pre-commit hook rejecting these extensions

**Clean:**
```bash
git rm $(git ls-files | grep -E "\.(bak|old|copy|tmp|orig)$")
```

### 1.4 Empty/Stub Files

**What it looks like:**
- Files created during scaffolding but never populated
- `services/emailService.ts` containing only `export {}` or a single empty class
- Test files with no test cases

**Detect:**
```bash
# Find very small files (likely stubs)
find ./src -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" | xargs wc -l 2>/dev/null | awk '$1 < 5 && $1 > 0' | sort -n

# Find files with only exports and no implementation
grep -rl "^export \{\}" src/ --include="*.ts" --include="*.tsx"
```

**Prevent:**
- Rule: "Do not create files unless they contain meaningful implementation"
- Knip detects unused/empty exports

**Clean:**
```bash
npx knip --include files  # Lists unused files
```

### 1.5 Build Artifacts in Git

**What it looks like:**
- `.next/`, `dist/`, `build/`, `__pycache__/`, `.turbo/` committed
- `node_modules/` or `venv/` in repository
- Compiled `.js` files alongside `.ts` source

**Detect:**
```bash
# Check for common build artifacts in git
git ls-files | grep -E "^(\.next|dist|build|__pycache__|node_modules|\.turbo|\.cache)/"
git ls-files | grep -E "\.(pyc|pyo|class)$"
```

**Prevent:**
- Comprehensive `.gitignore` -- use `npx gitignore node` or similar generators
- Pre-commit hook checking for large binary files and known build dirs

**Clean:**
```bash
# Remove from git tracking but keep locally
git rm -r --cached .next/ dist/ build/ __pycache__/
echo ".next/\ndist/\nbuild/\n__pycache__/" >> .gitignore
git add .gitignore && git commit -m "fix: remove build artifacts from tracking"
```

### 1.6 OS/IDE Junk Files

**What it looks like:**
- `.DS_Store`, `Thumbs.db` (OS files)
- `.idea/`, `.vscode/settings.json` with personal settings
- `.env` files with real or placeholder credentials

**Detect:**
```bash
git ls-files | grep -E "(\.DS_Store|Thumbs\.db|\.idea/|\.vscode/settings\.json)"
git ls-files | grep -E "\.env($|\.local|\.development)"
```

**Prevent:**
- Global gitignore: `git config --global core.excludesfile ~/.gitignore_global`
- Pre-commit hook with `detect-secrets` for credential scanning

**Clean:**
```bash
git rm --cached .DS_Store
echo ".DS_Store" >> .gitignore
# For secrets: use git-filter-repo to purge from history
```

---

## 2. COMMENT GARBAGE

### 2.1 Comments Everywhere (OX #1 -- 90-100% prevalence)

**What it looks like:**
```typescript
// BAD: AI tutorial-style comments
// Import the React library for building UI components
import React from 'react';

// Define the User interface with required properties
interface User {
  // The unique identifier for the user
  id: string;
  // The user's display name
  name: string;
  // The user's email address
  email: string;
}

// Create a function to format the user's name
function formatUserName(user: User): string {
  // Return the formatted name
  return user.name.trim();
}
```

**Detect:**
```bash
# Count comment density (comments per line of code)
# High ratio (>0.3) suggests over-commenting
grep -c "^\s*//" src/**/*.ts | awk -F: '{sum+=$2; count++} END {print sum/count " avg comments per file"}'

# Find "obvious" comments that restate the code
grep -rn "// Import\|// Define\|// Create\|// Return\|// Set\|// Get\|// Initialize\|// Declare" src/ --include="*.ts" --include="*.tsx"

# Find step-by-step tutorial comments
grep -rn "// Step [0-9]\|// First,\|// Next,\|// Then,\|// Finally," src/ --include="*.ts" --include="*.tsx"
```

**ESLint rules:**
```json
{
  "no-inline-comments": "warn",
  "capitalized-comments": ["warn", "always", { "ignoreConsecutiveComments": true }]
}
```

**Prevent:**
- Rule: "Do not add comments that restate what the code already says. Only comment WHY, never WHAT."
- Rule: "Remove all tutorial-style step-by-step comments"

**Clean:**
```bash
# Manual review is safest, but you can find candidates:
grep -rn "// .*the\|// .*this\|// .*a " src/ --include="*.ts" | head -50
# Use AI itself: "Remove all obvious/redundant comments from this file"
```

### 2.2 Permanent TODOs and FIXMEs

**What it looks like:**
```typescript
// TODO: implement this
// TODO: add error handling
// FIXME: this is a hack
// HACK: temporary workaround
// XXX: needs refactoring
throw new Error("Not implemented");
```

**Detect:**
```bash
# Find all TODOs/FIXMEs with age
grep -rn "TODO\|FIXME\|HACK\|XXX\|TEMP\|TEMPORARY" src/ --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx"

# Cross-reference with git blame to find OLD ones
grep -rn "TODO\|FIXME" src/ --include="*.ts" -l | xargs -I{} git log --format="%ai" -1 -- {} | sort

# Find "Not implemented" placeholders
grep -rn "Not implemented\|not yet implemented\|TODO: implement" src/ --include="*.ts" --include="*.tsx"
```

**ESLint rules:**
```json
{
  "no-warning-comments": ["warn", { "terms": ["todo", "fixme", "hack", "xxx"], "location": "start" }]
}
```

**Prevent:**
- Rule: "Never leave TODO/FIXME comments. Either implement it now or create a tracked issue."
- CI gate: fail if TODO count increases in a PR
- Pre-commit hook counting TODOs

**Clean:**
```bash
# List all with context for triage
grep -rn -A2 "TODO\|FIXME" src/ --include="*.ts" --include="*.tsx" > todo-audit.txt
# Either implement, remove, or convert to GitHub issues
```

### 2.3 Commented-Out Code

**What it looks like:**
```typescript
// function oldImplementation() {
//   return fetch('/api/old-endpoint');
// }

function newImplementation() {
  return fetch('/api/new-endpoint');
}
```

**Detect:**
```bash
# Find blocks of commented-out code (3+ consecutive comment lines that look like code)
grep -rn "^\s*//.*[{};=(]" src/ --include="*.ts" --include="*.tsx" | head -50

# ESLint plugin
# eslint-plugin-no-commented-out-code (community plugin)
```

**ESLint rules:**
```json
{
  "no-commented-out-code": "warn"
}
```
(Requires `eslint-plugin-unicorn` or similar)

**Prevent:**
- Rule: "Never commit commented-out code. Use git history to recover old code."
- Pre-commit hook detecting large comment blocks

**Clean:**
```bash
# This requires careful review -- automated removal is risky
# Best done file-by-file during code review
```

### 2.4 AI Attribution Comments

**What it looks like:**
```typescript
// Generated by Claude
// AI-generated code - review carefully
// Created with GitHub Copilot
// This code was written by an AI assistant
```

**Detect:**
```bash
grep -rn "Generated by\|AI-generated\|Copilot\|Claude\|ChatGPT\|written by.*AI\|created by.*assistant" src/ --include="*.ts" --include="*.tsx" --include="*.js"
```

**Prevent:**
- Rule: "Never add AI attribution comments to code"

**Clean:**
```bash
# Safe to remove all of these
grep -rl "Generated by\|AI-generated\|Copilot\|ChatGPT" src/ --include="*.ts" | xargs sed -i '/Generated by\|AI-generated\|Copilot\|ChatGPT/d'
```

### 2.5 AI Placeholder Comments

**What it looks like:**
```typescript
interface Config {
  apiUrl: any; // Replace with proper type if needed
  timeout: any; // TODO: add proper typing
}
```

**Detect:**
```bash
grep -rn "Replace with\|add proper\|update this\|change this\|modify as needed\|adjust as necessary" src/ --include="*.ts" --include="*.tsx"
grep -rn ": any" src/ --include="*.ts" --include="*.tsx" | wc -l  # Count `any` types
```

**Prevent:**
- Rule: "Never use `any` type. Never leave placeholder comments. Implement properly or ask for clarification."

**Clean:**
- Replace `any` with proper types
- Implement or remove placeholder comments

---

## 3. CODE GARBAGE

### 3.1 Unused Imports

**What it looks like:**
```typescript
import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
// Only useState is actually used below
```

**Detect:**
```json
// .eslintrc.json
{
  "plugins": ["unused-imports"],
  "rules": {
    "no-unused-vars": "off",
    "unused-imports/no-unused-imports": "error",
    "unused-imports/no-unused-vars": ["warn", {
      "vars": "all",
      "varsIgnorePattern": "^_",
      "args": "after-used",
      "argsIgnorePattern": "^_"
    }]
  }
}
```

```bash
# TypeScript compiler also catches this
npx tsc --noEmit 2>&1 | grep "is declared but"

# Quick grep approach
npx eslint --rule '{"no-unused-vars": "error"}' src/
```

**Prevent:**
- ESLint `unused-imports/no-unused-imports` with `--fix`
- TypeScript `noUnusedLocals: true` and `noUnusedParameters: true` in tsconfig.json
- Auto-fix on save in IDE

**Clean:**
```bash
npx eslint --fix --rule '{"unused-imports/no-unused-imports": "error"}' src/
```

### 3.2 Unused Variables and Functions

**What it looks like:**
```typescript
const config = loadConfig(); // never referenced
function helperFunction() { /* never called */ }
export const DEPRECATED_CONSTANT = 'old-value'; // exported but never imported
```

**Detect:**
```json
{
  "rules": {
    "no-unused-vars": ["error", { "argsIgnorePattern": "^_" }]
  }
}
```

```bash
# Knip finds unused exports across the entire project
npx knip
# ts-prune finds unused exports
npx ts-prune
```

**Prevent:**
- ESLint `no-unused-vars` as error
- Knip in CI pipeline
- TypeScript strict mode

**Clean:**
```bash
npx knip --fix  # Auto-remove unused exports
npx eslint --fix src/  # Auto-fix unused vars where possible
```

### 3.3 Console.log / Debug Statements

**What it looks like:**
```typescript
console.log('DEBUG: user data', userData);
console.log('here');
console.log('>>>>>>>>', response);
console.warn('TODO: remove this');
debugger;
```

**Detect:**
```json
{
  "rules": {
    "no-console": ["error", { "allow": ["warn", "error"] }],
    "no-debugger": "error"
  }
}
```

```bash
# Quick scan
grep -rn "console\.log\|console\.debug\|debugger" src/ --include="*.ts" --include="*.tsx" --include="*.js"

# Find debug-style logs (with markers)
grep -rn "console\.log.*DEBUG\|console\.log.*HERE\|console\.log.*>>>>\|console\.log.*TODO\|console\.log.*TEMP" src/
```

**Prevent:**
- ESLint `no-console` as error (allow `console.error` only)
- `no-debugger` as error
- Pre-commit hook stripping console.log

**Clean:**
```bash
npx eslint --fix --rule '{"no-console": "error"}' src/
# Or targeted removal:
sed -i '/console\.log/d' src/**/*.ts  # CAREFUL: review first
```

### 3.4 Empty Catch Blocks

**What it looks like:**
```typescript
try {
  await dangerousOperation();
} catch (e) {}

try {
  JSON.parse(input);
} catch (error) {
  // silently swallow the error
}
```

**Detect:**
```json
{
  "rules": {
    "no-empty": ["error", { "allowEmptyCatch": false }]
  }
}
```

```bash
grep -rn "catch.*{" src/ --include="*.ts" -A1 | grep -B1 "^\s*}"
```

**Prevent:**
- ESLint `no-empty` with `allowEmptyCatch: false`
- Rule: "Every catch block must either handle the error, re-throw, or log with context"

**Clean:**
- Add proper error handling to each empty catch

### 3.5 Placeholder / Stub Implementations

**What it looks like:**
```typescript
function processPayment(order: Order): void {
  throw new Error("Not implemented");
}

async function sendEmail(to: string, body: string): Promise<void> {
  // TODO: integrate with email service
  return;
}

const API_KEY = "your-api-key-here";
const DATABASE_URL = "postgresql://localhost:5432/mydb";
```

**Detect:**
```bash
# Find "Not implemented" throws
grep -rn "Not implemented\|not yet implemented\|NotImplementedError" src/ --include="*.ts" --include="*.tsx"

# Find placeholder values
grep -rn "your-.*-here\|CHANGE_ME\|REPLACE_ME\|xxx\|placeholder\|example\.com" src/ --include="*.ts" --include="*.tsx" --include="*.env*"

# Find hardcoded URLs/ports
grep -rn "localhost:[0-9]\|127\.0\.0\.1\|http://\|https://" src/ --include="*.ts" --include="*.tsx" | grep -v "node_modules\|\.test\.\|\.spec\."

# Find hardcoded credentials
grep -rn "password.*=.*['\"].*['\"]$\|api_key.*=.*['\"].*['\"]$\|secret.*=.*['\"].*['\"]$" src/ --include="*.ts" --include="*.tsx"
```

**Prevent:**
- ESLint `no-magic-numbers` for hardcoded values
- `detect-secrets` pre-commit hook for credentials
- Rule: "Never commit placeholder values. Use environment variables for all configuration."

**Clean:**
```bash
# detect-secrets scan
pip install detect-secrets
detect-secrets scan --all-files > .secrets.baseline
```

### 3.6 Duplicate Utility Functions (Bugs Deja-Vu -- OX #5)

**What it looks like:**
```typescript
// In src/utils/format.ts
export function formatDate(date: Date): string { ... }

// In src/components/DatePicker/helpers.ts
export function formatDate(date: Date): string { ... }  // Same logic!

// In src/api/transforms.ts
function formatDateString(d: Date): string { ... }  // Same logic, different name!
```

**Detect:**
```bash
# Find functions with the same name in multiple files
grep -rn "^export function\|^export const" src/ --include="*.ts" | awk -F'[ (]' '{print $3}' | sort | uniq -c | sort -rn | head -20

# jscpd for copy-paste detection
npx jscpd --min-lines 3 --min-tokens 30 --reporters console ./src

# Knip for finding unused/duplicate exports
npx knip --include duplicates
```

**Prevent:**
- Rule: "Before writing any utility function, search the codebase for existing implementations with similar names or functionality"
- Enforce a single `src/lib/` or `src/utils/` directory for shared code
- Ban `helpers.ts` and `utils.ts` naming -- use specific names like `date-formatting.ts`

**Clean:**
- Consolidate into single implementations
- Update all import paths
- Run tests to verify

### 3.7 Over-Abstraction (OX #3 -- Over-Specification)

**What it looks like:**
```typescript
// AI creates AbstractFactoryProviderManager for a simple function
interface IUserServiceProvider {
  getService(): IUserService;
}
class UserServiceProviderFactory implements IUserServiceProvider {
  getService(): IUserService {
    return new UserServiceImpl();
  }
}
// When all you needed was:
function getUser(id: string) { return db.users.findById(id); }
```

**Detect:**
```bash
# Find files with excessive interface/class declarations
grep -c "interface\|abstract class\|implements\|extends" src/**/*.ts | awk -F: '$2 > 5' | sort -t: -k2 -rn

# Find "Provider", "Factory", "Manager", "Handler" stacking
grep -rn "Factory\|Provider\|Manager\|Handler\|Adapter\|Wrapper" src/ --include="*.ts" | grep -E "(Factory|Provider|Manager|Handler){2,}"

# Cyclomatic complexity check
npx eslint --rule '{"complexity": ["error", 10]}' src/
```

**Prevent:**
- Rule: "Prefer simple functions over classes. Only abstract when there are 3+ concrete implementations."
- ESLint `max-classes-per-file` rule
- Code review focusing on YAGNI (You Ain't Gonna Need It)

### 3.8 Inconsistent Naming

**What it looks like:**
```typescript
// camelCase AND snake_case in the same file
const userName = 'John';
const user_email = 'john@example.com';
const UserAge = 25;

// Inconsistent file naming
// src/components/UserProfile.tsx
// src/components/user-settings.tsx
// src/components/account_page.tsx
```

**Detect:**
```bash
# Find snake_case in TypeScript files (where camelCase is standard)
grep -rn "[a-z]_[a-z]" src/ --include="*.ts" --include="*.tsx" | grep -v "node_modules\|__\|_test\|_spec" | head -20

# Check file naming consistency
find src/ -name "*.ts" -o -name "*.tsx" | xargs -I{} basename {} | sort | grep -E "^[a-z].*_|^[A-Z].*-"
```

**ESLint rules:**
```json
{
  "@typescript-eslint/naming-convention": ["error", {
    "selector": "variable", "format": ["camelCase", "UPPER_CASE"]
  }, {
    "selector": "function", "format": ["camelCase", "PascalCase"]
  }]
}
```

**Prevent:**
- Enforce naming conventions in ESLint
- Document conventions in CLAUDE.md / project rules

### 3.9 "Glue Code" Trap

**What it looks like:**
- Code that exists solely to connect two pieces, bypassing the service layer
- Hard-coded API versions in integration scripts
- Direct database calls scattered outside the data layer

**Detect:**
```bash
# Find direct database calls outside of service/repository layers
grep -rn "prisma\.\|db\.\|knex\.\|sequelize\." src/ --include="*.ts" | grep -v "service\|repository\|model\|migration\|seed" | head -20

# Find hardcoded API versions
grep -rn "v[0-9]\+\.\|/api/v[0-9]" src/ --include="*.ts" | grep -v "config\|constant\|\.env"
```

---

## 4. TEST GARBAGE

### 4.1 Fake Test Coverage (OX #8 -- 40-50% prevalence)

**What it looks like:**
```typescript
// Test with no real assertion
test('should work', () => {
  const result = processData(input);
  expect(result).toBeDefined(); // Passes for ANY non-undefined value
});

// Test that just calls a function without asserting
test('saving works', async () => {
  await component.save(); // No assertion at all -- passes because no error
});

// Test that asserts existence, not behavior
test('should render', () => {
  expect(someComponent.handleClick).toBeDefined(); // Never calls it
});

// Test that validates the bug, not the requirement
test('calculates total', () => {
  expect(calculateTotal(100, 0.1)).toBe(-10); // Locks in buggy behavior!
});
```

**Detect:**
```bash
# Find tests with no assertions
grep -rn "test(\|it(" src/ --include="*.test.*" --include="*.spec.*" -A10 | grep -B5 "});" | grep -v "expect\|assert\|should"

# Find weak assertions
grep -rn "toBeDefined()\|toBeTruthy()\|not\.toBeNull()\|not\.toBeUndefined()" src/ --include="*.test.*" --include="*.spec.*"

# Find tests with only console.log (no assertions)
grep -rn "test(\|it(" src/ --include="*.test.*" -A15 | grep "console\.log" | head -20

# Mutation testing (gold standard for test quality)
npx stryker run  # Stryker mutator
```

**Prevent:**
- Rule: "Every test must have at least one specific behavioral assertion using `toEqual`, `toBe`, or `toHaveBeenCalledWith`"
- Rule: "Tests must be written BEFORE implementation (TDD)"
- Ban `toBeDefined()` and `toBeTruthy()` as sole assertions
- Require mutation testing score > 70%

**Clean:**
- Audit all tests with `toBeDefined()` / `toBeTruthy()` -- replace with specific assertions
- Run mutation testing to find tests that pass even when code is broken

### 4.2 Over-Mocked Tests

**What it looks like:**
```typescript
// Mocks everything including the module under test
jest.mock('./userService');
jest.mock('./database');
jest.mock('./logger');
jest.mock('./cache');
jest.mock('./validator'); // Even mocking the thing we should be testing!

test('validates user', () => {
  const result = validateUser(mockUser);
  expect(mockValidator).toHaveBeenCalled(); // Testing mock, not code
});
```

**Detect:**
```bash
# Count mocks per test file (>5 is suspicious)
grep -c "jest\.mock\|vi\.mock\|sinon\.stub\|spyOn" src/**/*.test.* 2>/dev/null | awk -F: '$2 > 5' | sort -t: -k2 -rn

# Find tests that mock the module under test
# (This requires manual review but you can find candidates)
grep -rn "jest\.mock" src/ --include="*.test.*" | head -30
```

**Prevent:**
- Rule: "Never mock the module under test. Only mock external dependencies (DB, API, filesystem)."
- Prefer integration tests over heavily mocked unit tests
- Use dependency injection to make code testable without mocks

### 4.3 Snapshot Test Abuse

**What it looks like:**
```typescript
// Meaningless snapshot test
test('should render correctly', () => {
  const { container } = render(<MyComponent />);
  expect(container).toMatchSnapshot(); // Tests nothing specific
});
```

**Problems:**
- Provides false sense of high code coverage
- No assertion clarity -- doesn't state WHAT behavior is tested
- Updates become rubber-stamped (`jest --updateSnapshot`)
- Tightly coupled to implementation details

**Detect:**
```bash
# Count snapshot tests
grep -rn "toMatchSnapshot\|toMatchInlineSnapshot" src/ --include="*.test.*" --include="*.spec.*" | wc -l

# Find snapshot files
find . -name "*.snap" -not -path "./node_modules/*" | wc -l

# Large snapshot files (>100 lines)
find . -name "*.snap" -not -path "./node_modules/*" -exec wc -l {} \; | awk '$1 > 100'
```

**Prevent:**
- Rule: "No snapshot tests for behavior testing. Use explicit assertions."
- If snapshots are used, limit to visual regression only
- ESLint plugin: `eslint-plugin-jest` with `no-large-snapshots` rule

**Clean:**
```bash
# Remove snapshot files and rewrite tests with proper assertions
find . -name "*.snap" -not -path "./node_modules/*" -delete
# Then rewrite each test with behavioral assertions
```

### 4.4 Tests That Depend on Execution Order

**What it looks like:**
```typescript
let sharedState: any;

test('first test sets state', () => {
  sharedState = createUser();
  expect(sharedState).toBeDefined();
});

test('second test uses state from first', () => {
  expect(sharedState.name).toBe('test'); // Fails if run in isolation
});
```

**Detect:**
```bash
# Find shared mutable state in test files
grep -rn "^let \|^var " src/ --include="*.test.*" --include="*.spec.*" | grep -v "const"

# Run tests in random order
npx jest --randomize  # Jest 29+
npx vitest --sequence.shuffle
```

**Prevent:**
- Rule: "Each test must be completely independent. Use beforeEach for setup."
- Run tests with `--randomize` flag in CI

### 4.5 Test Files With No Tests

**What it looks like:**
```typescript
// src/components/Header.test.tsx
// Empty file, or:
describe('Header', () => {
  // TODO: add tests
});
```

**Detect:**
```bash
# Find test files with no test/it blocks
find src/ -name "*.test.*" -o -name "*.spec.*" | xargs grep -L "test(\|it(" 2>/dev/null

# Find describe blocks with no tests inside
grep -rn "describe(" src/ --include="*.test.*" -A5 | grep -B3 "});" | grep -v "test(\|it("
```

---

## 5. GIT GARBAGE

### 5.1 Giant Commits With Meaningless Messages

**What it looks like:**
```
commit abc123 - "update"
  153 files changed, 4521 insertions(+), 892 deletions(-)

commit def456 - "fix"
  47 files changed

commit ghi789 - "changes"
  89 files changed
```

**Detect:**
```bash
# Find commits with vague messages
git log --oneline | grep -iE "^[a-f0-9]+ (update|fix|changes|wip|temp|stuff|misc|test|asdf|working)$"

# Find oversized commits (>20 files changed)
git log --shortstat --oneline | awk '/files? changed/ && ($1+0) > 20 {print prev, $0} {prev=$0}'

# AI-specific: find commits that look auto-generated
git log --oneline | grep -iE "implement|add feature|refactor|improve" | head -20
```

**Prevent:**
- Commit hooks enforcing conventional commits format
- Max file change limit in pre-commit hook
- Rule: "Atomic commits -- one logical change per commit"

**Clean:**
```bash
# Interactive rebase to squash/rename (for unpushed commits only)
git rebase -i HEAD~10
```

### 5.2 Merge Conflict Markers Left in Code

**What it looks like:**
```
<<<<<<< HEAD
const timeout = 5000;
=======
const timeout = 10000;
>>>>>>> feature-branch
```

**Detect:**
```bash
# Pre-commit hook (recommended)
grep -rn "<<<<<<< \|=======\|>>>>>>> " src/ --include="*.ts" --include="*.tsx" --include="*.js"
```

**Pre-commit hook:**
```bash
#!/usr/bin/env bash
# .git/hooks/pre-commit -- reject conflict markers
CONFLICT_MARKERS='<<<<<<<|=======|>>>>>>>'
if git diff --staged | grep "^+" | grep -Ei "$CONFLICT_MARKERS" -c > /dev/null 2>&1; then
  echo "ERROR: Conflict markers found in staged files"
  exit 1
fi
```

**Prevent:**
- Pre-commit hook (as shown above)
- ESLint: `no-restricted-syntax` can catch these patterns

### 5.3 Binary Files and Large Assets

**What it looks like:**
- Images, PDFs, videos committed directly
- Compiled binaries, .woff fonts, .sqlite databases
- `.env` files with secrets

**Detect:**
```bash
# Find large files in git history
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | awk '/^blob/ && $3 > 1048576 {print $3, $4}' | sort -rn

# Find binary files currently tracked
git ls-files | xargs file | grep -v "text\|empty\|JSON\|XML"
```

**Prevent:**
- `.gitignore` for all binary types
- Git LFS for necessary large files
- Pre-commit hook rejecting files > 500KB

---

## 6. DEPENDENCY GARBAGE

### 6.1 Unused Packages

**What it looks like:**
- `package.json` lists 47 dependencies, only 30 are imported anywhere
- Packages installed during experimentation but never used
- DevDependencies that should be in dependencies (or vice versa)

**Detect:**
```bash
# depcheck -- finds unused dependencies
npx depcheck

# Knip -- more comprehensive
npx knip --include dependencies

# One-liner to remove unused deps
npm uninstall $(npx depcheck --oneline)
```

**Prevent:**
- Run `depcheck` or `knip` in CI pipeline
- Rule: "Remove unused dependencies before committing"

**Clean:**
```bash
npx knip --fix  # Auto-remove from package.json
npm install     # Regenerate lockfile
```

### 6.2 Duplicate Purpose Packages

**What it looks like:**
- `moment` AND `date-fns` AND `dayjs` all installed
- `axios` AND `node-fetch` AND `got`
- `lodash` AND `underscore`
- `express-validator` AND `joi` AND `zod`

**Detect:**
```bash
# Check for common duplicate-purpose packages
node -e "
const pkg = require('./package.json');
const deps = {...pkg.dependencies, ...pkg.devDependencies};
const groups = {
  'HTTP clients': ['axios', 'node-fetch', 'got', 'ky', 'superagent', 'request'],
  'Date libs': ['moment', 'date-fns', 'dayjs', 'luxon'],
  'Validation': ['joi', 'yup', 'zod', 'ajv', 'express-validator'],
  'Utility': ['lodash', 'underscore', 'ramda'],
  'CSS-in-JS': ['styled-components', '@emotion/styled', 'styled-jsx'],
  'State mgmt': ['redux', 'zustand', 'jotai', 'recoil', 'mobx', 'valtio'],
  'Testing': ['jest', 'vitest', 'mocha', 'ava', 'tape'],
};
Object.entries(groups).forEach(([cat, pkgs]) => {
  const found = pkgs.filter(p => deps[p]);
  if (found.length > 1) console.log('DUPLICATE ' + cat + ':', found.join(', '));
});
"
```

**Prevent:**
- Rule: "Check existing dependencies before adding a new package that serves the same purpose"
- Document approved packages per category in project rules

### 6.3 Outdated / Vulnerable Dependencies

**Detect:**
```bash
npm audit
npm outdated
npx npm-check-updates
```

**Prevent:**
- Dependabot / Renovate Bot for automated updates
- `npm audit` in CI pipeline (fail on high/critical)

---

## 7. ARCHITECTURE GARBAGE

### 7.1 God Files (1000+ lines)

**What it looks like:**
- `src/utils/index.ts` with 2000 lines of unrelated utilities
- `src/components/Dashboard.tsx` with 1500 lines
- `src/api/routes.ts` handling every endpoint

**Detect:**
```bash
# Find files over 500 lines
find src/ -name "*.ts" -o -name "*.tsx" | xargs wc -l | awk '$1 > 500 && $2 != "total"' | sort -rn

# ESLint rule
# "max-lines": ["warn", { "max": 500, "skipBlankLines": true, "skipComments": true }]
```

**ESLint rules:**
```json
{
  "max-lines": ["warn", { "max": 500, "skipBlankLines": true, "skipComments": true }],
  "max-lines-per-function": ["warn", { "max": 100, "skipBlankLines": true, "skipComments": true }]
}
```

**Prevent:**
- ESLint `max-lines` and `max-lines-per-function`
- Rule: "No file should exceed 500 lines. Split into focused modules."
- Architecture review in PR process

### 7.2 God Functions (100+ lines)

**What it looks like:**
```typescript
export async function handleUserRequest(req: Request) {
  // 200 lines of validation, business logic, database calls, response formatting...
}
```

**Detect:**
```json
{
  "max-lines-per-function": ["warn", { "max": 50, "skipBlankLines": true, "skipComments": true }],
  "complexity": ["warn", 10]
}
```

```bash
# Cyclomatic complexity analysis
npx eslint --rule '{"complexity": ["error", 15]}' src/
```

### 7.3 Circular Dependencies

**What it looks like:**
- `A.ts` imports `B.ts` imports `C.ts` imports `A.ts`
- Causes mysterious runtime errors, undefined imports, webpack warnings

**Detect:**
```bash
# madge -- circular dependency detector
npx madge --circular --extensions ts,tsx src/

# dpdm -- dependency analysis
npx dpdm --circular src/index.ts

# ESLint
# "import/no-cycle": "error" (from eslint-plugin-import)
```

**Prevent:**
```json
{
  "import/no-cycle": ["error", { "maxDepth": 3 }]
}
```

### 7.4 Barrel Files Defeating Tree Shaking (OX: related to Over-Specification)

**What it looks like:**
```typescript
// src/utils/index.ts (barrel file)
export * from './dateUtils';
export * from './stringUtils';
export * from './arrayUtils';
export * from './objectUtils';
// Importing ONE function pulls in ALL utils
```

**Detect:**
```bash
# Find barrel files (index.ts that only re-exports)
find src/ -name "index.ts" -o -name "index.tsx" | xargs grep -l "export \* from\|export { " | head -20

# Check for barrel imports in code
grep -rn "from '\.\./.*index'\|from '\.\./[^/]*'" src/ --include="*.ts" --include="*.tsx" | head -20
```

**Prevent:**
- Rule: "Import from specific module paths, not barrel files"
- ESLint `no-restricted-imports` to ban barrel imports:
```json
{
  "no-restricted-imports": ["error", {
    "patterns": ["*/index", "*/index.*"]
  }]
}
```

### 7.5 Inconsistent File Organization

**What it looks like:**
- Some features in `/components`, some in `/features`, some in `/pages`
- Mix of flat and nested structures
- No clear pattern for where new code should go

**Detect:**
```bash
# Visualize directory structure
find src/ -type d | head -40

# Check for competing organizational patterns
ls -d src/components/ src/features/ src/modules/ src/pages/ src/views/ src/screens/ 2>/dev/null
```

**Prevent:**
- Document file organization rules in CLAUDE.md
- Rule: "All new features go in `src/features/<feature-name>/`"
- Architecture Decision Record (ADR) for project structure

---

## 8. DOCUMENTATION GARBAGE

### 8.1 README That Doesn't Match Reality

**What it looks like:**
- Setup instructions reference deleted scripts
- API documentation describes endpoints that no longer exist
- "Getting Started" section has wrong prerequisites

**Detect:**
```bash
# Check if scripts referenced in README exist in package.json
grep "npm run\|yarn " README.md | grep -oP "(?:npm run |yarn )\K\S+" | while read cmd; do
  grep -q "\"$cmd\"" package.json || echo "MISSING SCRIPT: $cmd"
done

# Check if file paths referenced in README exist
grep -oP '`[^`]*\.(ts|tsx|js|jsx|json|yml|yaml)`' README.md | tr -d '`' | while read f; do
  [ ! -f "$f" ] && echo "MISSING FILE: $f"
done
```

### 8.2 Stale TODOs and Dangling References

**What it looks like:**
```typescript
// See UserService.processPayment() for details  <-- UserService was deleted
// As defined in RFC-2024-003  <-- No such RFC exists
// Ref: JIRA-1234  <-- Ticket closed 6 months ago
```

**Detect:**
```bash
# Find references to deleted files/functions
grep -rn "See \|Ref:\|as defined in\|from.*import" src/ --include="*.ts" | head -30
# Cross-reference with actual file existence (manual process)

# Age of TODOs
git log --diff-filter=A --format="%ai" -S "TODO" -- "*.ts" | sort | head -20
```

---

## 9. SECURITY GARBAGE (AI-Specific)

### 9.1 Hardcoded Credentials

**What it looks like:**
```typescript
const API_KEY = 'sk-proj-abc123...';
const DB_PASSWORD = 'supersecret';
const JWT_SECRET = 'my-jwt-secret';
```

**Detect:**
```bash
# detect-secrets
pip install detect-secrets
detect-secrets scan

# trufflehog
trufflehog filesystem --directory=. --only-verified

# gitleaks
gitleaks detect

# Quick grep
grep -rn "password\|secret\|api_key\|token\|credential" src/ --include="*.ts" --include="*.env*" | grep -v "process\.env\|\.example"
```

**Prevent:**
- `detect-secrets` as pre-commit hook
- `.env.example` with placeholder values only
- Rule: "All secrets must come from environment variables"

### 9.2 Permissive CORS / Auth Bypass

**What it looks like:**
```typescript
// AI loves to set cors to allow all
app.use(cors({ origin: '*' }));

// Missing auth on server actions
export async function deleteUser(userId: string) {
  // No auth check!
  await db.users.delete(userId);
}
```

**Detect:**
```bash
grep -rn "origin: '\*'\|origin: true\|credentials: true" src/ --include="*.ts"
grep -rn "export async function" src/ --include="*.ts" | grep -v "auth\|session\|verify\|check"
```

### 9.3 Deprecated / Insecure Patterns

**What it looks like:**
```typescript
const crypto = require('crypto');
const hash = crypto.createHash('md5'); // Insecure hash algorithm
```

**Detect:**
```bash
grep -rn "createHash('md5')\|createHash('sha1')" src/ --include="*.ts" --include="*.js"

# ESLint security plugin
# eslint-plugin-security
```

---

## 10. COMPOUND DETECTION SCRIPTS

### 10.1 Full Garbage Scan Script

```bash
#!/usr/bin/env bash
# ai-garbage-scan.sh -- Comprehensive AI code garbage detector
set -euo pipefail

echo "=== AI CODE GARBAGE SCAN ==="
echo ""

# 1. File Pollution
echo "--- FILE POLLUTION ---"
echo "Non-standard .md files:"
find . -name "*.md" -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./.planning/*" | grep -v -E "^\./(README|CHANGELOG|LICENSE|CONTRIBUTING|CODE_OF_CONDUCT)\.md$" | head -10 || echo "  None found"

echo "Backup/temp files:"
git ls-files 2>/dev/null | grep -E "\.(bak|old|copy|tmp|orig)$" | head -10 || echo "  None found"

echo "Build artifacts in git:"
git ls-files 2>/dev/null | grep -E "^(\.next|dist|build|__pycache__|\.turbo)/" | head -5 || echo "  None found"

echo "OS/IDE junk:"
git ls-files 2>/dev/null | grep -E "(\.DS_Store|Thumbs\.db|\.idea/)" | head -5 || echo "  None found"

echo ""

# 2. Comment Garbage
echo "--- COMMENT GARBAGE ---"
echo "Obvious comments (restate code):"
grep -rn "// Import\|// Define\|// Create\|// Return\|// Set the\|// Get the\|// Initialize" src/ --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l

echo "TODOs/FIXMEs:"
grep -rn "TODO\|FIXME\|HACK\|XXX" src/ --include="*.ts" --include="*.tsx" --include="*.js" 2>/dev/null | wc -l

echo "Commented-out code blocks:"
grep -rn "^\s*//.*[{};=(]$" src/ --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l

echo "AI attribution comments:"
grep -rn "Generated by\|AI-generated\|Copilot\|Claude\|ChatGPT" src/ --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l

echo ""

# 3. Code Garbage
echo "--- CODE GARBAGE ---"
echo "console.log statements:"
grep -rn "console\.log\|console\.debug\|debugger" src/ --include="*.ts" --include="*.tsx" --include="*.js" 2>/dev/null | wc -l

echo "Placeholder implementations:"
grep -rn "Not implemented\|CHANGE_ME\|REPLACE_ME\|your-.*-here" src/ --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l

echo "'any' types:"
grep -rn ": any\b" src/ --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l

echo "Empty catch blocks:"
grep -rn "catch.*{" src/ --include="*.ts" --include="*.tsx" 2>/dev/null -A1 | grep -B1 "^\s*}" | grep "catch" | wc -l

echo "Hardcoded localhost URLs:"
grep -rn "localhost:\|127\.0\.0\.1:" src/ --include="*.ts" --include="*.tsx" 2>/dev/null | grep -v "\.test\.\|\.spec\.\|\.env" | wc -l

echo ""

# 4. Test Garbage
echo "--- TEST GARBAGE ---"
echo "Weak assertions (toBeDefined/toBeTruthy only):"
grep -rn "toBeDefined()\|toBeTruthy()" src/ --include="*.test.*" --include="*.spec.*" 2>/dev/null | wc -l

echo "Snapshot tests:"
grep -rn "toMatchSnapshot\|toMatchInlineSnapshot" src/ --include="*.test.*" --include="*.spec.*" 2>/dev/null | wc -l

echo "Heavy mock files (>5 mocks):"
find src/ -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | xargs grep -l "jest\.mock\|vi\.mock" 2>/dev/null | xargs grep -c "jest\.mock\|vi\.mock" 2>/dev/null | awk -F: '$2 > 5' | wc -l

echo ""

# 5. Architecture
echo "--- ARCHITECTURE GARBAGE ---"
echo "God files (>500 lines):"
find src/ -name "*.ts" -o -name "*.tsx" 2>/dev/null | xargs wc -l 2>/dev/null | awk '$1 > 500 && $2 != "total"' | wc -l

echo "Potential duplicate utilities:"
grep -rn "^export function\|^export const" src/ --include="*.ts" 2>/dev/null | awk -F'[ (]' '{print $3}' | sort | uniq -c | sort -rn | awk '$1 > 1' | head -5

echo ""

# 6. Security
echo "--- SECURITY GARBAGE ---"
echo "Potential hardcoded secrets:"
grep -rn "password.*=.*['\"].*['\"]$\|api_key.*=.*['\"].*['\"]$\|secret.*=.*['\"].*['\"]$" src/ --include="*.ts" --include="*.tsx" 2>/dev/null | grep -v "process\.env\|\.example\|\.test\.\|\.spec\." | wc -l

echo "Permissive CORS:"
grep -rn "origin: '\*'\|origin: true" src/ --include="*.ts" 2>/dev/null | wc -l

echo ""
echo "=== SCAN COMPLETE ==="
```

### 10.2 ESLint Config for AI Garbage Detection

```json
{
  "plugins": ["unused-imports", "import"],
  "rules": {
    "no-console": ["error", { "allow": ["error"] }],
    "no-debugger": "error",
    "no-unused-vars": "off",
    "unused-imports/no-unused-imports": "error",
    "unused-imports/no-unused-vars": ["warn", {
      "vars": "all", "varsIgnorePattern": "^_",
      "args": "after-used", "argsIgnorePattern": "^_"
    }],
    "no-empty": ["error", { "allowEmptyCatch": false }],
    "no-warning-comments": ["warn", { "terms": ["todo", "fixme", "hack", "xxx"] }],
    "no-magic-numbers": ["warn", { "ignore": [0, 1, -1], "enforceConst": true }],
    "max-lines": ["warn", { "max": 500, "skipBlankLines": true, "skipComments": true }],
    "max-lines-per-function": ["warn", { "max": 80, "skipBlankLines": true, "skipComments": true }],
    "complexity": ["warn", 15],
    "import/no-cycle": ["error", { "maxDepth": 3 }],
    "import/no-duplicates": "error"
  }
}
```

### 10.3 Recommended Tool Stack

| Tool | Purpose | Command |
|------|---------|---------|
| **Knip** | Unused files, exports, dependencies | `npx knip` |
| **depcheck** | Unused npm packages | `npx depcheck` |
| **jscpd** | Copy-paste / duplicate code | `npx jscpd ./src` |
| **madge** | Circular dependencies | `npx madge --circular src/` |
| **detect-secrets** | Hardcoded credentials | `detect-secrets scan` |
| **gitleaks** | Secrets in git history | `gitleaks detect` |
| **Stryker** | Mutation testing (test quality) | `npx stryker run` |
| **ESLint** | All code quality rules | `npx eslint src/` |
| **SonarQube** | Comprehensive static analysis | Cloud or self-hosted |

### 10.4 Prevention Rules for AI Coding Assistants

Put these in your CLAUDE.md, .cursorrules, or system prompt:

```markdown
## Anti-Garbage Rules (ENFORCED)

### Files
- NEVER create .md documentation files unless explicitly requested
- NEVER create backup/temp files (.bak, .old, .copy, .tmp)
- NEVER commit build artifacts, OS files, or IDE configs
- Before creating a new utility file, search for existing implementations

### Comments
- NEVER add comments that restate what the code says
- NEVER add tutorial-style step-by-step comments
- NEVER add AI attribution comments
- NEVER leave TODO/FIXME -- implement it or create a tracked issue
- NEVER commit commented-out code

### Code
- NEVER use `any` type in TypeScript
- NEVER leave console.log/debug statements
- NEVER leave empty catch blocks -- handle or re-throw
- NEVER use placeholder implementations (throw "Not implemented")
- NEVER hardcode credentials, URLs, or magic numbers
- Before writing a utility function, search for existing ones
- Prefer simple functions over unnecessary class hierarchies

### Tests
- NEVER write tests with only toBeDefined() or toBeTruthy()
- NEVER mock the module under test
- NEVER write snapshot tests for behavior validation
- Every test MUST have specific behavioral assertions
- Write tests BEFORE implementation (TDD)

### Dependencies
- NEVER add a package without checking for existing alternatives in package.json
- NEVER install multiple packages that serve the same purpose

### Architecture
- No file over 500 lines
- No function over 80 lines
- No circular dependencies
- Import from specific module paths, not barrel files
```

---

## Key Statistics

- **15-28.7%** of AI-authored commits introduce at least one issue (arxiv, 5 AI tools studied)
- **41%** increase in code complexity after AI tool adoption (He et al.)
- **90-93%** of AI code defects are code smells, 5-8% bugs, ~2% security vulnerabilities (Java study)
- **8.3% to 12.3%** increase in copy-pasted code (GitClear, 2020-2024)
- **Copy-pasted code now exceeds refactored code** for the first time in GitClear's dataset history
- **AI introduces 2x as many security issues as it fixes** (arxiv large-scale study)
- **4x maintenance costs** by year two of unmanaged AI-generated code (InfoQ analysis)
- **19% slower** -- experienced devs using AI tools took 19% longer on tasks, while believing they were 24% faster (METR RCT study)
- **25-point gap** between AI tests that "look right" (86%) and actually trigger bugs (61%) (VIBEPASS study)
- **"6-Month Wall"** -- accumulated debt becomes unmaintainable around 6 months without rigorous oversight

---

## Sources

1. OX Security, "Army of Juniors: The AI Code Security Crisis" (Oct 2025) -- 300+ repo analysis, 10 anti-patterns
2. GitClear, AI-assisted code quality data 2020-2024 -- copy-paste and churn metrics
3. SlopCodeBench (arxiv:2603.24755) -- code erosion benchmarking across multi-turn edits
4. arxiv "A Large-Scale Empirical Study of AI-Generated Code" -- 5 AI tools, technical debt analysis
5. CodeRabbit analysis of 470 PRs -- null check and guardrail omission patterns
6. Augment Code, "Debugging AI-Generated Code: 8 Failure Patterns" -- systematic failure taxonomy
7. METR RCT study -- experienced devs 19% slower with AI tools
8. VIBEPASS (Salesforce Research) -- AI test generation effectiveness gap
9. Cursor Community Forums -- .md file pollution reports
10. Reddit r/ClaudeAI, r/ChatGPTCoding, r/ExperiencedDevs, r/iOSProgramming, r/vibecoding -- practitioner reports
11. InfoQ, "AI-Generated Code Creates New Wave of Technical Debt" -- maintenance cost projections
12. Tembo.io, "AI Technical Debt: How AI-Generated Code Creates Hidden Issues" -- structural shift analysis
13. SecurityWeek, "Vibe Coding's Real Problem Isn't Bugs -- It's Judgment"
14. BayTech Consulting, "AI Technical Debt: How Vibe Coding Increases TCO"
