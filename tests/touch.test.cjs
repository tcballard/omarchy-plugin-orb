const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const {spawnSync} = require('node:child_process');
const model = require('../TouchModel.js');
const config = require('../Model.js');
const example = require('../config.example.json');

test('Automatic requires an enabled provider, a real fold sensor and a definitive folded observation', () => {
    const yes = {ok:true,tabletEnabled:true,hasFoldSensor:true,folded:true};
    assert.equal(model.active('auto', yes), true);
    for (const status of [null, {}, {...yes,ok:false}, {...yes,tabletEnabled:false}, {...yes,hasFoldSensor:false}, {...yes,folded:null}, {...yes,folded:false}, {...yes,folded:'true'}]) assert.equal(!!model.active('auto',status), false);
    assert.equal(model.active('touch',null), true);
    assert.equal(model.active('desktop',yes), false);
});
test('touch output selection never follows a stale mouse or guesses between multiple internal panels', () => {
    const internal={name:'eDP-1',width:1024,height:768}, external={name:'DP-1',width:2560,height:1440};
    assert.equal(model.output('',[external,internal]),internal);
    assert.equal(model.output('DP-1',[external,internal]),external);
    assert.equal(model.output('eDP-2',[external,internal]),null);
    assert.equal(model.output('',[internal,{...internal,name:'DSI-1'}]),null);
    assert.equal(model.output('',[{...internal,width:0}]),null);
});
test('touch layouts keep large non-overlapping targets inside portrait, landscape and scaled viewports', () => {
    let radial=0, grid=0;
    for (const width of [240,320,568,744,1008]) for (const height of [160,320,568,744,1008])
    for (const count of [1,2,5,6,7,8]) for (const edge of ['left','right']) for (const shape of ['fan','ring']) for (const scale of [1,1.25,1.5]) {
        const geometry=model.layout(width,height,count,edge,shape,scale);
        assert.ok(geometry.size>=76);
        if (geometry.grid) {grid++;continue;}
        radial++;assert.equal(geometry.points.length,count);
        geometry.points.forEach((p,i)=>{
            assert.ok(p.x-geometry.size/2>=0 && p.x+geometry.size/2<=width);
            assert.ok(p.y-geometry.size/2>=0 && p.y+geometry.size/2<=height);
            assert.equal(model.hit(p.x,p.y,geometry),i);
            geometry.points.slice(i+1).forEach(q=>assert.ok(Math.abs(p.x-q.x)>=geometry.size || Math.abs(p.y-q.y)>=geometry.size,'hit boxes overlap'));
        });
    }
    assert.ok(radial>0 && grid>0);
});
test('tap, drag, long-press and cancellation cannot accidentally select another favourite', () => {
    const g=model.layout(744,744,6,'right','ring',1), a=g.points[0], b=g.points[2];
    const start=model.press(a.x,a.y,g);
    assert.equal(model.release(start,a.x,a.y,g,false),0);
    assert.equal(model.release(start,b.x,b.y,g,false),-1);
    assert.equal(model.release(start,b.x,b.y,g,true),2);
    assert.equal(model.release(start,0,0,g,true),-1);
    assert.equal(model.release({...start,held:true},a.x,a.y,g,true),-1);
    assert.equal(model.release(null,a.x,a.y,g,true),-1);
    const movedBack=model.move(model.move(start,b.x,b.y,g),a.x,a.y,g);
    assert.equal(model.release(movedBack,a.x,a.y,g,false),-1);
});
test('old settings remain Desktop; touch settings preserve unrelated metadata and reject concurrent edits', () => {
    const old=structuredClone(example);
    for (const key of Object.keys(old)) if (key.startsWith('touch') || key==='inputMode') delete old[key];
    old.custom={untouched:true};const before=config.parse(JSON.stringify(old),null).config;
    assert.equal(before.inputMode,'desktop');
    const edited={...before,inputMode:'touch',touchPosition:0.25};
    const saved=config.mergeSettings(old,before,edited);assert.equal(saved.error,'');
    assert.deepEqual(saved.document.custom,{untouched:true});assert.deepEqual(saved.document.actions,old.actions);
    const conflict=config.mergeSettings({...old,inputMode:'auto'},before,edited);assert.match(conflict.error,/changed elsewhere/);
    for (const patch of [{inputMode:'guess'},{touchPosition:NaN},{touchScale:0.5},{touchOutput:'bad\nname'},{touchDrag:1},{touchKeyboard:'exec'}])
        assert.ok(config.parse(JSON.stringify({...old,...patch}),null).error);
});
test('window metadata is bounded, literal and refreshed by address', () => {
    const rows=model.windows([{address:'0xa',title:'<img src=x>',workspace:{id:2,name:'two'},focusHistoryID:3}, {address:'0xb',title:'B',focusHistoryID:0}, {address:'injection'}]);
    assert.equal(rows.length,2);assert.equal(rows[0].address,'0xb');assert.equal(rows[1].title,'<img src=x>');
    assert.throws(()=>model.windows({}));
});

function fixture(fn) {
    const dir=fs.mkdtempSync(path.join(os.tmpdir(),'orb touch '));
    const bin=path.join(dir,'bin');fs.mkdirSync(bin);
    const log=path.join(dir,'calls');
    const put=(name,text)=>fs.writeFileSync(path.join(bin,name),text,{mode:0o755});
    put('omarchy-shell',`#!/usr/bin/env bash
if [[ $* == 'shell listPlugins' ]]; then cat "$ORB_FIXTURE/plugins.json"
elif [[ $1 == shell && $2 == summon ]]; then echo "\${ORB_REPLY:-ok}"
fi
printf '%s\\0' "$@" >> "$ORB_FIXTURE/calls"
`);
    put('hyprctl',`#!/usr/bin/env bash
if [[ $1 == -j ]]; then cat "$ORB_FIXTURE/$2.json"
elif [[ $1 == dispatch ]]; then printf '%s\\0' "$2" >> "$ORB_FIXTURE/calls"; echo "\${ORB_REPLY:-ok}"
else exit 1; fi
`);
    put('wtype','#!/bin/sh\nexit 0\n');
    const write=(name,data)=>fs.writeFileSync(path.join(dir,name+'.json'),JSON.stringify(data));
    write('plugins',[]);write('clients',[{address:'0xabc',mapped:true,title:'test'}]);write('workspaces',[{id:1,name:'1',monitor:'eDP-1'}]);write('monitors',[{name:'eDP-1'}]);
    const run=(args,env={})=>{
        const r=spawnSync('bash',[path.resolve(__dirname,'../scripts/touch'),...args],{encoding:'utf8',timeout:20000,env:{...process.env,PATH:bin+path.delimiter+process.env.PATH,XDG_CONFIG_HOME:path.join(dir,'config'),ORB_FIXTURE:dir,...env}});
        return {...r,json:JSON.parse(r.stdout)};
    };
    try {fn({run,write,put,dir,log});} finally {fs.rmSync(dir,{recursive:true,force:true});}
}
test('helper rejects command injection, stale windows and unavailable workspaces before dispatch',()=>fixture(({run,log})=>{
    for (const args of [['window','focus','0xabc;touch /tmp/no'],['window','focus','0xdef'],['window','move','0xabc','2'],['window','move','0xabc','1;bad'],['workspace','999'],['brightness','up','missing']]) {
        const r=run(args);assert.notEqual(r.status,0);assert.equal(r.json.ok,false);
    }
    assert.equal(fs.existsSync(log),false);
    assert.equal(run(['window','focus','0xabc']).json.ok,true);
    assert.match(fs.readFileSync(log,'utf8'),/address:0xabc/);
}));
test('an exit-zero compositor or shell refusal is still a failure',()=>fixture(({run,write})=>{
    assert.equal(run(['window','maximize','0xabc'],{ORB_REPLY:'invalid dispatcher'}).json.ok,false);
    write('plugins',[{id:'m44f4.omatouch',enabled:true}]);
    assert.equal(run(['keyboard','omatouch','show'],{ORB_REPLY:'unknown'}).json.ok,false);
}));
test('keyboard only invokes an enabled selected provider, and remaps above Orb before typing',()=>fixture(({run,write,log})=>{
    assert.equal(run(['keyboard','auto','show']).json.ok,false);
    write('plugins',[{id:'m44f4.omatouch',enabled:false}]);assert.equal(run(['keyboard','auto','show']).json.ok,false);
    write('plugins',[{id:'m44f4.omatouch',enabled:true}]);assert.equal(run(['keyboard','tablet','show']).json.ok,false);
    fs.writeFileSync(log,'');assert.equal(run(['keyboard','omatouch','show']).json.ok,true);
    const calls=fs.readFileSync(log,'utf8');assert.ok(calls.indexOf('hide')<calls.indexOf('summon'));
    assert.equal(run(['status']).json.keyboard,'omatouch');
}));
test('missing and disabled tablet providers cannot turn on Automatic mode',()=>fixture(({run,write})=>{
    write('plugins',[{id:'andreiyurik.tablet-mode',enabled:false}]);
    const r=run(['status']);assert.equal(r.json.tabletEnabled,false);assert.equal(r.json.hasFoldSensor,false);assert.equal(r.json.folded,null);
}));
