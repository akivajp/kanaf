require 'lev.image'

backlog = backlog or { }
backlog.logmsgs = { }
backlog.view_index = 1
backlog.interval_y = 10

function backlog.init()
  kanaf.history = { '' }
end

function backlog.add(ch)
  if kanaf.logging then
    kanaf.history[#kanaf.history] = kanaf.history[#kanaf.history] .. ch
  end
end

function backlog.fill_message(index)
  if not kanaf.history[index] then return false end

  if not backlog.logmsgs[index] then
    local msg = { }
    backlog.logmsgs[index] = msg
    msg.img = lev.image.layout(conf.backlog_w or 640)
    msg.x = conf.backlog_x or 0
    local str = lev.string.unicode(kanaf.history[index])
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
        tag = tostring(str:sub(1, found - 1))
--print('TAG:', tag)
        str = str:sub(found + 1)
      else
        msg.img:reserve_word(ch)
        str = str:sub(1)
      end
    end
    msg.img:complete()
  end
end

function backlog.get_end()
  backlog.logmsgs = { }
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
  if layers.lookup.backlog then
    layers.lookup.backlog.visible = false
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
  backlog.seek(backlog.view_index - 1)
end

function backlog.show()
  local h = 0
  local y = conf.backlog_y or 0

  local img = layers.lookup.backlog.img
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
  layers.lookup.backlog.visible = true
  layers.set_top('backlog')
end

