const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const model = require('../Model.js');
const base = JSON.parse(fs.readFileSync(`${__dirname}/../config.example.json`, 'utf8'));
const sig = document => JSON.stringify(model.bindingSignature(document));

test('a text mouse code and a number mouse code select the same button', () => {
    assert.equal(sig({ mouseOpen: true, mouseButton: '275' }), sig({ mouseOpen: true, mouseButton: 275 }));
    assert.notEqual(sig({ mouseOpen: true, mouseButton: '275' }), sig({ mouseOpen: true, mouseButton: '276' }));
    assert.equal(sig({ mouseOpen: true }), sig({ mouseOpen: true, mouseButton: null }));
    assert.equal(JSON.parse(sig({ mouseOpen: true }))[3], 277);
});

test('an invalid mouse code does not fall back to button 277 while the option is on', () => {
    assert.equal(JSON.parse(sig({ mouseOpen: true, mouseButton: 'abc' }))[3], 0);
    assert.equal(JSON.parse(sig({ mouseOpen: true, mouseButton: 'nope' }))[3], 0);
    assert.notEqual(sig({ mouseOpen: true, mouseButton: 'abc' }), sig({ mouseOpen: true, mouseButton: 277 }));
    const invalid = { ...base, mouseOpen: true, mouseButton: 'abc' };
    assert.match(model.parse(JSON.stringify(invalid), null).error, /275/);
});

test('the mouse code does not change the bind while the option is off', () => {
    assert.equal(sig({ mouseOpen: false, mouseButton: 275 }), sig({ mouseOpen: false, mouseButton: 276 }));
    assert.equal(JSON.parse(sig({ shortcut: 'SUPER + ALT + O', desktopRightClick: false, mouseOpen: false, mouseButton: 275 }))[3], 0);
    const stored = { ...base, mouseOpen: false, mouseButton: 275 };
    const parsed = model.parse(JSON.stringify(stored), null);
    assert.equal(parsed.error, '');
    assert.equal(parsed.config.mouseOpen, false);
    assert.equal(parsed.config.mouseButton, 275);
});
