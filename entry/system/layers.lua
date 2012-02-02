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
  layer.msg = t.msg or false
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

function msg_activate(name)
  if not name then return end
  for i, j in ipairs(layers) do
    if j.msg then
--      if j.name:match('^' .. tostring(name) .. "_") then
      if j.name:match('^' .. tostring(name)) then
        j.visible = true
        if j.img.type_name == 'lev.image.layout' then
          layers.active = j
        end
      else
        j.visible = false
      end
    end
  end
end

function msg_clear()
  if layers.active then
    layers.active.img:clear()
  end
end

function msg_reserve_clickable(name, val, on_click)
  if layers.active then
    layers.active.img:reserve_clickable(name, val, on_click)
  end
end

function msg_reserve_new_line()
  if layers.active then
    layers.active.img:reserve_new_line()
  end
end

function msg_reserve_word(txt, ruby)
  if layers.active then
    if ruby then
      layers.active.img:reserve_word(txt, ruby)
    else
      layers.active.img:reserve_word(txt)
    end
  end
end

function msg_show_next()
  if layers.active then
    layers.active.img:show_next()
  end
end

