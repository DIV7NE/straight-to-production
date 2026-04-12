'use strict';

const fs = require('fs');
const { PLUGIN_DIR, readManifest, deregisterStatusline } = require('./install');

const c = {
  cyan:   (s) => `\x1b[36m${s}\x1b[0m`,
  green:  (s) => `\x1b[32m${s}\x1b[0m`,
  red:    (s) => `\x1b[31m${s}\x1b[0m`,
  bold:   (s) => `\x1b[1m${s}\x1b[0m`,
  dim:    (s) => `\x1b[2m${s}\x1b[0m`,
};

function run() {
  console.log('');

  const manifest = readManifest(PLUGIN_DIR);

  if (!manifest) {
    console.log(c.red('  \u2717 STP is not installed (no manifest found at ' + PLUGIN_DIR + ')'));
    console.log('');
    process.exit(0);
  }

  const version = manifest.version || 'unknown';
  const fileCount = manifest.file_count || Object.keys(manifest.files || {}).length;

  // Remove plugin directory
  try {
    fs.rmSync(PLUGIN_DIR, { recursive: true, force: true });
  } catch (err) {
    console.log(c.red(`  \u2717 Failed to remove ${PLUGIN_DIR}: ${err.message}`));
    console.log('    Try manually: rm -rf "' + PLUGIN_DIR + '"');
    process.exit(1);
  }

  // Deregister statusline from settings.json
  deregisterStatusline();

  // Report
  console.log(c.cyan('\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557'));
  console.log(c.cyan('\u2551') + c.green(`  \u2713 STP v${version} uninstalled`) + ' '.repeat(Math.max(0, 23 - version.length)) + c.cyan('\u2551'));
  console.log(c.cyan('\u2560\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2563'));
  console.log(c.cyan('\u2551') + `  Removed ${fileCount} files from:` + ' '.repeat(Math.max(0, 14 - String(fileCount).length)) + c.cyan('\u2551'));
  console.log(c.cyan('\u2551') + c.dim(`  ${PLUGIN_DIR}`.slice(0, 43).padEnd(43)) + c.cyan('\u2551'));
  console.log(c.cyan('\u2551') + '  Statusline deregistered                  ' + c.cyan('\u2551'));
  console.log(c.cyan('\u2551') + '                                           ' + c.cyan('\u2551'));
  console.log(c.cyan('\u2551') + '  Restart Claude Code to complete removal. ' + c.cyan('\u2551'));
  console.log(c.cyan('\u255A\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255D'));
  console.log('');
}

module.exports = { run };
