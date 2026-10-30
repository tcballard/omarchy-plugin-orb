local function orbMouseBinding(key)
  local function position()
    local p = hl.get_cursor_pos()
    if not p or type(p.x) ~= 'number' or type(p.y) ~= 'number'
       or p.x ~= p.x or p.y ~= p.y or math.abs(p.x) > 1000000 or math.abs(p.y) > 1000000 then return nil end
    return p
  end
  local function emit(gesture, phase, p)
    if not p then return end
    local x, y = math.floor(p.x + 0.5), math.floor(p.y + 0.5)
    hl.dispatch(hl.dsp.event('orb/' .. gesture.owner .. '/' .. phase .. '/' .. tostring(x) .. ',' .. tostring(y) .. '/' .. tostring(gesture.ticks * 30)))
  end
  if not r.gestureTimer then
    r.gestureTimer = hl.timer(function()
      local g = r.gesture
      if not g or r.latest ~= g.owner then
        r.gesture = nil; r.gestureTimer:set_enabled(false); return
      end
      g.ticks = g.ticks + 1
      local p = position()
      if g.ticks >= 200 then
        emit(g, 'cancel', p or {x = g.x, y = g.y})
        r.gesture = nil; r.gestureTimer:set_enabled(false); return
      end
      if p and (p.x ~= g.x or p.y ~= g.y) then
        g.x, g.y = p.x, p.y
        emit(g, 'move', p)
      end
    end, { timeout = 30, type = 'repeat' })
    r.gestureTimer:set_enabled(false)
  end
  local pair = {}
  pair.press = assert(hl.bind(key, function()
    local p = position()
    if not p or not r.latest or r.gesture then return end
    local g = { owner = r.latest, x = p.x, y = p.y, ticks = 0 }
    r.gesture = g
    emit(g, 'press', p)
    r.gestureTimer:set_enabled(true)
  end, { description = 'Orb mouse button [orb:' .. token .. '] press' }))
  local ok, release = pcall(function()
    return assert(hl.bind(key, function()
      local g = r.gesture
      if not g then return end
      r.gesture = nil; r.gestureTimer:set_enabled(false)
      local p = position()
      if r.latest == g.owner then emit(g, p and 'release' or 'cancel', p or {x = g.x, y = g.y}) end
    end, { release = true, ignore_mods = true, description = 'Orb mouse button [orb:' .. token .. '] release' }))
  end)
  if not ok then pair.press:remove(); error(release) end
  pair.release = release
  function pair:remove()
    r.gesture = nil
    if r.gestureTimer then r.gestureTimer:set_enabled(false) end
    self.press:remove()
  end
  return pair
end
