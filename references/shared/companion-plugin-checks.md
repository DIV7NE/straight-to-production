# Companion Plugin & MCP Detection

Run these checks to detect installed companion tools. Used by `/stp:new-project`, `/stp:onboard-existing`, `/stp:upgrade`.

## Plugin checks
```bash
# ui-ux-pro-max (required for UI/UX work)
[ -f ".claude/skills/ui-ux-pro-max/SKILL.md" ] && echo "ui-ux-pro-max: installed" || echo "ui-ux-pro-max: MISSING"

# Agent Browser CLI + skill (required for QA)
command -v agent-browser >/dev/null 2>&1 && echo "agent-browser-cli: installed" || echo "agent-browser-cli: MISSING"
[ -f ".claude/skills/agent-browser/SKILL.md" ] && echo "agent-browser-skill: installed" || echo "agent-browser-skill: MISSING"

# Statusline
[ -f "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/stp-statusline.js" ] && echo "statusline: OK" || echo "statusline: MISSING"
```

## MCP server checks (attempt tool calls)
- Context7: try `resolve-library-id`
- Tavily: try `tavily_search`
- Context Mode: try `ctx_stats`

## Install commands (for missing tools)
```bash
# ui-ux-pro-max
npm i -g uipro-cli && uipro init --ai claude

# Agent Browser (3-step)
npm install -g agent-browser
agent-browser install
npx skills add vercel-labs/agent-browser

# MCP servers (show to user — they run these)
# Context7:     claude mcp add context7 -- npx -y @upstash/context7-mcp@latest
# Tavily:       claude mcp add tavily -- npx -y tavily-mcp@latest  (requires TAVILY_API_KEY)
# Context Mode: claude mcp add context-mode -- npx -y context-mode-mcp@latest
```
