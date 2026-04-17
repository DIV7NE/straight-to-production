#!/usr/bin/env node
// STP Statusline
// Shows: [upgrade pulse] | model | active feature [progress] | milestone | context bar
// Upgrade check is done once at session start (by check-upgrade.sh), cached to disk.
// This script only reads the cache — zero network calls, zero git calls.

const fs = require('fs');
const path = require('path');

let input = '';
const stdinTimeout = setTimeout(() => {
  // Fallback — always output something so the statusline isn't blank
  process.stdout.write('\x1b[34mSTP\x1b[0m');
  process.exit(0);
}, 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('error', () => {
  clearTimeout(stdinTimeout);
  process.stdout.write('\x1b[34mSTP\x1b[0m');
});
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const model = data.model?.display_name || 'Claude';
    const dir = path.basename(data.workspace?.current_dir || process.cwd());
    const remaining = data.context_window?.remaining_percentage;
    const effort = data.effort_level || null;

    const parts = [];

    // Upgrade indicator (pulsating magenta, far left) — reads cache only, no git/network
    try {
      const pluginDir = process.env.CLAUDE_PLUGIN_ROOT || path.resolve(__dirname, '../..');
      const cache = JSON.parse(fs.readFileSync(path.join(pluginDir, '.stp-upgrade-cache.json'), 'utf8'));
      if (cache.behind) {
        const ver = cache.remote_ver ? `v${cache.remote_ver}` : 'update';
        const count = cache.behind_count ? ` (${cache.behind_count} commits)` : '';
        parts.push(`\x1b[5;35m↑ ${ver}${count}\x1b[0m`);
      }
    } catch (e) {} // no cache = no indicator

    // Model (dim) + effort level.
    // Opus 4.7 uses `xhigh` as the default alongside legacy `max`.
    const effortColors = {
      low: '\x1b[2m',
      medium: '\x1b[33m',
      high: '\x1b[32m',
      xhigh: '\x1b[35m',
      max: '\x1b[1;35m', // only used for genuinely novel architectural work
    };
    const effortTag = effort ? ` ${effortColors[effort] || '\x1b[2m'}${effort}\x1b[0m` : '';
    parts.push(`\x1b[2m${model}\x1b[0m${effortTag}`);

    // Version (blue)
    try {
      const ver = fs.readFileSync('VERSION', 'utf8').trim();
      parts.push(`\x1b[34mv${ver}\x1b[0m`);
    } catch (e) {}

    // Active profile tag (silent for the default balanced profile; color-coded otherwise)
    //   balanced     → no tag (default, no clutter)
    //   opus-cto     → cyan (1M context, max power)
    //   sonnet-turbo → green (Sonnet 4.6 @ xhigh)
    //   opus-budget  → orange (haiku critic)
    //   sonnet-cheap → magenta (Sonnet 200K primary)
    //   pro-plan     → red (no sub-agents, tight budget)
    //   legacy names (intended-profile / budget-profile / sonnet-main) also tolerated
    try {
      const profileRaw = fs.readFileSync('.stp/state/profile.json', 'utf8');
      const profileData = JSON.parse(profileRaw);
      const profile = profileData.profile || 'balanced';
      const PROFILE_TAGS = {
        'opus-cto': '\x1b[36mopus-cto\x1b[0m',
        'intended-profile': '\x1b[36mopus-cto\x1b[0m',      // legacy alias
        'sonnet-turbo': '\x1b[32msonnet-turbo\x1b[0m',
        'opus-budget': '\x1b[38;5;208mopus-budget\x1b[0m',
        'budget-profile': '\x1b[38;5;208mopus-budget\x1b[0m', // legacy alias
        'sonnet-cheap': '\x1b[35msonnet-cheap\x1b[0m',
        'sonnet-main': '\x1b[35msonnet-cheap\x1b[0m',         // legacy alias
        'pro-plan': '\x1b[31mpro-plan\x1b[0m',
        '20-pro-plan': '\x1b[31mpro-plan\x1b[0m',             // legacy alias
      };
      if (PROFILE_TAGS[profile]) parts.push(PROFILE_TAGS[profile]);
      // 'balanced' / 'balanced-profile' → no tag (default)
    } catch (e) {} // no profile.json = balanced, no tag

    // Pace tag (only show if not the default 'batched')
    //   batched    → no tag
    //   deep       → cyan (curiosity mode, section-by-section)
    //   fast       → yellow (single-approval run-through)
    //   autonomous → red (unattended — warn user it's on)
    try {
      const paceRaw = fs.readFileSync('.stp/state/pace.json', 'utf8');
      const pace = (JSON.parse(paceRaw).pace || 'batched');
      const PACE_TAGS = {
        'deep': '\x1b[36m◆deep\x1b[0m',
        'fast': '\x1b[33m▸fast\x1b[0m',
        'autonomous': '\x1b[31m●auto\x1b[0m',
      };
      if (PACE_TAGS[pace]) parts.push(PACE_TAGS[pace]);
    } catch (e) {}

    // Stack tag (only show if non-generic + detected)
    try {
      const stackRaw = fs.readFileSync('.stp/state/stack.json', 'utf8');
      const stack = (JSON.parse(stackRaw).stack || 'generic');
      if (stack && stack !== 'generic') {
        parts.push(`\x1b[2m${stack}\x1b[0m`);
      }
    } catch (e) {}

    // Active feature + progress OR plan progress
    const featureFile = '.stp/state/current-feature.md';
    const planFile = '.stp/docs/PLAN.md';

    if (fs.existsSync(featureFile)) {
      try {
        const content = fs.readFileSync(featureFile, 'utf8');
        const title = content.split('\n')[0].replace(/^#*\s*/, '').slice(0, 25);
        const done = (content.match(/\[x\]/g) || []).length;
        const total = (content.match(/\[.\]/g) || []).length;

        // Progress color
        let pColor;
        if (total > 0 && done >= total / 2) pColor = '\x1b[32m'; // green
        else if (done > 0) pColor = '\x1b[33m'; // yellow
        else pColor = '\x1b[2m'; // dim

        parts.push(`\x1b[1m${title}\x1b[0m ${pColor}[${done}/${total}]\x1b[0m`);
      } catch (e) {}
    } else if (fs.existsSync(planFile)) {
      try {
        const content = fs.readFileSync(planFile, 'utf8');
        const done = (content.match(/\[x\]/g) || []).length;
        const total = (content.match(/\[.\]/g) || []).length;
        if (total > 0) {
          parts.push(`\x1b[2mPlan \x1b[32m${done}\x1b[2m/${total}\x1b[0m`);
        }
      } catch (e) {}
    }

    // Current milestone (cyan)
    if (fs.existsSync(planFile)) {
      try {
        const content = fs.readFileSync(planFile, 'utf8');
        const lines = content.split('\n');
        for (let i = 0; i < lines.length; i++) {
          if (lines[i].includes('[ ]')) {
            // Walk backwards to find milestone heading
            for (let j = i; j >= 0; j--) {
              if (lines[j].startsWith('### Milestone')) {
                const name = lines[j].replace(/^### Milestone \d+:\s*/, '').slice(0, 20);
                parts.push(`\x1b[36m${name}\x1b[0m`);
                i = lines.length; // break outer
                break;
              }
            }
          }
        }
      } catch (e) {}
    }

    // Context bar — shows FULL window with compaction threshold marker
    if (remaining != null) {
      const used = Math.max(0, Math.min(100, Math.round(100 - remaining)));
      const compactAt = 83; // ~83% is where auto-compact fires (100% - 16.5% buffer)

      // Bar: 20 chars = 100% of window. Compaction threshold marked with │
      const BAR_WIDTH = 20;
      const filledPos = Math.round(used * BAR_WIDTH / 100);
      const compactPos = Math.round(compactAt * BAR_WIDTH / 100);

      // Color: green < 50%, yellow < 65%, orange < compact, red/blink past compact
      let fillColor;
      if (used < 50) fillColor = '\x1b[32m';       // green
      else if (used < 65) fillColor = '\x1b[33m';   // yellow
      else if (used < compactAt) fillColor = '\x1b[38;5;208m'; // orange
      else fillColor = '\x1b[5;31m';                 // blinking red

      let bar = '';
      for (let i = 0; i < BAR_WIDTH; i++) {
        if (i === compactPos) {
          bar += `\x1b[0m\x1b[2m│\x1b[0m${fillColor}`; // dim threshold marker
        } else if (i < filledPos) {
          bar += '█';
        } else {
          bar += '\x1b[2m░\x1b[0m' + fillColor;
        }
      }

      // Show usage as fraction of the effective limit
      // If compaction is enabled (compactAt < 100), show X% of compaction threshold used
      // If compaction is disabled, show X% of full context used
      const effectiveLimit = compactAt < 100 ? compactAt : 100;
      const usedOfLimit = Math.min(100, Math.round(used * 100 / effectiveLimit));

      let label;
      if (used >= compactAt && compactAt < 100) {
        label = `\x1b[31m${usedOfLimit}% used ⚠ compact\x1b[0m`;
      } else {
        label = `${usedOfLimit}% used`;
      }

      // Context-threshold nudges — mirrors the 0-40 / 40-70 / 70-90 / 90%+ table in
      // references/session-management.md. Appended to the bar label so Claude sees it
      // on every tool call without the user having to prompt.
      //   0-40%  → silent
      //   40-70% → gentle cyan tip (optional compaction)
      //   70-90% → yellow warning (pause now)
      //   90%+   → red blinking (autocompact imminent)
      let nudge = '';
      if (used >= 90) {
        nudge = ' \x1b[5;31m⚠ /stp:session pause NOW\x1b[0m';
      } else if (used >= 70) {
        nudge = ' \x1b[33m→ /stp:session pause\x1b[0m';
      } else if (used >= 40) {
        nudge = ' \x1b[36m→ /compact if tool-heavy\x1b[0m';
      }

      parts.push(`${fillColor}${bar}\x1b[0m ${label}${nudge}`);
    }

    // Fallback: just show directory if nothing else
    if (parts.length <= 1) {
      parts.push(`\x1b[2m${dir}\x1b[0m`);
    }

    process.stdout.write(parts.join(' \x1b[2m│\x1b[0m '));
  } catch (e) {
    process.stdout.write('\x1b[34mSTP\x1b[0m');
  }
});
