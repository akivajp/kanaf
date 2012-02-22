require 'lev.image'
require 'lev.package'
require 'lev.timer'
require 'lev.util'

tags = tags or { }

tags.wait_timer = lev.stop_watch()
tags.wait_until = 0
tags.wait_slot = 0
tags.controls = { 'else', 'elseif', 'endif', 'if' }
tags.macros = { }

-- local functions

local function get_boolean(...)
  t = { ... }
  for i, j in pairs(t) do
    if j == 'true' then return true end
    if j == '1' then return true end
    if j == 1 then return true end
    if j == 'false' then return false end
    if j == '0' then return false end
    if j == 0 then return false end
    if type(j) == 'boolean' then
      return j
    end
  end
  return nil
end

local function get_number(...)
  t = { ... }
  for i, j in pairs(t) do
    local val = tonumber(j)
    if val then
      return val
    end
  end
  return nil
end

local function get_string(...)
  t = { ... }
  for i, j in pairs(t) do
    if j then
      local val = tostring(j)
      if val then
        return val
      end
    end
  end
  return nil
end


-- tag functions

function tags.anchor(param)
  local text = get_string(param.text, param.txt)
  local href = get_string(param.href)

  if text then
    local on_click
    if href then
      on_click = function() lev.util.open(href) end
    end
    message.reserve_clickable('anchor', text, on_click)
    backlog.add(text)
    message.show_next()
  end
end

function tags.backlog(param)
  local show = param.show
  local hide = param.hide
  local src = get_string(param.src, param.bg_image, param.bg)
  local alpha = get_number(param.alpha, param.a, param.opaque)
  local seek_end = param.seek_end
  local seek_init = param.seek_init
  local seek_next = param.seek_next
  local seek_prev = param.seek_prev

  if not layers.lookup.backlog then
    local img = lev.image.map()
    layers.add(img, {name = 'backlog', texture = true})
    layers.set_bg(nil, {name = 'backlog', texture = true, visible = true})
  end

  if seek_end then
    backlog.seek_end()
  elseif seek_init then
    backlog.seek_init()
  elseif seek_next then
    backlog.seek_next()
  elseif seek_prev then
    backlog.seek_prev()
  end

  if show then
    backlog.show()
  elseif hide then
    backlog.hide()
  end

  if src then
    local path = lev.package.resolve(src) or
                 lev.package.resolve(src .. '.png')
    if not path then
      local msg =
        string.format('warning at %s : image "%s" is not found',
                      kanaf.get_pos(), src)
      lev.debug.print(msg)
    end

    local img = lev.image.load(path)
    if img then
      layers.lookup.backlog.bg.img = img
    end
  end

  if alpha then
    layers.lookup.backlog.bg.alpha = alpha
  end
end

function tags.call(param)
  local target = param.target or param.name or param.anchor

  if not target then
    local msg =
      string.format('warning at %s : No target.', kanaf.get_pos())
    lev.debug.print(msg)
    return false
  end

  kanaf.call(target, param)
end

function tags.cm(param)
  backlog.new_page()
  message.clear()
end

function tags.debug(param)
  local enable = param.enable or param.start
  local disable = param.disable or param.stop
  local message = get_string(param.message, param.msg, param.text, param.txt)

  if enable or disable == false then
    system:start_debug()
  elseif disable or enable == false then
    system:stop_debug()
  end

  if message then
    local str = string.format('at %s : %s', kanaf.get_pos(), message)
    lev.debug.print(str)
    return true
  end
end

tags['else'] = function(param)
  local prop_if = param['if']

  if prop_if then
    return tags['if'](param)
  end

  return true
end

tags['elseif'] = function(param)
  return tags['if'](param)
end

function tags.endif(param)
  -- nothing to do
  return true
end

function tags.endmacro(param)
  -- nothing to do
  return true
end

function tags.eval(param)
  local code = get_string(param.code, param.exp, param.expression, param.expr)
  if code then
    local f = loadstring(code)
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
  local absolute = param.absolute or param.abs
  local bigger = param.bigger or param.big
  local smaller = param.smaller or param.small

  local active = layers.lookup.active
  if not active then
    local msg = string.format('warning at %s : no message are activated', kanaf.get_pos())
    lev.debug.print(msg)
    return false
  end

  if bigger then
    relative = true
    size = 2
  elseif smaller then
    relative = true
    size = -2
  end

  if type(color) == 'string' then
    color = lev.prim.color(color)
  elseif type(color) == 'number' then
    color = lev.prim.color{ code = color }
  else
    color = nil
  end

  if reset == true or reset == 'true' then
    active.img.font.size = conf.font_size
    active.img.fg_color = conf.fg_color
  end

  if size then
    if relative or absolute == false then
      active.img.font.size = active.img.font.size + size
    else
      active.img.font.size = size
    end
  end

  if color then
    active.img.fg_color = color
  end
end

tags['if'] = function(param)
  local cond = param.cond or param.condition or param.value or param.val
  local code = param.code or param.expression or param.expr or param.exp

  if cond then
    kanaf.skip_other_conditions()
    return true
  end

  if code then
    local f = loadstring(string.format('return %s', code))
    if f and f() then
      kanaf.skip_other_conditions()
      return true
    end
  end

  kanaf.seek_to_next_condition()
  return true
end

function tags.image(param)
  local src = param.src or param.storage or nil
  local name = get_string(param.layer, param.name)
  local x = get_number(param.x)
  local lx = get_number(param.lx, param.left, param.left_x)
  local cx = get_number(param.cx, param.center_x)
  local rx = get_number(param.rx, param.right, param.right_x)
  local y = get_number(param.y, param.top, param.top_y)
  local cy = get_number(param.center_y, param.cy)
  local by = get_number(param.bottom_y, param.bottom, param.by)
  local mode = param.mode or param.trans or param.effect or nil
  local duration = param.duration or param.time or 1
  local show = param.show or param.visible
  local hide = param.hide or param.unvisible
  local alpha = get_number(param.alpha, param.a, param.opacity)

  local layer = layers.lookup[name]
  if not layer then
    print(string.format('warning: layer "%s" is not found.', name))
    return false
  end

  -- property settings
  layer.x = lx or layer.x
  layer.y = y or layer.y
  layer.alpha = alpha or layer.alpha

  if show or hide == false then
    layer.visible = true
  elseif hide or show == false then
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

  -- center X positioning from left edge
  if x and layer.img then
    layer.x = x - (layer.img.w / 2)
  end
  -- X positioning with centerized axis
  if cx and layer.img then
    layer.x = (conf.frame_w - layer.img.w) / 2 + cx
  end
  -- X positioning from the right edge
  if rx and layer.img then
    layer.x = conf.frame_w - layer.img.w + rx 
  end
  -- Y positioning with centerized axis
  if cy and layer.img then
    layer.y = (conf.frame_h - layer.img.h) / 2 + cy
  end
  -- Y positioning from the bottom edge
  if by and layer.img then
    layer.y = conf.frame_h - layer.img.h + by
  end
end

function tags.jump(param)
  local target = param.target or param.to
  if target then
    kanaf.load_scenario(target)
  end
end

function tags.l(param)
  kanaf.key_pressed = false
  kanaf.current.status = 'wait_key'
  layers.lookup.wait_line.visible = true
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
      message.hide_all()
      message.activate('message')
      kanaf.load_scenario(target)
      kanaf.logging = true
    end
  end

  if img then
    message.reserve_clickable_image(img, hover, on_click, nil)
    message.show_next()
  elseif text then
    message.reserve_clickable(text, on_click, nil)
    message.show_next()
  end
end

function tags.load(param)
  local id = param.id or param.name
  local log = param.log or param.game

  if log then
    if not id then
      local msg = string.format('error at %s : id is not given', kanaf.get_pos())
      lev.debug.print(msg)
      return false
    end
    kanaf.load_log(id)
  end
end

function tags.logging(param)
  local enable = param.on or param.enable
  local disable = param.off or param.disable

  if enable or disable == false then
    kanaf.logging = true
  elseif disable or enable == false then
    kanaf.logging = false
  end
  return true
end

function tags.macro(param)
  local name = param.name or param.record
  local reset = param.reset or param.rewrite

  if not name then
    local msg = string.format('warning at %s : No macro name.',
                              kanaf.get_pos())
    lev.debug.print(msg)
    return false
  end

  if reset then
    tags.macros[name] = nil
  end

  local content = kanaf.seek_to_endmacro()
  if not tags.macros[name] then
    tags.macros[name] = content
  end
end

function tags.map(param)
  local clear = param.clear or param.reset
  local name = get_string(param.name, param.layer)
  local x = get_number(param.x)
  local lx = get_number(param.lx, param.left, param.left_x, 0)
  local cx = get_number(param.cx, param.center_x)
  local rx = get_number(param.rx, param.right, param.right_x)
  local y = get_number(param.y, param.top, param.top_y, 0)
  local cy = get_number(param.cy, param.center_y)
  local by = get_number(param.by, param.bottom, param.bottom_y)
  local src = get_string(param.src, param.image, param.storage, param.img)
  local alpha = get_number(param.alpha, param.a, param.opaque, 255)
  local hover = get_string(param.hover, param.hover_image)
  local text = get_string(param.text, param.string)
  local show = param.show or param.visible
  local hide = param.hide or param.unvisible
  local call = param.call
  local jump = param.jump or param.goto
  local create = param.create
  local delete = param.delete
  local font_size = param.font_size or param.size or 32
  local above = param.above or param.set_top
  local hover_se = param.hover_se or param.hover_sound
  local lclick_se = param.lclick_se or param.lclick_sound
  local str_on_lclick = param.on_lclick or param.on_left_click

  if create and name then
    layers.add(lev.image.map(),
               {name = name, texture = true, x = 0, y = 0})
  end

  if delete and name then
    layers.delete(name)
    return true
  end

  local layer = layers.lookup[name]
  if not layer then
    print(string.format('warning: layer "%s" is not found.', tostring(name)))
    return false
  end

  if above then
    layers.set_top(name)
  end

  if show or hide == false then
    layer.visible = true
  elseif hide or show == false then
    layer.visible = false
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
    font.size = font_size
    img = lev.image.string(font, text)
  elseif src then
    local path = lev.package.resolve(src)
    path = path or lev.package.resolve(src..'.png')
    if not path then
      print(string.format('warning: image "%s" is not found.', src))
      return false
    end
    img = lev.image.load(path)
    if not img then
      print(string.format('warning: error on loading image "%s"', src))
      return false
    end
  end

  local lclick_se_path = nil
  if lclick_se then
    lclick_se_path = lev.package.resolve(lclick_se) or
                     lev.package.resolve(lclick_se .. '.ogg')
    if not lclick_se_path then
      local msg =
        string.format('warning at %s : Sound "%s" is not found.',
                      kanaf.get_pos(), hover_se)
      lev.debug.print(msg)
    end
  end

  local on_lclick = nil
  if str_on_lclick then
    on_lclick = function()
      if mixer and lclick_se_path then
        mixer:slot(0):play(lclick_se_path)
      end
      kanaf.push('lclick', str_on_lclick)
    end
  elseif call then
    on_lclick = function()
      if mixer and lclick_se_path then
        mixer:slot(0):play(lclick_se_path)
      end
      kanaf.call(call, param)
    end
  elseif jump then
    on_lclick = function()
      if mixer and lclick_se_path then
        mixer:slot(0):play(lclick_se_path)
      end
      kanaf.load_scenario(jump)
    end
  else
    on_lclick = function()
      if mixer and lclick_se_path then
        mixer:slot(0):play(lclick_se_path)
      end
    end
  end

  local on_hover = nil
  if hover_se then
    local path = lev.package.resolve(hover_se) or
                 lev.package.resolve(hover_se .. '.ogg')
    if not path then
      local msg =
        string.format('warning at %s : Sound "%s" is not found.',
                      kanaf.get_pos(), hover_se)
      lev.debug.print(msg)
    else
      on_hover = function()
        if mixer then
          mixer:slot(0):play(path)
        end
      end
    end
  end

  if img then
    if x then
      lx = x - (img.w / 2)
    elseif cx then
      lx = (conf.frame_w - img.w) / 2 + cx
    elseif rx then
      lx = conf.frame_w - img.w + rx
    end
    if cy then
      y = (conf.frame_h - img.h) / 2 + cy
    end
    if by then
      y = conf.frame_h - img.h + by
    end

    local hover_img = nil
    if hover then
      local path = lev.package.resolve(hover)
      path = path or lev.package.resolve(hover..'.png')
      if not path then
        print(string.format('warning: image "%s" is not found.', hover))
        return false
      end
      hover_img = lev.image.load(path)
      if not hover_img then
        print(string.format('warning: error on loading image "%s"', hover))
        return false
      end
    else
      hover_img = img:clone()
    end
    layer.img:map_link { img, hover_img, lx, y, alpha = alpha,
                         on_lclick = on_lclick, on_hover = on_hover }
  end
end

function tags.msg(param)
  local all = param.all
  local create = param.create or param.new
  local delete = param.delete or param.del or param.remove
  local name = get_string(param.layer, param.name)
  local activate = param.activate or param.act
  local show = param.show or param.visible
  local hide = param.hide or param.unvisible
  local x = get_number(param.x)
  local y = get_number(param.y)
  local w = get_number(param.w, param.width)

  name = name or 'active'

  if create and name then
    layers.add(lev.image.layout(w or conf.frame_w)
               {name = name, texture = true, x = x or 0, y = y or 0})
  end

  if delete and name then
    layers.delete(name)
    return true
  end

  local layer = layers.lookup[name]
  if not all then
    if not layer then
      local msg = string.format('warning at %s : layer "%s" is not found', kanaf.get_pos(), name)
      lev.debug.print(msg)
      return false
    end
  end

  if activate then
    if not name or name == 'active' then
      local msg = string.format('warning at %s : please specify the layer name', kanaf.get_pos())
      lev.debug.print(msg)
      return false
    end
    message.activate(name)
  end

  if show or hide == false then
    if all then
      message.show_all()
    else
      layer.visible = true
    end
  elseif hide or show == false then
    if all then
      message.hide_all()
    else
      layer.visible = false
    end
  end

  if x then
    layer.x = x
  end
  if y then
    layer.y = y
  end
  if w and layer.img then
    layer.img.w = w
  end
end

function tags.p(param)
  kanaf.key_pressed = false
  kanaf.current.status = 'wait_key'
  layers.lookup.wait_page.visible = true
end

function tags.print(param)
  local text = get_string(param.text, param.txt, param.string)
  local ruby = get_string(param.ruby)
  local exp = get_string(param.exp, param.expression, param.expr, param.code)

  if text then
    if ruby then
      message.reserve_word(text, ruby)
      backlog.add(string.format('[print text="%s" ruby="%s"]', text, ruby))
      message.show_next()
    else
      kanaf.push('print', text)
    end
    return true
  elseif exp then
    local f = loadstring(string.format('return %s', exp))
    local val
    if not f then
      local msg =
        string.format('warning at %s : Syntax error : %s',
                      kanaf.get_pos(), exp)
      lev.debug.print(msg)
      return false
    end
    if f then
      val = f()
    end
    kanaf.push('print', val)
    return true
  end
end

function tags.r(param)
  message.reserve_new_line()
  message.complete()
  backlog.add('[r]')
end

tags['return'] = function()
  kanaf.ret()
end

function tags.s(param)
  kanaf.key_pressed = false
  kanaf.current.status = 'stop'
end

function tags.save(param)
  local id = param.id or param.name
  local log = param.log or param.game

  if log then
    if not id then
      local msg =
        string.format('warning at %s : No ID is given.', kanaf.get_pos())
      lev.debug.print(msg)
      return false
    end
    kanaf.save_log(id, conf.thumb_w, conf.thumb_h)
  end
end

function tags.screenshot(param)
  kanaf.thumbnail = screen.screen_shot
end

function tags.select(param)
  kanaf.logging = false
  message.hide_all()
  message.activate('select')
end

function tags.set(param)
  local event = param.event or param.evt
  local call = param.call
  local jump = param.jump
  local reset = param.reset or param.clear
  local lock = param.lock or param.locking

  file = file or kanaf.current.filename

  if event == 'on_exit' or event == 'on_quit' then
    if call then
      kanaf.current.on_quit = function() kanaf.call(call, param) end
    elseif jump then
      kanaf.current.on_quit = function() kanaf.load_scenario(jump) end
    elseif reset then
      kanaf.current.on_quit = nil
    end
  elseif event == 'on_left_down' or event == 'on_left' or event == 'on_ldown' then
    if call then
      kanaf.current.on_left_down = function() kanaf.call(call, param) end
    elseif jump then
      kanaf.current.on_left_down = function() kanaf.load_scenario(jump) end
    elseif reset then
      kanaf.current.on_left_down = nil
    end
  elseif event == 'on_right_down' or event == 'on_right' or event == 'on_rdown' then
    if call then
      kanaf.current.on_right_down = function() kanaf.call(call, param) end
    elseif jump then
      kanaf.current.on_right_down = function() kanaf.load_scenario(jump) end
    elseif reset then
      kanaf.current.on_right_down = nil
    end
  elseif event == 'on_wheel_down' then
    if call then
      kanaf.current.on_wheel_down = function()
        kanaf.call(call, param)
        if lock then
          kanaf.current.on_wheel_down = nil
        end
      end
    elseif jump then
      kanaf.current.on_wheel_down = function() kanaf.load_scenario(jump) end
    elseif reset then
      kanaf.current.on_wheel_down = nil
    end
  elseif event == 'on_wheel_up' then
    if call then
      kanaf.current.on_wheel_up = function()
        kanaf.call(call, param)
        if lock then
          kanaf.current.on_wheel_up = nil
        end
      end
    elseif jump then
      kanaf.current.on_wheel_up = function() kanaf.load_scenario(jump) end
    elseif reset then
      kanaf.current.on_wheel_up = nil
    end
  end
end

function tags.skip(param)
  local once = param.once or param.one

  if once then
    kanaf.key_pressed = true
    kanaf.skip_once = true
  end
end

function tags.sound(param)
  local src = get_string(param.src, param.source, param.storage, param.file)
  local slot = param.slot or 0
  local command = param.command or param.mode
  local clear = param.clear or param.close
  local load = param.load
  local open = param.open
  local pause = param.pause or param.stop
  local play = param.play
  local replay = param.replay
  local repeating = param['repeat'] or param.repeating or param.loop or false
  local wait = param.wait or param.waiting

  if not mixer then
    local msg = string.format('warning at %s : mixer is not initialized', kanaf.get_pos())
    lev.debug.print(msg)
    return false
  end

  local path = nil
  if src then
    path = lev.package.resolve(src)
    path = path or lev.package.resolve(src .. '.ogg')
    path = path or lev.package.resolve(src .. '.wav')
    if (not path) then
      local msg = string.format('warning at %s : sound file "%s" is not found', kanaf.get_pos(), src)
      lev.debug.print(msg)
      return false
    end
  end

  if slot <= 0 then
    repeating = false
  end
  if repeating then
    play = true
  end

  if slot == 0 then
    if not src then
      local msg = string.format('warning at %s : please specify sound source file', kanaf.get_pos())
      lev.debug.print(msg)
      return false
    end
    mixer:slot(0):play(path)
    return true
  end

  if clear then
    mixer:slot(slot):clear()
  elseif load then
    if (not src) then
      local msg = string.format('warning at %s : please specify sound source file', kanaf.get_pos())
      lev.debug.print(msg)
      return false
    end
    mixer:slot(slot):load(path)
  elseif open then
    if (not src) then
      local msg = string.format('warning at %s : please specify sound source file', kanaf.get_pos())
      lev.debug.print(msg)
      return false
    end
    mixer:slot(slot):open(path)
  elseif pause then
    mixer:slot(slot):pause()
  elseif play then
    if path then
      mixer:slot(slot):play(path, repeating)
    else
      mixer:slot(slot):play(repeating)
    end
  elseif replay then
    mixer:slot(slot).pos = 0
    mixer:slot(slot):play()
  end

  if wait then
    if mixer:slot(slot).is_playing then
      mixer:slot(slot):play(false)
      tags.wait_slot = slot
      kanaf.current.status = 'wait_sound'
    end
  end

  return true
end

function tags.wait(param)
  local delay = get_number(param.time, param.delay, param.duration)
  if delay then
    tags.wait_timer:start(0)
    tags.wait_until = delay
    kanaf.current.status = 'wait'
  else
  end
end

