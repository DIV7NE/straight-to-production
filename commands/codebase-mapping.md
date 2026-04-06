---
description: "Visual codebase map. Analyzes architecture, models, routes, components, and integrations — exports a self-contained HTML file you can open anywhere. One-time export, no server needed."
argument-hint: Optional focus (e.g., "just models and routes" or "focus on auth domain")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "Agent"]
---

> **Recommended effort: `/effort high`** — Architecture analysis requires broad codebase reading.

# STP: Codebase Mapping

You are generating a visual, exportable architecture map of the codebase. The output is a single self-contained HTML file the user can open in any browser — no server, no localhost, no dependencies beyond a CDN for Mermaid diagram rendering.

## What This Produces

A file at `.stp/docs/codebase-map.html` containing:
- **Overview** — system architecture diagram (Mermaid) + stack + stats
- **Data Models** — ER diagram (Mermaid) + model cards with fields, relations, domain groupings
- **Routes** — API + page routes in tables, grouped by domain, with method/auth/purpose
- **Components** — major UI components grouped by domain, shared vs feature-specific
- **Integrations** — external services with connection type and env vars
- **Dependencies** — feature dependency graph (Mermaid)

All in a dark-themed, tabbed interface with the same visual language as the STP Whiteboard.

## Process

### Step 1: Check for Existing Architecture Data

```bash
[ -f ".stp/docs/ARCHITECTURE.md" ] && echo "arch:exists" || echo "arch:none"
[ -f ".stp/docs/CONTEXT.md" ] && echo "context:exists" || echo "context:none"
```

If ARCHITECTURE.md exists, read it first — use it as a starting point rather than re-analyzing from scratch. Cross-reference claims against actual code (spot-check 3 items). If it's accurate and comprehensive, extract data from it. If it's stale or incomplete, supplement with fresh analysis.

If no existing docs, analyze from scratch (Step 2).

### Step 2: Analyze the Codebase

Collect ALL of the following. Read actual files — never guess.

**Stack detection:**
```bash
# Package manager + framework
ls package.json pyproject.toml Cargo.toml go.mod *.csproj Gemfile composer.json 2>/dev/null
# Read the primary config for framework + dependencies
```

**Stats:**
```bash
# Source files (adjust extensions for the stack)
find . -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.rs" -o -name "*.go" | grep -v node_modules | grep -v .next | wc -l
# Test files
find . -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" | grep -v node_modules | wc -l
# Models (Prisma/Django/SQLAlchemy/TypeORM — adapt to stack)
grep -c "^model " prisma/schema.prisma 2>/dev/null || echo 0
# API routes
find . -name "route.ts" -o -name "route.js" | grep -v node_modules | wc -l
# Pages
find . -name "page.tsx" -o -name "page.jsx" -o -name "page.ts" | grep -v node_modules | wc -l
```

**Models** — Read the schema file (Prisma, Django models, SQLAlchemy, etc.):
- Name, key fields (not every field — focus on identifiers, foreign keys, important business fields)
- Relationships (belongs to, has many)
- Domain grouping (Auth, Core, Billing, Content, etc.)

**Routes** — Read route handlers:
- Method (GET/POST/PUT/DELETE) — for page routes, use "PAGE"
- Path
- Auth required (yes/no)
- One-line purpose
- Domain grouping

**Components** — Read component directories:
- Name
- Domain (which feature area)
- Where it's used (which pages/features reference it)
- Shared (true if used across multiple domains)

**Integrations** — Read configs, env files, SDK imports:
- Service name
- Purpose
- Connection type (SDK, REST API, Webhook, OAuth)
- Required env vars

### Step 3: Build Mermaid Diagrams

Generate diagram code for each:

**Architecture diagram** (`diagrams.architecture`):
```
graph TD
  Client[Browser] --> Next[Next.js App]
  Next --> API[API Routes]
  API --> DB[(PostgreSQL)]
  API --> Auth[Clerk]
  API --> Stripe[Stripe]
  ...
```
Keep it high-level — major components and their connections. 8-15 nodes max. Use descriptive labels.

**ER diagram** (`diagrams.dataModel`):
```
erDiagram
  User ||--o{ Post : creates
  User ||--o{ Comment : writes
  Post ||--o{ Comment : has
  ...
```
Include ALL models with their key relationships. Use proper cardinality notation.

**Feature dependency graph** (`diagrams.featureDeps`):
```
graph TD
  Auth --> Dashboard
  Auth --> API
  Billing --> Auth
  Dashboard --> API
  ...
```
Show which feature domains depend on which. This is critical for understanding blast radius of changes.

### Step 4: Assemble the Data Object

Build a JSON object matching this exact schema:

```json
{
  "projectName": "Project Name",
  "generatedAt": "YYYY-MM-DD",
  "version": "X.Y.Z",
  "stack": {
    "framework": "Next.js 15",
    "language": "TypeScript 5.x",
    "database": "PostgreSQL (Supabase)",
    "auth": "Clerk",
    "styling": "Tailwind CSS v4",
    "deployment": "Vercel",
    "testing": "Vitest + Playwright"
  },
  "stats": {
    "sourceFiles": 142,
    "testFiles": 38,
    "models": 12,
    "apiRoutes": 24,
    "pageRoutes": 18,
    "components": 45
  },
  "diagrams": {
    "architecture": "graph TD\n  ...",
    "dataModel": "erDiagram\n  ...",
    "featureDeps": "graph TD\n  ..."
  },
  "models": [
    {
      "name": "User",
      "fields": ["id", "email", "name", "role", "createdAt"],
      "relations": ["Post", "Comment", "Subscription"],
      "domain": "Auth"
    }
  ],
  "routes": {
    "api": [
      { "method": "GET", "path": "/api/users", "auth": true, "purpose": "List all users", "domain": "Auth" }
    ],
    "pages": [
      { "method": "PAGE", "path": "/dashboard", "auth": true, "purpose": "Main dashboard", "domain": "Core" }
    ]
  },
  "components": [
    { "name": "UserCard", "domain": "Auth", "usedIn": ["Dashboard", "AdminPanel"], "shared": true }
  ],
  "integrations": [
    { "name": "Stripe", "purpose": "Payment processing", "type": "SDK", "envVars": ["STRIPE_SECRET_KEY", "STRIPE_WEBHOOK_SECRET"] }
  ]
}
```

**Rules for the data:**
- Only include what you actually found in the code. Do NOT invent models, routes, or integrations.
- Domain groupings should be consistent across models, routes, and components.
- Mermaid diagram code must be valid — test mentally that the syntax is correct.
- Field lists on models: max 8 fields per model (key identifiers + foreign keys + important business fields).
- Route purposes: one line, max 60 chars. Be specific ("List users with pagination") not vague ("Handle users").

### Step 5: Generate the HTML

Read the template, inject the data, write the output:

```bash
# Read template
cat "${CLAUDE_PLUGIN_ROOT}/whiteboard/codebase-map-template.html"
```

Replace the `__CODEBASE_DATA__` placeholder in the template with your JSON data object. Write the result to `.stp/docs/codebase-map.html`.

**Use the Write tool** to create the file. The content is the template HTML with `__CODEBASE_DATA__` replaced by the actual JSON.

**IMPORTANT:** The JSON is injected inside a `<script type="application/json">` tag. Ensure the JSON does not contain the literal string `</script>` (it won't for normal codebase data, but be aware).

### Step 6: Verify + Present

Verify the file was written:
```bash
wc -c .stp/docs/codebase-map.html
```

Present to the user:

```
╔═══════════════════════════════════════════════════════╗
║  ✓ CODEBASE MAP EXPORTED                              ║
║  [Project Name] — [N] models, [N] routes, [N] integs ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  📄 .stp/docs/codebase-map.html                       ║
║                                                       ║
║  Open in any browser — no server needed.              ║
║  All diagrams are vector SVG (lossless zoom).         ║
║                                                       ║
║  Sections:                                            ║
║  · Overview — system architecture diagram + stack     ║
║  · Data Models — ER diagram + [N] model cards         ║
║  · Routes — [N] API + [N] page routes by domain       ║
║  · Components — [N] components by domain              ║
║  · Integrations — [N] external services               ║
║  · Dependencies — feature dependency graph            ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

## If User Specifies a Focus

If the user says "just models and routes" or "focus on auth domain":
- Still generate the full HTML template (all tabs)
- But only populate the requested sections with data
- Other sections will show "No data" empty states
- This is faster for targeted analysis

## Rules

- **Read actual code.** Never guess models, routes, or integrations from memory or training data.
- **One-time export.** This is not a live server. Generate once, open anywhere.
- **No server needed.** The HTML file works by opening it directly in a browser. Mermaid loads from CDN.
- **Consistent domains.** Use the same domain names across models, routes, and components so the groupings align.
- **Valid Mermaid.** Double-check diagram syntax. Common mistakes: missing arrow syntax, unescaped special chars in labels (use quotes), duplicate node IDs.
- **Don't bloat.** For large codebases (100+ models, 200+ routes), focus on the most important items. Group related routes under domain headings. Limit model fields to key identifiers.
- **If ARCHITECTURE.md exists, leverage it.** Don't redo work. Extract what you can, supplement with fresh analysis for the visual data (diagrams, structured fields) that ARCHITECTURE.md doesn't have.
