// Opt-in real desktop removal/reinstallation. Always attempt reinstall after removal.
const {execFileSync}=require('node:child_process');
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),{createHash}=require('node:crypto');
const repo=path.resolve(__dirname,'..'),id='io.github.tcballard.orb';
const home=process.env.HOME,configDir=process.env.XDG_CONFIG_HOME||home+'/.config';
const target=home+'/.config/omarchy/plugins/'+id;
const paths={config:configDir+'/omarchy/orb.json',bindings:configDir+'/hypr/bindings.lua',module:configDir+'/hypr/orb.lua',shell:configDir+'/omarchy/shell.json'};
const run=(cmd,...args)=>execFileSync(cmd,args.map(String),{cwd:repo,encoding:'utf8',timeout:60000,env:{...process.env,OMARCHY_SHELL_IPC_TIMEOUT:'10s'}}).trim();
const json=(...a)=>JSON.parse(run(...a)),ipc=(...a)=>run('omarchy-shell',...a),status=()=>JSON.parse(ipc(id,'status'));
const read=p=>fs.readFileSync(p,'utf8'),hash=s=>createHash('sha256').update(s).digest('hex');
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function until(fn,message){for(let i=0;i<100;i++){try{if(fn())return;}catch{}await sleep(100);}throw Error(message);}
const key=k=>run('wtype','-s','80','-k',k,'-s','80');
const isOrb=b=>/^(Orb shortcut wheel|Orb on empty desktop|Orb mouse button) \[orb:/.test(b.description||'');
const installUrl=process.env.ORB_INSTALL_URL||'https://github.com/tcballard/omarchy-plugin-orb.git';
const unrelatedBindings=text=>text.split('\n').filter(line=>line!=='require("orb") -- Orb shortcut wheel').join('\n').trimEnd();
const unrelatedShell=text=>{const s=JSON.parse(text);s.plugins=(s.plugins||[]).filter(p=>p.id!==id);return s;};
const report={date:new Date().toISOString(),input_commit:run('git','rev-parse','HEAD'),omarchy_commit:run('git','-C',process.env.OMARCHY_PATH,'rev-parse','HEAD'),checks:[]};
const pass=name=>{report.checks.push({name,pass:true});console.log('PASS: '+name);};
const backup=path.join(repo,'artifacts','lifecycle-'+Date.now());fs.mkdirSync(backup,{recursive:true,mode:0o700});
const original=Object.fromEntries(Object.entries(paths).map(([name,p])=>[name,fs.existsSync(p)?read(p):null]));
for(const [name,text] of Object.entries(original))if(text!==null)fs.writeFileSync(path.join(backup,name),text,{mode:0o600});
const config=JSON.parse(original.config),focus=json('hyprctl','activewindow','-j').address;
const source=run('git','rev-parse','HEAD');let started=false,restored=false;
function preserved(){
  assert.equal(read(paths.config),original.config,'Orb settings changed');
  assert.equal(unrelatedBindings(fs.existsSync(paths.bindings)?read(paths.bindings):''),unrelatedBindings(original.bindings||''),'Unrelated bindings changed');
  assert.deepEqual(unrelatedShell(read(paths.shell)),unrelatedShell(original.shell),'Unrelated shell settings changed');
  assert.equal(run('hyprctl','configerrors'),'');
}
async function install(){console.log(run('omarchy','plugin','add',installUrl,'--enable','--yes'));await until(()=>json('omarchy-shell','shell','listPlugins').some(p=>p.id===id&&p.enabled)&&status().setupReady,'Orb native setup did not complete');restored=true;}
(async()=>{try{
  assert.equal(run('git','-C',target,'status','--porcelain'),'','Installed checkout has uncommitted changes');
  assert.equal(run('git','-C',target,'remote','get-url','origin'),'https://github.com/tcballard/omarchy-plugin-orb.git');
  assert.equal(run('hyprctl','configerrors'),'');
  report.previous_install=run('git','-C',target,'rev-parse','HEAD');
  report.config_sha256=hash(original.config);report.slot_count=config.actions.length;report.diameter=config.diameter;
  ipc('shell','hide',id);started=true;console.log(run('omarchy','plugin','remove',id,'--yes'));
  await until(()=>json('hyprctl','binds','-j').filter(isOrb).length===0,'Runtime bindings remained after native removal');
  assert.ok(!fs.existsSync(target),'Plugin checkout remains after removal');
  assert.ok(!fs.existsSync(paths.module),'Orb Lua module remains after removal');
  assert.ok(!fs.existsSync(paths.bindings)||!read(paths.bindings).includes('require("orb") -- Orb shortcut wheel'));
  assert.equal(json('hyprctl','binds','-j').filter(isOrb).length,0);
  assert.ok(!json('omarchy-shell','shell','listPlugins').some(p=>p.id===id));
  assert.ok(!JSON.stringify(json('hyprctl','layers','-j')).includes('omarchy-plugin-orb'));
  preserved();pass('Removal unloads Orb, deletes its checkout/module and removes both owned bindings');
  pass('Removal preserves Orb configuration, unrelated bindings and shell settings');
  await install();preserved();
  assert.equal(run('git','-C',target,'rev-parse','HEAD'),source);
  assert.equal(run('git','-C',target,'status','--porcelain'),'');
  let binds=json('hyprctl','binds','-j').filter(isOrb);
  assert.equal(binds.filter(b=>b.description.startsWith('Orb shortcut wheel [orb:')).length,1);
  assert.equal(binds.filter(b=>b.description.startsWith('Orb on empty desktop [orb:')).length,config.desktopRightClick?1:0);
  assert.equal(binds.filter(b=>b.description.startsWith('Orb mouse button [orb:')).length,config.mouseOpen?2:0);
  assert.ok(!fs.existsSync(paths.bindings)||!read(paths.bindings).includes('require("orb") -- Orb shortcut wheel'));
  pass('Fresh Git reinstall enables the exact candidate with one shortcut and the configured right-click binding');
  console.log(run('omarchy','plugin','disable',id));
  await until(()=>json('hyprctl','binds','-j').filter(isOrb).length===0,'Disable retained bindings');
  console.log(run('omarchy','plugin','enable',id));
  await until(()=>status().setupReady,'Re-enable setup did not complete');
  preserved();
  assert.equal(json('hyprctl','binds','-j').filter(isOrb).length,binds.length);
  run('hyprctl','reload');
  await until(()=>json('hyprctl','binds','-j').filter(isOrb).length===binds.length,'Reload did not restore runtime bindings');
  console.log(run('omarchy','plugin','update',id,'--yes'));
  pass('Native disable/re-enable, compositor reload and update retain exactly one set of bindings and saved settings');
  for(let i=0;i<3;i++){
    ipc('shell','summon',id,'{}');await until(()=>status().opacity===1,'Reinstalled Orb did not open');await sleep(200);
    assert.deepEqual(status().visibleItems,config.actions.map(a=>a.label));
    if(i===0){key('Home');key('Return');await until(()=>status().settingsOpen,'Settings did not open');assert.equal(status().draftDiameter,config.diameter);assert.equal(status().draftAnimation,config.animation!==false);assert.deepEqual(status().draftActions.map(a=>a.label),config.actions.map(a=>a.label));key('Escape');}
    key('Escape');await until(()=>!status().opened,'Escape did not dismiss');
  }
  preserved();pass('Three live summon/Escape cycles work; settings retain all slots, size and animation');
  if(focus){await sleep(150);assert.equal(json('hyprctl','activewindow','-j').address,focus);pass('Dismissal restores the previously focused window');}
  report.status='passed';
}catch(error){report.status='failed';report.error=error.message;console.error(error);process.exitCode=1;
}finally{
  if(started&&!restored){try{await install();console.log('Recovery: Orb reinstalled');}catch(error){report.recovery_error=error.message;console.error('Reinstall recovery failed: '+error.message);}}
  try{ipc('shell','hide',id);}catch{}
  if(focus)run('hyprctl','dispatch',`hl.dsp.focus({window="address:${focus}"})`);
  report.backup=backup;fs.writeFileSync(path.join(repo,'artifacts/lifecycle-live-results.json'),JSON.stringify(report,null,2)+'\n');
  console.log('Backup: '+backup);
}})();
