const assert = require('node:assert/strict');
const fs = require('node:fs');
const model = require('../Model.js');
const defaults = model.parse(fs.readFileSync(`${__dirname}/../config.example.json`, 'utf8'), null);
assert.equal(defaults.error, '');
assert.equal(defaults.config.actions.length, 6);
assert.equal(defaults.config.mouseOpen, false);
assert.equal(defaults.config.mouseButton, 277);
assert.equal(defaults.config.diameter, 240);
assert.equal(defaults.config.actions[5].menu, 'agents');
assert.equal(defaults.config.actions[4].children[1].label, 'Plugins');
const tooDeep = JSON.parse(fs.readFileSync(`${__dirname}/../config.example.json`, 'utf8'));
tooDeep.actions[4].children[0] = {label:'More',icon:'settings',children:[tooDeep.actions[0]]};
assert.ok(model.parse(JSON.stringify(tooDeep), defaults.config).error);
const ambiguous = JSON.parse(fs.readFileSync(`${__dirname}/../config.example.json`, 'utf8'));
ambiguous.actions[5].command=['false'];
assert.ok(model.parse(JSON.stringify(ambiguous), defaults.config).error);
assert.equal(model.parse('{', defaults.config).config, defaults.config);
assert.ok(model.parse('{"actions":[]}', defaults.config).error);
const adversarial = JSON.parse(fs.readFileSync(`${__dirname}/../config.example.json`, 'utf8'));
adversarial.actions[0].command = ['sh', null];
assert.ok(model.parse(JSON.stringify(adversarial), defaults.config).error);
adversarial.actions[0].command = ['printf', '$(touch /tmp/no)'];
adversarial.actions[0].label = '<img src="x">';
assert.equal(model.parse(JSON.stringify(adversarial), defaults.config).config.actions[0].label, '<img src="x">');
for (const size of [240, 280, 340, 440, 600]) {
  assert.equal(model.hit(size / 2, size / 2, size), -1);
  assert.equal(model.hit(-10, -10, size), -1);
  for (let i = 0; i < 6; i++) {
    const angle = (i * 60 - 90) * Math.PI / 180;
    assert.equal(model.hit(size/2 + Math.cos(angle)*size*.33, size/2 + Math.sin(angle)*size*.33, size), i);
  }
}
// Each submenu retains radial hit regions, including single-action and empty states.
for (const count of [0,1,2,3,4,5,6]) {
  assert.equal(model.hit(140,140,280,count),-1);
  if (!count) assert.equal(model.hit(140,45,280,count),-1);
  for (let i=0;i<count;i++) {
    const angle=(i*360/count-90)*Math.PI/180;
    assert.equal(model.hit(140+Math.cos(angle)*92,140+Math.sin(angle)*92,280,count),i);
    for (const offset of [-.45,.45]) {
      const edge=(i*360/count+offset*360/count-90)*Math.PI/180;
      assert.equal(model.hit(140+Math.cos(edge)*92,140+Math.sin(edge)*92,280,count),i);
    }
  }
}
// Corners, off-screen cursor, bars on each edge, logical fractional-scale dimensions.
for (const [w,h] of [[1920,1200],[1280,800],[800,600]]) {
  for (const reserved of [[0,30,0,0],[55,0,0,0],[0,0,60,45]]) {
    for (const [x,y] of [[0,0],[w,0],[0,h],[w,h],[-100,-100],[w/2,h/2]]) {
      for (const preferred of [240, 440, 700]) {
      const p = model.placement(x,y,w,h,reserved,preferred);
      assert.ok(p.x >= reserved[0]); assert.ok(p.y >= reserved[1]);
      assert.ok(p.x+p.size <= w-reserved[2]);
      assert.ok(p.y+p.size+p.footer <= h-reserved[3]);
      }
    }
  }
}
console.log('PASS: six sectors, dead zone, config validation, all edges and reserved bounds');

const app = {label:'Files',icon:'app',desktopId:'org.gnome.Nautilus'};
const base = JSON.parse(fs.readFileSync(`${__dirname}/../config.example.json`, 'utf8'));
const clone = value => JSON.parse(JSON.stringify(value));
const original = model.parse(JSON.stringify(base), null).config;
const draft = clone(original); draft.actions[3] = app;
const current = clone(base); current.shortcut = 'SUPER + ALT + P'; current.actions[0].extra = 'keep';
current.actions[2].label = 'Documents'; current.diameter = 300;
const merged = model.mergeSettings(current, original, draft);
assert.equal(merged.error, ''); assert.deepEqual(merged.document.actions[3], app);
assert.equal(merged.document.actions[2].label, 'Documents');
assert.equal(merged.document.actions[0].extra, 'keep');
assert.equal(merged.document.diameter, 300); assert.equal(merged.document.shortcut, current.shortcut);
current.actions[3].label = 'Capture elsewhere';
assert.match(model.mergeSettings(current, original, draft).error, /Slot 4 changed elsewhere/);
for (const bad of ['../escape', '/usr/bin/app', 'bad\napp', '', 'x'.repeat(256)]) {
    const invalid = clone(base); invalid.actions[3] = {...app, desktopId:bad};
    assert.ok(model.parse(JSON.stringify(invalid), null).error);
}
for (const extra of [{command:['true']}, {menu:'agents'}, {children:[app]}]) {
    const invalid = clone(base); invalid.actions[3] = {...app,...extra};
    assert.ok(model.parse(JSON.stringify(invalid), null).error);
}
const allowed = clone(base); allowed.actions[3] = app;
assert.deepEqual(model.parse(JSON.stringify(allowed), null).config.actions[3], app);
const postcard = {label:'Postcard', icon:'postcard', command:['omarchy-shell','shell','summon','tahayvr.postcard','{}']};
for (let i=0;i<6;i++) {
    const allSlots=clone(original); allSlots.actions[i]=postcard;
    assert.deepEqual(model.mergeSettings(base, original, allSlots).document.actions[i], postcard);
}
console.log('PASS: every slot editable, app IDs validated, untouched settings preserved, concurrent slot conflicts rejected');

for (const count of [5,6,7,8]) {
  const expanded = clone(base);
  while (expanded.actions.length < count) expanded.actions.push(postcard);
  expanded.actions.length=count;
  assert.equal(model.parse(JSON.stringify(expanded), null).error, '');
  for (let slot=0;slot<count;slot++) {
    const angle=(slot*360/count-90)*Math.PI/180;
    assert.equal(model.hit(128.5+Math.cos(angle)*85,128.5+Math.sin(angle)*85,257,count),slot);
  }
}
for (const count of [4,9]) {
  const invalid=clone(base);while(invalid.actions.length<count)invalid.actions.push(postcard);invalid.actions.length=count;
  assert.ok(model.parse(JSON.stringify(invalid),null).error);
}
const expandedDraft=clone(original);expandedDraft.actions.push(postcard,app);
const metadata=clone(base);metadata.actions[0].custom='preserve';metadata.desktopRightClick=true;
const added=model.mergeSettings(metadata,original,expandedDraft);
assert.equal(added.error,'');assert.equal(added.document.actions.length,8);assert.equal(added.document.actions[0].custom,'preserve');assert.equal(added.document.desktopRightClick,true);
const eight=model.parse(JSON.stringify(added.document),null).config;
const reduced=clone(eight);reduced.actions.splice(1,1);reduced.actions.pop();
const removed=model.mergeSettings(added.document,eight,reduced);
assert.equal(removed.error,'');assert.equal(removed.document.actions.length,6);assert.equal(removed.document.actions[1].label,'Files');assert.equal(removed.document.actions[0].custom,'preserve');
const concurrentlyEdited=clone(base);concurrentlyEdited.actions[1].label='Different';
assert.match(model.mergeSettings(concurrentlyEdited,original,expandedDraft).error,/changed elsewhere/);
assert.equal(model.mergeSettings(added.document,original,original).document.actions.length,8);
console.log('PASS: 5–8 slots, radial hit regions, add/remove persistence, metadata preservation and structural conflicts');
