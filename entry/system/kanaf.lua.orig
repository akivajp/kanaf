require 'lev.fs'
require 'lev.package'
require 'lev.string'
require 'lev.util'

lev.require 'system/tags'

-- record variables
log = { }
sys = { }
tmp = { }

--module('kanaf', package.seeall)
kanaf = kanaf or { }
kanaf.current = { }

-- functions

function kanaf.call(filename, target)
  if not filename then
    filename = current.filename or conf.first_load
  end
  local real_file
  local found = lev.package.resolve(filename)
              or lev.package.resolve(filename .. '.knf')
              or lev.package.resolve(filename .. '.txt')
              or error(string.format('Neither %s.knf nor %s.txt is not found', filename, filename))

  local buffer = nil
  local infile = io.open(tostring(found), 'r')
  local content = infile:read('*a')
  if target then
    target = target:gsub('^%*', '')
    local pos   = content:find('^%s*%*'..target..'[%s%|]')
    pos  = pos or content:find('\n%s*%*'..target..'[%s%|]')
    if pos then
      buffer = lev.string.unicode(content:sub(pos))
    else
      print(string.format('error: label "%s" is not found on file "%s"', target, filename))
      return false
    end
  else
    buffer = lev.string.unicode(content)
  end

  local prev = kanaf.current
  table.insert(kanaf.call_stack, kanaf.current)
  kanaf.current = { }
  current = kanaf.current
  current.on_left_down = prev.on_left_down
  current.on_quit = prev.on_quit
  current.on_right_down = prev.on_right_down

  current.buffer = buffer
  current.filename = filename
  current.new_line = true
  current.status = 'continue'
  return true
end

function kanaf.exit()
  kanaf.save_system()
  system:quit(true)
end

-- find tag starting with "left" and ending with "right". e.g: [ and ]
-- seek at next position from the correspondence termination
-- return the found string
function kanaf.find_tag(left, right)
  local found = ''
  local ch = tostring(current.buffer:index(0))
  if not (ch == left) then
    return found
  end
  current.buffer = current.buffer:sub(1)

  local count = 1
  ch = tostring(current.buffer:index(0))
  current.buffer = current.buffer:sub(1)
  while #ch > 0 do
    if ch == left then
      count = count + 1
    elseif ch == right then
      count = count - 1
    end
    if count == 0 then
      return found
    end
    found = found .. ch
    ch = tostring(current.buffer:index(0))
    current.buffer = current.buffer:sub(1)
  end
  return ''
end

function kanaf.get_log(id)
  lev.fs.mkdir(conf.save_dir, true)
  local suffix = ''
  if id then suffix = '_'..id end
  local f = loadfile(conf.save_dir .. '/' .. conf.save_log .. suffix .. '.lua')
  if f then
    return f()
  else
    return false
  end
end

function kanaf.get_log_date(id)
  local t = kanaf.get_log(id) or { }
  return t.date
end

function kanaf.get_log_image(id)
  local suffix = ''
  if id then suffix = '_'..id end
  return conf.save_dir .. '/' .. conf.save_log .. suffix .. '.png'
end

function kanaf.get_log_scene(id)
  local t = kanaf.get_log(id) or { }
  return tostring(t.scene)
end

-- init the data
function kanaf.init()
  -- state variables
  kanaf.call_stack = { }
  kanaf.history = ''
  kanaf.interrupted = false
  kanaf.logging = false
  kanaf.key_pressed = false

  kanaf.current = { }
  kanaf.current.buffer = lev.string.create()
  kanaf.current.filename = nil
  kanaf.current.new_line = false
  kanaf.current.on_left_down = nil
  kanaf.current.on_quit = nil
  kanaf.current.on_right_down = nil
  kanaf.current.status = ''
  current = kanaf.current

  kanaf.load_system()
  kanaf.load_scenario(conf.first_load)
end

-- load file and init
function kanaf.load_scenario(filename, target)
  if not filename then
    filename = current.filename or conf.first_load
  end
  local real_file
  local found = lev.package.resolve(filename)
              or lev.package.resolve(filename .. '.knf')
              or lev.package.resolve(filename .. '.txt')
              or error(string.format('Neither %s.knf nor %s.txt is not found', filename, filename))

  local infile = io.open(tostring(found), 'r')
  local content = infile:read('*a')
  if target then
    target = target:gsub('^%*', '')
    local pos   = content:find('^%s*%*'..target..'[%s%|]')
    pos  = pos or content:find('\n%s*%*'..target..'[%s%|]')
    if pos then
      current.buffer = lev.string.unicode(content:sub(pos))
    else
      print(string.format('error: label "%s" is not found on file "%s"', target, filename))
      return false
    end
  else
    current.buffer = lev.string.unicode(content)
  end

  current.content = content
  current.filename = filename
  current.new_line = true
  current.status = 'continue'
  return true
end

function kanaf.load_log(id)
  lev.fs.mkdir(conf.save_dir, true)
  local suffix = ''
  if id then suffix = '_'..id end
  local f = loadfile(conf.save_dir .. '/' .. conf.save_log .. suffix .. '.lua')
  if f then
    log = f()
  else
    log = { }
  end
--  kanaf.init()
  kanaf.history = log.history or ''
  kanaf.logging = log.logging or false
--print('LOADING', log.filename, log.label, log.scene)
  kanaf.load_scenario(log.filename, log.label)
end

function kanaf.load_system()
  lev.fs.mkdir(conf.save_dir, true)
  local f = loadfile(conf.save_dir .. '/' .. conf.save_system .. '.lua')
  if f then
    sys = f()
  else
    sys = { }
  end
  sys.count = (sys.count or 0) + 1
end

-- extract the tag and parse it
-- return 1 : tag name
-- return 2 : tag parameters
function kanaf.parse_tag()
  local tag = kanaf.find_tag('[', ']')
--print('TAG:', tag)
  local code = tag:match('^%[(.*)%]$')
  if code then
    local f = loadstring(code)
    if f then f() end
  else
    local tag_name = tag:match('^%s*([^%s,]+)') or ''
    local tag_body = tag:match('^%s*[^%s,]+[%s,]+(.*)$')
    local params = {}

    if tag_body then
      local params_str = ''
--print('TAG BODY: ', tag_body)
      while #tag_body > 0 do
        tag_body = tag_body:gsub('^[%s,]+', '')
        if tag_body:find('^%w') then
          -- word or "table.variable" is found
          local pos1, pos2 = tag_body:find('^[%w._]+')
          params_str = params_str..tag_body:sub(1, pos2)
          tag_body = tag_body:sub(pos2 + 1)
          local pos1, pos2 = tag_body:find('^%s*%=%s*')
          if pos1 then
            -- "property =' is found
            params_str = params_str .. '='
            tag_body = tag_body:sub(pos2 + 1)

            if tag_body:find('^%(') then
              -- "(expression)" is found
              local pos1, pos2 = tag_body:find('^%b()')
              if pos1 then
                params_str = params_str .. tag_body:sub(1, pos2) .. ','
                tag_body = tag_body:sub(pos2 + 1)
              else
                print("warning: no right paren ')' correspoinding with left paren '('")
                break
              end
            elseif tag_body:find('^"') then
              -- "string" is found 
              local pos1, pos2 = tag_body:find('[^%"]%"')
              if pos2 then
                params_str = params_str .. tag_body:sub(1, pos2) .. ','
                tag_body = tag_body:sub(pos2 + 1)
              else
                print([[warning: no right double quotation '"' correspoinding with the left]])
                break
              end
            elseif tag_body:find("^'") then
              -- 'string' is found
              local pos1, pos2 = tag_body:find("[^%']%'")
              if pos2 then
                params_str = params_str .. tag_body:sub(1, pos2) .. ','
                tag_body = tag_body:sub(pos2 + 1)
              else
                print([[warning: no right single quotation (') correspoinding with the left]])
                break
              end
            else
              -- other expression is found
              local pos1, pos2 = tag_body:find("[%s,]+")
              if pos1 then
                -- "param ," form is found
                params_str = params_str .. tag_body:sub(1, pos1-1) .. ','
                tag_body = tag_body:sub(pos2 + 1)
              else
                -- "param$" form is found
                params_str = params_str .. tag_body
                break
              end
            end
          else
            -- "param [property]" is found
            params_str = params_str .. '=true,'
          end
        end
      end
      if params_str then
--print('PARAMS: ', params_str)
        local f = loadstring(string.format('return {%s}', params_str))
        if f then
          params = f() or {}
        else
          print('error: tag syntax error')
        end
      end
    end

    return tag_name, params
  end
end

function kanaf.proc_next()
--print('STATUS:', current.status)
  if current.status == 'continue' then
    kanaf.proc_token()
    while current.status == 'continue' and (kanaf.skip_mode or kanaf.skip_one) do
      kanaf.proc_token()
    end
    kanaf.skip_one = false
  elseif current.status == 'stop' then
    return kanaf.stop()
  elseif current.status == 'wait' then
    return kanaf.wait()
  elseif current.status == 'wait_key' then
    return kanaf.wait_key()
  end
end

-- processing one token of the scenario
function kanaf.proc_token()
  local ch = tostring(current.buffer:index(0))
--print('CH:', ch)
  if #ch == 0 then
    current.status = 'stop'
    return true
  end
  if ch == '[' then
    current.new_line = false
    local tag_name, params = kanaf.parse_tag()
--print('TAG:', tag_name)
    params = params or { }
    if tags[tag_name] and params.cond ~= false then
      return tags[tag_name](params)
    end
    return false
  elseif ch == '*' and current.new_line then
    -- label setting
    current.new_line = false
    local line = tostring(kanaf.seek_to_endl())
    local label = line:match('%*([^|]+)|?')
    local scene  = line:match('%*[^|]+|(.*)')
    if label and scene and #scene > 0 then
      log.label = label
      log.scene = scene
      log.history = kanaf.history
      log.logging = kanaf.logging
      log.filename = current.filename
      kanaf.save_system()
--print('SCENE:', log.label, log.scene)
    end
  elseif ch == '\n' or ch == '\r' then
    -- line feed
    current.new_line = true
    current.buffer = current.buffer:sub(1)
    if kanaf.logging then
      kanaf.history = kanaf.history .. '\n'
    end
  elseif ch == ';' then
    -- comment line
    current.new_line = false
    kanaf.seek_to_endl()
  elseif ch == '\\' then
    -- escaping code
    current.new_line = false
    current.buffer = current.buffer:sub(1)
    ch = tostring(current.buffer:index(0))
    message_reserve_word(ch)
    message_show_next()
    current.buffer = current.buffer:sub(1)
    if kanaf.logging then
      kanaf.history = kanaf.history .. '\\' .. ch
    end
    return true
  else
    -- ordinal character
    current.new_line = false
    message_reserve_word(ch)
    message_show_next()
    current.buffer = current.buffer:sub(1)
    if kanaf.logging then
      kanaf.history = kanaf.history .. ch
    end
    return true
  end
end

function kanaf.ret()
  local c = table.remove(kanaf.call_stack)
  if not c then
    print("error: call stack has no records")
    return false
  end

  kanaf.current = c
  current = kanaf.current
end

function kanaf.save_log(id, w, h)
  local suffix = ''
  if id then suffix = '_'..id end
  log.date = os.date('%Y/%m/%d %H:%M:%S')
  local file = io.open(conf.save_dir .. '/' .. conf.save_log .. suffix .. '.lua', 'w')
  file:write('return ' .. lev.util.serialize(log) .. '\n')
  file:close()
  local img = kanaf.thumbnail
  if w and h then
    img = img:resize(w, h)
  end
  if img then
    img:save(conf.save_dir .. '/' .. conf.save_log .. suffix .. '.png')
  end
end

function kanaf.save_system()
  local file = io.open(conf.save_dir .. '/' .. conf.save_system .. '.lua', 'w')
  file:write('return ' .. lev.util.serialize(sys) .. '\n')
  file:close()
end

function kanaf.seek_to(term)
  local index = current.buffer:find(term)
  if index < 0 then return '' end

  local value = current.buffer:sub(0, index)
print('VALUE:', value)
  current.buffer = current.buffer:sub(index + #lev.string.unicode(term))
  return value.str
end

function kanaf.seek_to_endl()
  local line = ''
  while true do
    ch = tostring(current.buffer:index(0))
    if #ch == 0 or ch == '\r' or ch == '\n' then
      break
    end
    line = line .. ch
    current.buffer = current.buffer:sub(1)
  end
  return line
end

function kanaf.stop()
  return nil
end

function kanaf.wait()
  if kanaf.skip_mode then
    current.status = 'continue'
    return
  end

  if tags.wait_timer.time < tags.wait_until then
    current.status = 'wait'
  else
    current.status = 'continue'
  end
end

function kanaf.wait_key()
  if kanaf.skip_mode then
    kanaf.key_pressed = true
  end
  if kanaf.key_pressed then
    layers_lookup.wait_line.visible = false
    layers_lookup.wait_page.visible = false
    kanaf.key_pressed = false
    current.status = 'continue'
  end
end

