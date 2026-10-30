const assert = require('node:assert/strict');
const fs = require('node:fs');
const model = require('../Model.js');
const clone = value => JSON.parse(JSON.stringify(value));
const base = JSON.parse(fs.readFileSync(`${__dirname}/../config.example.json`, 'utf8'));
base.actions[0].note = 'keep with Browser';
base.actions[4].note = 'keep with submenu';
base.actions[4].children[0].note = 'keep with Themes';
const original = model.parse(JSON.stringify(base), null).config;
const draft = () => ({...clone(original), actionOrigins: original.actions.map((_, i) => i),
    childOrigins: original.actions.map(a => a.children ? a.children.map((_, i) => i) : [])});

for (const count of [6, 7, 8]) {
    const list = Array.from({length: count}, (_, i) => i);
    for (let from = 0; from < count; from++) for (let to = 0; to < count; to++) {
        const moved = model.move(list, from, to);
        assert.equal(moved[to], from);
        assert.deepEqual([...moved].sort(), list);
        assert.deepEqual(list, Array.from({length: count}, (_, i) => i));
    }
}
const reordered = draft();
for (const key of ['actions', 'actionOrigins', 'childOrigins']) reordered[key] = model.move(reordered[key], 0, 4);
const result = model.mergeSettings(base, original, reordered);
assert.equal(result.error, '');
assert.equal(result.document.actions[4].label, 'Browser');
assert.equal(result.document.actions[4].note, base.actions[0].note);
assert.equal(result.document.actions[3].note, base.actions[4].note);
const concurrent = clone(base); concurrent.actions[2].label = 'Elsewhere';
assert.match(model.mergeSettings(concurrent, original, reordered).error, /changed elsewhere/);
const metadataOnly = clone(base); metadataOnly.actions[0].note = 'new metadata';
assert.equal(model.mergeSettings(metadataOnly, original, reordered).document.actions[4].note, 'new metadata');
const badOrder = draft(); badOrder.actionOrigins[1] = 0;
assert.match(model.mergeSettings(base, original, badOrder).error, /Invalid shortcut arrangement/);
console.log('PASS: all drag destinations, keyboard movement, moved metadata and concurrent reorder conflicts');

const edited = draft();
edited.actions[4].label = 'My tools';
edited.actions[4].children.reverse(); edited.childOrigins[4].reverse();
edited.actions[4].children[1].label = 'Theme picker';
const submenu = model.mergeSettings(base, original, edited);
assert.equal(submenu.error, '');
assert.equal(submenu.document.actions[4].note, 'keep with submenu');
assert.equal(submenu.document.actions[4].children[1].note, 'keep with Themes');
assert.equal(submenu.document.actions[4].children[1].label, 'Theme picker');
const custom = draft();
custom.actions[4] = {label: 'Print literal', icon: 'terminal', command: ['printf', '%s', 'a b', '$(touch /tmp/orb-never)', '', 'a"b']};
const command = model.mergeSettings(base, original, custom);
assert.equal(command.error, '');
assert.deepEqual(command.document.actions[4].command, custom.actions[4].command);
assert.equal(command.document.actions[4].children, undefined);
assert.equal(command.document.actions[4].note, 'keep with submenu');
for (const n of [0, 13]) {
    const invalid = draft(); invalid.actions[4].children = Array.from({length:n}, () => clone(original.actions[0]));
    assert.ok(model.mergeSettings(base, original, invalid).error);
}
const nested = draft(); nested.actions[4].children[0] = clone(original.actions[4]);
assert.ok(model.mergeSettings(base, original, nested).error);
console.log('PASS: submenu editing/reordering preserves metadata, command arguments remain literal, nesting and counts validated');

for (const [input, canonical, mask, key] of [
    ['super + alt + p', 'SUPER + ALT + P', 72, 'P'],
    ['SHIFT + SUPER + CTRL + F12', 'SUPER + CTRL + SHIFT + F12', 69, 'F12'],
    ['SUPER + SPACE', 'SUPER + SPACE', 64, 'SPACE']
]) assert.deepEqual(model.shortcut(input), {value:canonical, mask, key, error:''});
for (const input of ['', 'ALT + O', 'SUPER + SUPER + O', 'SUPER + O + ALT', 'SUPER + F13', 'SUPER + ;', null]) assert.ok(model.shortcut(input).error);
assert.equal(model.bindingConflict([{key:'P',modmask:72,description:'Other app'}], 'SUPER + ALT + P', false), 'SUPER + ALT + P is already in use. Choose another shortcut.');
assert.equal(model.bindingConflict([{key:'P',modmask:72,description:'Orb shortcut wheel [orb:123-456]'}], 'SUPER + ALT + P', false), '');
assert.match(model.bindingConflict([{key:'mouse:273',modmask:0}], 'SUPER + ALT + P', true), /right-click is already in use/);
assert.equal(model.bindingConflict([{key:'mouse:273',modmask:64}], 'SUPER + ALT + P', true), '');
const opening = draft(); opening.shortcut = 'SUPER + CTRL + F12'; opening.desktopRightClick = true;
const activation = model.mergeSettings(base, original, opening);
assert.equal(activation.error, ''); assert.equal(activation.document.shortcut, opening.shortcut); assert.equal(activation.document.desktopRightClick, true);
const changed = clone(base); changed.shortcut = 'SUPER + SHIFT + F11';
assert.match(model.mergeSettings(changed, original, opening).error, /shortcut setting changed elsewhere/);
const external = clone(base); external.animation = false; external.desktopRightClick = true;
assert.equal(model.mergeSettings(external, original, draft()).document.animation, false);
assert.equal(model.mergeSettings(external, original, draft()).document.desktopRightClick, true);
assert.equal(model.mouseButton(undefined).value, 277);
assert.equal(model.mouseButton(277).error, '');
assert.equal(model.mouseButton('275').value, 275);
for (const bad of [271, 272, 273, 274, 512, 277.5, '27', '277 ', 'mouse:277', true, false]) assert.ok(model.mouseButton(bad).error);
assert.equal(model.mouseButton(511).value, 511);
const omitted = clone(base); delete omitted.mouseOpen; delete omitted.mouseButton;
const omittedConfig = model.parse(JSON.stringify(omitted), null).config;
assert.equal(omittedConfig.mouseOpen, false); assert.equal(omittedConfig.mouseButton, 277);
const enabled = clone(base); enabled.mouseOpen = true; enabled.mouseButton = 275;
assert.equal(model.parse(JSON.stringify(enabled), null).config.mouseButton, 275);
enabled.mouseButton = 273; enabled.desktopRightClick = true;
assert.match(model.parse(JSON.stringify(enabled), null).error, /extra mouse/);
enabled.mouseButton = 275; enabled.desktopRightClick = false;
assert.equal(model.parse(JSON.stringify(enabled), null).error, '');
assert.match(model.bindingConflict([{key:'mouse:277', modmask:0, description:'Other'}], 'SUPER + ALT + O', false, true, 277), /already in use/);
assert.match(model.bindingConflict([{key:'mouse:277', modmask:64, description:'User chord'}], 'SUPER + ALT + O', false, true, '277'), /already in use/);
assert.equal(model.bindingConflict([{key:'mouse:277', modmask:0, description:'Orb mouse button [orb:1-2]'}], 'SUPER + ALT + O', false, true, 277), '');
assert.match(model.bindingConflict([], 'SUPER + ALT + O', true, true, 273), /extra mouse/);
assert.equal(model.bindingConflict([], 'SUPER + ALT + O', false, false, 277), '');
assert.equal(model.parse(JSON.stringify({...base, mouseOpen:true, mouseButton:'276'}), null).config.mouseButton, 276);
const mouseDraft = draft(); mouseDraft.mouseOpen = true; mouseDraft.mouseButton = 276;
const mouseSaved = model.mergeSettings(base, original, mouseDraft);
assert.equal(mouseSaved.error, ''); assert.equal(mouseSaved.document.mouseOpen, true); assert.equal(mouseSaved.document.mouseButton, 276);
const mouseElsewhere = clone(base); mouseElsewhere.mouseButton = 275;
assert.match(model.mergeSettings(mouseElsewhere, original, mouseDraft).error, /mouseButton/);
console.log('PASS: opening settings, shortcut grammar, key/desktop/mouse conflicts and concurrent scalar edits');
