-- Package Requirements

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

-- Kanaf Module Requirements

lev.require 'colors'
--lev.require 'const'
lev.require 'kanaf'
lev.require 'layers'

-- Initialize

system = lev.system()
mixer = system:mixer()

-- Configuration
conf = conf or {}
conf.app_id = 'kanaf'
conf.caption = 'Kanaf Scripting System'
conf.fg_color = white
conf.fps = 50
--conf.font_size = 17
conf.font_size = 16
conf.first_load = 'start'
conf.frame_h = 480
conf.frame_w = 640
conf.message_x = 15
conf.message_y = 380
conf.message_w = 600
conf.message_h = 90
conf.num_layers = 5
conf.save_dir = 'savedata'
conf.save_log = 'log'
conf.save_system = 'system'
conf.select_x = 15
conf.select_y = 10
conf.wait_line_icon = 'wait_line.png'
conf.wait_page_icon = 'wait_page.png'

-- Mixer Slots

if mixer then
  slots = {}
  slots.effect = mixer:slot(1)
  slots.voice  = mixer:slot(2)
  slots.bgm    = mixer:slot(3)
end

-- Layers

layers_init()
-- background layer
layers_add(lev.image.transition(),
           {name = 'bg', visible = true, texture = true})
layers_lookup['0'] = layers_lookup.bg
layers_lookup[ 0 ] = layers_lookup.bg
-- foreground layers
for i = 1, conf.num_layers do
  layers_add(lev.image.transition(), {name = tostring(i), alias = i, x = 0, y = 0, texture = true})
end
-- message foreground
layers_add(lev.image.layout(conf.frame_w - 20),
           {name = 'message', alias='msg', x = conf.message_x, y = conf.message_y, texture = true})
-- message background
layers_set_bg(lev.image.create(conf.frame_w, conf.frame_h),
              {name = 'message', texture = true, visible = true})
layers_lookup.message.bg.img:fill_rect(10, 375, conf.frame_w - 20, 95, lev.prim.color(0, 0, 255, 128))
layers_lookup.message.img.font.size = conf.font_size
layers_lookup.message.img.color = conf.fg_color or white
-- selection foreground
layers_add(lev.image.layout(conf.frame_w - 20),
           {name = 'select', alias='sel', x = conf.select_x, y = conf.select_y, texture = true})
-- selection background
layers_set_bg(lev.image.create(conf.frame_w, conf.frame_h),
              {name = 'select', texture = true, visible = true})
layers_lookup.select.bg.img:fill_rect(10, 5, conf.frame_w - 20, conf.frame_h - 10, lev.prim.color(200, 0, 255, 128))
layers_lookup.select.img.font.size = conf.font_size
layers_lookup.select.img.color = conf.fg_color or white

-- wait line icon
local icon_path = lev.package.resolve(conf.wait_line_icon)
if not icon_path then
  error(string.format('%s is not found'), conf.wait_line_icon)
end
layers_add(lev.image.load(icon_path),
           {name = 'wait_line', visible = false, x = 590, y = 440, texture = true})
-- wait page icon
local icon_path = lev.package.resolve(conf.wait_page_icon)
if not icon_path then
  error(string.format('%s is not found'), conf.wait_page_icon)
end
layers_add(lev.image.load(icon_path),
           {name = 'wait_page', visible = false, x = 590, y = 440, texture = true})
-- message layer activation
message_activate('message')

-- Design

window = system:window { caption = conf.caption, w = conf.frame_w, h = conf.frame_h, f = 'hidden' }
screen = window:screen()

-- Controls
kanaf.init()
--if (not kanaf.load(conf.first_load)) then
--  error(string.format(_'%s is not found!', conf.first_load))
--  return -1
--end

system.on_key_down = function(e)
  print('down', e.key, e.keycode)
  if e.key == 'escape' then
    if system.on_right_down then
print('JUMP TO RIGHT!')
      system.on_right_down()
    end
--    system:quit()
  elseif e.key == 'lctrl' then
    kanaf.skip_mode = true
  elseif e.key == 'q' then
    system:quit(true)
  end
end

system.on_key_up = function(e)
  print('up', e.key, e.keycode)
  if e.key == 'lctrl' then
    kanaf.skip_mode = false
  end
end

system.on_left_down = function(e)
  if kanaf.current.on_left_down then
    kanaf.current.on_left_down()
  else
    -- click waiting process
    if kanaf.current.status == 'wait_key' then
      kanaf.key_pressed = true
    end
    if kanaf.current.status == 'continue' then
      kanaf.skip_one = true
    end

    -- clickable images' process
    local lay = layers_get_top_visible()
    if lay then
      if lay.img.type_name == 'lev.image.layout' then
        lay.img:on_left_click(e.x - lay.x, e.y - lay.y)
      elseif lay.img.type_name == 'lev.image.map' then
        lay.img:on_left_click(e.x - lay.x, e.y - lay.y)
      end
    end
  end
end

system.on_right_down = function(e)
  if kanaf.current.on_right_down then
    kanaf.current.on_right_down()
  end
end

system.on_motion = function(e)
  -- clickable images' process
  local lay = layers_get_top_visible()
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
  for i, j in ipairs(layers) do
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
  screen.redraw()
end

proc_timer = system:timer(10)
proc_timer.on_tick = function()
--  print('PROC')
  kanaf.proc_next()
end

system.on_quit = function()
  if kanaf.current.on_quit then
    kanaf.current.on_quit()
  else
    system:quit(true)
  end
end

system:run()

kanaf.exit()
kanaf.save_log()

--print()
--print(log.history)
system:close()

