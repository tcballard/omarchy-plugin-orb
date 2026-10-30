const test = require('node:test');
const assert = require('node:assert/strict');
const model = require('../Model.js');

test('custom images and new built-in icons survive validation for commands and submenus', () => {
    const leaf = {label: 'A command', icon: '/home/user/My icons/a #1.svg', command: ['true']};
    const menu = {label: 'My menu', icon: '/home/user/menu.PNG', children: [leaf]};
    assert.deepEqual(model.action(menu, 0), menu);
    assert.equal(model.iconUrl(leaf.icon), 'file:///home/user/My%20icons/a%20%231.svg');
    for (const icon of ['search', 'link', 'code', 'calendar', 'clock', 'mail', 'lock', 'power', 'cloud', 'bookmark'])
        assert.equal(model.action({...leaf, icon}, 1).icon, icon);
    for (const icon of ['https://example.com/a.png', 'relative.png', '/tmp/icon.txt', '/tmp/a.png\n', '/tmp/a\0.png', ''])
        assert.equal(model.action({...leaf, icon}, 1), null);
});
