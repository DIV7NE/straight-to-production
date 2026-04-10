#!/usr/bin/env node
/**
 * STP Model Profiles — Single Source of Truth
 *
 * Inspired by GSD's `get-shit-done/bin/lib/model-profiles.cjs` (which works reliably).
 *
 * This file is the canonical mapping of STP sub-agents to Claude models for each
 * optimization profile. STP commands and hooks call this file as a CLI to:
 *   - Set the active profile        : node model-profiles.cjs set <profile>
 *   - Read the current profile      : node model-profiles.cjs current
 *   - Resolve a model for an agent  : node model-profiles.cjs resolve <agent>
 *   - Print the full mapping table  : node model-profiles.cjs table [profile]
 *
 * The active profile is stored in `.stp/state/profile.json` as a minimal JSON file:
 *   {"profile": "balanced-profile", "set_at": "2026-04-09T01:03:09Z"}
 *
 * **Critical insight from GSD:** When a profile says an agent should use the
 * parent session's model (e.g. "use opus when running on opus, sonnet on sonnet"),
 * the resolved value is the literal string `"inherit"`. STP commands MUST interpret
 * `"inherit"` as: omit the `model=` parameter from the Agent() spawn call entirely,
 * which causes Claude Code to inherit the parent session's model.
 *
 * Current STP profiles (intended/balanced/budget) do NOT use the inherit sentinel
 * because STP intentionally spawns Sonnet sub-agents even when the main session is
 * Opus, for cost reasons. The inherit sentinel and code path are retained for:
 *   - Future STP profiles where an agent should match the parent session's model
 *   - Non-Anthropic runtimes (Codex, OpenCode, Gemini CLI) where hardcoding Anthropic
 *     model IDs would break the spawn — inherit causes the runtime's default to be used
 *
 * See the `*** KNOWN LIMITATION ***` block below for caveats about STP agent frontmatters.
 */

'use strict';

const fs = require('fs');
const path = require('path');

// ─────────────────────────────────────────────────────────────────────────
// Canonical mapping: per-agent × per-profile → model
// ─────────────────────────────────────────────────────────────────────────
//
// Profile semantics:
//   intended-profile  — Original STP architecture, "as is — we do nothing".
//                       Main session = Opus 4.6 [1M] (chosen by user when launching Claude Code).
//                       Sub-agents = sonnet (cheap builders, matches the original hardcoded
//                       behavior from STP v0.3.7 and earlier). Researcher/explorer happen
//                       INLINE in main session (Opus 1M absorbs them without context pressure).
//
//   balanced-profile  — Opus for planning, Sonnet for execution + verification.
//                       All sub-agents = sonnet (consistent regardless of main session).
//                       Mandatory researcher/explorer sub-agents to keep main session lean.
//
//   budget-profile    — Sonnet for everything except Critic (Haiku, with escalation).
//                       All write/test agents = sonnet.
//                       Critic = haiku for first pass; commands escalate to sonnet on ≥2 issues.
//                       Strict context discipline: mandatory researcher/explorer.
//
// Sentinel values:
//   "inherit" — omit the model parameter from Agent() spawn; use parent session's model.
//               Reserved for future profiles or non-Anthropic runtimes (Codex, OpenCode,
//               Gemini CLI). NOT used by intended/balanced/budget — STP intentionally uses
//               Sonnet sub-agents even when main is Opus, for cost reasons.
//
//               *** KNOWN LIMITATION ***
//               STP's agent files (executor.md, qa.md, critic.md, researcher.md, explorer.md)
//               all have `model: sonnet` in their frontmatter as a defensive default. The
//               Claude Code Agent tool's model resolution chain is:
//                 1. Spawn-time model param (highest precedence)
//                 2. Agent file frontmatter `model:` field
//                 3. Parent session model (lowest precedence)
//               When the spawn omits the model param (the inherit sentinel path), the agent
//               frontmatter takes over — so the spawn ACTUALLY runs on Sonnet, not the
//               parent session model. The "inherit" semantic is therefore a NO-OP in STP today.
//               This is fine because no current profile uses inherit. To make it actually
//               inherit, you'd need to remove the `model:` line from the relevant agent files.
//
//   "inline"  — do NOT spawn a sub-agent at all; main session handles this work directly.
//               Used by intended-profile for researcher/explorer.
//   "sonnet" / "opus" / "haiku" — pass this exact value as the spawn model parameter.

const MODEL_PROFILES = {
  // ┌─────────────────────────┬─────────────────────┬─────────────────────┬─────────────────────┐
  // │ Agent                   │ intended-profile    │ balanced-profile    │ budget-profile      │
  // ├─────────────────────────┼─────────────────────┼─────────────────────┼─────────────────────┤
  'stp-executor':             { 'intended-profile': 'sonnet',  'balanced-profile': 'sonnet', 'budget-profile': 'sonnet' },
  'stp-qa':                   { 'intended-profile': 'sonnet',  'balanced-profile': 'sonnet', 'budget-profile': 'sonnet' },
  'stp-critic':               { 'intended-profile': 'sonnet',  'balanced-profile': 'sonnet', 'budget-profile': 'haiku'  },
  'stp-critic-escalation':    { 'intended-profile': 'sonnet',  'balanced-profile': 'sonnet', 'budget-profile': 'sonnet' },
  'stp-researcher':           { 'intended-profile': 'inline',  'balanced-profile': 'sonnet', 'budget-profile': 'sonnet' },
  'stp-explorer':             { 'intended-profile': 'inline',  'balanced-profile': 'sonnet', 'budget-profile': 'sonnet' },
  // └─────────────────────────┴─────────────────────┴─────────────────────┴─────────────────────┘
};

// Discipline rules (independent of model selection — affects how commands behave)
const PROFILE_DISCIPLINE = {
  'intended-profile': {
    clear_between_phases: 'recommended',
    context_mode_required: 'recommended',
    researcher_mandatory: false,
    explorer_mandatory: false,
    max_main_session_kb: null,
    description: 'Original STP architecture. Opus 4.6 [1M] main + Sonnet sub-agents. Light context discipline.',
  },
  'balanced-profile': {
    clear_between_phases: 'mandatory',
    context_mode_required: 'mandatory',
    researcher_mandatory: true,
    explorer_mandatory: true,
    max_main_session_kb: 120,
    description: 'Opus plans, Sonnet executes. All sub-agents = sonnet. Mandatory context discipline.',
  },
  'budget-profile': {
    clear_between_phases: 'enforced',
    context_mode_required: 'hard-block',
    researcher_mandatory: true,
    explorer_mandatory: true,
    max_main_session_kb: 100,
    description: 'Sonnet writes, Haiku verifies (with Sonnet escalation). Hardcore context discipline.',
  },
};

// Derive valid profile names from the table (so adding a profile = add a column, no other changes)
const VALID_PROFILES = Object.keys(MODEL_PROFILES['stp-executor']);
const DEFAULT_PROFILE = 'balanced-profile';

// ─────────────────────────────────────────────────────────────────────────
// Core resolver functions
// ─────────────────────────────────────────────────────────────────────────

/**
 * Returns a mapping from agent → resolved model for the given profile.
 * Returns 'inherit' for parent-session inheritance, 'inline' for no-sub-agent.
 */
function getAgentToModelMap(profile) {
  const normalized = normalizeProfile(profile);
  const map = {};
  for (const [agent, profileMap] of Object.entries(MODEL_PROFILES)) {
    map[agent] = profileMap[normalized];
  }
  return map;
}

/**
 * Resolves the model for a specific agent under the given profile.
 */
function resolveAgentModel(agent, profile) {
  const normalized = normalizeProfile(profile);
  if (!MODEL_PROFILES[agent]) {
    throw new Error(`Unknown agent: ${agent}. Valid: ${Object.keys(MODEL_PROFILES).join(', ')}`);
  }
  return MODEL_PROFILES[agent][normalized];
}

/**
 * Returns the discipline rules for the given profile.
 */
function getDiscipline(profile) {
  const normalized = normalizeProfile(profile);
  return PROFILE_DISCIPLINE[normalized];
}

/**
 * Normalizes a profile name. Accepts shortcuts:
 *   "intended"  → "intended-profile"
 *   "balanced"  → "balanced-profile"
 *   "budget"    → "budget-profile"
 *   "INTENDED"  → "intended-profile" (case-insensitive)
 */
function normalizeProfile(profile) {
  if (!profile || typeof profile !== 'string') return DEFAULT_PROFILE;
  const trimmed = profile.trim().toLowerCase();
  if (VALID_PROFILES.includes(trimmed)) return trimmed;
  const withSuffix = trimmed.endsWith('-profile') ? trimmed : `${trimmed}-profile`;
  if (VALID_PROFILES.includes(withSuffix)) return withSuffix;
  throw new Error(`Unknown profile: "${profile}". Valid: ${VALID_PROFILES.join(', ')}`);
}

/**
 * Reads the active profile from .stp/state/profile.json.
 * Defaults to intended-profile if file is missing or malformed.
 */
function readActiveProfile(projectRoot) {
  const root = projectRoot || process.cwd();
  const profileFile = path.join(root, '.stp', 'state', 'profile.json');
  try {
    const data = JSON.parse(fs.readFileSync(profileFile, 'utf8'));
    return normalizeProfile(data.profile || DEFAULT_PROFILE);
  } catch (e) {
    return DEFAULT_PROFILE;
  }
}

/**
 * Writes the active profile to .stp/state/profile.json.
 */
function writeActiveProfile(profile, projectRoot) {
  const root = projectRoot || process.cwd();
  const stateDir = path.join(root, '.stp', 'state');
  const profileFile = path.join(stateDir, 'profile.json');
  const normalized = normalizeProfile(profile);

  fs.mkdirSync(stateDir, { recursive: true });

  // Backup existing if present and malformed
  if (fs.existsSync(profileFile)) {
    try {
      JSON.parse(fs.readFileSync(profileFile, 'utf8'));
    } catch (e) {
      const backup = `${profileFile}.bak.${Date.now()}`;
      fs.copyFileSync(profileFile, backup);
    }
  }

  const payload = {
    version: 1,
    profile: normalized,
    set_at: new Date().toISOString(),
    set_by: 'stp:set-profile-model',
  };
  fs.writeFileSync(profileFile, JSON.stringify(payload, null, 2) + '\n', 'utf8');
  return normalized;
}

// ─────────────────────────────────────────────────────────────────────────
// Pretty-print helpers
// ─────────────────────────────────────────────────────────────────────────

function formatTable(profile) {
  const map = getAgentToModelMap(profile);
  const disc = getDiscipline(profile);
  const agentWidth = Math.max('Agent'.length, ...Object.keys(map).map((a) => a.length));
  const modelWidth = Math.max('Model'.length, ...Object.values(map).map((m) => m.length));

  const sep = '─'.repeat(agentWidth + 2) + '┼' + '─'.repeat(modelWidth + 2);
  const header = ' ' + 'Agent'.padEnd(agentWidth) + ' │ ' + 'Model'.padEnd(modelWidth);

  let out = '';
  out += `\n  Profile: ${profile}\n`;
  out += `  ${disc.description}\n\n`;
  out += '  ' + header + '\n';
  out += '  ' + sep + '\n';
  for (const [agent, model] of Object.entries(map)) {
    out += '  ' + ' ' + agent.padEnd(agentWidth) + ' │ ' + model.padEnd(modelWidth) + '\n';
  }
  out += '\n  Discipline:\n';
  out += `    /clear between phases : ${disc.clear_between_phases}\n`;
  out += `    Context Mode MCP      : ${disc.context_mode_required}\n`;
  out += `    Researcher mandatory  : ${disc.researcher_mandatory}\n`;
  out += `    Explorer mandatory    : ${disc.explorer_mandatory}\n`;
  out += `    Max main session KB   : ${disc.max_main_session_kb === null ? 'unlimited' : disc.max_main_session_kb}\n`;
  out += '\n  Sentinels:\n';
  out += '    "inherit" → omit model param from Agent() spawn (use parent session model)\n';
  out += '    "inline"  → do NOT spawn a sub-agent; main session handles this work\n';
  return out;
}

function formatBanner(profile, action) {
  const cyan = '\x1b[36m';
  const bold = '\x1b[1;37m';
  const reset = '\x1b[0m';
  const disc = getDiscipline(profile);

  let out = '';
  out += `${cyan}╔══════════════════════════════════════════════════════════════╗${reset}\n`;
  out += `${cyan}║${reset}  ${bold}✓ Profile ${action}: ${profile}${reset}` + ' '.repeat(Math.max(0, 62 - 14 - action.length - profile.length)) + `${cyan}║${reset}\n`;
  out += `${cyan}║${reset}  ${disc.description.slice(0, 60).padEnd(60)}  ${cyan}║${reset}\n`;
  out += `${cyan}╚══════════════════════════════════════════════════════════════╝${reset}\n`;
  return out;
}

// ─────────────────────────────────────────────────────────────────────────
// CLI entry point
// ─────────────────────────────────────────────────────────────────────────

function main(argv) {
  const [, , cmd, ...args] = argv;
  const projectRoot = process.env.STP_PROJECT_ROOT || process.cwd();

  switch (cmd) {
    case 'set':
    case 'set-profile':
    case 'config-set-model-profile': {
      // Filter out --raw and other flags
      const positional = args.filter((a) => !a.startsWith('--'));
      const target = positional[0];
      if (!target) {
        process.stderr.write(`error: missing profile name\nusage: model-profiles.cjs set <intended|balanced|budget>\nvalid: ${VALID_PROFILES.join(', ')}\n`);
        process.exit(1);
      }
      try {
        const written = writeActiveProfile(target, projectRoot);
        if (args.includes('--raw')) {
          // Match GSD's --raw flag: minimal output for command-context display
          process.stdout.write(formatBanner(written, 'set'));
          process.stdout.write(formatTable(written));
          process.stdout.write(`\n  Saved to: .stp/state/profile.json\n`);
          process.stdout.write(`  Active for: every /stp:* command from now on\n\n`);
        } else {
          process.stdout.write(written + '\n');
        }
      } catch (e) {
        process.stderr.write(`error: ${e.message}\n`);
        process.exit(1);
      }
      break;
    }

    case 'current':
    case 'get': {
      const active = readActiveProfile(projectRoot);
      process.stdout.write(active + '\n');
      break;
    }

    case 'resolve': {
      const agent = args[0];
      if (!agent) {
        process.stderr.write(`error: missing agent name\nusage: model-profiles.cjs resolve <agent>\nvalid: ${Object.keys(MODEL_PROFILES).join(', ')}\n`);
        process.exit(1);
      }
      try {
        const profile = readActiveProfile(projectRoot);
        const model = resolveAgentModel(agent, profile);
        process.stdout.write(model + '\n');
      } catch (e) {
        process.stderr.write(`error: ${e.message}\n`);
        process.exit(1);
      }
      break;
    }

    case 'resolve-all': {
      // Print all agent models for the current profile, one per line, KEY=VALUE format
      const profile = readActiveProfile(projectRoot);
      const map = getAgentToModelMap(profile);
      process.stdout.write(`STP_PROFILE=${profile}\n`);
      for (const [agent, model] of Object.entries(map)) {
        // Convert agent name to env var: stp-executor → STP_MODEL_EXECUTOR
        const envName = 'STP_MODEL_' + agent.replace(/^stp-/, '').replace(/-/g, '_').toUpperCase();
        process.stdout.write(`${envName}=${model}\n`);
      }
      const disc = getDiscipline(profile);
      process.stdout.write(`STP_CLEAR_DISCIPLINE=${disc.clear_between_phases}\n`);
      process.stdout.write(`STP_CONTEXT_MODE_LEVEL=${disc.context_mode_required}\n`);
      process.stdout.write(`STP_RESEARCHER_MANDATORY=${disc.researcher_mandatory}\n`);
      process.stdout.write(`STP_EXPLORER_MANDATORY=${disc.explorer_mandatory}\n`);
      process.stdout.write(`STP_MAX_MAIN_KB=${disc.max_main_session_kb === null ? '' : disc.max_main_session_kb}\n`);
      break;
    }

    case 'discipline': {
      const profile = args[0] ? normalizeProfile(args[0]) : readActiveProfile(projectRoot);
      const disc = getDiscipline(profile);
      process.stdout.write(JSON.stringify(disc, null, 2) + '\n');
      break;
    }

    case 'table': {
      const profile = args[0] ? normalizeProfile(args[0]) : readActiveProfile(projectRoot);
      process.stdout.write(formatTable(profile));
      break;
    }

    case 'all-tables': {
      // Print all 3 profile tables for comparison
      for (const p of VALID_PROFILES) {
        process.stdout.write(formatTable(p));
      }
      break;
    }

    case 'list':
    case 'profiles': {
      process.stdout.write(VALID_PROFILES.join('\n') + '\n');
      break;
    }

    case 'help':
    case '--help':
    case '-h':
    case undefined: {
      process.stdout.write(`STP Model Profiles — single source of truth for sub-agent model allocation

USAGE:
  node model-profiles.cjs <command> [args]

COMMANDS:
  set <profile>         Set the active profile (writes .stp/state/profile.json)
                        Aliases: set-profile, config-set-model-profile
                        Flag: --raw  (verbose human-readable output)

  current               Print the currently active profile name
                        Alias: get

  resolve <agent>       Print the resolved model for the given agent under
                        the active profile (e.g. "sonnet", "haiku", "inherit")

  resolve-all           Print all agent → model mappings as KEY=VALUE lines
                        suitable for shell sourcing or eval

  discipline [profile]  Print discipline rules for a profile (default: active)

  table [profile]       Print the agent → model table for a profile (default: active)

  all-tables            Print all 3 profile tables side by side

  list                  Print valid profile names, one per line

  help                  Show this help

PROFILES:
  ${VALID_PROFILES.join('\n  ')}

SENTINELS:
  inherit  → omit the model param from Agent() spawn; use parent session model
  inline   → do NOT spawn a sub-agent; main session handles this work directly

EXAMPLES:
  node model-profiles.cjs set balanced --raw
  node model-profiles.cjs current
  node model-profiles.cjs resolve stp-executor
  node model-profiles.cjs resolve-all
  node model-profiles.cjs table budget-profile
`);
      break;
    }

    default: {
      process.stderr.write(`error: unknown command "${cmd}"\nrun: node model-profiles.cjs help\n`);
      process.exit(1);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Module exports + CLI dispatch
// ─────────────────────────────────────────────────────────────────────────

module.exports = {
  MODEL_PROFILES,
  PROFILE_DISCIPLINE,
  VALID_PROFILES,
  DEFAULT_PROFILE,
  getAgentToModelMap,
  resolveAgentModel,
  getDiscipline,
  normalizeProfile,
  readActiveProfile,
  writeActiveProfile,
  formatTable,
  formatBanner,
};

if (require.main === module) {
  main(process.argv);
}
