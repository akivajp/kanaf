-- Package Requirements

require 'lev.debug'
require 'lev.draw'
require 'lev.image'
require 'lev.map'
require 'lev.package'
require 'lev.prim'
require 'lev.sound'
require 'lev.system'
require 'lev.timer'
require 'lev.util'
require 'debug'

-- System Initialization

system = lev.system()

-- Configuration
lev.require 'config'

-- Initialization of Important instances
mixer = lev.mixer()
screen = lev.screen { caption = conf.caption,
                      w = conf.frame_w,
                      h = conf.frame_h }
--screen = system:screen { caption = conf.caption,
--                         w = conf.frame_w,
--                         h = conf.frame_h }


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
lev.require 'system/media'
lev.require 'system/message'
lev.require 'system/select'

if not lev.font() then
  error('NO FONTS ARE FOUND!')
end
--lev.debug.print(lev.font().path)

-- Mixer Slots

if mixer then
  slots = {}
  slots.effect = mixer:slot(1)
  slots.voice  = mixer:slot(2)
  slots.bgm    = mixer:slot(3)
end

-- Layers
-- background layer
layers.init()
layers.create('bg')
-- foreground layers
layers.create('fg')
-- text layers
layers.create('text')
-- message layer ( sub layer of text )
layers.create('text.message.print')
layers.lookup['text.message.print'].img =
  lev.layout(conf.message_w - conf.message_margin * 2)
layers.lookup['text.message.print'].x =
  conf.message_x + conf.message_margin
layers.lookup['text.message.print'].y =
  conf.message_y + conf.message_margin
layers.lookup['text.message'].img =
  media.find_image('message_bg')
layers.lookup['text.message.print'].img.font.size = conf.font_size
layers.lookup['text.message.print'].img.fg_color = conf.fg_color
message.activate('text.message.print')
layers.lookup['text.message'].visible = false
-- select layer ( sub layer of text )
--layers.create('text.select.print')
--layers.lookup['text.select.print'].img =
--  lev.layout(conf.frame_w - 20)
--layers.lookup['text.select.print'].x = conf.select_x
--layers.lookup['text.select.print'].y = conf.select_y
---- selection background
--layers.lookup['text.select'].img =
--  lev.bitmap(lev.package.resolve('select_bg.png'))
--layers.lookup['text.select'].alpha = 200
--layers.lookup['text.select.print'].img.font.size = conf.font_size
--layers.lookup['text.select.print'].img.fg_color = conf.fg_color
--layers.lookup['text.select'].visible = false
-- wait line icon
layers.create('top.wait_line')
layers.lookup['top.wait_line'].img =
  media.find_image(conf.wait_line_icon)
layers.lookup['top.wait_line'].x = 590
layers.lookup['top.wait_line'].y = 440
layers.lookup['top.wait_line'].visible = false
-- wait page icon
layers.create('top.wait_page')
layers.lookup['top.wait_page'].img =
  media.find_image(conf.wait_page_icon)
layers.lookup['top.wait_page'].x = 590
layers.lookup['top.wait_page'].y = 440
layers.lookup['top.wait_page'].visible = false
-- wait icon
layers.create('top.wait')
layers.lookup['top.wait'].img = media.build_animation('icon_wait_', 0.5)
layers.lookup['top.wait'].x = 590
layers.lookup['top.wait'].y = 430
layers.lookup['top.wait'].visible = false

-- Control Init
kanaf.init()

-- Last Events
events = { }

-- Events

screen.on_close = function()
print('ON CLOSE')
  if kanaf.current.on_quit then
    kanaf.current.on_quit()
  else
    system:quit(true)
  end
end

screen.on_key_down = function(e)
--  print('down', e.key, e.keycode, e.id)
  if e.key == 'escape' then
    if screen.on_right_down then
      screen.on_right_down()
    end
--    system:quit()
  elseif e.key == 'lctrl' then
    kanaf.skip_mode = true
  elseif e.key == 'd' then
    system:start_debug()
  elseif e.key == 'q' then
    system:quit(true)
  elseif e.key == 'rctrl' then
    kanaf.skip_mode = true
  elseif e.key == 'return' then
    screen.on_left_down(e)
  elseif e.key == 'space' then
    screen.on_left_down(e)
  end
end

screen.on_key_up = function(e)
--  print('up', e.key, e.keycode)
  if e.key == 'lctrl' then
    kanaf.skip_mode = false
  elseif e.key == 'rctrl' then
    kanaf.skip_mode = false
  end
end

screen.on_left_down = function(e)
print('ON LEFT DOWN', e.x, e.y, e.time)
  local last = events.last_left_down
  events.last_left_down = e.clone

  if last then
    local duration = e.time - last.time
--print('DOWN DURATION:', duration)
    if duration < 0.2 then
print('DOUBLE CLICK!')
      kanaf.on_double_click(x, y)
    end
  end

  if kanaf.current.on_left_down then
    kanaf.current.on_left_down()
  else
    local done = layers.on_left_down(e.x, e.y)
    if not done then
      -- click waiting process
      if kanaf.current.status == 'wait_key' then
        kanaf.key_pressed = true
      end
      if kanaf.current.status == 'continue' then
        conf.autoskip = false
  --      if message.active.visible then
          kanaf.skip_once = true
  --      end
      end
    end
  end
end

screen.on_left_up = function(e)
  print('ON LEFT UP', e.x, e.y, e.time)
  local down = events.last_left_down
--  print('LAST LEFT DOWN', down.x, down.y, down.time)
--  print('TERM:', e.time - down.time)
  local duration = e.time - down.time
--  if duration > 0.1 then
--    print('SINGLE CLICK!')
--  end

  layers.on_left_up(e.x, e.y)
end

screen.on_right_down = function(e)
  if kanaf.current.on_right_down then
    kanaf.current.on_right_down()
  end
end

screen.on_motion = function(e)
--print('ON MOTION', e.x, e.y, e.left_is_down)
  if e.left_is_down
  then
    -- left dragging
  else
    -- free motions
    layers.on_motion(e.x, e.y)
  end
end

sw = lev.stop_watch()
screen.redraw = function(e)
  kanaf.request_redraw = false
--  if sw then sw:start() end
  screen:clear()
  layers.draw()
  screen:swap()
--print('DRAW TIME:', sw and sw.time)
--print('end draw\n')
end

-- Execute

--window:show()
--screen:map2d(0, conf.frame_w, 0, conf.frame_h)
--screen:enable_alpha_blending()

counts = { }
total = 0
for i = 1, 10 do
  table.insert(counts, 1)
  total = total + 1
end
sw = lev.stop_watch()
draw_timer = lev.clock(conf.fps)
draw_timer.on_tick = function()
  kanaf.request_redraw = true
end

proc_timer = lev.timer(20 / 1000)
proc_timer.on_tick = function()
--  if sw then sw:start() end
--  print('CURRENT FILE', kanaf.current.filename)
--  print('PROC')
  kanaf.proc_next()
--  print('PROCCESS TIME: ', sw and sw.time)
end

screen.on_wheel = function(e)
  if sw then sw:start() end
--  print('WHEEL', e.x, e.y, e.z, e.dx, e.dy, e.dz)
  if e.y > 0 and kanaf.current.on_wheel_up then
    kanaf.current.on_wheel_up()
    kanaf.proc_next()
  elseif e.y < 0 and kanaf.current.on_wheel_down then
    kanaf.current.on_wheel_down()
    kanaf.proc_next()
  end
--  print('WHEEL PROCESS:', sw and sw.time)
end

system.on_quit = function()
  print('ONQUIT')
  return false
end

system.on_idle = function()
  if kanaf.request_redraw then
    kanaf.request_redraw = false
--    print('START REDRAW')
    screen.redraw()
--    print('END REDRAW\n')
  end
  collectgarbage()
end

--screen:set_full_screen(true)
system:run()

kanaf.exit()
--kanaf.save_log(nil, 128, 96)

--print()
--print(log.history)
--system:close()

