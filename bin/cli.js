#!/usr/bin/env node
'use strict';

const pkg = require('../package.json');

const c = {
  cyan:   (s) => `\x1b[36m${s}\x1b[0m`,
  green:  (s) => `\x1b[32m${s}\x1b[0m`,
  yellow: (s) => `\x1b[33m${s}\x1b[0m`,
  bold:   (s) => `\x1b[1m${s}\x1b[0m`,
  dim:    (s) => `\x1b[2m${s}\x1b[0m`,
};

if (process.argv.includes('--version') || process.argv.includes('-v')) {
  console.log(pkg.version);
  process.exit(0);
}

console.log('');
console.log(c.cyan('╔═══════════════════════════════════════════════════════╗'));
console.log(c.cyan('║') + c.bold('  STP — Straight To Production                        ') + c.cyan('║'));
console.log(c.cyan('║') + c.dim(`  v${pkg.version}`) + ' '.repeat(50 - pkg.version.length) + c.cyan('║'));
console.log(c.cyan('╠═══════════════════════════════════════════════════════╣'));
console.log(c.cyan('║') + '                                                       ' + c.cyan('║'));
console.log(c.cyan('║') + c.yellow('  ⚠  npx stp-cc is deprecated.                        ') + c.cyan('║'));
console.log(c.cyan('║') + '                                                       ' + c.cyan('║'));
console.log(c.cyan('║') + '  STP installs through Claude Code\'s plugin system.    ' + c.cyan('║'));
console.log(c.cyan('║') + '  Open Claude Code and run these two commands:         ' + c.cyan('║'));
console.log(c.cyan('║') + '                                                       ' + c.cyan('║'));
console.log(c.cyan('║') + c.green('  /plugin marketplace add DIV7NE/straight-to-production') + c.cyan('║'));
console.log(c.cyan('║') + c.green('  /plugin install stp@stp                              ') + c.cyan('║'));
console.log(c.cyan('║') + '                                                       ' + c.cyan('║'));
console.log(c.cyan('║') + '  That\'s it. Skills show as /stp:setup, /stp:think,    ' + c.cyan('║'));
console.log(c.cyan('║') + '  /stp:build, etc. Updates: re-run /plugin install     ' + c.cyan('║'));
console.log(c.cyan('║') + '                                                       ' + c.cyan('║'));
console.log(c.cyan('╚═══════════════════════════════════════════════════════╝'));
console.log('');
