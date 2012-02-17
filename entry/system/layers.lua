-- layers settings

require 'table'

layers = layers or { }
layers.list = { }
layers.lookup = { }

function layers.init()
  layers.list = { }
  layers.lookup = { }
end

function layers.add(img, t)
  if not (t and t.name) then return false end
  if layers.lookup[t.name] then return false end
  local layer = { }
  table.insert(layers.list, layer)
  layer.bg = t.bg or nil
  layer.compile = t.compile or false
  layer.img = img
  layer.texture = t.texture or t.texturize or false
  layer.name = t.name or nil
  layer.visible = t.visible or t.on or false
  layer.x = t.x or 0
  layer.y = t.y or 0
  layer.alpha = t.alpha or 255

  if t.name then
    layers.lookup[t.name] = layer
  end
  if t.alias then
    layers.lookup[t.alias] = layer
  end
end

function layers.delete(name)
  local layer = layers.lookup[name]
  if not layer then return false end

  for i,j in ipairs(layers.list) do
    if j == layer then
      table.remove(layers.list, i)
    end
  end
  for i,j in pairs(layers.lookup) do
    if j == layer then
      layers.lookup[i] = nil
    end
  end
  return true
end

function layers.get_top_visible()
  for i = #layers.list,1,-1 do
    local j = layers.list[i]
    if j.img and j.visible then
      return j
    end
  end
  return nil
end

function layers.set_top(name)
  local layer = layers.lookup[name]
  if not layer then return false end

  for i, j in ipairs(layers.list) do
    if j == layer then
      table.remove(layers.list, i)
      break
    end
  end
  table.insert(layers.list, layer)
end

function layers.set_bg(img, t)
  if not (t and layers.lookup[t.name]) then return false end
  local fg = layers.lookup[t.name]
  local bg = { }
  bg.fg = fg
  bg.compile = t.compile or false
  bg.img = img
  bg.texture = t.texture or t.texturize or false
  bg.name = t.name or nil
  bg.visible = t.visible or t.on or false
  bg.x = t.x or 0
  bg.y = t.y or 0
  bg.alpha = t.alpha or 255
  fg.bg = bg
end

