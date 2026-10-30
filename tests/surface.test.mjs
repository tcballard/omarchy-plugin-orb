import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const source = fs.readFileSync(new URL('../OrbOverlay.qml', import.meta.url), 'utf8');
const surface = source;
function body(marker) {
  const start = surface.indexOf(marker);
  assert.ok(start >= 0, `Missing surface contract: ${marker}`);
  const open = surface.indexOf('{', start);
  let depth = 1, end = open + 1;
  while (depth && end < surface.length) {
    if (surface[end] === '{') depth++;
    if (surface[end] === '}') depth--;
    end++;
  }
  assert.equal(depth, 0);
  return surface.slice(open + 1, end - 1);
}
function expression(marker) {
  const start = surface.indexOf(marker);
  assert.ok(start >= 0, `Missing surface contract: ${marker}`);
  return surface.slice(start + marker.length).split(/\n(?=    \S)/)[0].trim();
}
function fixture() {
  const a = {name:'eDP-1', width:1920, height:1200};
  const b = {name:'DP-1', width:2560, height:1440};
  const ma = {name:a.name, scale:1, lastIpcObject:{x:0,y:0}}, mb = {name:b.name, scale:1.5, lastIpcObject:{x:1920,y:0}};
  const deferred = [];
  const state = {shown:false, targetScreen:null, width:1920, height:1200, devicePixelRatio:1,
    requestedScreen:"", respectReserved:false, backingWindowVisible:false, contentRevealed:false, refreshes:0, preferPointerScreen:false, openingPointer:{x:0,y:0},
    Quickshell:{screens:[a,b]}, Hyprland:{focusedMonitor:ma, monitors:{values:[ma,mb]}},
    Qt:{callLater:fn=>deferred.push(fn)}, WlrKeyboardFocus:{Exclusive:1, None:0}, shownKeyboardFocus:1};
  state.Hyprland.refreshMonitors = () => state.refreshes++;
  state.window = state;
  const context = vm.createContext(state);
  const run = code => vm.runInContext(code, context);
  state.requestedOutput = () => run(`(function() {${body('function requestedOutput()')}})()`);
  state.focusedScreen = () => run(`(function() {${body('function focusedScreen()')}})()`);
  state.screenAtPointer = point => {state.point = point; return run(`(function(point) {${body('function screenAtPointer(point)')}})(point)`);};
  Object.defineProperty(state, 'targetMonitor', {get:()=>run(`(function() {${body('readonly property var targetMonitor:')}})()`)});
  Object.defineProperty(state, 'contentReady', {get:()=>run(expression('readonly property bool contentReady:'))});
  const change = shown => {state.shown=shown; run(body('onShownChanged:'));};
  const reveal = () => run(body('onContentReadyChanged:'));
  const flush = () => {while(deferred.length) deferred.shift()();};
  return {state, a, b, ma, mb, run, change, reveal, flush};
}

test('release shell surface uses core PanelWindow without qs.Ui.OverlayWindow', () => {
  assert.match(surface, /^PanelWindow \{/m);
  assert.doesNotMatch(source, /\bOverlayWindow\s*\{/);
  assert.match(surface, /WlrLayershell\.layer: WlrLayer\.Overlay/);
  assert.match(surface, /respectReserved \? ExclusionMode\.Normal : ExclusionMode\.Ignore/);
});
test('open selects focused output and keeps its monitor geometry when focus moves', () => {
  const {state, a, b, ma, mb, change} = fixture();
  change(true);
  assert.equal(state.targetScreen, a);
  state.Hyprland.focusedMonitor = mb;
  assert.equal(state.targetScreen, a);
  assert.equal(state.targetMonitor, ma);
  change(false);
  assert.equal(state.targetScreen, null);
  change(true);
  assert.equal(state.targetScreen, b);
  assert.equal(state.targetMonitor, mb);
  assert.equal(state.refreshes, 2);
});
test('content waits for mapped fullscreen geometry and scale, then reveals next turn', () => {
  const {state, ma, change, reveal, flush} = fixture();
  change(true);
  assert.equal(state.contentReady, false);
  state.backingWindowVisible = true;
  state.width = 800;
  assert.equal(state.contentReady, false);
  state.width = 1920;
  ma.scale = 1.5;
  assert.equal(state.contentReady, false);
  state.devicePixelRatio = 1.5;
  assert.equal(state.contentReady, true);
  reveal();
  assert.equal(state.contentRevealed, false);
  flush();
  assert.equal(state.contentRevealed, true);
  change(false);
  reveal();
  flush();
  assert.equal(state.contentRevealed, false);
});
test('gesture opening selects the pointer output and falls back safely', () => {
  const {state, a, b, change} = fixture();
  state.preferPointerScreen = true;
  state.openingPointer = {x:2300,y:200};
  change(true); assert.equal(state.targetScreen,b);
  change(false); state.openingPointer = {x:-500,y:-500};
  change(true); assert.equal(state.targetScreen,a);
});
test('closing before deferred reveal does not reveal hidden content or retain focus', () => {
  const {state, run, change, reveal, flush} = fixture();
  change(true);
  state.backingWindowVisible = true;
  reveal();
  change(false);
  flush();
  assert.equal(state.contentRevealed, false);
  assert.equal(run(expression('WlrLayershell.keyboardFocus:')), state.WlrKeyboardFocus.None);
});
test('hotplug clears removed output before remapping and cannot reopen a closed wheel', () => {
  for (const close of [false,true]) {
    const {state, b, mb, run, change, flush} = fixture();
    change(true);
    state.Quickshell.screens = [b];
    state.Hyprland.monitors.values = [mb];
    run(body('function onScreensChanged()'));
    assert.equal(state.targetScreen, null);
    if (close) change(false);
    flush();
    assert.equal(state.targetScreen, close ? null : b);
  }
});
test('no outputs remain hidden and unavailable focused output falls back to first', () => {
  const {state, a, run, change} = fixture();
  state.Hyprland.focusedMonitor = null;
  change(true);
  assert.equal(state.targetScreen, a);
  change(false);
  state.Quickshell.screens = [];
  state.Hyprland.monitors.values = [];
  change(true);
  assert.equal(state.targetScreen, null);
  assert.equal(state.contentReady, false);
  assert.equal(run(expression('visible:')), false);
});
test('explicit touch output never falls back to pointer or focused output, including hotplug', () => {
 const {state,b,run,change,flush}=fixture();state.requestedScreen='DP-1';change(true);assert.equal(state.targetScreen,b);
 state.Quickshell.screens=state.Quickshell.screens.filter(s=>s!==b);run(body('function onScreensChanged()'));flush();assert.equal(state.targetScreen,null);assert.equal(state.contentReady,false);
 change(false);state.requestedScreen='missing';change(true);assert.equal(state.targetScreen,null);
});
test('reserved touch area still waits for mapping and matching fractional scale', () => {
 const {state,ma,change,reveal,flush}=fixture();state.respectReserved=true;change(true);state.width=1900;state.height=1100;
 assert.equal(state.contentReady,false);state.backingWindowVisible=true;ma.scale=1.25;assert.equal(state.contentReady,false);
 state.devicePixelRatio=1.25;assert.equal(state.contentReady,true);reveal();flush();assert.equal(state.contentRevealed,true);
 state.height=1300;reveal();flush();assert.equal(state.contentRevealed,false);
});
