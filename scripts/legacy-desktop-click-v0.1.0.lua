-- Desktop-only right-click. App, panel and widget clicks pass through untouched.
-- Current Hyprland Lua API: auto_consuming + { ok = false } passes the event on.
local function contains(p, x, y, w, h, pad)
  if not (p and x and y and w and h) then return true end -- fail closed
  pad = pad or 0
  return p.x >= x - pad and p.y >= y - pad and p.x < x + w + pad and p.y < y + h + pad
end
local function axis(value, name, index)
  if type(value) ~= "table" then return nil end
  return value[name] or value[index]
end
hl.bind("mouse:273", function()
  local pass = { ok = false }
  local p = hl.get_cursor_pos()
  local monitor = hl.get_monitor_at_cursor()
  if not p or not monitor then return pass end
  local workspace = monitor.active_workspace
  if not workspace or monitor.active_special_workspace then return pass end
  -- No desktop actions through application bounds, including window borders.
  for _, window in ipairs(hl.get_windows({ mapped = true })) do
    local on_desktop = window.pinned or (window.workspace and window.workspace.id == workspace.id)
    if on_desktop and window.visible and not window.hidden and contains(p,
        axis(window.at, "x", 1), axis(window.at, "y", 2),
        axis(window.size, "x", 1), axis(window.size, "y", 2), 8) then
      return pass
    end
  end
  local background = false
  for _, layer in ipairs(hl.get_layers({ monitor = monitor })) do
    if layer.mapped and contains(p, layer.x, layer.y, layer.w, layer.h) then
      if layer.layer == 0 then
        background = true
      else
        return pass
      end
    end
  end
  if not background then return pass end
  hl.exec_cmd("omarchy-shell shell summon io.github.tcballard.orb '{}'")
  return { ok = true }
end, { auto_consuming = true, description = "Orb on empty desktop" })
