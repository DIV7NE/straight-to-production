#!/usr/bin/env node
// Pilot Statusline
// Shows: model | active feature [progress] | milestone | context bar

const fs = require('fs');
const path = require('path');

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const model = data.model?.display_name || 'Claude';
    const dir = path.basename(data.workspace?.current_dir || process.cwd());
    const remaining = data.context_window?.remaining_percentage;

    const parts = [];

    // Model (dim)
    parts.push(`\x1b[2m${model}\x1b[0m`);

    // Version (blue)
    try {
      const ver = fs.readFileSync('VERSION', 'utf8').trim();
      parts.push(`\x1b[34mv${ver}\x1b[0m`);
    } catch (e) {}

    // Active feature + progress OR plan progress
    const featureFile = '.pilot/current-feature.md';
    const planFile = 'PLAN.md';

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

    // Context bar (same logic as GSD)
    if (remaining != null) {
      const AUTO_COMPACT_BUFFER_PCT = 16.5;
      const usableRemaining = Math.max(0, ((remaining - AUTO_COMPACT_BUFFER_PCT) / (100 - AUTO_COMPACT_BUFFER_PCT)) * 100);
      const used = Math.max(0, Math.min(100, Math.round(100 - usableRemaining)));

      const filled = Math.floor(used / 10);
      const bar = '█'.repeat(filled) + '░'.repeat(10 - filled);

      let ctx;
      if (used < 50) {
        ctx = `\x1b[32m${bar} ${used}%\x1b[0m`;
      } else if (used < 65) {
        ctx = `\x1b[33m${bar} ${used}%\x1b[0m`;
      } else if (used < 80) {
        ctx = `\x1b[38;5;208m${bar} ${used}%\x1b[0m`;
      } else {
        ctx = `\x1b[5;31m${bar} ${used}%\x1b[0m`;
      }
      parts.push(ctx);
    }

    // Fallback: just show directory if nothing else
    if (parts.length <= 1) {
      parts.push(`\x1b[2m${dir}\x1b[0m`);
    }

    process.stdout.write(parts.join(' \x1b[2m│\x1b[0m '));
  } catch (e) {
    process.stdout.write('\x1b[34mPilot\x1b[0m');
  }
});
