-- Package Requirements

require 'lev.debug'
require 'lev.draw'
require 'lev.image'
require 'lev.package'
require 'lev.prim'
require 'lev.sound'
require 'lev.system'
require 'lev.timer'
require 'lev.util'

-- Path Settings
lev.package.clear_search()
lev.package.add_search('')
lev.package.add_search('image')
lev.package.add_search('scenario')
lev.package.add_search('sound')
lev.package.add_search('system')

-- Font Finding Settings
lev.require 'system/fonts'

-- Kanaf Module Requirements

lev.require 'system/colors'
lev.require 'system/kanaf'
lev.require 'system/layers'
lev.require 'system/message'

-- Initialize

system = lev.system()
mixer = system:mixer()

-- Configuration
conf = conf or {}
conf.app_id = 'kanaf'
conf.backlog_x = 30
conf.backlog_y = 30
conf.backlog_w = 580
conf.backlog_h = 420
conf.caption = 'Kanaf Scripting System'
conf.fg_color = white
conf.fps = 50
--conf.font_size = 17
conf.font_size = 18
conf.first_load = 'start'
conf.frame_h = 480
conf.frame_w = 640
conf.message_x = 15
conf.message_y = 320
conf.message_w = 610
conf.message_margin = 5
conf.num_layers = 5
conf.save_dir = 'savedata'
conf.save_log = 'log'
conf.save_system = 'system'
conf.select_x = 30
conf.select_y = 30
conf.select_w = 580
conf.thumb_w = 128
conf.thumb_h = 96
conf.wait_line_icon = 'wait_line.png'
conf.wait_page_icon = 'wait_page.png'

if not lev.font.load() then
  error('NO FONTS ARE FOUND!')
end

-- Mixer Slots

if mixer then
  slots = {}
  slots.effect = mixer:slot(1)
  slots.voice  = mixer:slot(2)
  slots.bgm    = mixer:slot(3)
end

-- Layers

layers.init()
-- background layer
layers.add(lev.image.transition(),
           {name = 'bg', visible = true, texture = true})
layers.lookup['0'] = layers.lookup.bg
layers.lookup[ 0 ] = layers.lookup.bg
-- foreground layers
for i = 1, conf.num_layers do
  layers.add(lev.image.transition(), {name = tostring(i), alias = i, x = 0, y = 0, texture = true})
end
-- message foreground
layers.add(lev.image.layout(conf.message_w - conf.message_margin * 2),
           {name = 'message', alias='msg', x = conf.message_x + conf.message_margin,
            y = conf.message_y + conf.message_margin, texture = true})
-- message background
layers.set_bg(lev.image.load(lev.package.resolve('message_bg.png')),
              {name = 'message', texture = true, visible = true, alpha = 200})
--layers.set_bg(lev.image.create(conf.frame_w, conf.frame_h),
--              {name = 'message', texture = true, visible = true})
--layers.lookup.message.bg.img:fill_rect(conf.message_x, conf.message_y, conf.message_w, conf.message_h,
--                                       lev.prim.color(0, 0, 255, 128))
layers.lookup.message.img.font.size = conf.font_size
layers.lookup.message.img.color = conf.fg_color or white
-- selection foreground
layers.add(lev.image.layout(conf.frame_w - 20),
           {name = 'select', alias='sel', x = conf.select_x, y = conf.select_y, texture = true})
-- selection background
layers.set_bg(lev.image.load(lev.package.resolve('select_bg.png')),
              {name = 'select', texture = true, visible = true, alpha = 200})
--layers.set_bg(lev.image.create(conf.frame_w, conf.frame_h),
--              {name = 'select', texture = true, visible = true})
--layers.lookup.select.bg.img:fill_rect(10, 5, conf.frame_w - 20, conf.frame_h - 10, lev.prim.color(200, 0, 255, 128))
layers.lookup.select.img.font.size = conf.font_size
layers.lookup.select.img.color = conf.fg_color or white

-- wait line icon
local icon_path = lev.package.resolve(conf.wait_line_icon)
if not icon_path then
  error(string.format('%s is not found'), conf.wait_line_icon)
end
layers.add(lev.image.load(icon_path),
           {name = 'wait_line', visible = false, x = 590, y = 440, texture = true})
-- wait page icon
local icon_path = lev.package.resolve(conf.wait_page_icon)
if not icon_path then
  error(string.format('%s is not found'), conf.wait_page_icon)
end
layers.add(lev.image.load(icon_path),
           {name = 'wait_page', visible = false, x = 590, y = 440, texture = true})

-- Design

window = system:window { caption = conf.caption, w = conf.frame_w, h = conf.frame_h, f = 'hidden' }
screen = window:screen()

-- Controls
kanaf.init()

window.on_close = function()
  if kanaf.current.on_quit then
    kanaf.current.on_quit()
  else
    system:quit(true)
  end
end

window.on_key_down = function(e)
--  print('down', e.key, e.keycode, e.id)
  if e.key == 'escape' then
    if window.on_right_down then
      window.on_right_down()
    end
--    system:quit()
  elseif e.key == 'lctrl' then
    kanaf.skip_mode = true
  elseif e.key == 'q' then
    system:quit(true)
  elseif e.key == 'rctrl' then
    kanaf.skip_mode = true
  elseif e.key == 'return' then
    window.on_left_down(e)
  elseif e.key == 'space' then
    window.on_left_down(e)
  end
end

window.on_key_up = function(e)
--  print('up', e.key, e.keycode)
  if e.key == 'lctrl' then
    kanaf.skip_mode = false
  elseif e.key == 'rctrl' then
    kanaf.skip_mode = false
  end
end

window.on_left_down = function(e)
  if kanaf.current.on_left_down then
    kanaf.current.on_left_down()
  else
    -- click waiting process
    if kanaf.current.status == 'wait_key' then
      kanaf.key_pressed = true
    end
    if kanaf.current.status == 'continue' then
      kanaf.skip_once = true
    end

    -- clickable images' process
    local lay = layers.get_top_visible()
    if lay then
      if lay.img.type_name == 'lev.image.layout' then
        lay.img:on_left_click(e.x - lay.x, e.y - lay.y)
      elseif lay.img.type_name == 'lev.image.map' then
        lay.img:on_left_click(e.x - lay.x, e.y - lay.y)
      end
    end
  end
end

window.on_right_down = function(e)
  if kanaf.current.on_right_down then
    kanaf.current.on_right_down()
  end
end

window.on_motion = function(e)
  -- clickable images' process
  local lay = layers.get_top_visible()
  if lay then
    if lay.img.type_name == 'lev.image.layout' then
      lay.img:on_hover(e.x - lay.x, e.y - lay.y)
    elseif lay.img.type_name == 'lev.image.map' then
      lay.img:on_hover(e.x - lay.x, e.y - lay.y)
    end
  end
end

--sw = lev.stop_watch()
screen.redraw = function(e)
--  if sw then sw:start() end
  screen:clear(0, 0, 0)
  for i, j in ipairs(layers.list) do
    if j.img and j.texture then
      j.img:texturize()
    end
    if j.bg and j.bg.img and j.bg.texture then
      j.bg.img:texturize()
    end
    if j.visible then
      if j.bg and j.bg.img and j.bg.visible then
        screen:draw(j.bg.img, j.bg.x, j.bg.y, j.bg.alpha)
      end
      if j.img then
--print('drawing: ', j.name)
        screen:draw(j.img, j.x or 0, j.y or 0, j.alpha)
      end
    end
  end
  screen:swap()
--print('TIME:', sw and sw.time)
end

-- Execute

window:show()
screen:map2d(0, conf.frame_w, 0, conf.frame_h)
screen:enable_alpha_blending()

counts = { }
total = 0
for i = 1, 10 do
  table.insert(counts, 1)
  total = total + 1
end
sw = lev.stop_watch()
draw_timer = system:clock(60)
draw_timer.on_tick = function()
--  table.insert(counts, sw.time)
--  total = total + sw.time - table.remove(counts, 1)
--  sw:start()
--  print('FPS: ', #counts / total)
--  print('DRAW')
  collectgarbage()
  screen.redraw()
end

proc_timer = system:timer(10)
proc_timer.on_tick = function()
--  print('PROC')
  kanaf.proc_next()
end

window.on_wheel = function(e)
--  print('wheel', e.x, e.y)
  if e.y > 0 and kanaf.current.on_wheel_up then
    kanaf.current.on_wheel_up()
  elseif e.y < 0 and kanaf.current.on_wheel_down then
    kanaf.current.on_wheel_down()
    kanaf.proc_next()
  end
end

--system.on_quit = function()
--  print('ONQUIT')
--  return false
--end

system:run()

kanaf.exit()
--kanaf.save_log(nil, 128, 96)

--print()
--print(log.history)
--system:close()

