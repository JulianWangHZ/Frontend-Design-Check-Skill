#!/usr/bin/env bash
set -euo pipefail

node -e '
  const fs = require("fs");
  const read = (f) => JSON.parse(fs.readFileSync(f, "utf8"));
  const plugin = read(".claude-plugin/plugin.json");
  const pkg = read("package.json");
  const manifest = read(".release-please-manifest.json");
  read(".claude-plugin/marketplace.json");
  const versions = { "plugin.json": plugin.version, "package.json": pkg.version, "manifest": manifest["."] };
  if (new Set(Object.values(versions)).size !== 1) {
    console.error("version mismatch:", versions);
    process.exit(1);
  }
'

f=skills/frontend-design-check/SKILL.md
head -1 "$f" | grep -qx -- '---'
grep -q '^name: frontend-design-check$' "$f"
grep -q '^description: ' "$f"
