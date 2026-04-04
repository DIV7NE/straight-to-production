#!/usr/bin/env node
// STP Statusline
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
    const effort = data.effort_level || null;

    const parts = [];

    // Model (dim) + effort level
    const effortColors = { low: '\x1b[2m', medium: '\x1b[33m', high: '\x1b[32m', max: '\x1b[35m' };
    const effortTag = effort ? ` ${effortColors[effort] || '\x1b[2m'}${effort}\x1b[0m` : '';
    parts.push(`\x1b[2m${model}\x1b[0m${effortTag}`);

    // Version (blue)
    try {
      const ver = fs.readFileSync('VERSION', 'utf8').trim();
      parts.push(`\x1b[34mv${ver}\x1b[0m`);
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

      parts.push(`${fillColor}${bar}\x1b[0m ${label}`);
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
