// Real plugin-manager install/upgrade/remove, restricted to an owned nest.
const {execFileSync:exec,spawnSync}=require('node:child_process');
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
assert.ok(process.env.OMADEV_SLOT&&process.env.OMADEV_OWNER,'Run only in an owned omadev nest');
const repo=path.resolve(__dirname,'..'),id='io.github.tcballard.orb';
const run=(cmd,...args)=>exec(cmd,args.map(String),{cwd:repo,encoding:'utf8',timeout:90000}).trim();
const json=(...args)=>JSON.parse(run(...args)),ipc=(...args)=>run('omarchy-shell',...args),status=()=>JSON.parse(ipc(id,'status'));
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function until(check,message){for(let i=0;i<140;i++){try{if(check())return;}catch{}await sleep(100);}throw Error(message||'Timed out');}
const root=path.join(process.env.XDG_CONFIG_HOME,'omarchy'),target=path.join(root,'plugins',id),config=path.join(root,'orb.json'),shell=path.join(root,'shell.json');
assert.ok(fs.realpathSync(root).startsWith(process.env.OMADEV_HOME+'/'));
assert.ok(fs.lstatSync(target).isSymbolicLink(),'Start with the nest plugin link, never an existing checkout');
assert.equal(fs.realpathSync(target),repo);
const source=run('git','rev-parse','HEAD');assert.equal(run('git','status','--porcelain'),'','Commit the candidate before lifecycle acceptance');
const legacy='343207fe59ee08875b5f263337c72c8b957ce583';
run('git','merge-base','--is-ancestor',legacy,source);
const oldConfig=fs.readFileSync(config,'utf8'),oldShell=fs.readFileSync(shell,'utf8'),link=fs.readlinkSync(target);
const unrelatedShell=value=>{const s=JSON.parse(value);s.plugins=(s.plugins||[]).filter(p=>p.id!==id);return s;};
const baselineErrors=run('hyprctl','configerrors'),isOrb=b=>/^(Orb shortcut wheel|Orb on empty desktop|Orb mouse button) \[orb:/.test(b.description||'');
const binds=()=>json('hyprctl','binds','-j').filter(isOrb);
const key=k=>run('wtype','-s','80','-k',k,'-s','80');
const report={date:new Date().toISOString(),input_commit:source,omarchy:run('git','-C',process.env.OMARCHY_PATH,'rev-parse','HEAD'),legacy,checks:[]};
const pass=name=>{report.checks.push(name);console.log('PASS:',name);};
const work=fs.mkdtempSync(path.join(repo,'artifacts/release-lifecycle-')),origin=path.join(work,'origin.git');
const fixture=JSON.parse(run('git','show',legacy+':config.example.json'));
fixture.diameter=270;fixture.animation=false;fixture.desktopRightClick=true;fixture.custom={keep:'metadata'};
fixture.actions[0].note='keep browser';fixture.actions[4].children[0].note='keep child';
fixture.actions.push({label:'Seventh',icon:'files',command:['true'],note:'keep seven'},{label:'Eighth',icon:'terminal',command:['true']});
const fixtureText=JSON.stringify(fixture,null,2)+'\n';
function preserved(text){
    assert.equal(fs.readFileSync(config,'utf8'),text,'Saved Orb settings changed');
    assert.deepEqual(unrelatedShell(fs.readFileSync(shell,'utf8')),unrelatedShell(oldShell),'Unrelated shell settings changed');
    assert.equal(run('hyprctl','configerrors'),baselineErrors);
}
async function remove(){
    if(fs.existsSync(target))console.log(run('omarchy','plugin','remove',id,'--yes'));
    await until(()=>binds().length===0,'Removal left Orb bindings');
    assert.ok(!fs.existsSync(target));
    assert.ok(!JSON.stringify(json('hyprctl','layers','-j')).includes('omarchy-plugin-orb'));
}
async function ready(){await until(()=>status().setupReady&&status().version===JSON.parse(fs.readFileSync(path.join(repo,'manifest.json'),'utf8')).version,'Candidate failed to load/setup');assert.equal(status().setupError,'');}
async function restart(){run('omarchy','restart','shell');await ready();}
async function openSettings(){ipc('shell','summon',id,'{}');await until(()=>status().ready&&status().revealed&&status().opacity===1);await sleep(180);key('Home');key('Return');await until(()=>status().settingsOpen);}
(async()=>{try{
    run('git','clone','--bare','--quiet',repo,origin);
    run('git','--git-dir='+origin,'update-ref','refs/heads/release-fixture',legacy);
    run('git','--git-dir='+origin,'symbolic-ref','HEAD','refs/heads/release-fixture');
    await remove();fs.writeFileSync(config,fixtureText);
    console.log(run('omarchy','plugin','add',origin,'--enable','--yes'));
    assert.equal(run('git','-C',target,'rev-parse','HEAD'),legacy);
    await until(()=>json('omarchy-shell','shell','listPlugins').some(p=>p.id===id&&p.enabled));
    preserved(fixtureText);pass('Install the published v0.1.1 Git source with an eight-slot legacy layout');
    run('git','--git-dir='+origin,'update-ref','refs/heads/release-fixture',source);
    console.log(run('omarchy','plugin','update',id,'--yes'));await restart();
    assert.equal(run('git','-C',target,'rev-parse','HEAD'),source);assert.equal(run('git','-C',target,'status','--porcelain'),'');
    preserved(fixtureText);assert.equal(binds().length,2);assert.equal(status().shape,'circle');
    await openSettings();assert.equal(status().draftActions.length,8);assert.equal(status().draftDiameter,270);assert.equal(status().draftAnimation,false);assert.equal(status().undoCount,0);key('Escape');key('Escape');
    pass('Upgrade through the native manager to the exact candidate; byte-preserve legacy settings, metadata, custom size and eight slots');
    console.log(run('omarchy','plugin','disable',id));await until(()=>binds().length===0);
    console.log(run('omarchy','plugin','enable',id));await ready();await until(()=>binds().length===2);
    run('hyprctl','reload');await until(()=>binds().length===2);preserved(fixtureText);
    pass('Disable removes both bindings; enable and compositor reload restore exactly one keyboard and desktop binding');
    await remove();preserved(fixtureText);pass('Native removal unloads the overlay and bindings while retaining settings and unrelated shell configuration');
    fs.unlinkSync(config);
    console.log(run('omarchy','plugin','add',origin,'--enable','--yes'));await restart();
    const fresh=fs.readFileSync(config,'utf8'),expected=JSON.parse(fs.readFileSync(path.join(repo,'config.example.json')));
    assert.deepEqual(JSON.parse(fresh),expected);assert.equal(binds().length,1);
    await openSettings();assert.equal(status().draftActions.length,6);assert.equal(status().version,JSON.parse(fs.readFileSync(path.join(repo,'manifest.json'),'utf8')).version);key('Escape');key('Escape');
    pass('A fresh native Git install creates the default six-slot configuration, loads Settings and registers one shortcut automatically');
    for(let i=0;i<3;i++){
        ipc('shell','summon',id,'{}');await until(()=>status().ready&&status().opacity===1);await sleep(160);key('Escape');await until(()=>!status().opened);
    }
    console.log(run('omarchy','plugin','update',id,'--yes'));preserved(fresh);assert.equal(binds().length,1);
    await remove();assert.equal(fs.readFileSync(config,'utf8'),fresh);
    pass('Repeated open/Escape and unchanged update work; fresh removal preserves the generated configuration and removes the owned binding');
    report.status='passed';
}catch(error){report.status='failed';report.error=error.stack;throw error;
}finally{
    try{if(fs.existsSync(target))await remove();}catch(error){report.cleanup_error=error.message;}
    if(!fs.existsSync(target))fs.symlinkSync(link,target);
    fs.writeFileSync(config,oldConfig);fs.writeFileSync(shell,oldShell);
    run('omarchy','restart','shell');await ready();
    fs.writeFileSync(path.join(repo,'artifacts/release-lifecycle-results.json'),JSON.stringify(report,null,2)+'\n');
}})().catch(error=>{console.error(error);process.exitCode=1;});
