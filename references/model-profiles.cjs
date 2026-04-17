#!/usr/bin/env node
/**
 * STP Model Profiles — Single Source of Truth (v1.0)
 *
 * Canonical mapping of STP sub-agents to Claude models for each optimization
 * profile. STP commands + hooks call this file as a CLI to:
 *   - Set the active profile        : node model-profiles.cjs set <profile>
 *   - Read the current profile      : node model-profiles.cjs current
 *   - Resolve a model for an agent  : node model-profiles.cjs resolve <agent>
 *   - Print all agent mappings      : node model-profiles.cjs resolve-all
 *   - Print the mapping table       : node model-profiles.cjs table [profile]
 *
 * Active profile stored in `.stp/state/profile.json`.
 *
 * PROFILE SYSTEM (v1.0 — renamed, plus new sonnet-turbo):
 *
 *   opus-cto       — Opus 4.7 [1M ctx] main + Sonnet sub-agents. Loose discipline.
 *                    For solo devs who want maximum power. Most expensive.
 *                    (Renamed from: intended-profile)
 *
 *   balanced       — DEFAULT. Opus 4.7 main plans + Sonnet sub-agents execute.
 *                    Mandatory context discipline. Daily-driver profile.
 *                    (Renamed from: balanced-profile)
 *
 *   sonnet-turbo   — Sonnet 4.6 [200K] main @ xhigh + adaptive thinking.
 *                    All sub-agents = sonnet. NEW in v1.0. For users who don't
 *                    need Opus's planning depth but want quality execution with
 *                    lower cost + faster turnaround.
 *
 *   opus-budget    — Opus 4.7 main + Sonnet executor + Haiku critic (escalates
 *                    to Sonnet). Strict context discipline. Cheaper Opus route.
 *                    (Renamed from: budget-profile)
 *
 *   sonnet-cheap   — Sonnet 4.6 [200K] main + Sonnet executor + Haiku critic/QA
 *                    (Sonnet escalation). Cheapest profile that still uses sub-agents.
 *                    (Renamed from: sonnet-main)
 *
 *   pro-plan       — $20/mo Claude Pro plan. ZERO sub-agents — all work inline.
 *                    Constraint = message count, not tokens. ≤30 msgs/feature,
 *                    deterministic verification only (no AI critic/QA).
 *                    (Renamed from: 20-pro-plan)
 *
 * SENTINELS:
 *   "inherit" — omit the model param from Agent() spawn; use parent session model.
 *               Works correctly in v1.0 because `regenerate-agents.sh` strips the
 *               `model:` line from agents/*.md when the profile resolves to `inherit`.
 *
 *   "inline"  — do NOT spawn a sub-agent; main session handles this work directly.
 *               In v1.0 `regenerate-agents.sh` removes the agent file entirely when
 *               the profile resolves to `inline`, so accidental spawns error out.
 *
 *   "sonnet" / "opus" / "haiku" — pass this exact value as the spawn model parameter.
 */

'use strict';

const fs = require('fs');
const path = require('path');

// ─────────────────────────────────────────────────────────────────────────
// Canonical mapping: per-agent × per-profile → model
// ─────────────────────────────────────────────────────────────────────────

const MODEL_PROFILES = {
  // ┌─────────────────────────┬──────────┬──────────┬──────────────┬─────────────┬──────────────┬──────────┐
  // │ Agent                   │ opus-cto │ balanced │ sonnet-turbo │ opus-budget │ sonnet-cheap │ pro-plan │
  // ├─────────────────────────┼──────────┼──────────┼──────────────┼─────────────┼──────────────┼──────────┤
  'stp-executor':             { 'opus-cto': 'sonnet', 'balanced': 'sonnet', 'sonnet-turbo': 'sonnet', 'opus-budget': 'sonnet', 'sonnet-cheap': 'sonnet', 'pro-plan': 'inline' },
  'stp-qa':                   { 'opus-cto': 'sonnet', 'balanced': 'sonnet', 'sonnet-turbo': 'sonnet', 'opus-budget': 'sonnet', 'sonnet-cheap': 'haiku',  'pro-plan': 'inline' },
  'stp-critic':               { 'opus-cto': 'sonnet', 'balanced': 'sonnet', 'sonnet-turbo': 'sonnet', 'opus-budget': 'haiku',  'sonnet-cheap': 'haiku',  'pro-plan': 'inline' },
  'stp-critic-escalation':    { 'opus-cto': 'sonnet', 'balanced': 'sonnet', 'sonnet-turbo': 'sonnet', 'opus-budget': 'sonnet', 'sonnet-cheap': 'sonnet', 'pro-plan': 'inline' },
  'stp-researcher':           { 'opus-cto': 'inline', 'balanced': 'sonnet', 'sonnet-turbo': 'sonnet', 'opus-budget': 'sonnet', 'sonnet-cheap': 'sonnet', 'pro-plan': 'inline' },
  'stp-explorer':             { 'opus-cto': 'inline', 'balanced': 'sonnet', 'sonnet-turbo': 'sonnet', 'opus-budget': 'sonnet', 'sonnet-cheap': 'sonnet', 'pro-plan': 'inline' },
  // └─────────────────────────┴──────────┴──────────┴──────────────┴─────────────┴──────────────┴──────────┘
};

// Discipline rules (independent of model selection — affects how commands behave)
const PROFILE_DISCIPLINE = {
  'opus-cto': {
    clear_between_phases: 'recommended',
    context_mode_required: 'recommended',
    researcher_mandatory: false,
    explorer_mandatory: false,
    max_main_session_kb: null,
    main_effort: 'xhigh',
    description: 'Opus 4.7 [1M ctx] main + Sonnet sub-agents. Loose discipline — 1M absorbs research inline.',
  },
  'balanced': {
    clear_between_phases: 'mandatory',
    context_mode_required: 'mandatory',
    researcher_mandatory: true,
    explorer_mandatory: true,
    max_main_session_kb: 120,
    main_effort: 'xhigh',
    description: 'DEFAULT. Opus 4.7 plans, Sonnet executes. Mandatory context discipline.',
  },
  'sonnet-turbo': {
    clear_between_phases: 'mandatory',
    context_mode_required: 'mandatory',
    researcher_mandatory: true,
    explorer_mandatory: true,
    max_main_session_kb: 100,
    main_effort: 'xhigh',
    description: 'Sonnet 4.6 [200K] main @ xhigh + adaptive thinking. All sub-agents = sonnet. Fast + cheaper than Opus.',
  },
  'opus-budget': {
    clear_between_phases: 'enforced',
    context_mode_required: 'hard-block',
    researcher_mandatory: true,
    explorer_mandatory: true,
    max_main_session_kb: 100,
    main_effort: 'xhigh',
    description: 'Opus 4.7 main + Sonnet executor + Haiku critic (Sonnet escalation). Hardcore context discipline.',
  },
  'sonnet-cheap': {
    clear_between_phases: 'enforced',
    context_mode_required: 'hard-block',
    researcher_mandatory: true,
    explorer_mandatory: true,
    max_main_session_kb: 80,
    main_effort: 'xhigh',
    description: 'Sonnet 4.6 main + Sonnet executor + Haiku critic/QA (Sonnet escalation). Cheapest profile with sub-agents.',
  },
  'pro-plan': {
    clear_between_phases: 'enforced',
    context_mode_required: 'hard-block',
    researcher_mandatory: false,
    explorer_mandatory: false,
    max_main_session_kb: 60,
    main_effort: 'high',
    max_messages_per_feature: 30,
    max_messages_per_5h: 80,
    no_subagents: true,
    allowed_commands: ['build', 'debug', 'session', 'setup'],
    blocked_commands: ['think', 'review'],
    verification: 'deterministic-only',
    description: '$20/mo Pro plan. ZERO sub-agents — all work inline. ≤30 msgs/feature, deterministic verification only.',
  },
};

// Derive valid profile names from the table
const VALID_PROFILES = Object.keys(MODEL_PROFILES['stp-executor']);
const DEFAULT_PROFILE = 'balanced';

// Legacy profile name aliases (for one-session backward-compat with state files
// written by STP v0.x). migrate-v1.sh rewrites these to canonical names; this map
// is a safety net for any state file migrate-v1 missed.
const LEGACY_ALIASES = {
  'intended-profile': 'opus-cto',
  'balanced-profile': 'balanced',
  'budget-profile':   'opus-budget',
  'sonnet-main':      'sonnet-cheap',
  '20-pro-plan':      'pro-plan',
};

// ─────────────────────────────────────────────────────────────────────────
// Core resolver functions
// ─────────────────────────────────────────────────────────────────────────

function getAgentToModelMap(profile) {
  const normalized = normalizeProfile(profile);
  const map = {};
  for (const [agent, profileMap] of Object.entries(MODEL_PROFILES)) {
    map[agent] = profileMap[normalized];
  }
  return map;
}

function resolveAgentModel(agent, profile) {
  const normalized = normalizeProfile(profile);
  if (!MODEL_PROFILES[agent]) {
    throw new Error(`Unknown agent: ${agent}. Valid: ${Object.keys(MODEL_PROFILES).join(', ')}`);
  }
  return MODEL_PROFILES[agent][normalized];
}

function getDiscipline(profile) {
  const normalized = normalizeProfile(profile);
  return PROFILE_DISCIPLINE[normalized];
}

function normalizeProfile(profile) {
  if (!profile || typeof profile !== 'string') return DEFAULT_PROFILE;
  const trimmed = profile.trim().toLowerCase();

  // Direct match
  if (VALID_PROFILES.includes(trimmed)) return trimmed;

  // Legacy alias (pre-v1.0 state files)
  if (LEGACY_ALIASES[trimmed]) return LEGACY_ALIASES[trimmed];

  // Try adding -profile suffix (for people who type "balanced" expecting "balanced-profile")
  // — but v1.0 removed suffixes, so this path only matches legacy aliases above.
  throw new Error(`Unknown profile: "${profile}". Valid: ${VALID_PROFILES.join(', ')}`);
}

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

function writeActiveProfile(profile, projectRoot) {
  const root = projectRoot || process.cwd();
  const stateDir = path.join(root, '.stp', 'state');
  const profileFile = path.join(stateDir, 'profile.json');
  const normalized = normalizeProfile(profile);

  fs.mkdirSync(stateDir, { recursive: true });

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
    set_by: 'stp:setup model',
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
  out += `    Main effort level     : ${disc.main_effort}\n`;
  out += `    Max main session KB   : ${disc.max_main_session_kb === null ? 'unlimited' : disc.max_main_session_kb}\n`;
  if (disc.no_subagents) {
    out += `    Sub-agents            : DISABLED (all work inline)\n`;
    out += `    Max msgs/feature      : ${disc.max_messages_per_feature}\n`;
    out += `    Max msgs/5h window    : ${disc.max_messages_per_5h}\n`;
    out += `    Verification          : ${disc.verification}\n`;
    out += `    Allowed commands      : ${disc.allowed_commands.join(', ')}\n`;
    out += `    Blocked commands      : ${disc.blocked_commands.join(', ')}\n`;
  }
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
      const positional = args.filter((a) => !a.startsWith('--'));
      const target = positional[0];
      if (!target) {
        process.stderr.write(`error: missing profile name\nusage: model-profiles.cjs set <${VALID_PROFILES.join('|')}>\n`);
        process.exit(1);
      }
      try {
        const written = writeActiveProfile(target, projectRoot);
        if (args.includes('--raw')) {
          process.stdout.write(formatBanner(written, 'set'));
          process.stdout.write(formatTable(written));
          process.stdout.write(`\n  Saved to: .stp/state/profile.json\n`);
          process.stdout.write(`  Active for: every /stp:* command from now on\n`);
          process.stdout.write(`  Next step: run 'bash hooks/scripts/regenerate-agents.sh' to update agents/*.md\n\n`);
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
        // stp-executor → STP_MODEL_EXECUTOR; stp-critic-escalation → STP_MODEL_CRITIC_ESCALATION
        const envName = 'STP_MODEL_' + agent.replace(/^stp-/, '').replace(/-/g, '_').toUpperCase();
        process.stdout.write(`${envName}=${model}\n`);
      }
      const disc = getDiscipline(profile);
      process.stdout.write(`STP_CLEAR_DISCIPLINE=${disc.clear_between_phases}\n`);
      process.stdout.write(`STP_CONTEXT_MODE_LEVEL=${disc.context_mode_required}\n`);
      process.stdout.write(`STP_RESEARCHER_MANDATORY=${disc.researcher_mandatory}\n`);
      process.stdout.write(`STP_EXPLORER_MANDATORY=${disc.explorer_mandatory}\n`);
      process.stdout.write(`STP_MAIN_EFFORT=${disc.main_effort}\n`);
      process.stdout.write(`STP_MAX_MAIN_KB=${disc.max_main_session_kb === null ? '' : disc.max_main_session_kb}\n`);
      if (disc.no_subagents) process.stdout.write(`STP_NO_SUBAGENTS=true\n`);
      if (disc.max_messages_per_feature) process.stdout.write(`STP_MAX_MSGS_PER_FEATURE=${disc.max_messages_per_feature}\n`);
      if (disc.max_messages_per_5h) process.stdout.write(`STP_MAX_MSGS_PER_5H=${disc.max_messages_per_5h}\n`);
      if (disc.verification) process.stdout.write(`STP_VERIFICATION=${disc.verification}\n`);
      if (disc.allowed_commands) process.stdout.write(`STP_ALLOWED_COMMANDS=${disc.allowed_commands.join(',')}\n`);
      if (disc.blocked_commands) process.stdout.write(`STP_BLOCKED_COMMANDS=${disc.blocked_commands.join(',')}\n`);
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

  all-tables            Print all profile tables side by side

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
  node model-profiles.cjs table sonnet-turbo
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
  LEGACY_ALIASES,
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
