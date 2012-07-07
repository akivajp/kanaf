require 'lev.package'
lev.require 'system/layers'

message = message or { }

function message.activate(name)
  local layer = layers.lookup[name]
  if not layer then return false end
  if layer.img and layer.img.type_name == 'lev.layout' then
    message.active = layer
    message.active.visible = true
    message.active.parent.visible = true
  end
end

function message.clear()
  if message.active then
    message.active.img:clear()
  end
end

function message.complete()
  if message.active then
    message.active.img:complete()
  end
end

function message:hide()
  if message.active then
    message.active.visible = false
    message.active.parent.visible = false
  end
end

--function message.hide_all()
--  for i, j in ipairs(layers.list) do
--    if j and j.img and j.img.type_name == 'lev.layout' then
--      j.visible = false
--    end
--  end
--end

function message.reserve_clickable(text, on_click, on_hover)
  if message.active then
    message.active.img:reserve_clickable(text, on_click, on_hover)
  end
end

function message.reserve_clickable_image(img, img_hover, on_click, on_hover)
  if message.active then
    message.active.img:reserve_clickable(img, img_hover, on_click, on_hover)
  end
end

function message.reserve_new_line()
  if message.active then
    message.active.img:reserve_new_line()
  end
end

function message.reserve_word(txt, arg2)
  local auto_filling = true
  if type(arg2) == 'boolean' then
    auto_filling = arg2
  end

  local ruby = nil
  if type(arg2) == 'string' then
    ruby = arg2
  end

  if message.active then
    if ruby then
      message.active.img:reserve_word(txt, ruby)
    else
      message.active.img:reserve_word(txt, auto_filling)
    end
  end
end

function message.show()
  if message.active then
    message.active.visible = true
    message.active.parent.visible = true
  end
end

--function message.show_all()
--  for i, j in ipairs(layers.list) do
--    if j and j.img and j.img.type_id == 'lev.layout' then
--      j.visible = true
--    end
--  end
--end

function message.show_next()
  if message.active then
    message.active.img:show_next()
  end
end

