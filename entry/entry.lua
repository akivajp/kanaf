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
lev.require 'const'
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
conf.save_game = 'log'
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
-- message background
layers_add(lev.image.create(conf.frame_w, conf.frame_h),
           {name = 'message_bg', alias='msg_bg', texture = true})
layers_lookup.message_bg.img:fill_rect(10, 375, conf.frame_w - 20, 95, lev.prim.color(0, 0, 255, 128))
-- message foreground
layers_add(lev.image.layout(conf.frame_w - 20),
           {name = 'message_fg', alias='msg_fg', x = conf.message_x, y = conf.message_y, texture = true})
layers_lookup.message_fg.img.font.size = conf.font_size
layers_lookup.message_fg.img.color = conf.fg_color or white
-- selection background
layers_add(lev.image.create(conf.frame_w, conf.frame_h),
           {name = 'select_bg', alias='sel_bg', texture = true})
layers_lookup.select_bg.img:fill_rect(10, 5, conf.frame_w - 20, conf.frame_h - 10, lev.prim.color(200, 0, 255, 128))
-- selection foreground
layers_add(lev.image.layout(conf.frame_w - 10),
           {name = 'select_fg', alias='sel_fg', x = conf.select_x, y = conf.select_y, texture = true})
layers_lookup.select_fg.img.font.size = conf.font_size
layers_lookup.select_fg.img.color = conf.fg_color or white
-- top level map
layers_add(lev.image.map(),
           {name = 'top', x = 0, y = 0, texture = true})
message_activate('message')
--message_activate('select')

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

-- Design

window = system:window { caption = conf.caption, w = conf.frame_w, h = conf.frame_h, f = 'hidden' }
screen = window:screen()

-- Controls
kanaf.init()
--if (not kanaf.load(conf.first_load)) then
--  error(string.format(_'%s is not found!', conf.first_load))
--  return -1
--end

system.on_left_down = function(e)
  -- click waiting process
  if kanaf.status == 'wait_key' then
    kanaf.key_pressed = true
  end

  -- clickable images' process
  for i,j in ipairs(layers) do
    if j.visible and j.img then
      if j.img.type_name == 'lev.image.layout' then
        local off_x = j.x
        local off_y = j.y
        j.img:on_left_click(e.x - off_x, e.y - off_y)
      elseif j.img.type_name == 'lev.image.map' then
        local off_x = j.x
        local off_y = j.y
        j.img:on_left_click(e.x - off_x, e.y - off_y)
      end
    end
  end
end

system.on_right_down = function(e)
  print('right', e.x, e.y)
--  app:yield()
end

system.on_motion = function(e)
  for i,j in ipairs(layers) do
    if j.visible and j.img then
      if j.img.type_name == 'lev.image.layout' then
        local off_x = j.x
        local off_y = j.y
        j.img:on_hover(e.x - off_x, e.y - off_y)
      elseif j.img.type_name == 'lev.image.map' then
        local off_x = j.x
        local off_y = j.y
        j.img:on_hover(e.x - off_x, e.y - off_y)
      end
    end
  end
end

system.on_key_down = function(e)
--  print('down', e.key, e.x, e.y)
--  e:skip()
end

screen.redraw = function(e)
  if sw then sw:start() end
  screen:clear(0, 0, 0)
  for i, j in ipairs(layers) do
    if j.img and j.texture then
      j.img:texturize()
    end
    if j.img and j.visible then
--print('drawing: ', j.name)
      screen:draw(j.img, j.x or 0, j.y or 0, j.alpha)
    end
  end
  screen:swap()
--print('time', sw and sw.time)
end

-- Execute

window:show()
screen:map2d(0, conf.frame_w, 0, conf.frame_h)
screen:enable_alpha_blending()

sw = lev.stop_watch()
system.on_tick = function()
  sw:start()
  kanaf.proc()
  screen.redraw()
  system:delay(20)
end

system:run()

kanaf.exit()
kanaf.save_game()

--print()
--print(log.history)
system:close()

