const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const model = require('../Model.js');

test('bundled helper URLs decode to literal local paths', () => {
    assert.equal(model.localPath('file:///home/user/My%20plugins/orb/scripts/launch'), '/home/user/My plugins/orb/scripts/launch');
    assert.equal(model.localPath('file:///opt/a%23b/scripts/agents'), '/opt/a#b/scripts/agents');
});

test('QML resolves bundled helpers only through Model.localPath', () => {
    for (const file of fs.readdirSync(`${__dirname}/..`).filter(f => f.endsWith('.qml'))) {
        const source = fs.readFileSync(`${__dirname}/../${file}`, 'utf8');
        assert.doesNotMatch(source, /resolvedUrl\("scripts\/[^"]*"\)\.toString\(\)/, `${file} strips a helper URL by hand`);
    }
});
