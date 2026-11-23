require('./host-desktop.cjs');
// Real still on an empty workspace; no recording or configuration edits.
const {execFileSync}=require('node:child_process');
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const repo=path.resolve(__dirname,'..');
const run=(cmd,...args)=>execFileSync(cmd,args.map(String),{encoding:'utf8',timeout:15000}).trim();
const json=(...args)=>JSON.parse(run(...args));
const id='io.github.tcballard.orb',ipc=(...args)=>run('omarchy-shell',...args);
const state=()=>JSON.parse(ipc(id,'status')),sleep=ms=>new Promise(r=>setTimeout(r,ms));
const saved={workspace:json('hyprctl','activeworkspace','-j').id,focus:json('hyprctl','activewindow','-j').address,pointer:json('hyprctl','cursorpos','-j')};
const move=(x,y)=>run(repo+'/artifacts/input/pointer',Math.round(x),Math.round(y),1920,1200,0);
(async()=>{try {
  const monitor=json('hyprctl','monitors','-j').find(m=>m.focused);
  assert.ok(monitor.width===1920&&monitor.height===1200&&monitor.scale===1&&monitor.transform===0);
  assert.ok(!json('hyprctl','clients','-j').some(w=>w.workspace.name==='orb-preview'));
  ipc('shell','hide',id);
  run('hyprctl','dispatch','hl.dsp.focus({workspace="name:orb-preview"})');
  await sleep(400);move(960,500);ipc('shell','summon',id,'{}');
  for(let i=0;i<100&&state().opacity!==1;i++)await sleep(100);
  assert.equal(state().opacity,1);await sleep(250);
  run('wtype','-k','1');await sleep(150);
  const s=state(),output=repo+'/artifacts/preview.png';
  assert.equal(json('hyprctl','activeworkspace','-j').name,'orb-preview','Workspace changed during capture');
  assert.ok(!json('hyprctl','monitors','-j').find(m=>m.focused).specialWorkspace?.id,'A special workspace covers the preview');
  assert.ok(!json('hyprctl','clients','-j').some(w=>w.mapped&&!w.hidden&&(w.pinned||w.workspace.name==='orb-preview')),'A window covers the preview');
  run('grim','-g',`${Math.floor(s.x-16)},${Math.floor(s.y-16)} ${Math.ceil(s.diameter+32)}x${Math.ceil(s.diameter+s.footerHeight+32)}`,output);
  fs.writeFileSync(repo+'/artifacts/preview-provenance.json',JSON.stringify({date:new Date().toISOString(),input_commit:run('git','-C',repo,'rev-parse','HEAD'),output,diameter:s.diameter,items:s.visibleItems,caption:s.selectionCaption,monitor:monitor.name},null,2)+'\n');
  console.log('Captured '+output);
} finally {
  ipc('shell','hide',id);
  run('hyprctl','dispatch',`hl.dsp.focus({workspace="${saved.workspace}"})`);
  if(saved.focus)run('hyprctl','dispatch',`hl.dsp.focus({window="address:${saved.focus}"})`);
  move(saved.pointer.x,saved.pointer.y);
}})().catch(error=>{console.error(error);process.exitCode=1;});
