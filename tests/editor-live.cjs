// Run only inside an owned omadev nest. All input/configuration stays in that nest.
const {execFileSync:exec,spawnSync}=require('node:child_process');
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
assert.ok(process.env.OMADEV_SLOT && process.env.OMADEV_OWNER,'Run through omadev, never on the host desktop');
const repo=path.resolve(__dirname,'..'),id='io.github.tcballard.orb';
const run=(command,...args)=>exec(command,args.map(String),{encoding:'utf8',timeout:15000}).trim();
const json=(...args)=>JSON.parse(run(...args)),ipc=(...args)=>run('omarchy-shell',...args),status=()=>JSON.parse(ipc(id,'status'));
const sleep=ms=>new Promise(resolve=>setTimeout(resolve,ms));
async function until(check,message){for(let i=0;i<70;i++){if(check())return;await sleep(80);}throw Error(message||'Timed out');}
const key=value=>run('wtype','-s','50','-k',value,'-s','50');
const chord=(modifier,value)=>run('wtype','-M',modifier,'-k',value,'-m',modifier,'-s','70');
const text=value=>run('wtype','--',value);
const monitor=json('hyprctl','monitors','-j').find(m=>m.focused),pointer=path.join(repo,'artifacts/input/pointer');
const move=(x,y,button=0,end)=>run(pointer,Math.round(x),Math.round(y),monitor.width,monitor.height,button,...(end?end.map(Math.round):[]));
const config=path.join(process.env.XDG_CONFIG_HOME,'omarchy/orb.json');
assert.ok(config.startsWith(process.env.OMADEV_HOME+'/'),'Configuration must belong to the nest');
const oldText=fs.readFileSync(config,'utf8');
let s;
const fixture=JSON.parse(fs.readFileSync(path.join(repo,'config.example.json'),'utf8'));
fixture.desktopRightClick=false;fixture.custom='preserve';fixture.actions[0].note='Browser metadata';fixture.actions[4].children[0].note='Themes metadata';
const fixtureText=JSON.stringify(fixture,null,2)+'\n',report=[];
const pass=message=>{report.push(message);console.log('PASS:',message);};
function capture(name){
    let s=status();if(s.settingsOpen)move(s.settingsX+30,s.settingsY+25);
    run('sleep','0.2');s=status();
    const region=s.settingsOpen?['-g',`${Math.floor(s.settingsX)},${Math.floor(s.settingsY)} ${Math.ceil(s.settingsWidth)}x${Math.ceil(s.settingsHeight)}`]:[];
    run('grim',...region,path.join(repo,'artifacts',name+'.png'));
}
function control(name){const s=status(),c=s.settingsControls.find(c=>c.name===name);assert.ok(c,'Missing UI control '+name);return {...c,x:c.x+s.settingsX,y:c.y+s.settingsY};}
async function click(name){
    let c=control(name);assert.ok(c.enabled,'Disabled UI control '+name);
    if(!/^orb-(tab-|save$|cancel$)/.test(name)) for(let i=0;i<24;i++){
        const s=status(),l=s.settingsLayout,top=s.settingsY+l.bodyY,bottom=top+l.bodyHeight,center=c.y+c.height/2;
        if(center>=top&&center<=bottom)break;
        assert.ok(i<23,'Could not scroll UI control into view: '+name);
        move(s.settingsX+l.bodyX+l.bodyWidth/2,top+l.bodyHeight/2,center<top?-2:-1);await sleep(130);c=control(name);
    }
    move(c.x+c.width/2,c.y+c.height/2,272);await sleep(100);
}
async function fill(name,value){await click(name);chord('ctrl','a');text(value);await sleep(70);}
async function openSettings(){ipc('shell','summon',id,'{}');await until(()=>status().opened&&status().ready&&status().opacity===1);await sleep(130);key('Home');key('Return');await until(()=>status().settingsOpen);await sleep(100);}
async function save(){await click('orb-save');await until(()=>!status().settingsOpen&&!status().settingsSaving,'Save failed: '+status().settingsError);}
async function reset(){ipc('shell','hide',id);fs.writeFileSync(config,fixtureText);await until(()=>status().visibleItems[0]==='Browser'&&status().visibleItems.length===6);await sleep(180);}
function saved(){return JSON.parse(fs.readFileSync(config,'utf8'));}
function previewPoint(s,index){const angle=(index*360/s.draftActions.length-90)*Math.PI/180,p=s.preview;return [s.settingsX+p.x+p.diameter/2+Math.cos(angle)*p.diameter*.33,s.settingsY+p.y+p.diameter/2+Math.sin(angle)*p.diameter*.33];}
async function choose(query){text(query);await until(()=>status().pickerItems.length>0);key('Return');await sleep(100);}
async function undoChecks(){
    await reset();await openSettings();assert.equal(status().version,JSON.parse(fs.readFileSync(path.join(repo,'manifest.json'),'utf8')).version);assert.equal(control('orb-undo').enabled,false);
    const original=status().draftActions,origins=status().draftActionOrigins,children=status().draftChildOrigins;
    await click('orb-tab-1');await click('orb-size-large');await click('orb-shape-polygon');
    await click('orb-tab-2');await fill('orb-opening-key','F12');await click('orb-tab-0');
    const opening=[status().settingsWidth,status().settingsHeight];
    chord('alt','Right');assert.equal(status().undoCount,1);assert.equal(status().draftActions[1].label,'Browser');
    key('Delete');assert.equal(status().draftActions.length,5);assert.equal(status().undoCount,2);
    await click('orb-undo');assert.equal(status().draftActions.length,6);assert.equal(status().draftActions[1].label,'Browser');
    chord('ctrl','z');assert.deepEqual(status().draftActions,original);assert.deepEqual(status().draftActionOrigins,origins);assert.deepEqual(status().draftChildOrigins,children);
    assert.equal(status().draftDiameter,480);assert.equal(status().draftShape,'polygon');assert.equal(status().draftShortcut.replace(/\s+/g,' '),'SUPER + ALT + F12');assert.equal(control('orb-undo').enabled,false);
    let s=status();move(...previewPoint(s,0),272,previewPoint(s,2));await until(()=>status().draftActions[2].label==='Browser');await click('orb-undo');assert.deepEqual(status().draftActions,original);
    await click('orb-add-slot');await choose('Terminal');assert.equal(status().draftActions.length,7);await click('orb-undo');assert.equal(status().draftActions.length,6);
    await click('orb-slot-4');await fill('orb-action-name','Temporary submenu');await click('orb-action-remove-child-0');await click('orb-action-use');
    assert.equal(status().draftActions[4].label,'Temporary submenu');await click('orb-undo');assert.deepEqual(status().draftChildOrigins,children);assert.deepEqual(status().draftActions,original);
    await click('orb-browse-actions');let pick=status();move(...previewPoint(pick,0),272);await fill('orb-catalog-search','Files');await until(()=>status().pickerItems[0]==='Files');await click('orb-catalog-choice-0');assert.equal(status().draftActions[0].label,'Files');await click('orb-undo');assert.deepEqual(status().draftActions,original);
    // Native text undo must not consume the shortcut history underneath it.
    s=status();move(...previewPoint(s,0),272,previewPoint(s,1));await until(()=>status().undoCount===1);
    await fill('orb-catalog-search','Terminal');text('x');chord('ctrl','z');assert.equal(status().undoCount,1,'Text undo changed the shortcut draft');
    await click('orb-undo');assert.deepEqual(status().draftActions,original);assert.deepEqual([status().settingsWidth,status().settingsHeight],opening);
    await click('orb-browse-actions');capture('release-settings');await save();assert.equal(saved().diameter,480);assert.equal(saved().shape,'polygon');assert.deepEqual(saved().actions,fixture.actions);
    await openSettings();assert.equal(status().undoCount,0);assert.equal(control('orb-undo').enabled,false);chord('alt','Right');await click('orb-cancel');
    await openSettings();assert.equal(status().undoCount,0);assert.deepEqual(status().draftActions,original);await click('orb-cancel');
    pass('Installed version is shown; Undo restores remove, reorder, drag, add, submenu and catalog edits with identities intact, preserves appearance/opening drafts and text undo, and clears on Save/Cancel');
    await reset();
}
async function appearancePlacement(){
    const [left,top,right,bottom]=monitor.reserved||[0,0,0,0];
    const frame=()=>{const s=status();return [s.settingsX,s.settingsY,s.settingsWidth,s.settingsHeight];};
    for(const count of [6,8]){
        const sample=JSON.parse(fixtureText);while(sample.actions.length<count)sample.actions.push({...sample.actions[0]});
        const sampleText=JSON.stringify(sample,null,2)+'\n';fs.writeFileSync(config,sampleText);
        await until(()=>status().visibleItems.length===count);await sleep(180);
        for(const p of [[1,1],[monitor.width-1,1],[1,monitor.height-1],[monitor.width-1,monitor.height-1],[1,monitor.height/2],[monitor.width-1,monitor.height/2]]){
            ipc('shell','hide',id);move(...p);await openSettings();const opening=frame(),s=status();
            assert.deepEqual([s.windowWidth,s.windowHeight],[monitor.width,monitor.height],'The nest was resized during the check; rerun with a stable display');
            assert.ok(s.settingsX>=left+11.5&&s.settingsY>=top+11.5);
            assert.ok(s.settingsX+s.settingsWidth<=monitor.width-right-11.5&&s.settingsY+s.settingsHeight<=monitor.height-bottom-11.5);
            assert.ok(Math.abs(s.settingsX+s.settingsWidth/2-(left+monitor.width-right)/2)<=.5,'Settings must be horizontally centred regardless of the pointer');
            assert.ok(Math.abs(s.settingsY+s.settingsHeight/2-(top+monitor.height-bottom)/2)<=.5,'Settings must be vertically centred in the usable area');
            await click('orb-tab-1');assert.deepEqual(frame(),opening);
            for(const [name,value] of [['small',240],['medium',360],['large',480]]){
                await click('orb-size-'+name);assert.equal(status().draftDiameter,value);assert.deepEqual(frame(),opening);
            }
            const slider=control('orb-size-slider'),start=[slider.x+1,slider.y+slider.height/2],end=[slider.x+slider.width-1,start[1]];
            assert.ok(slider.x>=s.settingsX&&slider.x+slider.width<=s.settingsX+s.settingsWidth);
            move(...start,272,end);await sleep(160);assert.equal(status().draftDiameter,600);assert.deepEqual(frame(),opening);
            move(...end,272,start);await sleep(160);assert.equal(status().draftDiameter,220);assert.deepEqual(frame(),opening);
            if(count===8&&p[0]===monitor.width-1&&p[1]===monitor.height/2)capture('appearance-centred');
            await click('orb-tab-2');assert.deepEqual(frame(),opening);await click('orb-tab-0');assert.deepEqual(frame(),opening);
            await click('orb-cancel');assert.equal(fs.readFileSync(config,'utf8'),sampleText);
        }
    }
    pass('Six/eight-slot Settings stay centred and fully on-screen at corners and side edges; tabs, presets and full slider drags retain their opening frame');
    await reset();
}
const output=path.join(repo,'artifacts/command-arguments.json'),probe=path.join(repo,'artifacts/orb-command-probe');
fs.rmSync(output,{force:true});
fs.writeFileSync(probe,'#!/usr/bin/python3\nimport json,sys,os\noutput='+JSON.stringify(output)+'\nwith open(output+".tmp", "w") as f: json.dump(sys.argv[1:], f)\nos.replace(output+".tmp", output)\n',{mode:0o755});
(async()=>{try{
await until(()=>spawnSync('omarchy-shell',[id,'status'],{encoding:'utf8'}).status===0,'Orb did not finish loading');
await reset();await until(()=>status().setupReady,'Native shortcut setup failed: '+status().setupError);
await undoChecks();
if(process.argv.includes('--undo-only'))return;
if(!process.argv.includes('--submenu-only'))await appearancePlacement();
if(process.argv.includes('--appearance-only'))return;
move(monitor.width/2,monitor.height/2);
if(!process.argv.includes('--submenu-only')){
await openSettings();const initialFrame=[status().settingsWidth,status().settingsHeight];await click('orb-tab-1');
for(const [name,value] of [['small',240],['medium',360],['large',480]]){
    await click('orb-size-'+name);assert.equal(status().draftDiameter,value);
    assert.deepEqual([status().settingsWidth,status().settingsHeight],initialFrame);
}
await click('orb-cancel');assert.equal(fs.readFileSync(config,'utf8'),fixtureText);
pass('Small, Medium and Large stage exact sizes without resizing Settings; Cancel preserves the saved size');
await openSettings();await click('orb-browse-actions');assert.equal(status().browsingActions,true);
const catalogScroll=control('orb-catalog-scrollbar'),firstChoiceY=control('orb-catalog-choice-0').y,outerScroll=status().settingsLayout.scroll;
move(catalogScroll.x-20,catalogScroll.y+catalogScroll.height/2,-1);await sleep(180);
assert.ok(!status().settingsControls.some(c=>c.name==='orb-catalog-choice-0')||control('orb-catalog-choice-0').y<firstChoiceY,'The catalog must scroll independently');
assert.equal(status().settingsLayout.scroll,outerScroll,'Catalog scrolling must leave the wheel in place');
await fill('orb-catalog-search','Files');await until(()=>status().pickerItems[0]==='Files');
const unassigned=JSON.stringify(status().draftActions);
let source=control('orb-catalog-choice-0');s=status();
const centre=[s.settingsX+s.preview.x+s.preview.diameter/2,s.settingsY+s.preview.y+s.preview.diameter/2];
move(source.x+source.width/2,source.y+source.height/2,272,centre);await sleep(120);assert.equal(JSON.stringify(status().draftActions),unassigned);
source=control('orb-catalog-choice-0');s=status();move(source.x+source.width/2,source.y+source.height/2,272,[s.settingsX+20,s.settingsY+20]);await sleep(120);assert.equal(JSON.stringify(status().draftActions),unassigned);
source=control('orb-catalog-choice-0');s=status();let destination=previewPoint(s,0);
assert.ok(destination[1]>=s.settingsY+s.settingsLayout.bodyY,'The wheel must remain visible beside the picker');
move(source.x+source.width/2,source.y+source.height/2,272,destination);await until(()=>status().draftActions[0].label==='Files','Catalog drag did not assign the slot');
assert.equal(status().browsingActions,true);assert.equal(fs.readFileSync(config,'utf8'),fixtureText);
s=status();move(...previewPoint(s,0),272,previewPoint(s,1));await until(()=>status().draftActions[1].label==='Files');assert.equal(status().browsingActions,true);
await click('orb-cancel');assert.equal(fs.readFileSync(config,'utf8'),fixtureText);
pass('Dragging from the searchable catalog assigns a draft slot; dropping in the centre or outside cancels; Cancel preserves the file');
await openSettings();await click('orb-browse-actions');await fill('orb-catalog-search','Files');
source=control('orb-catalog-choice-0');s=status();move(source.x+source.width/2,source.y+source.height/2,272,previewPoint(s,0));await until(()=>status().draftActions[0].label==='Files');
await fill('orb-catalog-search','Make something cool');source=control('orb-catalog-choice-0');s=status();move(source.x+source.width/2,source.y+source.height/2,272,previewPoint(s,5));await until(()=>status().draftActions[5].children?.length===3);
capture('editor-action-browser');await click('orb-tab-1');await click('orb-size-medium');await save();
assert.equal(saved().diameter,360);assert.equal(saved().actions[0].label,'Files');assert.equal(saved().actions[0].note,'Browser metadata');assert.equal(saved().actions[5].children.length,3);assert.equal(saved().custom,'preserve');
await openSettings();assert.equal(status().draftDiameter,360);assert.equal(status().draftActions[0].label,'Files');
await click('orb-browse-actions');await fill('orb-catalog-search','Ghostty');await until(()=>status().pickerItems.some(t=>t.toLowerCase().includes('ghostty')));key('Return');
assert.ok(status().draftActions[0].desktopId,'Keyboard assignment must retain the installed app desktop ID');await save();assert.ok(saved().actions[0].desktopId);
await openSettings();await click('orb-browse-actions');s=status();move(...previewPoint(s,2),272);assert.equal(status().selectedSlot,2);
await fill('orb-catalog-search','Screenshot');await click('orb-catalog-choice-0');assert.equal(status().draftActions[2].label,'Screenshot');await click('orb-cancel');assert.equal(saved().actions[2].label,'Files');assert.ok(saved().actions[0].desktopId);
pass('Several catalog assignments and a size preset save/reopen together, including submenus and app IDs; metadata and click/keyboard alternatives work');
await reset();
if(process.argv.includes('--catalog-only'))return;
await openSettings();capture('editor-shortcuts');
s=status();let from=previewPoint(s,0),to=previewPoint(s,2);move(...from,272,to);
await until(()=>status().draftActions[2].label==='Browser','Drag did not reorder');
await click('orb-cancel');assert.equal(fs.readFileSync(config,'utf8'),fixtureText);
pass('Real pointer drag changes the draft; Cancel leaves the saved arrangement unchanged');
await openSettings();chord('alt','Right');assert.equal(status().draftActions[1].label,'Browser');await save();
assert.equal(saved().actions[1].note,'Browser metadata');assert.equal(saved().custom,'preserve');
await openSettings();assert.equal(status().draftActions[1].label,'Browser');await save();
await openSettings();s=status();from=previewPoint(s,1);to=previewPoint(s,3);move(...from,272,to);await until(()=>status().draftActions[3].label==='Browser');await save();
assert.equal(saved().actions[3].note,'Browser metadata');
pass('Keyboard and pointer reordering save/reopen correctly, retain metadata, and unchanged Save finishes');
await reset();await openSettings();await click('orb-tab-2');await fill('orb-opening-key','F13');assert.equal(control('orb-save').enabled,false);
await fill('orb-opening-key','F12');await click('orb-modifier-Ctrl');await click('orb-desktop-click');capture('editor-opening');await save();
await until(()=>status().setupReady&&!status().setupError,'Opening controls did not register');
let binds=json('hyprctl','binds','-j');assert.equal(binds.filter(b=>b.key==='F12'&&b.modmask===76&&b.description.startsWith('Orb shortcut wheel [orb:')).length,1);
assert.equal(binds.filter(b=>b.key==='mouse:273'&&b.modmask===0&&b.description.startsWith('Orb on empty desktop [orb:')).length,1);
run('hyprctl','reload');await until(()=>json('hyprctl','binds','-j').some(b=>b.key==='F12'&&b.modmask===76&&b.description.startsWith('Orb shortcut wheel [orb:')),'Bindings did not recover after compositor reload');
await openSettings();await click('orb-tab-2');assert.equal(status().draftShortcut,'SUPER + CTRL + ALT + F12');assert.equal(status().draftDesktopRightClick,true);
await click('orb-modifier-Ctrl');await click('orb-modifier-Alt');await fill('orb-opening-key','O');const beforeConflict=fs.readFileSync(config,'utf8');await click('orb-save');
await until(()=>!status().settingsSaving&&status().settingsError.includes('already in use'));assert.equal(fs.readFileSync(config,'utf8'),beforeConflict);capture('editor-shortcut-conflict');await click('orb-cancel');
pass('Opening controls persist, bindings update and recover after reload, invalid keys are blocked, conflicts preserve the file and working bindings');
await reset();await openSettings();await click('orb-slot-0');await click('orb-action-mode-1');
await fill('orb-action-name','Argument check');await fill('orb-action-program',probe);await fill('orb-action-argument-0','hello world');await fill('orb-action-argument-1','$(literal)');
capture('editor-custom-command');await click('orb-action-use');await save();
assert.deepEqual(saved().actions[0].command,[probe,'hello world','$(literal)']);key('1');key('Return');await until(()=>fs.existsSync(output));assert.deepEqual(JSON.parse(fs.readFileSync(output,'utf8')),['hello world','$(literal)']);
pass('Custom command editor saves and launches a program with exact arguments, including spaces and shell punctuation');
}
await reset();await openSettings();await click('orb-slot-4');assert.equal(status().editorMode,2);await fill('orb-action-name','My tools');
await click('orb-action-edit-child-0');await until(()=>status().editingChild===0);await choose('Terminal');await until(()=>status().editingChild===-1);
assert.equal(status().editorChildren[0].label,'Terminal');await click('orb-action-add-child');await click('orb-child-mode-1');
await fill('orb-child-name','Submenu probe');await fill('orb-child-program',probe);await click('orb-child-add-argument');await fill('orb-child-argument-0','submenu argument');await click('orb-child-use');
await until(()=>status().editingChild===-1);await click('orb-action-up-child-2');await click('orb-action-remove-child-2');
assert.deepEqual(status().editorChildren.map(a=>a.label),['Terminal','Submenu probe']);capture('editor-submenu');await click('orb-action-use');await save();
assert.equal(saved().actions[4].children[0].note,'Themes metadata');assert.equal(saved().actions[4].label,'My tools');
key('5');key('Return');await until(()=>status().submenu==='My tools');assert.deepEqual(status().visibleItems,['Terminal','Submenu probe']);key('2');key('Return');await until(()=>JSON.parse(fs.readFileSync(output,'utf8'))[0]==='submenu argument');
await openSettings();await click('orb-slot-4');await click('orb-action-edit-child-1');await click('orb-child-mode-1');await fill('orb-child-name','Discard this');key('Escape');assert.equal(status().editorChildren[1].label,'Submenu probe');key('Escape');key('Escape');assert.equal(saved().actions[4].children[1].label,'Submenu probe');
pass('Submenu actions can be edited, added, reordered, removed, saved and launched; nested Cancel discards its draft');
await reset();await openSettings();await click('orb-add-slot');await choose('Themes');assert.equal(status().draftActions.length,7);await click('orb-add-slot');await choose('Postcard');assert.equal(status().draftActions.length,8);await save();
await openSettings();assert.equal(status().draftActions.length,8);key('Delete');key('Delete');key('Delete');key('Delete');assert.equal(status().draftActions.length,5);await save();
pass('The editor retains add/save/reopen/remove from five to eight shortcuts and prevents fewer than five');
for(const p of [[1,1],[monitor.width-1,1],[1,monitor.height-1],[monitor.width-1,monitor.height-1]]){
    ipc('shell','hide',id);move(...p);await openSettings();s=status();assert.ok(s.settingsX>=12&&s.settingsY>=12);assert.ok(s.settingsX+s.settingsWidth<=monitor.width-12&&s.settingsY+s.settingsHeight<=monitor.height-12);key('Escape');
}
pass('Settings remain inside the nested monitor at all four pointer corners');
}catch(error){
try{capture('editor-failure');fs.writeFileSync(path.join(repo,'artifacts/editor-failure.json'),JSON.stringify(status(),null,2));}catch{}
throw error;
}finally{
try{ipc('shell','hide',id);}catch{}
fs.writeFileSync(config,oldText);
fs.writeFileSync(path.join(repo,'artifacts/editor-live-results.json'),JSON.stringify({date:new Date().toISOString(),source:run('git','-C',repo,'rev-parse','HEAD'),workingTree:run('git','-C',repo,'status','--short'),runtimeHashes:Object.fromEntries(['ActionPicker.qml','ActionEditor.qml','SettingsPanel.qml','WheelPreview.qml','Wheel.qml','Model.js','OrbOverlay.qml','ShortcutHistory.js','AppLibraryCompat.qml'].map(f=>[f,require('node:crypto').createHash('sha256').update(fs.readFileSync(path.join(repo,f))).digest('hex')])),omarchy:run('git','-C',process.env.OMARCHY_PATH,'rev-parse','HEAD'),display:{width:monitor.width,height:monitor.height,scale:monitor.scale},report},null,2)+'\n');
}})().catch(error=>{console.error(error);process.exitCode=1;});
