-- Desktop-only right-click. App, panel and widget clicks pass through untouched.
-- Current Hyprland Lua API: auto_consuming + { ok = false } passes the event on.
local function contains(p, x, y, w, h, pad)
  if not (p and x and y and w and h) then return true end -- fail closed
  pad = pad or 0
  return p.x >= x - pad and p.y >= y - pad and p.x < x + w + pad and p.y < y + h + pad
end
-- Hyprland 0.57.1 reports no id for named and special workspaces; use the name.
local function sameWorkspace(a, b)
  if not a or not b then return false end
  if a.id ~= nil and b.id ~= nil then return a.id == b.id end
  return a.name ~= nil and a.name == b.name
end
local function axis(value, name, index)
  if type(value) ~= "table" then return nil end
  return value[name] or value[index]
end
return hl.bind("mouse:273", function()
  local pass = { ok = false }
  local p = hl.get_cursor_pos()
  local monitor = hl.get_monitor_at_cursor()
  if not p or not monitor then return pass end
  local workspace = monitor.active_workspace
  if not workspace or monitor.active_special_workspace then return pass end
  -- No desktop actions through application bounds, including window borders.
  for _, window in ipairs(hl.get_windows({ mapped = true })) do
    local on_desktop = window.pinned or sameWorkspace(window.workspace, workspace)
    if on_desktop and window.visible and not window.hidden and contains(p,
        axis(window.at, "x", 1), axis(window.at, "y", 2),
        axis(window.size, "x", 1), axis(window.size, "y", 2), 8) then
      return pass
    end
  end
  local layers = hl.get_layers({ monitor = monitor })
  local backgrounds = {}
  for _, layer in ipairs(layers) do
    if layer.mapped and layer.layer == 0 then backgrounds[#backgrounds + 1] = layer end
  end
  -- Omarchy hosts the bar and some plugins in full-monitor surfaces that take no
  -- keyboard focus and mask input to their visible parts. Hyprland reports only
  -- the surface size, so skip exactly those; any other layer still blocks.
  local function inputMaskedHost(layer)
    if layer.keyboard_interactivity ~= 0 then return false end
    for _, b in ipairs(backgrounds) do
      if layer.x == b.x and layer.y == b.y and layer.w == b.w and layer.h == b.h then return true end
    end
    return false
  end
  local background = false
  for _, layer in ipairs(layers) do
    if layer.mapped and contains(p, layer.x, layer.y, layer.w, layer.h) then
      if layer.layer == 0 then
        background = true
      elseif not inputMaskedHost(layer) then
        return pass
      end
    end
  end
  if not background then return pass end
  hl.exec_cmd("omarchy-shell shell summon io.github.tcballard.orb '{}'")
  return { ok = true }
end, { auto_consuming = true, description = "Orb on empty desktop" })
