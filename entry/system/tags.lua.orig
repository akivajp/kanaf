require 'lev.image'
require 'lev.package'
require 'lev.timer'
require 'lev.util'

tags = tags or { }

tags.wait_timer = lev.stop_watch()
tags.wait_until = 0

--function activate(param)
--  local name = param.name or param.layer or ''
--  message_activate(name)
--end

function tags.anchor(param)
  local text = param.text or param.txt or param[1]
  local href = param.href

  if text then
    local on_click
    if href then
      on_click = function() lev.util.open(href) end
    end
    message_reserve_clickable('anchor', text, on_click)
    kanaf.history = kanaf.history .. text
    message_show_next()
  end
end

function tags.call(param)
  local file = param.storage or param.src or param.file
  local target = param.target or param.name

  if not target then
    print('warning: target is not given')
    return false
  end

  kanaf.call(file, target)
end

function tags.clear(param)
  kanaf.history = kanaf.history .. '\n'
  message_clear()
end

function tags.cm(param)
  kanaf.history = kanaf.history .. '\n'
  message_clear()
end

function tags.eval(param)
  local code = param.code or param.exp or param.expression or param.expr or param[1]
  if code then
    local f = loadstring(tostring(code))
    if f then
      f()
    end
  end
end

function tags.exit(param)
  kanaf.exit()
end

function tags.font(param)
  local color = param.color
  local size = param.size
  local reset = param.reset or param.clear or false
  local relative = param.relative or param.rel or true
  local absolute = param.absolute or param.abs or false
  local bigger = param.bigger or param.big
  local smaller = param.smaller or param.small

  if bigger then
    relative = true
    size = 2
  elseif smaller then
    relative = true
    size = -2
  end

  if (not absolute) then
    relative = true
  end
  if relative then
    absolute = false
  end

  if type(color) == 'string' then
    color = lev.prim.color(color)
  elseif type(color) == 'number' then
    color = lev.prim.color{ code = color }
  else
    color = nil
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
        if relative == true then
          j.img.font.size = j.img.font.size + size
        else
          j.img.font.size = size
        end
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

function tags.image(param)
  local src = param.src or param.storage or nil
  local name = param.layer or param.name or nil
  local x = param.x or param.left or param.left_x
  local center_x = param.center_x or param.cx
  local right_x = param.right_x or param.right or param.rx
  local y = param.y or param.top or param.top_y
  local center_y = param.center_y or param.cy
  local bottom_y = param.bottom_y or param.bottom or param.by
  local mode = param.mode or param.trans or param.effect or nil
  local duration = param.duration or param.time or 1
  local visible = param.visible
  local alpha = param.alpha or param.a or param.opacity

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

function tags.jump(param)
  local file = param.filename or param.file or param.storage
  local target = param.target or param.to
  if target then
    kanaf.load_scenario(file, target)
  end
end

function tags.l(param)
  kanaf.key_pressed = false
  kanaf.current.status = 'wait_key'
  layers_lookup.wait_line.visible = true
end

function tags.link(param)
  local img_src = param.image or param.img
  local hover_src = param.hover_image or param.hover_img or param.hover
  local text = param.text or param.string
  local file = param.filename or param.file or param.storage
  local target = param.target or param.goto or param.to

  local img = nil
  local hover = nil
  if img_src then
    local path = lev.package.resolve(img_src)
    path = path or lev.package.resolve(img_src .. '.png')
    if path then
      img = lev.image.load(path)
    else
      print(string.format('waring: image file "%s" is not found', img_src))
    end
  end
  if hover_src then
    local path = lev.package.resolve(hover_src)
    path = lev.package.resolve(hover_src .. '.png')
    if path then
      hover = lev.image.load(path)
    else
      print(string.format('waring: image file "%s" is not found', hover_src))
    end
  end

  if (not img) and (not text) then
    print('warning: text is not given.')
    return false
  end

  local on_click
  if target then
    on_click = function()
      message_deactivate('select')
      message_activate('message')
      kanaf.load_scenario(file, target)
      kanaf.logging = true
    end
  end

  if img then
    message_reserve_clickable_image(img, hover, on_click, nil)
    message_show_next()
  elseif text then
    message_reserve_clickable(text, on_click, nil)
    message_show_next()
  end
end

function tags.load(param)
  local id = param.id or param.name
  local log = param.log or param.game

  if log then
    if not id then
      print('error: id is not given')
      return false
    end
    kanaf.load_log(id)
  end
end

function tags.logging(param)
  local enable = param.on or param.enable
  local disable = param.off or param.disable

  if enable == true or enable == 1 then
    kanaf.logging = true
  elseif enable == false or enable == 0 or disable then
    kanaf.logging = false
  end
  return true
end

function tags.map(param)
  local clear = param.clear or param.reset
  local name = param.name or param.layer
  local x = param.x or param.left or param.left_x or 0
  local center_x = param.center_x or param.cx
  local right_x = param.right_x or param.right or param.rx
  local y = param.y or param.top or param.top_y or 0
  local center_y = param.center_y or param.cy
  local bottom_y = param.bottom_y or param.bottom or param.by
  local src = param.src or param.image or param.storage or param.img
  local alpha = param.alpha or param.a or param.opaque or 255
  local hover = param.hover or param.hover_image
  local text = param.text or param.string
  local visible = param.visible
  local call = param.call
  local jump = param.jump or param.goto
  local file = param.file or param.filename
  local create = param.create
  local delete = param.delete

--  file = file or kanaf.current.file

  if create then
    layers_add(lev.image.map(),
               {name = name, texture = true, x = 0, y = 0})
  end

  if delete then
    layers_delete(name)
    return true
  end

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

  local img = nil
  if text then
    local font = lev.font.load()
    font.size = 32
    img = lev.image.string(font, tostring(text))
  elseif src then
    local path = lev.package.resolve(src)
    path = path or lev.package.resolve(src..'.png')
    if not path then
      print(string.format('warning: image "%s" is not found.', tostring(src)))
      return false
    end
    img = lev.image.load(path)
    if not img then
      print(string.format('warning: error on loading image "%s"', tostring(path)))
      return false
    end
  end

  if img then
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
      path = path or lev.package.resolve(hover..'.png')
      if not path then
        print(string.format('warning: image "%s" is not found.', tostring(hover)))
        return false
      end
      local hover_img = lev.image.load(path)
      if not hover_img then
        print(string.format('warning: error on loading image "%s"', tostring(hover)))
        return false
      end

      file = file or kanaf.current.filename
      local on_lclick = nil
      if call then
        on_lclick = function()
          kanaf.call(file, call)
        end
      elseif jump then
        on_lclick = function()
          kanaf.load_scenario(file, jump)
        end
      end
      layer.img:map_link{ img, hover_img, x, y, on_lclick = on_lclick, on_hover = on_hover }
    else
      layer.img:map_image(img, x, y, alpha)
    end
  end
end

function tags.p(param)
  kanaf.key_pressed = false
  kanaf.current.status = 'wait_key'
  layers_lookup.wait_page.visible = true
end

function tags.print(param)
  local text = param.text or param.txt or param.string
  local ruby = param.ruby
  local exp = param.exp or param.expression or param.expr or param.code

  if text then
    if ruby then
      text = tostring(text)
      ruby = tostring(ruby)
      message_reserve_word(text, ruby)
      local format = string.format('[print text="%s" ruby="%s"]', text, ruby)
      kanaf.history = kanaf.history .. format
      message_show_next()
    else
      kanaf.current.buffer = tostring(text) .. kanaf.current.buffer
    end
    return true
  elseif exp then
--print('CODE: ', string.format('return %s', tostring(exp)))
    local f = loadstring(string.format('return %s', tostring(exp)))
--print('F: ', f)
    local val
    if f then
      val = f()
    end
--print('VAL: ', val)
    kanaf.current.buffer = tostring(val) .. kanaf.current.buffer
    return true
  end
end

function tags.r(param)
  message_reserve_new_line()
  message_show_next()
  message_show_next()
  kanaf.history = kanaf.history .. '[r]'
end

tags['return'] = function()
  kanaf.ret()
end

function tags.s(param)
  kanaf.key_pressed = false
  kanaf.current.status = 'stop'
--  kanaf.current.buffer = '[s]' .. kanaf.current.buffer
end

function tags.save(param)
  local id = param.id or param.name
  local log = param.log or param.game

  if log then
    if not id then
      print('error: id is not given')
      return false
    end
    kanaf.save_log(id, conf.thumb_w, conf.thumb_h)
  end
end

function tags.screenshot(param)
  kanaf.thumbnail = screen.screen_shot
end

function tags.select(param)
  message_deactivate('message')
  message_activate('select')
  kanaf.logging = false
end

function tags.set(param)
  local event = param.event or param.evt
  local call = param.call
  local jump = param.jump
  local file = param.file or param.filename or param.storage
  local reset = param.reset or param.clear

  file = file or kanaf.current.filename

  if event == 'on_exit' or event == 'on_quit' then
    if call then
      kanaf.current.on_quit = function() kanaf.call(file, call) end
    elseif jump then
      kanaf.current.on_quit = function() kanaf.load_scenario(file, jump) end
    elseif reset then
      kanaf.current.on_quit = nil
    end
  elseif event == 'on_left_down' or event == 'on_left' or event == 'on_ldown' then
    if call then
      kanaf.current.on_left_down = function() kanaf.call(file, call) end
    elseif jump then
      kanaf.current.on_left_down = function() kanaf.load_scenario(file, jump) end
    elseif reset then
      kanaf.current.on_left_down = nil
    end
  elseif event == 'on_right_down' or event == 'on_right' or event == 'on_rdown' then
    if call then
      kanaf.current.on_right_down = function() kanaf.call(file, call) end
    elseif jump then
      kanaf.current.on_right_down = function() kanaf.load_scenario(file, jump) end
    elseif reset then
      kanaf.current.on_right_down = nil
    end
  end
end

function tags.sound(param)
  local src = param.src or param.source or param.storage or param.file
  local slot = param.slot or 0
  local command = param.command or param.mode
  local repeating = param['repeat'] or param.repeating or param.loop or false

  if not mixer then
    print('warning: mixer is not initialized')
    return false
  end

  local path = nil
  if src then
    path = lev.package.resolve(src)
    path = path or lev.package.resolve(src .. '.ogg')
    path = path or lev.package.resolve(src .. '.wav')
    if (not path) then
      print(string.format('warning: sound file "%s" is not found', src))
      return false
    end
  end

  if slot == 0 then
    if not src then
      print('please specify sound source file')
      return false
    end
    mixer:slot(0):play(path)
    return true
  end

  if slot <= 0 then
    repeating = false
  end

  if command == 'clear' then
    mixer:slot(slot):clear()
  elseif command == 'close' then
    mixer:slot(slot):clear()
  elseif command == 'load' then
    if (not src) then
      print('please specify sound source file')
    end
    mixer:slot(slot):load(path)
  elseif command == 'open' then
    if (not src) then
      print('please specify sound source file')
    end
    mixer:slot(slot):open(path)
  elseif command == 'pause' then
    mixer:slot(slot):pause()
  elseif command == 'play' then
    if path then
      mixer:slot(slot):play(path, repeating)
    else
      mixer:slot(slot):play(repeating)
    end
  elseif command == 'stop' then
    mixer:slot(slot):pause()
  end
  return true
end

function tags.wait(param)
  local delay = param.time or param.delay or param.duration or param[1] or 1
  delay = tonumber(delay)
  if delay then
    tags.wait_timer:start(0)
    tags.wait_until = delay
    kanaf.current.status = 'wait'
  else
  end
end

