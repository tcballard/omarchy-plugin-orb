#!/usr/bin/env node
// Record or verify docs/ACCEPTANCE.json runtime_sha256: the files whose exact
// contents an acceptance run tested. Run with --write only after the recorded
// checks pass on this tree; without it, report any stale or missing entries.
import fs from 'node:fs';
import path from 'node:path';
import { root, files, hash, readJSON } from './common.mjs';

export const runtimeFile = f => /^[^/]+\.(qml|js|lua)$/.test(f)
  || ['config.example.json', 'manifest.json'].includes(f)
  || /^(assets|scripts|tests\/qml)\//.test(f);

export function runtimeHashes(base = root) {
  return Object.fromEntries(files(base).filter(runtimeFile).map(f => [f, hash(fs.readFileSync(path.join(base, f)))]));
}

export function staleHashes(recorded, current) {
  const names = new Set([...Object.keys(recorded || {}), ...Object.keys(current)]);
  return [...names].sort().filter(f => recorded?.[f] !== current[f])
    .map(f => `${!(f in current) ? 'removed' : !recorded?.[f] ? 'unrecorded' : 'changed'}: ${f}`);
}

if (process.argv[1] === new URL(import.meta.url).pathname) {
  const file = path.join(root, 'docs/ACCEPTANCE.json');
  const acceptance = readJSON(file), current = runtimeHashes();
  if (process.argv.includes('--write')) {
    acceptance.runtime_sha256 = current;
    fs.writeFileSync(file, JSON.stringify(acceptance, null, 2) + '\n');
    console.log(`Recorded ${Object.keys(current).length} runtime hashes in docs/ACCEPTANCE.json.`);
  } else {
    const stale = staleHashes(acceptance.runtime_sha256, current);
    if (stale.length) {
      console.error(`docs/ACCEPTANCE.json runtime_sha256 does not match this tree:\n  ${stale.join('\n  ')}`);
      console.error('Re-run the recorded checks, then: node scripts/runtime-hashes.mjs --write');
      process.exitCode = 1;
    } else console.log(`PASS: ${Object.keys(current).length} runtime hashes match docs/ACCEPTANCE.json.`);
  }
}
