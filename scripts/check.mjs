#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { root, files, readJSON, validate } from './common.mjs';

export function check(base=root) {
  const c=readJSON(path.join(base,'.template/project.json'));
  validate(c);
  const tree=files(base);
  for(const f of tree) {
    if(f.startsWith('.template/blueprint/') || f.startsWith('scripts/') || f.startsWith('tests/')) continue;
    assert(!/@@[A-Z_]+@@/.test(fs.readFileSync(path.join(base,f),'utf8')),`Unresolved token in ${f}`);
  }
  const read=f=>fs.readFileSync(path.join(base,f),'utf8');
  for(const f of ['README.md','LICENSE','CREDITS.md','AGENTS.md','docs/ACCEPTANCE.json','.github/workflows/ci.yml','.github/workflows/release.yml']) assert(tree.includes(f),`Missing ${f}`);
  const readme=read('README.md');
  assert(readme.includes('<h1 align="center">'),'Centered title required');
  for(const m of readme.matchAll(/\]\(([^)]+)\)/g)) {
    const link=m[1].split('#')[0];
    if(link && !/^[a-z]+:/.test(link)) assert(fs.existsSync(path.join(base,link)),`Broken README link ${link}`);
  }
  for(const f of tree.filter(f=>f.startsWith('.github/workflows/'))) {
    for(const m of read(f).matchAll(/uses:\s+([^\s#]+)/g)) assert(/@[a-f0-9]{40}$/.test(m[1]),`Unpinned action in ${f}`);
    assert(read(f).includes('permissions:'),`Missing explicit permissions ${f}`);
    assert(!read(f).includes('pull_request_target'), 'Untrusted PR execution must not get a privileged workflow');
  }
  // Orb is an initialized plugin; the starter's theme/app/package checks do not apply.
  assert.equal(c.kind,'plugin','Orb must remain a plugin project');
  const m=readJSON(path.join(base,'manifest.json'));
  assert.equal(m.schemaVersion,1);assert.equal(m.id,c.id);
  const kinds={'bar-widget':'barWidget',bar:'bar',panel:'panel',overlay:'overlay',menu:'menu',service:'service'};
  assert(Array.isArray(m.kinds)&&m.kinds.length>0&&new Set(m.kinds).size===m.kinds.length);
  for(const k of m.kinds) assert(kinds[k] && m.entryPoints[kinds[k]],`Missing entry point for ${k}`);
  for(const [k,f] of Object.entries(m.entryPoints)) {
    assert(Object.values(kinds).includes(k));
    assert(typeof f==='string' && /^[A-Za-z0-9_./-]+\.qml$/.test(f) && !f.startsWith('/') && !f.split('/').includes('..'));
    assert(tree.includes(f),`Missing QML ${f}`);
  }
  assert.equal(readJSON(path.join(base,'.omarchy-workbench.json')).schemaVersion,1);
  return c;
}
if(process.argv[1]===new URL(import.meta.url).pathname) {
  try {const c=check();console.log(`PASS: ${c.kind} structure, identity, links and CI policy (${c.initialized?'initialized project':'template starter'}). Native and live checks are separate.`);}
  catch(e){console.error(e.message);process.exitCode=1;}
}
