-- layers settings

require 'table'

function layers_init()
  layers = {}
  layers_lookup = {}
end

function layers_add(img, t)
  if not (t and t.name) then return false end
  if layers_lookup[t.name] then return false end
--print('LAYER ADD: ', t.name)
  local layer = { }
  table.insert(layers, layer)
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
    layers_lookup[t.name] = layer
  end
  if t.alias then
    layers_lookup[t.alias] = layer
  end
end

function layers_delete(name)
  local layer = layers_lookup[name]
  if not layer then return false end

  for i,j in pairs(layers) do
    if j == layer then
      table.remove(layers, i)
    end
  end
  for i,j in pairs(layers_lookup) do
    if j == layer then
      layers_lookup[i] = nil
    end
  end
  return true
end

function layers_set_bg(img, t)
  if not (t and layers_lookup[t.name]) then return false end
--print('SET BG', t.name)
  local fg = layers_lookup[t.name]
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

function layers_get_top_visible()
  for i = #layers,1,-1 do
    local j = layers[i]
    if j.img and j.visible then
      return j
    end
  end
  return nil
end

function message_activate(name)
  if not name then return end
  if layers_lookup[name] then
    layers_lookup.active = layers_lookup[name]
    layers_lookup.active.visible = true
  end
end

function message_deactivate(name)
  if not name then return end
  if layers_lookup[name] then
    layers_lookup[name].visible = false
  end
end

function message_clear()
  if layers_lookup.active then
    layers_lookup.active.img:clear()
  end
end

function message_reserve_clickable(text, on_click, on_hover)
  if layers_lookup.active then
    layers_lookup.active.img:reserve_clickable(text, on_click, on_hover)
  end
end

function message_reserve_clickable_image(img, img_hover, on_click, on_hover)
  if layers_lookup.active then
    layers_lookup.active.img:reserve_clickable(img, img_hover, on_click, on_hover)
  end
end

function message_reserve_new_line()
  if layers_lookup.active then
    layers_lookup.active.img:reserve_new_line()
  end
end

function message_reserve_word(txt, ruby)
  if layers_lookup.active then
    if ruby then
      layers_lookup.active.img:reserve_word(txt, ruby)
    else
      layers_lookup.active.img:reserve_word(txt)
    end
  end
end

function message_show_next()
  if layers_lookup.active then
    layers_lookup.active.img:show_next()
  end
end

