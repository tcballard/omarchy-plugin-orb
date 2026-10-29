const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),os=require('node:os'),path=require('node:path');
const {spawnSync}=require('node:child_process'),model=require('../Model.js'),example=require('../config.example.json');
const clone=x=>structuredClone(x),parse=x=>model.parse(JSON.stringify(x),null).config;
test('named wheels switch fixed positions, save old edits and preserve metadata',()=>{
 const doc=clone(example);doc.custom={keep:true};doc.actions[0].note='keep';
 const before=parse(doc),draft=clone(before);draft.wheels.push({id:'code',name:'Code',actions:clone(doc.actions).reverse()});draft.activeWheel='code';draft.actions[0].label='Edited';draft.actionOrigins=before.actions.map((_,i)=>i);
 const result=model.mergeSettings(doc,before,draft);assert.equal(result.error,'');
 assert.equal(result.document.actions[0].label,doc.actions.at(-1).label);
 assert.equal(result.document.wheels[0].actions[0].label,'Edited');assert.equal(result.document.wheels[0].actions[0].note,'keep');assert.deepEqual(result.document.custom,doc.custom);
 const next=parse(result.document),back=model.mergeSettings(result.document,next,{...next,activeWheel:'everyday'});
 assert.equal(back.error,'');assert.equal(back.document.actions[0].label,'Edited');
});
test('legacy saves do not invent library fields; library conflicts reject without losing other edits',()=>{
 const doc=clone(example),original=parse(doc);assert.deepEqual(model.mergeSettings(doc,original,clone(original)).document,doc);
 const draft=clone(original);draft.wheels[0].name='Travel';
 const changed=clone(doc);changed.actions[0].label='Other editor';
 assert.match(model.mergeSettings(changed,original,draft).error,/changed elsewhere/);
 const setups=[{id:'code',name:'Code',workspace:3,layout:'columns',apps:['org.test.App']}];
 const saved=model.mergeSettings(doc,original,{...original,setups});assert.equal(saved.error,'');assert.deepEqual(saved.document.setups,setups);
 assert.match(model.mergeSettings({...doc,setups:[{...setups[0],name:'Other'}]},original,{...original,setups}).error,/changed elsewhere/);
});
test('invalid wheels and work setups fail validation',()=>{
 const doc=clone(example),before=parse(doc);
 for(const patch of [{activeWheel:'missing'},{wheels:[]},{wheels:[before.wheels[0],before.wheels[0]]},{wheels:[{...before.wheels[0],actions:[]}]},{setups:[{id:'x',name:'X',workspace:0,layout:'columns',apps:['ok']}]},{setups:[{id:'x',name:'X',workspace:1,layout:'columns',apps:['bad;command']}] }])assert.ok(model.parse(JSON.stringify({...doc,...patch}),null).error);
 assert.deepEqual(model.action({label:'Work',icon:'terminal',menu:'setups'},0),{label:'Work',icon:'terminal',menu:'setups'});
});
test('wheel transfer bundles icons, previews without writing, and binds import to the reviewed content',()=>{
 const dir=fs.mkdtempSync(path.join(os.tmpdir(),'orb share ')),dest=path.join(dir,'wheel.orb.json'),data=path.join(dir,'data');
 const run=(verb,value='')=>spawnSync('bash',[path.resolve(__dirname,'../scripts/layout-share'),verb,dest,value],{encoding:'utf8',env:{...process.env,XDG_DATA_HOME:data}});
 try {
  const icon=path.join(dir,'custom.svg');fs.writeFileSync(icon,'<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"><rect width="16" height="16" fill="red"/></svg>');
  const wheel={name:'Travel',actions:clone(example.actions)};wheel.actions[0].icon=icon;wheel.actions[0].private='do not export';
  let r=run('export',JSON.stringify(wheel));assert.equal(r.status,0,r.stderr+r.stdout);
  const pkg=JSON.parse(fs.readFileSync(dest));assert.equal(pkg.wheel.actions[0].private,undefined);assert.equal(Object.keys(pkg.assets).length,1);
  r=run('preview');assert.equal(r.status,0,r.stderr+r.stdout);const preview=JSON.parse(r.stdout);assert.equal(fs.existsSync(data),false);
  fs.appendFileSync(dest,' ');assert.notEqual(run('import',preview.digest).status,0);assert.equal(fs.existsSync(data),false);
  r=run('preview');const current=JSON.parse(r.stdout);r=run('import',current.digest);assert.equal(r.status,0,r.stderr+r.stdout);
  const imported=JSON.parse(r.stdout).wheel;assert.equal(fs.readFileSync(imported.actions[0].icon,'utf8'),fs.readFileSync(icon,'utf8'));
  fs.writeFileSync(imported.actions[0].icon,'corrupt');assert.notEqual(run('import',current.digest).status,0);
  for(const bad of [{...pkg,assets:{}},{...pkg,assets:{'../escape':'abc'}},{...pkg,version:999}]){fs.writeFileSync(dest,JSON.stringify(bad));assert.notEqual(run('preview').status,0);}
 } finally {fs.rmSync(dir,{recursive:true,force:true});}
});
