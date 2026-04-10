# Required Companion Plugins & MCP Servers

STP requires the following installed for full capability.

## Plugins (installed per project)
| Plugin | Purpose | Install |
|--------|---------|---------|
| **ui-ux-pro-max** (v2.5+) | Design intelligence — 67 styles, 161 palettes, 57 font pairings, product-type-aware recommendations. Generates persistent DESIGN-SYSTEM.md. | `npm i -g uipro-cli && uipro init --ai claude` |

## MCP Servers (installed globally)
| MCP Server | Purpose | Why mandatory |
|------------|---------|---------------|
| **Context7** | Live documentation retrieval — resolve library IDs, query current API docs, verify patterns against latest versions | STP's research phases (Phase 4, Phase 5b) depend on Context7 to prevent building on stale training data. Without it, architecture decisions use potentially outdated API knowledge. |
| **Tavily** | Deep web research — best practices, industry standards, competitive analysis, structured research | STP's research phases use Tavily for implementation patterns, security advisories, and "how do production apps solve this" queries. Without it, research depth is significantly reduced. |
| **Context Mode** | Context window protection — runs commands/searches in sandbox, keeps raw output out of context, indexes results for follow-up queries | STP's subagents and research phases generate large outputs. Context Mode prevents context window flooding, enabling longer sessions before compaction. Essential for `/stp:work-full`'s 22 sub-phases. |

## Browser automation tooling (CLI + Claude Code skill — not an MCP)
| Tool | Purpose | Install |
|------|---------|---------|
| **[Vercel Agent Browser](https://github.com/vercel-labs/agent-browser)** | Native Rust CLI for browser automation. STP's QA agent and `/stp:review` use it via the Bash tool to test running apps like a real user — navigate pages, click elements with snapshot refs, fill forms, verify rendered state, take screenshots, test responsive layouts. Without it, QA is limited to API/curl-only testing. | 3-step install: `npm install -g agent-browser` (CLI), `agent-browser install` (downloads Chrome for Testing), `npx skills add vercel-labs/agent-browser` (installs the Claude Code skill at `.claude/skills/agent-browser/SKILL.md` that teaches the snapshot-ref workflow). |

## Enforcement
`/stp:new-project` and `/stp:upgrade` preflight checks verify plugins, MCP servers, and Vercel Agent Browser. `/stp:onboard-existing` only DETECTS them (read-only) and notes any missing in `AUDIT.md` for the user to install themselves afterward. If missing in `/stp:new-project` or `/stp:upgrade`, the user is prompted to install before proceeding. Any STP command that touches UI/UX code MUST invoke `/ui-ux-pro-max` before writing frontend code. Research phases MUST use Context7 for library docs and Tavily for industry research — never rely solely on training data. QA phases MUST use the `agent-browser` CLI for any project with UI.
