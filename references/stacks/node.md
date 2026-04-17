# Node Stack Reference (v1.0)

**Use when:** `.stp/state/stack.json` has `"primary": "node"`. Auto-loaded by `/stp:build`, `/stp:think`, `/stp:debug`.

## Detection markers
Files whose presence indicates this stack (detect-stack.sh scans for these):
- `package.json` + any of: `express`, `fastify`, `@nestjs/core`, `koa`, `hapi` in dependencies
- `src/server.ts`, `src/app.ts`, `src/main.ts` with no frontend framework imports
- `.nvmrc`, `.node-version` in root
- (secondary) `Dockerfile` with `FROM node:*`, `pm2.config.js`, `ecosystem.config.js`

## Commands
- **test:** `npm test` (or `npx jest --forceExit`, `npx vitest run`)
- **build:** `npx tsc --project tsconfig.json` (or `npm run build`)
- **lint:** `npx eslint . --ext .ts,.js`
- **type-check:** `npx tsc --noEmit`
- **format:** `npx prettier --write .`

## stack.json fields
```json
{
  "primary": "node",
  "ui": false,
  "test_cmd": "npm test",
  "build_cmd": "npm run build",
  "lint_cmd": "npx eslint . --ext .ts,.js",
  "type_cmd": "npx tsc --noEmit"
}
```

## Idiomatic patterns (what good code looks like)
- Route handlers are thin — business logic lives in service classes or functions, not inline
- All async handlers are wrapped in error-catching middleware — no unhandled promise rejections
- Environment config is validated at boot with zod or envalid — crash fast if required vars are absent
- Database access is through a repository or query-builder layer, never raw SQL in route handlers
- Secrets are never logged — use a log sanitizer or redact sensitive keys in the logging config

## Common gotchas
- Unhandled `Promise` rejections in async route handlers silently swallow errors in Express — always use `express-async-errors` or explicit try/catch
- `process.exit()` in AWS Lambda / serverless contexts prevents cleanup — use graceful shutdown hooks
- `require` caching means singleton modules are not re-evaluated on hot reload — restart dev server after env changes
- Missing `await` on database calls returns a Promise object instead of the result — no error, just wrong data
- `node_modules` in Docker images without `.dockerignore` bloats images to gigabytes

## Opus 4.7 prompt adjustments (inject when stack matches)
- "All HTTP handlers must handle errors explicitly — never let an unhandled rejection reach the process. Use middleware error boundaries."
- "Validate all inbound request shapes with zod or class-validator before touching business logic."

## Anti-slop patterns for this stack
- `// TODO: add validation` — slop (validate inputs before any handler logic)
- `console.log(password)` — slop (never log credentials or tokens)
- `catch (e) {}` (empty catch) — slop (always handle or rethrow)
- `process.env.SECRET || 'dev-secret'` — slop (fail loudly when required secrets are absent)

## Companion plugins / MCP servers
- **Context7** — pull live docs for Express, Fastify, NestJS, Prisma, and Node.js core APIs
- **Tavily** — research security advisories, middleware patterns, and deployment configurations

## References (external)
- Node.js best practices: https://github.com/goldbergyoni/nodebestpractices
- Fastify docs: https://fastify.dev/docs/latest/
