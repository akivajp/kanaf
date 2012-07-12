require 'lev.image'
lev.require 'system/layers'

backlog = backlog or { }
backlog.logmsgs = { }
backlog.view_index = 1
backlog.interval_y = 10

function backlog.init()
  kanaf.history = { '' }
--  layers.create('text.backlog.print')
  layers.create('top.backlog.print')
--  backlog.bg = layers.lookup['text.backlog']
  backlog.bg = layers.lookup['top.backlog']
  backlog.bg.visible = false
--  backlog.fg = layers.lookup['text.backlog.print']
  backlog.fg = layers.lookup['top.backlog.print']
  backlog.fg.img = lev.map()
  backlog.fg.blocking = true
end

function backlog.add(ch)
  if kanaf.logging then
    kanaf.history[#kanaf.history] = kanaf.history[#kanaf.history] .. ch
  end
end

function backlog.fill_message(index)
--  if sw then sw:start() end
  if not kanaf.history[index] then return false end

  if not backlog.logmsgs[index] then
    local msg = { }
    backlog.logmsgs[index] = msg
    msg.img = lev.layout(conf.backlog_w or 640)
    msg.x = conf.backlog_x or 0
    local str = lev.ustring(kanaf.history[index])
    while true do
      local ch = tostring(str:index(0))
--print('CH:', ch)
      if ch == '' then
        break
      elseif ch == '\\' then
        msg.img:reserve_word(str:index(1))
        str = str:sub(2)
      elseif ch == '[' then
        local found = str:find(']')
        if not found then break end
--print('FOUND:', found)
        local tag = tostring(str:sub(1, found - 1))
--print('TAG:', tag)
        local tag_name, params = kanaf.parse_tag(tag)
--print('TAG NAME:', tag_name, params)
        if tag_name == 'print' then
          if params.ruby then
            msg.img:reserve_word(params.text, params.ruby)
          else
            msg.img:reserve_word(params.text)
          end
        end
        str = str:sub(found + 1)
      else
        msg.img:reserve_word(ch)
        str = str:sub(1)
      end
    end
    msg.img:complete()
  end
--  print('BACKLOG FILL MESSAGE: ', sw and sw.time)
end

function backlog.get_end()
  local h = 0

  for i = #kanaf.history, 1, -1 do
    if not backlog.logmsgs[i] then
      backlog.fill_message(i)
    end

    local msg = backlog.logmsgs[i]
    if msg and msg.img then
      h = h + msg.img.h + backlog.interval_y
    end
    if h > conf.backlog_h then
      return i + 1
    end
  end
  return 1
end

function backlog.hide()
  backlog.logmsgs = { }
  if backlog.bg then
    backlog.bg.visible = false
  end
end

function backlog.new_page()
  if kanaf.logging then
    table.insert(kanaf.history, '')
  end
end

function backlog.seek(index)
  if index <= 0 then
    backlog.view_index = 0
    return true
  end

  local index_stop = backlog.get_end()
  if index > index_stop then
    backlog.view_index = index_stop
  else
    backlog.view_index = index
  end
end

function backlog.seek_end()
  backlog.view_index = backlog.get_end()
end

function backlog.seek_init()
  backlog.view_index = 1
end

function backlog.seek_next()
  backlog.seek(backlog.view_index + 1)
end

function backlog.seek_prev()
  backlog.view_index = backlog.view_index - 1
  if backlog.view_index <= 0 then
    backlog.view_index = 1
  end
end

function backlog.show()
--  if sw then sw:start() end
  local h = 0
  local y = conf.backlog_y or 0

  local img = backlog.fg.img
  img:clear()
  for i = backlog.view_index, #kanaf.history do
    if not backlog.logmsgs[i] then
      backlog.fill_message(i)
    end

    local msg = backlog.logmsgs[i]
    if msg and msg.img then
      if h + msg.img.h > conf.backlog_h then break end
      img:map_image(msg.img, msg.x, y + h, 255)
      h = h + msg.img.h + backlog.interval_y
    end
  end
  backlog.fg.visible = true
  backlog.bg.visible = true
--  layers.set_top('text.backlog')
  layers.set_top('top.backlog')
--  print('BACKLOG SHOW :', sw and sw.time)
end

