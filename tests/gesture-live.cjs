const {execFileSync: exec} = require('node:child_process');
const fs = require('node:fs'), path = require('node:path'), assert = require('node:assert/strict');
assert.ok(process.env.OMADEV_SLOT && process.env.OMADEV_OWNER, 'Run only inside an owned omadev nest');
const repo = path.resolve(__dirname, '..'), id = 'io.github.tcballard.orb';
const run = (cmd, ...args) => exec(cmd, args.map(String), {cwd: repo, encoding: 'utf8', timeout: 15000}).trim();
const json = (...args) => JSON.parse(run(...args));
const ipc = (...args) => run('omarchy-shell', ...args), status = () => JSON.parse(ipc(id, 'status'));
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
async function until(check, message) {
    for (let i = 0; i < 100; i++) { try { if (check()) return; } catch {} await sleep(100); }
    throw Error(message);
}
const root = path.join(process.env.XDG_CONFIG_HOME, 'omarchy');
assert.ok(fs.realpathSync(root).startsWith(process.env.OMADEV_HOME + '/'), 'Configuration must be isolated to the nest');
const config = path.join(root, 'orb.json'), original = fs.readFileSync(config, 'utf8');
const monitors = json('hyprctl', 'monitors', '-j');
assert.equal(monitors.length, 1, 'This virtual-pointer fixture requires one monitor');
const monitor = monitors[0];
assert.equal(monitor.scale, 1, 'This fixture requires scale 1');
assert.equal(monitor.transform || 0, 0, 'This fixture requires an unrotated monitor');
const pointer = path.join(repo, 'artifacts/input/pointer');
assert.ok(fs.existsSync(pointer), 'Run ./tests/build-pointer first');
const move = (x, y, button = 0, end) => run(pointer, Math.round(x), Math.round(y), monitor.width, monitor.height, button, ...(end || []).map(Math.round));
const existing = json('hyprctl', 'binds', '-j');
const isOrb = b => (b.description || '').startsWith('Orb mouse button [orb:');
const button = [275, 276, 277, 278, 279].find(code => !existing.some(b => b.key === `mouse:${code}` && !isOrb(b)));
assert.ok(button, 'No unused extra button is available in this nest');
const oldPointer = json('hyprctl', 'cursorpos', '-j');
const work = fs.mkdtempSync(path.join(repo, 'artifacts/gesture-'));
const record = path.join(work, 'launches'), helper = path.join(work, 'record.sh');
fs.writeFileSync(helper, '#!/bin/bash\nprintf "%s\\n" "$1" >> "$2"\n', {mode: 0o700});
const action = label => ({label, icon: 'terminal', command: ['bash', helper, label, record]});
const fixture = JSON.parse(fs.readFileSync(path.join(repo, 'config.example.json'), 'utf8'));
fixture.mouseOpen = true; fixture.mouseButton = button; fixture.desktopRightClick = false; fixture.animation = false;
fixture.actions[0] = action('Fixture launch');
fixture.actions[1] = {label: 'Fixture menu', icon: 'settings', children: [action('Child')]};
const cx = monitor.width / 2, cy = monitor.height / 2;
const extraBinds = () => json('hyprctl', 'binds', '-j').filter(b => b.key === `mouse:${button}` && isOrb(b));
const count = () => fs.existsSync(record) ? fs.readFileSync(record, 'utf8').trim().split('\n').length : 0;
const report = [];
function pass(message) { report.push(message); console.log('PASS:', message); }
(async () => {
    try {
        ipc('shell', 'hide', id);
        fs.writeFileSync(config, JSON.stringify(fixture, null, 2) + '\n');
        await until(() => status().setupReady && extraBinds().length === 2 && status().visibleItems[0] === 'Fixture launch', 'Gesture binding did not become ready');
        move(cx, cy, button);
        await until(() => status().opened && status().revealed, 'Tap did not open Orb');
        assert.equal(count(), 0);
        const diameter = status().menuWidth;
        move(cx, cy, button);
        await until(() => !status().opened, 'Second tap did not dismiss Orb');
        pass('Tap opens and a second tap dismisses');
        move(cx, cy, button, [cx, cy - diameter * 0.33]);
        await until(() => count() === 1 && !status().opened, 'Hold, move and release did not launch the fixture');
        pass('Hold, move and release launches the selected shortcut once');
        move(cx, cy, button, [cx, cy]);
        await until(() => !status().opened && !status().gestureActive, 'Holding the centre did not cancel');
        assert.equal(count(), 1);
        pass('Holding and releasing without a selection cancels');
        move(cx, cy, button, [cx + diameter * 0.33 * Math.cos(Math.PI / 6), cy - diameter * 0.33 * Math.sin(Math.PI / 6)]);
        await until(() => status().opened && status().submenu === 'Fixture menu', 'A submenu gesture did not open the submenu');
        assert.equal(count(), 1);
        pass('Releasing over a submenu opens it without running a child');
        ipc('shell', 'hide', id);
        fixture.mouseOpen = false;
        fs.writeFileSync(config, JSON.stringify(fixture, null, 2) + '\n');
        await until(() => extraBinds().length === 0, 'Disabling the mouse option left a binding');
        pass('Disabling the mouse option releases both owned bindings');
    } finally {
        try { ipc('shell', 'hide', id); } catch {}
        fs.writeFileSync(config, original);
        try { move(oldPointer.x - (monitor.x || 0), oldPointer.y - (monitor.y || 0)); } catch {}
        fs.writeFileSync(path.join(work, 'results.json'), JSON.stringify({date: new Date().toISOString(), checks: report}, null, 2));
    }
})().catch(error => { console.error(error); process.exitCode = 1; });
