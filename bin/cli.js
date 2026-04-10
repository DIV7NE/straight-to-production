#!/usr/bin/env node
'use strict';

const args = process.argv.slice(2);

if (args.includes('--version') || args.includes('-v')) {
  console.log(require('../package.json').version);
  process.exit(0);
}

if (args.includes('--help') || args.includes('-h')) {
  const pkg = require('../package.json');
  console.log(`
  stp-cc v${pkg.version} — Straight To Production for Claude Code

  Usage:
    npx stp-cc              Install or upgrade STP
    npx stp-cc --uninstall  Remove STP completely
    npx stp-cc --version    Show version
    npx stp-cc --help       Show this help

  After install, start a Claude Code session and run:
    /stp:new-project         Start a new project
    /stp:onboard-existing    Onboard existing codebase

  More info: https://github.com/DIV7NE/stp
`);
  process.exit(0);
}

if (args.includes('--uninstall') || args.includes('-u')) {
  require('./uninstall').run();
} else {
  require('./install').run();
}
