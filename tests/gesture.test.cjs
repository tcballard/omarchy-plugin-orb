const test = require('node:test');
const assert = require('node:assert/strict');
const gesture = require('../Gesture.js');
const model = require('../Model.js');
const owner = '1792450000000-123456789';
const event = (type, x, y, elapsed = 0) => ({type, x, y, elapsed});

test('only valid, owner-scoped compositor events are accepted', () => {
    assert.deepEqual(gesture.parse(`orb/${owner}/press/-22.500,140.000/0`, owner), event('press', -22.5, 140));
    for (const input of [
        `orb/other/press/1,2/0`, `orb/${owner}/launch/1,2/0`, `orb/${owner}/release/NaN,2/0`,
        `orb/${owner}/release/1000001,2/0`, `orb/${owner}/press/1,2/0\n`,
        `orb/${owner}/press/1,2/0;command`, `orb/${owner}/release/1,2/6001`
    ]) assert.equal(gesture.parse(input, owner), null);
});

test('a short stationary tap opens; a held centre or returned-to-centre gesture cancels', () => {
    const start = gesture.begin(event('press', 120, 120));
    assert.equal(gesture.outcome(gesture.update(start, event('release', 122, 121, 150))), 'tap');
    assert.equal(gesture.outcome(gesture.update(start, event('release', 120, 120, 400))), 'cancel');
    const moved = gesture.update(start, event('move', 120, 40, 100));
    const returned = gesture.update(moved, event('release', 120, 120, 200));
    assert.equal(gesture.outcome(returned), 'select');
    assert.equal(model.hit(returned.currentX, returned.currentY, 240, 6, 'circle'), -1);
});

test('a moved release selects the actual radial sector and cannot activate twice', () => {
    const start = gesture.begin(event('press', 120, 120));
    const moved = gesture.update(start, event('move', 120, 40, 100));
    const released = gesture.update(moved, event('release', 120, 40, 200));
    assert.equal(gesture.outcome(released), 'select');
    assert.equal(model.hit(released.currentX, released.currentY, 240, 6, 'circle'), 0);
    assert.strictEqual(gesture.update(released, event('release', 200, 120, 300)), released);
    assert.equal(model.hit(0, 0, 240, 6, 'circle'), -1);
});
