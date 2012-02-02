require 'lev.image'
require 'lev.package'
require 'lev.timer'
require 'lev.util'

module('tags', package.seeall)

wait_timer = lev.stop_watch()
wait_until = 0

-- list of immediate executing tags
replacers = {'anchor', 'font', 'link', 'ruby'}
-- list of tags separating blocks of drawing
stoppers = {'br', 'clear', 'cm', 'r', 's', 'wait'}

function activate(param)
  local name = param.name or param.layer or ''
  msg_activate(name)
end

function anchor(param)
  local text = param.text or param.txt or param[1]
  local href = param.href

  if text then
    local on_click
    if href then
      on_click = function() lev.util.open(href) end
    end
    msg_reserve_clickable('anchor', text, on_click)
    kanaf.history = kanaf.history .. text
    table.insert(kanaf.do_list, function() msg_show_next() end)
  end
end

function br()
  layers.msgfg.img:reserve_new_line()
  layers.msgfg.img:draw_next()
  kanaf.history = kanaf.history .. '[br]'
end

function call(param)
  local file = param.storage or param.src or param.file
  local target = param.target or param.name

  if not target then
    print('warning: target is not given')
  end
  file = file or log.filename

  kanaf.call(file, target)
end

function clear()
  kanaf.history = kanaf.history .. '\n'
  msg_clear()
end

function cm()
  kanaf.history = kanaf.history .. '\n'
  msg_clear()
end

function font(param)
  local color = param.color
  local size = param.size
  local reset = param.reset or param.clear

  if type(color) == 'string' then
    color = lev.prim.color(color)
  end

  if reset == true or reset == 'true' then
    for i,j in ipairs(layers) do
      if j.img and j.img.type_name == 'lev.image.layout' then
        j.img.font.size = conf.font_size
        j.img.fg_color = conf.fg_color
      end
    end
  else
  end

  if size then
    for i,j in ipairs(layers) do
      if j.img and j.img.type_name == 'lev.image.layout' then
        j.img.font.size = size
      end
    end
  end

  if color then
    for i,j in ipairs(layers) do
      if j.img and j.img.type_name == 'lev.image.layout' then
        j.img.fg_color = color
      end
    end
  end
end

function eval(p)
  local expr = p.expression or p.expr or p.code or p[1] or ''
  if expr then
    local f = loadstring(string.format('return %s', tostring(expr)))
print('code: ', string.format('return %s', tostring(expr)))
print('f: ', f)
    local val
    if f then
      val = f()
    end
print('val: ', val)
    kanaf.buffer = tostring(val) .. kanaf.buffer
  end
end

function exit()
  kanaf.exit()
end

function image(param)
  local src = param.src or param.storage or nil
  local name = param.layer or param.name or nil
  local x = param.x
  local center_x = param.center_x or param.cx
  local right_x = param.right_x or param.rx
  local y = param.y
  local center_y = param.center_y or param.cy
  local bottom_y = param.bottom_y or param.by
  local mode = param.mode or param.trans or param.effect or nil
  local duration = param.duration or param.time or 1
  local visible = param.visible
  local alpha = param.alpha or param.a

  local layer = layers_lookup[name]
  if not layer then
    print(string.format('warning: layer "%s" is not found.', tostring(name)))
    return false
  end

  -- property settings
  layer.x = x or layer.x
  layer.y = y or layer.y
  layer.alpha = alpha or layer.alpha
  if visible == true then
    layer.visible = true
  elseif visible == false then
    layer.visible = false
  end

  local src_path
  if src then
    src_path = lev.package.resolve(src)
    src_path = src_path or lev.package.resolve(src .. '.png')
    if not src_path then
      print(string.format('image "%s" is not found', src))
    end
  end

  if mode then
    if layer.img and layer.img.type_name ~= 'lev.image.transition' then
      layer.img = lev.image.transition(layer.img)
    end

    layer.img:set_next { src_path, duration = duration, mode = mode }
  else
    if src_path then
      if layer.img and layer.img.type_name == 'lev.image.transition' then
        layer.img:set_current(src_path)
      else
        layer.img = lev.image.transition(src_path)
      end
    end
  end

  -- X positioning with centerized axis
  if center_x and layer.img then
    layer.x = (conf.frame_w - layer.img.w) / 2 + center_x
  end
  -- X positioning from the right edge
  if right_x and layer.img then
    layer.x = conf.frame_w - layer.img.w + right_x
  end
  -- Y positioning with centerized axis
  if center_y and layer.img then
    layer.y = (conf.frame_h - layer.img.h) / 2 + center_y
  end
  -- Y positioning from the bottom edge
  if bottom_y and layer.img then
    layer.y = conf.frame_h - layer.img.h + bottom_y
  end
end

function jump(param)
  local file = param.filename or param.file or param.storage or nil
  local target = param.target or param.to
  kanaf.load_scenario(file, target)
end

function l()
  kanaf.key_pressed = false
  kanaf.status = 'wait_key'
  layers_lookup.wait_line.visible = true
end

function link(param)
  local src = param.src or param.source or param.storage
  local file = param.filename or param.file or nil
  local target = param.target

  val = kanaf.seek_to('[endlink]')
  if #val == 0 then return end

  local on_click
  if target then
    on_click = function() kanaf.load_scenario(file, target) end
  end
  msg_reserve_clickable('anchor', val, on_click)
--  kanaf.history = kanaf.history .. text
  table.insert(kanaf.do_list, function() msg_show_next() end)
end

function logging(param)
  local enable = param.enable or param[1]
  local disable = param.disable

--print('ENABLE: ', enable)
  if enable == true or enable == 1 then
    log.logging = true
  elseif enable == false or enable == 0 or disable then
    log.logging = false
  end
  return true
end

function map(param)
  local clear = param.clear
  local name = param.name or param.layer
  local x = param.x
  local center_x = param.center_x or param.cx
  local right_x = param.right_x or param.rx
  local y = param.y
  local center_y = param.center_y or param.cy
  local bottom_y = param.bottom_y or param.by
  local src = param.src or param.image
  local hover = param.hover or param.hover_image
  local text = param.text
  local visible = param.visible
  local call = param.call
  local jump = param.jump or param.goto
  local file = param.file or param.filename or log.filename

  local layer = layers_lookup[name]
  if not layer then
    print(string.format('warning: layer "%s" is not found.', tostring(name)))
    return false
  end

  if type(visible) == 'boolean' then
    layer.visible = visible
  end

  if not layer.img or layer.img.type_name ~= 'lev.image.map' then
    layer.img = lev.image.map()
  end

  if clear then
    layer.img:clear()
  end

  if text then
    local font = lev.font.load()
    font.size = 32
    local str = lev.image.string(font, text)
    layer.img:map_image(str, x, y)
  elseif src then
    local path = lev.package.resolve(src)
    if not path then
      print(string.format('warning: image "%s" is not found.', tostring(src)))
      return false
    end
    local img = lev.image.load(path)
    if not img then
      print(string.format('warning: error on loading image "%s"', tostring(path)))
      return false
    end

    if center_x then
      x = (conf.frame_w - img.w) / 2 + center_x
    end
    if right_x then
      x = conf.frame_w - img.w + right_x
    end
    if center_y then
      y = (conf.frame_h - img.h) / 2 + center_y
    end
    if bottom_y then
      y = conf.frame_h - img.h + bottom_y
    end

    if hover then
      local path = lev.package.resolve(hover)
      if not path then
        print(string.format('warning: image "%s" is not found.', tostring(hover)))
        return false
      end
      local hover_img = lev.image.load(path)
      if not hover_img then
        print(string.format('warning: error on loading image "%s"', tostring(hover)))
        return false
      end

      local on_lclick = nil
      if call then
        on_lclick = function()
          kanaf.call(file, target)
        end
      elseif jump then
        on_lclick = function()
          kanaf.load_scenario(file, jump)
        end
      end
      layer.img:map_link{ img, hover_img, x, y, on_lclick = on_lclick, on_hover = on_hover }
    else
      layer.img:map_image(img, x, y)
    end
  end
end

function p()
  kanaf.key_pressed = false
  kanaf.status = 'wait_key'
  layers_lookup.wait_page.visible = true
end

function r()
  msg_reserve_new_line()
  msg_show_next()
  kanaf.history = kanaf.history .. '[r]'
end

function ruby(param)
  local text = param.text or param[1]
  if text then
    local ch = tostring(kanaf.buffer:index(0))
    kanaf.buffer = kanaf.buffer:sub(1)
    msg_reserve_word(ch, text)
    kanaf.history = kanaf.history .. string.format('[ruby text="%s"]%s', text, ch)
    table.insert(kanaf.do_list, function() msg_show_next() end)
  end
end

function wait(param)
  local delay = param.delay or param.duration or param[1] or 1
  delay = tonumber(delay)
  if delay then
    wait_timer:start(0)
    wait_until = delay
    kanaf.status = 'wait'
  else
  end
end

function s()
  kanaf.key_pressed = false
  kanaf.status = 'stop'
end

