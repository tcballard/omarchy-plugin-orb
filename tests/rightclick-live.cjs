require('./host-desktop.cjs');
const {execFileSync:e}=require('node:child_process');const fs=require('node:fs'),assert=require('node:assert/strict'),path=require('node:path');
const repo=path.resolve(__dirname,'..');const run=(c,...a)=>e(c,a.map(String),{encoding:'utf8',timeout:15000}).trim();const json=(c,...a)=>JSON.parse(run(c,...a));
const id='io.github.tcballard.orb',ipc=(...a)=>run('omarchy-shell',...a),status=()=>JSON.parse(ipc(id,'status'));const sleep=t=>new Promise(r=>setTimeout(r,t));
async function until(f,message){for(let i=0;i<100;i++){const v=f();if(v)return v;await sleep(100);}throw Error(message);}
const original={pointer:json('hyprctl','cursorpos','-j'),focus:json('hyprctl','activewindow','-j').address,workspace:json('hyprctl','activeworkspace','-j').id};
const move=(x,y,b=0)=>run(repo+'/artifacts/input/pointer',Math.round(x),Math.round(y),1920,1200,b);
const key=k=>run('wtype','-s','80','-k',k,'-s','80');let testWindow=null;const report=[];const pass=s=>{report.push(s);console.log('PASS:',s);};
(async()=>{try{
 assert.equal(run('hyprctl','configerrors'),'');
 const binds=json('hyprctl','binds','-j');assert.equal(binds.filter(b=>b.description==='Orb on empty desktop').length,1);assert.ok(binds.some(b=>b.key==='mouse:273'&&b.modmask===64&&b.description==='Resize window'));
 ipc('shell','hide',id);assert.ok(!json('hyprctl','clients','-j').some(w=>w.workspace.name==='orb-rightclick-test'));
 run('hyprctl','dispatch','hl.dsp.focus({workspace="name:orb-rightclick-test"})');await sleep(350);
 move(960,500,273);await until(()=>status().opened&&status().opacity===1,'Desktop right-click did not open Orb');await sleep(180);key('Escape');await until(()=>!status().opened,'Escape did not dismiss Orb');
 pass('Real right-click on empty desktop opens Orb; Escape dismisses');
 move(960,500,272);await sleep(200);assert.equal(status().opened,false);pass('Left-click remains unchanged; Super+right-click resize binding preserved');
 const before=json('hyprctl','clients','-j').map(w=>w.address);run('hyprctl','dispatch','hl.dsp.exec_cmd("omarchy launch nautilus")');
 testWindow=await until(()=>json('hyprctl','clients','-j').find(w=>!before.includes(w.address)&&/nautilus/i.test(w.class)),'Test Files window did not open');await sleep(400);
 move(testWindow.at[0]+testWindow.size[0]*.75,testWindow.at[1]+testWindow.size[1]*.5,273);await sleep(350);assert.equal(status().opened,false);
 run('grim','-o','eDP-1',repo+'/artifacts/orb-app-rightclick.png');key('Escape');pass('Right-click inside Files passes through without opening Orb; context-menu still captured');
 run('hyprctl','dispatch',`hl.dsp.window.close({window="address:${testWindow.address}"})`);testWindow=null;
 assert.equal(run('hyprctl','configerrors'),'');pass('Hyprland configuration remains clean');
}finally{
 ipc('shell','hide',id);if(testWindow)run('hyprctl','dispatch',`hl.dsp.window.close({window="address:${testWindow.address}"})`);
 run('hyprctl','dispatch',`hl.dsp.focus({workspace="${original.workspace}"})`);if(original.focus)run('hyprctl','dispatch',`hl.dsp.focus({window="address:${original.focus}"})`);move(original.pointer.x,original.pointer.y);
 fs.writeFileSync(repo+'/artifacts/rightclick-live-results.json',JSON.stringify({date:new Date().toISOString(),report},null,2));
}})().catch(e=>{console.error(e);process.exitCode=1;});
