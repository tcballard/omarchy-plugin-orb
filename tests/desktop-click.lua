local callback, flags, launches
local windows, layers, point = {}, {}, {x=900,y=500}
hl = {
  bind = function(key, cb, opts) assert(key == "mouse:273"); callback=cb; flags=opts end,
  get_cursor_pos = function() return point end,
  get_monitor_at_cursor = function() return {name="eDP-1",active_workspace={id=1}} end,
  get_windows = function() return windows end,
  get_layers = function() return layers end,
  exec_cmd = function(cmd) assert(cmd == "omarchy-shell shell summon io.github.tcballard.orb '{}'"); launches = launches + 1 end
}
dofile("desktop-click.lua")
assert(flags.auto_consuming and not flags.locked and not flags.ignore_mods)
launches=0
local wallpaper={mapped=true,layer=0,namespace="omarchy-background",x=0,y=0,w=1920,h=1200}
layers={wallpaper}; assert(callback().ok); assert(launches==1)
windows={{visible=true,hidden=false,workspace={id=1},at={x=800,y=400},size={x=300,y=300}}}
assert(not callback().ok); assert(launches==1)
windows[1].visible=false; assert(callback().ok)
windows[1].visible=true; windows[1].workspace.id=2; assert(callback().ok)
windows={}; layers={wallpaper,{mapped=true,layer=2,namespace="omarchy-bar",x=0,y=0,w=1920,h=30}}
point={x=900,y=15}; assert(not callback().ok)
point={x=900,y=500}; layers={wallpaper,{mapped=true,layer=3,namespace="popup",x=0,y=0,w=1920,h=1200}}
assert(not callback().ok)
layers={}; assert(not callback().ok)
layers={wallpaper}; windows={{visible=true,workspace={id=1},at={},size={}}}; assert(not callback().ok)
-- Current Omarchy hosts the bar (and some plugins) in full-monitor top-layer
-- surfaces that take no keyboard focus and mask input to their visible parts.
windows={}; point={x=900,y=500}
local host={mapped=true,layer=2,namespace="omarchy-bar",keyboard_interactivity=0,x=0,y=0,w=1920,h=1200}
local before=launches
layers={wallpaper,host}; assert(callback().ok); assert(launches==before+1)
layers={wallpaper,host,{mapped=true,layer=2,namespace="omarchy-dock",keyboard_interactivity=0,x=0,y=990,w=1920,h=210}}
point={x=900,y=1100}; assert(not callback().ok) -- partial surfaces still block
point={x=900,y=500}
layers={wallpaper,{mapped=true,layer=2,namespace="modal",keyboard_interactivity=1,x=0,y=0,w=1920,h=1200}}
assert(not callback().ok) -- a focus-taking overlay blocks
layers={wallpaper,{mapped=true,layer=2,namespace="almost",keyboard_interactivity=0,x=0,y=0,w=1919,h=1200}}
assert(not callback().ok) -- only an exact full-monitor host is skipped
layers={host}; assert(not callback().ok) -- no wallpaper: fail closed
-- Named/special workspaces have no id; a scratchpad window must not block a named desktop.
local monitorAt=hl.get_monitor_at_cursor
hl.get_monitor_at_cursor=function() return {name="eDP-1",active_workspace={name="orb-test"}} end
layers={wallpaper}; windows={{visible=true,hidden=false,workspace={name="special:scratchpad"},at={x=800,y=400},size={x=300,y=300}}}
assert(callback().ok)
windows[1].workspace={name="orb-test"}; assert(not callback().ok)
hl.get_monitor_at_cursor=monitorAt
print('PASS: desktop-only right-click; app/layer clicks pass through; unknown geometry fails closed')
