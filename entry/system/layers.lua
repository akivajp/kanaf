-- layers settings

require 'table'

function layers_init()
  layers = {}
  layers_lookup = {}
end

function layers_add(img, t)
  local layer = { }
  table.insert(layers, layer)
  local t = t or {}
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

function message_activate(name)
  if not name then return end
  for i, j in pairs(layers_lookup) do
    if tostring(i):match('^' .. tostring(name)) then
      j.visible = true
      if j.img and j.img.type_name == 'lev.image.layout' then
        layers_lookup.active = j
      end
    end
  end
end

function message_deactivate(name)
  if not name then return end
  for i, j in pairs(layers_lookup) do
    if tostring(i):match('^' .. tostring(name)) then
      j.visible = false
    end
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

