const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const old = ['claude','codex','grok','opencode','pi','omp','ori','agy','copilot','crush','cursor-agent','muse','kimi','hermes','openclaw'];
const added = ['qwen','dsh','mcode','kiro-cli','freebuff','kilo','devin','amp','commandcode'];
const ids = [...old, ...added];
function fixture(t) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'orb agents '));
  t.after(() => fs.rmSync(dir, {recursive:true, force:true}));
  const bin = path.join(dir, 'bin');
  const home = path.join(dir, 'home');
  fs.mkdirSync(bin); fs.mkdirSync(home);
  for (const tool of ['dirname','readlink','grep','jq']) {
    const found = spawnSync('/bin/bash', ['-c', 'command -v "$1"', 'bash', tool], {encoding:'utf8'}).stdout.trim();
    fs.symlinkSync(found, path.join(bin, tool));
  }
  const env = {PATH:bin, HOME:home, LOG:path.join(dir,'launch'), INVENTORY:path.join(dir,'inventory'), MISE_LOG:path.join(dir,'mise-log')};
  const write = (file, body) => {fs.mkdirSync(path.dirname(file), {recursive:true}); fs.writeFileSync(file, '#!/bin/bash\n'+body+'\n', {mode:0o755}); return file;};
  const executable = (id, base=bin) => write(path.join(base,id), 'printf "%s\\0" "$0" "$PWD" "$@" > "$LOG"');
  const run = (script, args=[]) => spawnSync(path.join(root,'scripts',script), args, {env, cwd:home, encoding:'utf8'});
  const menu = () => {const r=run('agents'); assert.equal(r.status,0,r.stderr); return JSON.parse(r.stdout);};
  const inventory = entries => {
    fs.writeFileSync(env.INVENTORY, JSON.stringify(entries));
    write(path.join(bin,'mise'), '[[ "$*" == "ls --installed --json" && "$MISE_OFFLINE" == 1 ]] || exit 90\nprintf "%s\\n" "$*" >> "$MISE_LOG"\nwhile IFS= read -r line || [[ -n $line ]]; do printf "%s\\n" "$line"; done < "$INVENTORY"');
  };
  return {dir,bin,home,env,write,executable,run,menu,inventory};
}
test('missing agents remain absent without mise (older installations)', t => {
  const f=fixture(t); assert.deepEqual(f.menu(),[]);
  for (const id of ids) assert.equal(f.run('agents',['--resolve',id]).status,1);
});
test('all existing and new agents are discovered without executing them', t => {
  const f=fixture(t); ids.forEach(id=>f.executable(id));
  const rows=f.menu(); assert.equal(rows.length,ids.length);
  assert.deepEqual(rows.map(r=>r.command.at(-1)),ids);
  for (const row of rows) assert.deepEqual(row.command.slice(0,-1),['omarchy','launch','tui','--app-id=org.omarchy.agent',path.join(root,'scripts/agent')]);
  assert.equal(fs.existsSync(f.env.LOG),false);
});
test('new agents resolve both mise layouts and off-PATH user installs', t => {
  const f=fixture(t); const entries={};
  added.forEach((id,i)=>{
    const base=path.join(f.dir,'mise installs',id);
    entries[id]=[{active:true,install_path:base}];
    f.executable(id,i%2 ? base : path.join(base,'bin'));
  });
  f.inventory(entries);
  assert.deepEqual(f.menu().map(r=>r.command.at(-1)),added);
  for (const id of added) {
    const user=f.executable(id,path.join(f.home,'.local/bin'));
    assert.equal(f.run('agents',['--resolve',id]).stdout.trim(),user);
  }
  assert.equal(fs.existsSync(f.env.LOG),false);
});
test('installer wrappers, shim aliases and non-executables are excluded everywhere', t => {
  const f=fixture(t);
  const bodies=['mise use -g tool','mise x tool -- tool','mise exec tool -- tool','mise install tool','omarchy-install-tool --now'];
  const entries={};
  added.forEach((id,i)=>{
    f.write(path.join(f.bin,id),bodies[i%bodies.length]);
    const base=path.join(f.dir,'install',id);
    entries[id]=[{install_path:base}];
    f.write(path.join(base,'bin',id),bodies[(i+1)%bodies.length]);
    f.write(path.join(f.home,'.local/bin',id),bodies[(i+2)%bodies.length]);
  });
  f.inventory(entries); assert.deepEqual(f.menu(),[]);
  const shim=f.executable('real',path.join(f.dir,'mise/shims'));
  fs.rmSync(path.join(f.bin,'amp')); fs.symlinkSync(shim,path.join(f.bin,'amp'));
  const noexec=f.executable('qwen'); fs.chmodSync(noexec,0o644);
  assert.deepEqual(f.menu(),[]); assert.equal(fs.existsSync(f.env.LOG),false);
});
test('active mise installation wins and user symlinks to real binaries work', t => {
  const f=fixture(t); const active=path.join(f.dir,'active'); const inactive=path.join(f.dir,'inactive');
  const expected=f.executable('amp',active); f.executable('amp',inactive);
  f.inventory({amp:[{install_path:inactive,active:false},{install_path:active,active:true}]});
  assert.equal(f.run('agents',['--resolve','amp']).stdout.trim(),expected);
  fs.symlinkSync(expected,path.join(f.bin,'amp'));
  assert.equal(f.run('agents',['--resolve','amp']).stdout.trim(),path.join(f.bin,'amp'));
});
test('launch adapters preserve argv, no prompts or bypass flags, and the default agent', t => {
  const f=fixture(t); ids.forEach(id=>f.executable(id));
  f.executable('omarchy-launch-openclaw');
  f.write(path.join(f.bin,'omarchy-agent-account-home'),'printf ""');
  const config=path.join(f.home,'.config/omarchy/current'); fs.mkdirSync(config,{recursive:true});
  const defaults=path.join(config,'agent'); fs.writeFileSync(defaults,'codex\n');
  fs.mkdirSync(path.join(f.home,'Work'));
  for (const id of ids) {
    const r=f.run('agent',[id,'--yolo','unrequested task; $(touch surprise)']);
    assert.equal(r.status,0,r.stderr);
    const argv=fs.readFileSync(f.env.LOG,'utf8').split('\0').slice(0,-1);
    assert.equal(argv[0],path.join(f.bin,id==='openclaw'?'omarchy-launch-openclaw':id));
    assert.equal(argv[1],path.join(f.home,'Work'));
    assert.deepEqual(argv.slice(2),({ori:['code'],dsh:['web'],'kiro-cli':['chat'],openclaw:['--tui']})[id]||[]);
  }
  assert.equal(fs.readFileSync(defaults,'utf8'),'codex\n');
  fs.rmSync(f.env.LOG); fs.rmSync(path.join(f.bin,'amp'));
  assert.equal(f.run('agent',['amp']).status,1);
  assert.equal(f.run('agent',['amp; true']).status,1);
  assert.equal(fs.existsSync(f.env.LOG),false);
});
