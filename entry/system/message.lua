require 'lev.package'
lev.require 'system/layers'

message = message or { }

function message.activate(name)
  local layer = layers.lookup[name]
  if not layer then return false end
  if layer.img and layer.img.type_name == 'lev.image.layout' then
    layers.lookup.active = layer
    layers.lookup.active.visible = true
  end
end

function message.clear()
  if layers.lookup.active then
    layers.lookup.active.img:clear()
  end
end

function message.complete()
  if layers.lookup.active then
    layers.lookup.active.img:complete()
  end
end

function message.hide_all()
  for i, j in ipairs(layers.list) do
    if j and j.img and j.img.type_name == 'lev.image.layout' then
      j.visible = false
    end
  end
end

function message.reserve_clickable(text, on_click, on_hover)
  if layers.lookup.active then
    layers.lookup.active.img:reserve_clickable(text, on_click, on_hover)
  end
end

function message.reserve_clickable_image(img, img_hover, on_click, on_hover)
  if layers.lookup.active then
    layers.lookup.active.img:reserve_clickable(img, img_hover, on_click, on_hover)
  end
end

function message.reserve_new_line()
  if layers.lookup.active then
    layers.lookup.active.img:reserve_new_line()
  end
end

function message.reserve_word(txt, ruby)
  if layers.lookup.active then
    if ruby then
      layers.lookup.active.img:reserve_word(txt, ruby)
    else
      layers.lookup.active.img:reserve_word(txt)
    end
  end
end

function message.show_all()
  for i, j in ipairs(layers.list) do
    if j and j.img and j.img.type_id == 'lev.image.layout' then
      j.visible = true
    end
  end
end

function message.show_next()
  if layers.lookup.active then
    layers.lookup.active.img:show_next()
  end
end

