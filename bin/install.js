'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// ── ANSI colors ──────────────────────────────────────────────────────────────

const c = {
  cyan:   (s) => `\x1b[36m${s}\x1b[0m`,
  green:  (s) => `\x1b[32m${s}\x1b[0m`,
  yellow: (s) => `\x1b[33m${s}\x1b[0m`,
  red:    (s) => `\x1b[31m${s}\x1b[0m`,
  bold:   (s) => `\x1b[1m${s}\x1b[0m`,
  dim:    (s) => `\x1b[2m${s}\x1b[0m`,
};

// ── Constants ────────────────────────────────────────────────────────────────

const PKG = require('../package.json');
const SRC_DIR = path.resolve(__dirname, '..');
const HOME = process.env.HOME || process.env.USERPROFILE;
const CLAUDE_DIR = path.join(HOME, '.claude');
const PLUGIN_DIR = path.join(CLAUDE_DIR, 'plugins', 'stp');
const MANIFEST_NAME = '.install-manifest.json';
const BACKUP_ROOT = path.join(HOME, '.stp-local-patches');

// Items to copy from the npm package into the plugin directory.
// Order doesn't matter — each is copied recursively.
const COPY_ITEMS = [
  'skills',
  'agents',
  'hooks',
  'references',
  'templates',
  'whiteboard',
  'assets',
  '.claude-plugin',
  '.claude',       // contains skills/ui-ux-pro-max
  'CLAUDE.md',
  'README.md',
  'CHANGELOG.md',
];

// ── Helpers ──────────────────────────────────────────────────────────────────

function sha256(filePath) {
  return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex');
}

/** Recursively list all files under `dir`, returning paths relative to `base`. */
function walkDir(dir, base) {
  base = base || dir;
  const results = [];
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return results; }
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === '.git' || entry.name === 'node_modules') continue;
      results.push(...walkDir(full, base));
    } else {
      results.push(path.relative(base, full));
    }
  }
  return results;
}

/** Copy a file or directory recursively. */
function copyRecursive(src, dest) {
  const stat = fs.statSync(src);
  if (stat.isDirectory()) {
    fs.mkdirSync(dest, { recursive: true });
    for (const entry of fs.readdirSync(src)) {
      copyRecursive(path.join(src, entry), path.join(dest, entry));
    }
  } else {
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.copyFileSync(src, dest);
  }
}

// ── Manifest ─────────────────────────────────────────────────────────────────

function readManifest(dir) {
  const p = path.join(dir, MANIFEST_NAME);
  if (!fs.existsSync(p)) return null;
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return null; }
}

/** Build a SHA-256 manifest of every file under `dir`. */
function buildFileHashes(dir) {
  const hashes = {};
  for (const rel of walkDir(dir)) {
    if (rel === MANIFEST_NAME) continue;
    try { hashes[rel] = sha256(path.join(dir, rel)); } catch { /* skip unreadable */ }
  }
  return hashes;
}

function writeManifest(dir, version) {
  const files = buildFileHashes(dir);
  const manifest = {
    version,
    installed_at: new Date().toISOString(),
    install_type: 'npm',
    package: 'stp-cc',
    file_count: Object.keys(files).length,
    files,
  };
  fs.writeFileSync(path.join(dir, MANIFEST_NAME), JSON.stringify(manifest, null, 2));
  return manifest;
}

// ── Upgrade helpers ──────────────────────────────────────────────────────────

/** Compare installed files against manifest to find user modifications. */
function detectModifiedFiles(dir, manifest) {
  if (!manifest || !manifest.files) return [];
  const modified = [];
  for (const [rel, oldHash] of Object.entries(manifest.files)) {
    const full = path.join(dir, rel);
    if (!fs.existsSync(full)) continue;
    try {
      if (sha256(full) !== oldHash) modified.push(rel);
    } catch { /* skip */ }
  }
  return modified;
}

/** Back up user-modified files before overwriting. Returns backup dir path. */
function backupModifiedFiles(dir, modifiedFiles, oldVersion) {
  if (modifiedFiles.length === 0) return null;

  const ts = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const backupDir = path.join(BACKUP_ROOT, `v${oldVersion}_${ts}`);
  fs.mkdirSync(backupDir, { recursive: true });

  for (const rel of modifiedFiles) {
    const src = path.join(dir, rel);
    const dest = path.join(backupDir, rel);
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.copyFileSync(src, dest);
  }

  fs.writeFileSync(path.join(backupDir, 'backup-meta.json'), JSON.stringify({
    from_version: oldVersion,
    to_version: PKG.version,
    backed_up_at: new Date().toISOString(),
    files: modifiedFiles,
  }, null, 2));

  return backupDir;
}

// ── Statusline ───────────────────────────────────────────────────────────────

function registerStatusline(pluginDir) {
  const settingsPath = path.join(CLAUDE_DIR, 'settings.json');
  let settings = {};

  if (fs.existsSync(settingsPath)) {
    try { settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8')); } catch { /* start fresh */ }
  }

  const scriptPath = path.join(pluginDir, 'hooks', 'scripts', 'stp-statusline.js');
  settings.statusLine = {
    type: 'command',
    command: `node "${scriptPath}"`,
  };

  fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
}

function deregisterStatusline() {
  const settingsPath = path.join(CLAUDE_DIR, 'settings.json');
  if (!fs.existsSync(settingsPath)) return;
  try {
    const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
    if (settings.statusLine && typeof settings.statusLine.command === 'string'
        && settings.statusLine.command.includes('stp-statusline')) {
      delete settings.statusLine;
      fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
    }
  } catch { /* skip */ }
}

// ── Hook permissions ─────────────────────────────────────────────────────────

function makeHooksExecutable(dir) {
  const scriptsDir = path.join(dir, 'hooks', 'scripts');
  if (!fs.existsSync(scriptsDir)) return;
  for (const name of fs.readdirSync(scriptsDir)) {
    if (name.endsWith('.sh')) {
      try { fs.chmodSync(path.join(scriptsDir, name), 0o755); } catch { /* skip */ }
    }
  }
}

// ── Main install ─────────────────────────────────────────────────────────────

function run() {
  console.log('');
  console.log(c.cyan('\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557'));
  console.log(c.cyan('\u2551') + c.bold('  STP \u2014 Straight To Production             ') + c.cyan('\u2551'));
  console.log(c.cyan('\u2551') + c.dim(`  v${PKG.version}`) + ' '.repeat(39 - PKG.version.length) + c.cyan('\u2551'));
  console.log(c.cyan('\u255A\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255D'));
  console.log('');

  // ── Pre-flight checks ──────────────────────────────────────────────────

  if (!fs.existsSync(CLAUDE_DIR)) {
    console.log(c.red('  \u2717 Claude Code config not found at ' + CLAUDE_DIR));
    console.log('    Install Claude Code first: https://docs.anthropic.com/en/docs/claude-code');
    process.exit(1);
  }

  // ── Detect existing install ────────────────────────────────────────────

  const oldManifest = readManifest(PLUGIN_DIR);
  const isUpgrade = oldManifest !== null;
  let backupPath = null;

  if (isUpgrade) {
    const oldVer = oldManifest.version || 'unknown';

    if (oldVer === PKG.version) {
      console.log(c.green(`  \u2713 STP v${PKG.version} is already installed and up to date.`));
      console.log('');
      process.exit(0);
    }

    console.log(c.yellow(`  \u25BA Upgrading: v${oldVer} \u2192 v${PKG.version}`));
    console.log('');

    // Detect & back up user-modified files
    const modified = detectModifiedFiles(PLUGIN_DIR, oldManifest);
    if (modified.length > 0) {
      backupPath = backupModifiedFiles(PLUGIN_DIR, modified, oldVer);
      console.log(c.yellow(`  \u26A0 ${modified.length} locally modified file(s) backed up:`));
      console.log(c.dim(`    ${backupPath}`));
      for (const f of modified.slice(0, 8)) {
        console.log(c.dim(`    \u2022 ${f}`));
      }
      if (modified.length > 8) {
        console.log(c.dim(`    \u2026 and ${modified.length - 8} more`));
      }
      console.log('');
    }
  } else {
    console.log('  \u25BA Installing STP...');
    console.log('');
  }

  // ── Copy plugin files ──────────────────────────────────────────────────

  fs.mkdirSync(PLUGIN_DIR, { recursive: true });

  let fileCount = 0;
  for (const item of COPY_ITEMS) {
    const src = path.join(SRC_DIR, item);
    if (!fs.existsSync(src)) continue;

    const dest = path.join(PLUGIN_DIR, item);

    if (fs.statSync(src).isDirectory()) {
      copyRecursive(src, dest);
      fileCount += walkDir(src).length;
    } else {
      fs.mkdirSync(path.dirname(dest), { recursive: true });
      fs.copyFileSync(src, dest);
      fileCount++;
    }
  }

  // ── Post-copy setup ────────────────────────────────────────────────────

  makeHooksExecutable(PLUGIN_DIR);
  registerStatusline(PLUGIN_DIR);
  const manifest = writeManifest(PLUGIN_DIR, PKG.version);

  // ── Report ─────────────────────────────────────────────────────────────

  console.log(c.green('  \u2713 Plugin files installed') + c.dim(` (${fileCount} files)`));
  console.log(c.green('  \u2713 Hook scripts executable'));
  console.log(c.green('  \u2713 Statusline registered'));
  console.log(c.green('  \u2713 Install manifest written') + c.dim(` (${manifest.file_count} tracked)`));

  if (backupPath) {
    console.log(c.yellow('  \u26A0 Local patches saved') + c.dim(` (${backupPath})`));
  }

  console.log('');

  if (!isUpgrade) {
    // ── Environment check ──────────────────────────────────────────────
    const { execFileSync } = require('child_process');

    console.log(c.cyan('  \u2500\u2500 Environment \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500'));
    console.log('');
    console.log(c.green('  \u2713 ') + 'Node.js ' + process.version);

    try {
      const pyVer = execFileSync('python3', ['--version'], { encoding: 'utf8', timeout: 3000 }).trim();
      console.log(c.green('  \u2713 ') + pyVer);
    } catch {
      console.log(c.yellow('  \u26A0 ') + 'Python 3 not found ' + c.dim('(needed for /stp:whiteboard)'));
    }

    // ── MCP servers ────────────────────────────────────────────────────
    console.log('');
    console.log(c.cyan('  \u2500\u2500 MCP Servers \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500'));
    console.log('');
    console.log('  Run these in your terminal ' + c.dim('(one-time, copy-paste):'));
    console.log('');
    console.log(c.dim('    claude mcp add context7 -- npx -y @upstash/context7-mcp@latest'));
    console.log(c.dim('    claude mcp add tavily -- npx -y tavily-mcp@latest'));
    console.log(c.dim('    /plugin marketplace add mksglu/context-mode'));
    console.log(c.dim('    /plugin install context-mode@context-mode'));
    console.log('');
    console.log('  ' + c.dim('Tavily requires TAVILY_API_KEY \u2014 get one at https://tavily.com'));

    // ── Get started ────────────────────────────────────────────────────
    console.log('');
    console.log(c.cyan('  \u2500\u2500 Get Started \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500'));
    console.log('');
    console.log('  Open Claude Code and run:');
    console.log('');
    console.log(c.bold('    /stp:welcome           ') + c.dim('Guided setup \u2014 checks plugins, picks profile'));
    console.log(c.bold('    /stp:new-project       ') + c.dim('Start building from scratch'));
    console.log(c.bold('    /stp:onboard-existing  ') + c.dim('Onboard an existing codebase'));
  } else {
    console.log(c.cyan('  \u25BA Restart Claude Code to activate new hooks:'));
    console.log('    1. ' + c.bold('/exit') + '  (or Ctrl+D)');
    console.log('    2. ' + c.bold('claude'));
  }

  console.log('');
  console.log(c.dim('  https://github.com/DIV7NE/straight-to-production'));
  console.log('');
}

// ── Exports ──────────────────────────────────────────────────────────────────

module.exports = {
  run,
  PLUGIN_DIR,
  CLAUDE_DIR,
  MANIFEST_NAME,
  readManifest,
  deregisterStatusline,
};
