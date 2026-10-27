import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import vm from 'node:vm';
import {spawnSync} from 'node:child_process';

const root=path.resolve(import.meta.dirname,'..');
const token='1792450000000-123456789';
const marker='-- Orb shortcut wheel: managed by omarchy-plugin-orb/install';
const legacy=marker+'\no.bind("SUPER + ALT + O", "Orb shortcut wheel", { panel = "io.github.tcballard.orb" })\n';
const example=fs.readFileSync(path.join(root,'config.example.json'),'utf8');
function fixture(fn) {
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'orb native '));
  try {
    const config=path.join(dir,'config'), bin=path.join(dir,'bin'); fs.mkdirSync(bin);
    fs.writeFileSync(path.join(bin,'hyprctl'),`#!/bin/bash
set -eu
case "$1" in
  binds)
    if [[ -f "$ORB_FIXTURE/applied" ]]; then
      [[ $ORB_MODE != missing ]] || { echo '[]'; exit; }
      cat "$ORB_FIXTURE/registered.json"
    else
      cat "$ORB_FIXTURE/binds.json"
    fi ;;
  eval)
    printf '%s' "$2" > "$ORB_FIXTURE/apply.lua"
    touch "$ORB_FIXTURE/applied"
    [[ $ORB_MODE != eval-error ]] || { echo 'error: fixture Lua failure'; exit; }
    echo ok ;;
  reload)
    if [[ ! -f "$ORB_FIXTURE/reloaded" ]]; then
      touch "$ORB_FIXTURE/reloaded"
      [[ $ORB_MODE != reload ]] || exit 1
    fi ;;
  configerrors)
    if [[ -f "$ORB_FIXTURE/reloaded" ]]; then
      [[ $ORB_MODE != query ]] || exit 1
      [[ $ORB_MODE != configerrors ]] || echo 'Fixture config error'
    fi ;;
  *) exit 2 ;;
esac
`,{mode:0o755});
    fs.writeFileSync(path.join(dir,'binds.json'),'[]');
    const run=(mode='')=>{
      const file=path.join(config,'omarchy/orb.json');
      const value=JSON.parse(fs.existsSync(file)?fs.readFileSync(file,'utf8'):example);
      const parts=(value.shortcut||'SUPER + ALT + O').split('+').map(s=>s.trim().toUpperCase());
      const bits={SUPER:64,ALT:8,CTRL:4,SHIFT:1};
      const binds=[{key:parts.at(-1),modmask:parts.slice(0,-1).reduce((m,p)=>m|(bits[p]||0),0),description:`Orb shortcut wheel [orb:${token}]`}];
      if(value.desktopRightClick)binds.push({key:'mouse:273',modmask:0,description:`Orb on empty desktop [orb:${token}]`});
      if(value.mouseOpen) {
        binds.push({key:`mouse:${value.mouseButton||277}`,modmask:0,description:`Orb mouse button [orb:${token}] press`,release:false});
        binds.push({key:`mouse:${value.mouseButton||277}`,modmask:0,description:`Orb mouse button [orb:${token}] release`,release:true});
      }
      fs.writeFileSync(path.join(dir,'registered.json'),JSON.stringify(binds));
      return spawnSync('bash',[path.join(root,'scripts/setup'),token],{encoding:'utf8',timeout:10000,
        env:{...process.env,PATH:bin+path.delimiter+process.env.PATH,HOME:dir,XDG_CONFIG_HOME:config,ORB_FIXTURE:dir,ORB_MODE:mode}});
    };
    const put=(file,content)=>{const p=path.join(config,file);fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,content);return p;};
    fn({dir,config,run,put});
  } finally {fs.rmSync(dir,{recursive:true,force:true});}
}
test('fresh native enable initializes defaults once and writes no Hyprland config',()=>fixture(({config,run})=>{
  let r=run();assert.equal(r.status,0,r.stderr);assert.match(r.stdout,/ready/);
  assert.equal(fs.readFileSync(path.join(config,'omarchy/orb.json'),'utf8'),example);
  assert.equal(fs.statSync(path.join(config,'omarchy/orb.json')).mode&0o777,0o600);
  assert.equal(fs.existsSync(path.join(config,'hypr')),false);
  r=run();assert.equal(r.status,0,r.stderr);
}));
test('repeat enable preserves the released config and all custom metadata',()=>fixture(({config,run,put,dir})=>{
  const original=JSON.parse(example);original.custom={keep:true};original.shortcut='SUPER + CTRL + P';original.desktopRightClick=true;
  const raw=JSON.stringify(original,null,4)+'\n';put('omarchy/orb.json',raw);
  const r=run();assert.equal(r.status,0,r.stderr);
  assert.equal(fs.readFileSync(path.join(config,'omarchy/orb.json'),'utf8'),raw);
  const code=fs.readFileSync(path.join(dir,'apply.lua'),'utf8');assert.match(code,/SUPER \+ CTRL \+ P/);assert.match(code,/auto_consuming = true/);
}));
test('modifier ordering is canonical before retaining an existing key',()=>fixture(({run,put,dir})=>{
  put('omarchy/orb.json',JSON.stringify({...JSON.parse(example),shortcut:'alt + super + ctrl + p'}));
  const r=run();assert.equal(r.status,0,r.stderr);
  const code=fs.readFileSync(path.join(dir,'apply.lua'),'utf8');
  assert.match(code,/SUPER \+ CTRL \+ ALT \+ P/);
  assert.doesNotMatch(code,/ALT \+ SUPER/);
}));
for(const [name,binds] of [
  ['keyboard',[{key:'O',modmask:72,description:'User shortcut'}]],
  ['desktop',[{key:'mouse:273',modmask:0,description:'User right-click'}]]
]) test(`${name} conflict preserves user bindings and refuses registration`,()=>fixture(({dir,run,put})=>{
  put('omarchy/orb.json',JSON.stringify({...JSON.parse(example),desktopRightClick:true}));
  fs.writeFileSync(path.join(dir,'binds.json'),JSON.stringify(binds));
  const r=run();assert.notEqual(r.status,0);assert.match(r.stderr,/already/);assert.equal(fs.existsSync(path.join(dir,'apply.lua')),false);
}));
for(const mode of ['eval-error','missing']) test(`registration ${mode} cannot report success`,()=>fixture(({run})=>{
  const r=run(mode);assert.notEqual(r.status,0);assert.match(r.stderr,/failure|did not complete/);
}));
for(const shortcut of ['SUPER + O; os.execute("false")','SUPER + SUPER + O','ALT + O','SUPER + O + P'])
  test(`unsafe/invalid shortcut ${shortcut} is refused`,()=>fixture(({run,put,dir})=>{
    put('omarchy/orb.json',JSON.stringify({...JSON.parse(example),shortcut}));
    assert.notEqual(run().status,0);assert.equal(fs.existsSync(path.join(dir,'apply.lua')),false);
  }));
for(const mode of ['none','reload','query','configerrors']) for(const hasBindings of [false,true])
  test(`legacy migration ${mode}; existing bindings ${hasBindings}`,()=>fixture(({config,run,put})=>{
    put('hypr/orb.lua',legacy);
    const other='-- user bindings\n';
    if(hasBindings)put('hypr/bindings.lua',other+'require("orb") -- Orb shortcut wheel\n');
    put('hypr/unrelated.lua','-- preserve\n');
    const r=run(mode);
    assert.equal(fs.readFileSync(path.join(config,'hypr/unrelated.lua'),'utf8'),'-- preserve\n');
    if(mode==='none'){
      assert.equal(r.status,0,r.stderr);assert.equal(fs.existsSync(path.join(config,'hypr/orb.lua')),false);
      assert.equal(hasBindings ? fs.readFileSync(path.join(config,'hypr/bindings.lua'),'utf8') : null,hasBindings?other:null);
    }else{
      assert.notEqual(r.status,0);assert.match(r.stderr,/migration failed/);
      assert.equal(fs.readFileSync(path.join(config,'hypr/orb.lua'),'utf8'),legacy);
      assert.equal(fs.existsSync(path.join(config,'hypr/bindings.lua')),hasBindings);
      if(hasBindings)assert.equal(fs.readFileSync(path.join(config,'hypr/bindings.lua'),'utf8'),other+'require("orb") -- Orb shortcut wheel\n');
    }
  }));
test('extra-button registration, conflicts and lifecycle are safe',()=>fixture(({dir,run,put})=>{
  const base=JSON.parse(example);
  const capture=value=>{
    put('omarchy/orb.json',JSON.stringify({...base,...value}));
    const result=run(); assert.equal(result.status,0,result.stderr);
    return fs.readFileSync(path.join(dir,'apply.lua'),'utf8');
  };
  const on=capture({mouseOpen:true,mouseButton:275});
  const both=capture({mouseOpen:true,mouseButton:275,desktopRightClick:true});
  const changed=capture({mouseOpen:true,mouseButton:276,desktopRightClick:true});
  const off=capture({mouseOpen:false});
  assert.match(on,/orbMouseBinding\("mouse:275"\)/);
  assert.match(on,/release = true/);
  for(const code of [272,273,274,512]){
    fs.rmSync(path.join(dir,'applied'),{force:true});
    put('omarchy/orb.json',JSON.stringify({...base,mouseOpen:true,mouseButton:code}));
    const result=run(); assert.notEqual(result.status,0); assert.match(result.stderr,/275 to 511/);
    assert.equal(fs.existsSync(path.join(dir,'applied')),false);
  }
  for(const modmask of [0,64]){
    fs.writeFileSync(path.join(dir,'binds.json'),JSON.stringify([{key:'mouse:275',modmask,description:'User mouse'}]));
    put('omarchy/orb.json',JSON.stringify({...base,mouseOpen:true,mouseButton:275}));
    const result=run(); assert.notEqual(result.status,0); assert.match(result.stderr,/already in use/);
  }
  const interpreter=['lua','lua5.4','texlua'].find(cmd=>spawnSync('which',[cmd]).status===0);
  assert.ok(interpreter,'Lua interpreter required for lifecycle tests');
  const script=path.join(dir,'mouse-lifecycle.lua');
  const newer='1792450000001-123456789';
  fs.writeFileSync(script,`local registered, events = {}, {}
local pointer = {x=100,y=200}
local failRelease = false
hl = {
  bind = function(key, cb, opts)
    if failRelease and opts.release then return nil end
    local bind = { key=key, callback=cb, opts=opts, removed=false }
    function bind:remove() for _, b in ipairs(registered) do if b.key==self.key then b.removed=true end end end
    table.insert(registered, bind); return bind
  end,
  timer = function(cb, opts)
    local timer={ callback=cb, enabled=true }
    function timer:set_enabled(value) self.enabled=value end
    return timer
  end,
  get_cursor_pos = function() return pointer end,
  dsp = { event=function(value) return value end },
  dispatch = function(value) table.insert(events,value) end,
  exec_cmd = function() end
}
local function evaluate(code) assert(load(code))() end
local function live() local n=0; for _,b in ipairs(registered) do if not b.removed then n=n+1 end end; return n end
local function get(key, release) for _,b in ipairs(registered) do if b.key==key and not b.removed and (b.opts.release==true)==release then return b end end end
local function fire(key, release) local b=assert(get(key,release)); b.callback() end
local on=${JSON.stringify(on)}
local both=${JSON.stringify(both)}
local changed=${JSON.stringify(changed)}
local off=${JSON.stringify(off)}
evaluate(on); assert(live()==3)
local timer=assert(__orb_native_bindings.gestureTimer); assert(not timer.enabled)
fire('mouse:275',false); assert(timer.enabled)
assert(events[1]=='orb/${token}/press/100,200/0')
pointer={x=110,y=150}; timer.callback(); assert(events[2]=='orb/${token}/move/110,150/30')
fire('mouse:275',true); assert(not timer.enabled and events[3]=='orb/${token}/release/110,150/30')
fire('mouse:275',true); assert(#events==3)
local oldPress=get('mouse:275',false); local oldRelease=get('mouse:275',true)
evaluate(both); assert(live()==4 and get('mouse:275',false)==oldPress and get('mouse:275',true)==oldRelease)
evaluate(changed); assert(live()==4 and not get('mouse:275',false) and get('mouse:276',true))
failRelease=true
assert(not pcall(evaluate, string.gsub(changed,'276','277')))
assert(live()==4 and get('mouse:276',false) and not get('mouse:277',false))
failRelease=false
evaluate(off); assert(live()==1 and not timer.enabled)
evaluate(on); assert(live()==3)
evaluate(${JSON.stringify(on.replaceAll(token,newer))}); assert(live()==3)
fire('mouse:275',false); assert(events[#events]=='orb/${newer}/press/110,150/0')
fire('mouse:275',true)
fire('mouse:275',false); pointer=nil; fire('mouse:275',true)
assert(events[#events]=='orb/${newer}/cancel/110,150/0' and not timer.enabled)
pointer={x=110,y=150}; fire('mouse:275',false)
for i=1,200 do timer.callback() end
assert(events[#events]=='orb/${newer}/cancel/110,150/6000' and not timer.enabled)
local before=#events; fire('mouse:275',true); assert(#events==before)
fire('mouse:275',false); assert(timer.enabled)
evaluate(${JSON.stringify(off.replaceAll(token,newer))}); assert(live()==1 and not timer.enabled)
print('PASS: ordered gestures, binding reuse, rollback and cleanup')
`);
  const lua=spawnSync(interpreter,[script],{encoding:'utf8'});assert.equal(lua.status,0,lua.stdout+lua.stderr);
}));
test('an invalid mouse code cannot silently acquire a different button',()=>fixture(({dir,run,put})=>{
  put('omarchy/orb.json',JSON.stringify({...JSON.parse(example),mouseOpen:true,mouseButton:'abc'}));
  const result=run(); assert.notEqual(result.status,0); assert.match(result.stderr,/275/);
  assert.equal(fs.existsSync(path.join(dir,'apply.lua')),false);
}));
test('modified legacy module is retained without changing unrelated files',()=>fixture(({run,put,config})=>{
  const modified=legacy+'-- my changes\n';put('hypr/orb.lua',modified);put('hypr/bindings.lua','require("orb") -- Orb shortcut wheel\n');
  const r=run();assert.notEqual(r.status,0);assert.match(r.stderr,/Modified legacy/);
  assert.equal(fs.readFileSync(path.join(config,'hypr/orb.lua'),'utf8'),modified);
}));
test('Lua lifecycle removes only owned handles, survives reload and rejects late applies',()=>fixture(({run,dir,put})=>{
  put('omarchy/orb.json',JSON.stringify({...JSON.parse(example),desktopRightClick:true}));
  assert.equal(run().status,0);
  const apply=fs.readFileSync(path.join(dir,'apply.lua'),'utf8');
  put('omarchy/orb.json',JSON.stringify({...JSON.parse(example),desktopRightClick:false}));
  assert.equal(run().status,0);
  const keyboardOnly=fs.readFileSync(path.join(dir,'apply.lua'),'utf8');
  const context=vm.createContext({});vm.runInContext(fs.readFileSync(path.join(root,'BindingLifecycle.js'),'utf8'),context);
  const cleanup=context.cleanup(token), newer='1792450000001-123456789';
  const lua=`local registered = {}; local count = 0
hl = { bind = function(key, cb, opts)
  local bind = { key = key, callback = cb, description = opts.description, removed = false }
  function bind:remove() for _, other in ipairs(registered) do if other.key == self.key then other.removed = true end end end
  table.insert(registered, bind); return bind
end, exec_cmd = function() count = count + 1 end }
local function evaluate(code) assert(load(code))() end
local function live() local n=0; for _, b in ipairs(registered) do if not b.removed then n=n+1 end end; return n end
local apply = ${JSON.stringify(apply)}
local cleanup = ${JSON.stringify(cleanup)}
evaluate(apply); assert(live() == 2); registered[1].callback(); assert(count == 1)
evaluate(apply); assert(live() == 2) -- repeated config file event
evaluate(${JSON.stringify(apply.replaceAll('SUPER + ALT + O','SUPER + ALT + P'))}); assert(live() == 2) -- replace key, retain desktop handle
evaluate(apply); assert(live() == 2) -- restore key, still retain desktop handle
evaluate(${JSON.stringify(keyboardOnly)}); assert(live() == 1) -- retain keyboard handle while disabling desktop
local originalBind = hl.bind
hl.bind = function(key, cb, opts) if key == "mouse:273" then return nil end; return originalBind(key, cb, opts) end
assert(not pcall(evaluate, apply)); assert(live() == 1) -- partial failure keeps the prior working keyboard
hl.bind = originalBind
evaluate(apply); assert(live() == 2)
evaluate(${JSON.stringify(apply.replaceAll(token,newer))}); assert(live() == 2)
evaluate(cleanup); assert(live() == 2) -- late old unload cannot delete new handles
evaluate(apply); assert(live() == 2) -- late old apply is tombstoned
for _, b in ipairs(registered) do b.removed = true end; __orb_native_bindings = nil
evaluate(apply); assert(live() == 2) -- compositor reload clears Lua state/binds
evaluate(cleanup); assert(live() == 0)
evaluate(apply); assert(live() == 0) -- destroyed menu cannot register later
print('PASS: native binding lifecycle')
`;
  const script=path.join(dir,'lifecycle.lua');fs.writeFileSync(script,lua);
  const interpreter=['lua','lua5.4','texlua'].find(cmd=>spawnSync('which',[cmd]).status===0);
  assert.ok(interpreter,'Lua interpreter required for lifecycle tests (lua5.4 or texlua)');
  const r=spawnSync(interpreter,[script],{encoding:'utf8'});assert.equal(r.status,0,r.stdout+r.stderr);
}));
