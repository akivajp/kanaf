-- layers settings

require 'table'

layers = layers or { }
layers.root = { }
--layers.list = { }
layers.lookup = { }

function layers.init()
  layers.root = { }
--  layers.list = { }
  layers.lookup = { }
  layers.lookup['root'] = layers.root
  layers.root.children = { }
  layers.root.name = 'root'
  layers.root.visible = true
  layers.root.x = 0
  layers.root.y = 0
end

function layers.create(entry)
  if not (type(entry) == 'string') then return false end
  if layers.lookup[entry] then return true end

  local prev_name = 'root'
  local name = ''
  for i in entry:gmatch('[^.]+') do
    name = name .. i
    if not layers.lookup[name] then
--print('REGISTERING:', name)
      local parent = layers.lookup[prev_name]
      local layer = { }
      layer.name = name
      layer.visible = true
      layer.parent = parent
      layer.children = { }
      layer.alpha = 255
      layer.x = 0
      layer.y = 0
      table.insert(parent.children, layer)
      layers.lookup[name] = layer
    end
    prev_name = name
    name = name .. '.'
  end
end

--function layers.add(entry, img, t)
--  if not (t and t.name) then return false end
--  if layers.lookup[t.name] then return false end
--  local layer = { }
--  table.insert(layers.list, layer)
--  layer.bg = t.bg or nil
--  layer.img = img
--  layer.name = t.name or nil
--  layer.visible = t.visible or t.on or false
--  layer.x = t.x or 0
--  layer.y = t.y or 0
--  layer.alpha = t.alpha or 255
--
--  if t.name then
--    layers.lookup[t.name] = layer
--  end
--  if t.alias then
--    layers.lookup[t.alias] = layer
--  end
--end

function layers.delete(name)
--print('START DELETING', name)
  local lay = layers.lookup[name]
  if not lay then return false end
  if name == 'root' then return false end

  local parent = lay.parent
  for i, j in ipairs(parent.children) do
    if j == lay then
--print('YES DELETING!', name)
      table.remove(parent.children, i)
    end
  end
  for i, j in pairs(layers.lookup) do
    if j == lay then
      layers.lookup[i] = nil
    end
  end
--print('END DELETING', name)
  return true
end

function layers.draw(lay, x, y)
  lay = lay or layers.root
  x = x or 0
  y = y or 0

  if lay.visible then
    if lay.img then
      lay.img:texturize()
--      print('draw!', lay.name, x + lay.x, x + lay.y, lay.alpha)
      screen:draw(lay.img, x + lay.x, x + lay.y, lay.alpha)
    end
    for i, j in pairs(lay.children) do
      layers.draw(j, x + lay.x, y + lay.y)
    end
  end
end

function layers.get_top_visible(lay)
  lay = lay or layers.root
  if not lay.visible then return nil end
--print('VISIBLE?', lay.name, lay.visible)
  for i = #lay.children,1,-1 do
    local j = lay.children[i]
--print('VISIBLE?', j.img, lay.visible)
    local lay = layers.get_top_visible(j)
    if lay then return lay end
  end
  if lay.visible and lay.img then
    return lay
  else
    return nil
  end
end

function layers.hide_sub(lay)
  if type(lay) == 'string' then
    lay = layers.lookup[lay]
  end
  if not lay then return false end

  for i, j in pairs(lay.children) do
    j.visible = false
  end
end

function layers.set_top(name)
  local lay = layers.lookup[name]
  if not lay then return false end
  if name == 'root' then return false end

  local parent = lay.parent
  for i, j in pairs(parent.children) do
    if j == lay then
      table.remove(parent.children, i)
      break
    end
  end
  table.insert(parent.children, lay)
  return true

--  for i, j in ipairs(layers.list) do
--    if j == layer then
--      table.remove(layers.list, i)
--      break
--    end
--  end
--  table.insert(layers.list, layer)
end

--function layers.set_bg(img, t)
--  if not (t and layers.lookup[t.name]) then return false end
--  local fg = layers.lookup[t.name]
--  local bg = { }
--  bg.fg = fg
--  bg.img = img
--  bg.name = t.name or nil
--  bg.visible = t.visible or t.on or false
--  bg.x = t.x or 0
--  bg.y = t.y or 0
--  bg.alpha = t.alpha or 255
--  fg.bg = bg
--end

