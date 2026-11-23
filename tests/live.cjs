require('./host-desktop.cjs');
// Explicitly invoked, real desktop test. Uses virtual input, never mocks launchers.
// ORB_POINTER must name an inspected Wayland virtual-pointer tool accepting
// x y outputWidth outputHeight button (0 moves, 272 left-clicks).
const {execFileSync} = require('node:child_process');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const path = require('node:path');
const id = 'io.github.tcballard.orb';
const pointer = process.env.ORB_POINTER;
if (!pointer) throw new Error('Set ORB_POINTER to the virtual pointer test tool');
const run = (cmd, ...args) => execFileSync(cmd, args.map(String), {encoding:'utf8', timeout:15000}).trim();
const json = (cmd, ...args) => JSON.parse(run(cmd,...args));
const ipc = (...args) => run('omarchy-shell', ...args);
const sleep = ms => new Promise(r=>setTimeout(r,ms));
const status = () => JSON.parse(ipc(id,'status'));
const dispatch = expression => run('hyprctl','dispatch',expression);
const key = k => run('wtype','-s','40','-k',k,'-s','40');
const saved = {workspace:json('hyprctl','activeworkspace','-j').name, pointer:json('hyprctl','cursorpos','-j'), focus:json('hyprctl','activewindow','-j').address};
const monitor = json('hyprctl','monitors','-j').find(m=>m.focused);
assert.equal(monitor.scale,1,'This XPS harness requires scale 1');
assert.equal(monitor.transform,0);
// Orb keeps a 12px margin inside the monitor's reserved (bar) space.
const [resL,resT,resR,resB] = monitor.reserved || [0,0,0,0];
const edge = {left:resL+12, top:resT+12, right:monitor.width-resR-12, bottom:monitor.height-resB-12};
const move = (x,y,button=0) => run(pointer,Math.round(x),Math.round(y),monitor.width,monitor.height,button);
const report = [];
const artifacts = path.join(__dirname,'../artifacts');
fs.mkdirSync(artifacts,{recursive:true});
let themeRestoration = null;
async function until(fn, message, timeout=4000) {
  const end = Date.now()+timeout;
  while (Date.now()<end) { const value=fn(); if(value) return value; await sleep(60); }
  throw new Error(message);
}
async function open() {
  ipc('shell','summon',id,'{}');
  const shown=await until(()=>{const s=status();return s.opened&&s.positioned&&s.ready&&s.revealed&&s.visible&&s.opacity===1?s:false;},'Wheel did not become visible');
  await sleep(100); // Allow the compositor to deliver keyboard focus after mapping.
  return shown;
}
const pass = (name,detail={}) => {report.push({name,pass:true,...detail});console.log('PASS:',name);};
function layers() {
  return Object.values(json('hyprctl','layers','-j')).flatMap(m=>Object.values(m.levels).flat()).map(l=>l.namespace);
}
(async()=>{
  try {
    dispatch('hl.dsp.focus({ workspace = "name:orb-demo" })');
    move(960,560);
    let s;
    if(!process.argv.includes('--menus-only')) {
    s=await open();
    key('Right'); assert.equal(status().selected,0);
    key('Left'); assert.equal(status().selected,5);
    key('3'); assert.equal(status().selected,2);
    key('Escape'); assert.equal(status().opened,false);
    pass('Keyboard navigation, wrap, numeric selection and Escape');
    // Repeated summon resets the existing window; toggle closes it.
    for(let n=0;n<12;n++) {await open(); key('Escape'); assert.equal(status().opened,false);}
    await open(); await open(); assert.equal(layers().filter(n=>n==='omarchy-plugin-orb').length,1);
    ipc('shell','toggle',id,'{}'); assert.equal(status().opened,false);
    pass('12 open/cancel cycles, repeated summon and toggle, one layer');
    for(const [x,y] of [[resL+1,resT+1],[monitor.width-resR-2,resT+1],[resL+1,monitor.height-resB-2],[monitor.width-resR-2,monitor.height-resB-2]]) {
      move(x,y);s=await open();
      assert.ok(s.x>=edge.left && s.y>=edge.top);
      assert.ok(s.x+s.diameter<=edge.right && s.y+s.diameter+38<=edge.bottom);
      key('Escape');
    }
    pass('All four physical screen corners stay inside the bar and monitor bounds');
    move(960,560);s=await open();
    move(s.x+s.diameter/2,s.y+s.diameter*.19);
    move(s.x+s.diameter/2+3,s.y+s.diameter*.19);
    assert.equal(status().selected,0); assert.equal(status().keyboard,false);
    key('Right');assert.equal(status().selected,1);await sleep(200);assert.equal(status().selected,1);
    move(1700,1100,272);assert.equal(status().opened,false);
    pass('Real pointer hover, keyboard takes over, outside click dismisses');
    if(process.argv.includes('--actions')) {
      const checks=[['Browser',0,/chromium|firefox|brave|chrome/i],['Terminal',1,/ghostty|alacritty|kitty|foot/i],['Files',2,/nautilus/i],['Screenshot',3,/postcard|omasnap/],['Themes',4,/omarchy-image-selector/],['Plugins',5,/omarchy-menu/]];
      for(const [label,index,expected] of checks) {
        dispatch('hl.dsp.focus({ workspace = "name:orb-demo" })');
        const before=json('hyprctl','clients','-j').map(w=>w.address);
        move(960,560);s=await open();
        if(index===1) {
          const angle=(index*60-90)*Math.PI/180;
          move(s.x+s.diameter/2+Math.cos(angle)*s.diameter*.33,s.y+s.diameter/2+Math.sin(angle)*s.diameter*.33,272);
        } else if(index === 2) {
          // Files is a built-in submenu of locations; open Home from it.
          key('3');key('Return');
          assert.equal(status().submenu,'Files');
          key('1');key('Return');
        } else if(index >= 4) {
          key('5');key('Return');
          assert.equal(status().submenu,'Settings');
          key(String(index-3));key('Return');
        } else {key(String(index+1));key('Return');}
        await until(()=>!status().opened,'Wheel failed to dismiss after activation');
        const result=await until(()=>{
          if(index<3) {
            const created=json('hyprctl','clients','-j').find(w=>!before.includes(w.address)&&expected.test(w.class));
            if(created)return {class:created.class};
            const active=json('hyprctl','activewindow','-j');return index===0&&expected.test(active.class||'')?{class:active.class}:false;
          }
          const names=layers();return names.some(n=>expected.test(n))?{layers:names.filter(n=>expected.test(n))}:false;
        },`${label} did not open`,9000);
        assert.equal(status().lastAction,index===2?'Home':label);
        pass(`Real action: ${label}`,result);
        // Only close brand-new test windows, never existing user windows/tabs.
        if(index<3) {
          const created=json('hyprctl','clients','-j').filter(w=>!before.includes(w.address)&&expected.test(w.class));
          for(const w of created) dispatch(`hl.dsp.window.close({ window = "address:${w.address}" })`);
        } else key('Escape');
        await sleep(250);
      }
    }
    }
    move(960,560);s=await open();
    assert.ok(s.diameter <= 280, 'Compact default is too large');
    key('5');key('Return');assert.equal(status().submenu,'Settings');
    assert.deepEqual(status().items,['Themes','Plugins']);
    assert.equal(status().menuWidth,s.diameter);
    assert.equal(status().menuX,s.x);assert.equal(status().menuY,s.y);
    move(s.x+s.diameter/2,s.y+s.diameter/2,272);
    assert.equal(status().submenu,'');assert.equal(status().opened,true);
    key('6');key('Return');
    await until(()=>!status().loading && status().items.length, 'Installed agents did not load');
    assert.equal(status().submenu,'Agents');
    const expectedAgents=json(path.join(__dirname,'../scripts/agents')).map(a=>a.label);
    assert.deepEqual(status().items,expectedAgents);
    if(process.argv.includes('--glyphs')) {
      const capture = name => { const v=status(); run('grim','-g',`${Math.floor(v.x-10)},${Math.floor(v.y-10)} ${Math.ceil(v.diameter+20)}x${Math.ceil(v.diameter+58)}`,`${artifacts}/orb-agents-${name}.png`); };
      await sleep(250);capture('marks-dark');
      const current=path.join(process.env.HOME,'.local/state/omarchy/current/theme');
      themeRestoration=[fs.readFileSync(`${current}/colors.toml`).toString('base64'),fs.readFileSync(`${current}/shell.toml`).toString('base64')];
      const old=status().background;
      ipc('shell','applyTheme',fs.readFileSync(`${process.env.OMARCHY_PATH}/themes/catppuccin-latte/colors.toml`).toString('base64'),'');
      await until(()=>status().background!==old,'Light palette did not apply');
      key('2');await sleep(250);capture('marks-light');
      ipc('shell','applyTheme',...themeRestoration);themeRestoration=null;
      await until(()=>status().background===old,'Original palette did not restore');
      pass('Agent glyph stills captured on original and light palettes; original palette restored');
      key('Escape');key('6');key('Return');
      await until(()=>!status().loading&&status().items.length,'Agents did not reload');
    }
    const submenu=status();
    assert.ok(submenu.menuX>=edge.left && submenu.menuY>=edge.top);
    assert.ok(submenu.menuX+submenu.menuWidth<=edge.right && submenu.menuY+submenu.menuHeight<=edge.bottom);
    key('Down');assert.equal(status().selected,0);
    key('Escape');assert.equal(status().submenu,'');assert.equal(status().opened,true);
    key('Escape');assert.equal(status().opened,false);
    pass('Compact circular menus, installed-only agents, centre-click back and Escape', {agents:expectedAgents});
    if(process.argv.includes('--agents')) {
      const agentFile=path.join(process.env.HOME,'.config/omarchy/defaults/agent');
      const defaultBefore=fs.existsSync(agentFile)?fs.readFileSync(agentFile,'utf8'):null;
      const before=json('hyprctl','clients','-j').map(w=>w.address);
      move(960,560);s=await open();
      run('grim','-g',`${Math.floor(s.x-10)},${Math.floor(s.y-10)} ${Math.ceil(s.diameter+20)}x${Math.ceil(s.diameter+58)}`,`${artifacts}/orb-compact.png`);
      const angle=(5*60-90)*Math.PI/180;
      move(s.x+s.diameter/2+Math.cos(angle)*s.diameter*.33,s.y+s.diameter/2+Math.sin(angle)*s.diameter*.33,272);
      await until(()=>status().submenu==='Agents'&&!status().loading&&status().items.length,'Agent submenu failed');
      s=status();
      run('grim','-g',`${Math.floor(s.menuX-10)},${Math.floor(s.menuY-10)} ${Math.ceil(s.menuWidth+20)}x${Math.ceil(s.menuHeight+20)}`,`${artifacts}/orb-agents.png`);
      const codex=s.items.indexOf('Codex');assert.ok(codex>=0);
      const ca=(codex*360/s.visibleItems.length-90)*Math.PI/180;
      move(s.x+s.diameter/2+Math.cos(ca)*s.diameter*.33,s.y+s.diameter/2+Math.sin(ca)*s.diameter*.33,272);
      const launched=await until(()=>json('hyprctl','clients','-j').find(w=>!before.includes(w.address)&&w.class==='org.omarchy.agent'),'Agent terminal did not launch',9000);
      await sleep(700);
      assert.equal(status().lastAction,'Codex');assert.equal(status().opened,false);
      assert.equal(fs.existsSync(agentFile)?fs.readFileSync(agentFile,'utf8'):null,defaultBefore);
      dispatch(`hl.dsp.window.close({ window = "address:${launched.address}" })`);
      pass('Pointer opens Agents and launches Codex in the agent terminal; default agent unchanged');
    }
    if(process.argv.includes('--settings')) {
      for(const [label,row,namespace] of [['Themes',0,'omarchy-image-selector'],['Plugins',1,'omarchy-menu']]) {
        move(960,560);s=await open();
        const a=(4*60-90)*Math.PI/180;
        move(s.x+s.diameter/2+Math.cos(a)*s.diameter*.33,s.y+s.diameter/2+Math.sin(a)*s.diameter*.33,272);
        s=status();assert.equal(s.submenu,'Settings');
        if (row===0) run('grim','-g',`${Math.floor(s.x-10)},${Math.floor(s.y-10)} ${Math.ceil(s.diameter+20)}x${Math.ceil(s.diameter+58)}`,`${artifacts}/orb-settings.png`);
        const ra=(row*360/s.visibleItems.length-90)*Math.PI/180;
        move(s.x+s.diameter/2+Math.cos(ra)*s.diameter*.33,s.y+s.diameter/2+Math.sin(ra)*s.diameter*.33,272);
        await until(()=>layers().includes(namespace),`${label} failed to open`);
        assert.equal(status().lastAction,label);key('Escape');
        pass(`Pointer activates Settings → ${label}`);
      }
      const before=json('hyprctl','clients','-j').map(w=>w.address);
      move(960,560);s=await open();
      const a=Math.PI/6;
      move(s.x+s.diameter/2+Math.cos(a)*s.diameter*.33,s.y+s.diameter/2+Math.sin(a)*s.diameter*.33,272);
      const files=await until(()=>json('hyprctl','clients','-j').find(w=>!before.includes(w.address)&&/nautilus/i.test(w.class)),'Files pointer launch failed',9000);
      assert.equal(status().lastAction,'Files');
      dispatch(`hl.dsp.window.close({ window = "address:${files.address}" })`);
      pass('Compact wheel pointer launches Files');
    }
    if(process.argv.includes('--theme')) {
      const home=process.env.HOME;
      const current=`${home}/.local/state/omarchy/current/theme`;
      themeRestoration=[fs.readFileSync(`${current}/colors.toml`).toString('base64'),fs.readFileSync(`${current}/shell.toml`).toString('base64')];
      move(960,560);await open();const old=status();
      ipc('shell','applyTheme',fs.readFileSync(`${process.env.OMARCHY_PATH}/themes/everforest/colors.toml`).toString('base64'),'');
      await until(()=>status().foreground!==old.foreground,'Theme tokens did not update');
      run('grim','-g','675,280 570x600',`${artifacts}/orb-everforest.png`);
      ipc('shell','applyTheme',...themeRestoration);themeRestoration=null;
      await until(()=>status().foreground===old.foreground,'Original colours did not restore');
      pass('Live shell theme token change to Everforest and restoration; app configs untouched');
      key('Escape');
    }
    dispatch(`hl.dsp.focus({ window = "address:${saved.focus}" })`);
    const beforeFocus=json('hyprctl','activewindow','-j').address;
    await open();key('Escape');await sleep(150);
    assert.equal(json('hyprctl','activewindow','-j').address,beforeFocus);
    assert.ok(!layers().includes('omarchy-plugin-orb'));
    pass('Escape restores previous window focus and removes exclusive layer');
  } catch(error) {
    report.push({pass:false,error:error.message});process.exitCode=1;console.error(error);
  } finally {
    if(themeRestoration) ipc('shell','applyTheme',...themeRestoration);
    ipc('shell','hide',id);
    dispatch(`hl.dsp.focus({ workspace = ${JSON.stringify(saved.workspace)} })`);
    if(saved.focus) dispatch(`hl.dsp.focus({ window = "address:${saved.focus}" })`);
    move(saved.pointer.x,saved.pointer.y);
    fs.writeFileSync(`${artifacts}/live-results.json`,JSON.stringify({date:new Date().toISOString(),report},null,2));
  }
})();
