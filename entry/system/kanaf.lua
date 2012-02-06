require 'lev.fs'
require 'lev.package'
require 'lev.string'
require 'lev.util'

lev.require 'tags'

-- status variables
log = { }
sys = { }
tmp = { }

module('kanaf', package.seeall)

-- state variables

buffer = lev.string.create()
content = ''
history = ''
key_pressed = false
new_line = false
status = ''
do_list = {}

-- functions

function call(filename, target)
  if not filename then
    filename = log.filename or conf.first_load
  end
  local real_file
  local found = lev.package.resolve(filename)
              or lev.package.resolve(filename .. '.knf')
              or lev.package.resolve(filename .. '.txt')
              or error(string.format('Neither %s.knf nor %s.txt is not found', filename, filename))

  local infile = io.open(tostring(found), 'r')
  content = infile:read('*a')
  buffer = lev.string.unicode(content)
  key_pressed = false
  if log.logging == false then
    logging = false
  else
    logging = true
  end
  new_line = true
  status = 'continue'
  do_list = {}
  history = history or ''

  call_stack = call_stack or {}
  table.insert(call_stack, buffer)

  log.filename = filename
  if target then
--print('FINDING:', target)
    local pos = content:find(string.format('^%%*%s|', target))
    pos = pos or content:find(string.format('^%%*%s\r?\n', target))
    pos = pos or content:find(string.format('\n%%*%s|', target))
    pos = pos or content:find(string.format('\n%%*%s\r?\n', target))
    if pos then
      buffer = lev.string.unicode(content:sub(pos))
    end
  end
  return true
end

function exit()
  save_system()
  system:quit()
end

-- find tag starting with "left" and ending with "right". e.g: [ and ]
-- seek at next position from the correspondence termination
-- return the found string
function find_tag(left, right)
  local found = ''
  local ch = tostring(buffer:index(0))
  if not (ch == left) then
    return found
  end
  buffer = buffer:sub(1)

  local count = 1
  ch = tostring(buffer:index(0))
  buffer = buffer:sub(1)
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
    ch = tostring(buffer:index(0))
    buffer = buffer:sub(1)
  end
  return ''
end

-- init the data
function init()
  buffer = lev.string.unicode(content)
  key_pressed = false
--  log.history = ''

  history = ''
  load_system()
  load_game()
--  load_scenario(conf.first_load)
end

-- load file and init
function load_scenario(filename, target)
  if not filename then
    filename = log.filename or conf.first_load
  end
  local real_file
  local found = lev.package.resolve(filename)
              or lev.package.resolve(filename .. '.lyl')
              or lev.package.resolve(filename .. '.txt')
              or error(string.format('Neither %s.lyl nor %s.txt is not found', filename, filename))

  local infile = io.open(tostring(found), 'r')
  local con = infile:read('*a')
  if target then
--print('FINDING:', target)
    local pos  = con:find(string.format('^%%*%s|', target))
    pos = pos or con:find(string.format('^%%*%s\r?\n', target))
    pos = pos or con:find(string.format('\n%%*%s|', target))
    pos = pos or con:find(string.format('\n%%*%s\r?\n', target))
    if pos then
      buffer = lev.string.unicode(con:sub(pos))
    else
      print(string.format('error: label "%s" is not found on file "%s"', target, filename))
      return false
    end
  else
    buffer = lev.string.unicode(con)
  end

  content = con
  key_pressed = false
  if log.logging == false then
    logging = false
  else
    logging = true
  end
  new_line = true
  status = 'continue'
  do_list = {}
  history = history or ''

  log.filename = filename
  return true
end

function load_game(id)
  lev.fs.mkdir(conf.save_dir, true)
  local suffix = ''
  if id then suffix = '_'..id end
  local f = loadfile(conf.save_dir .. '/' .. conf.save_game .. suffix .. '.lua')
  if f then
    _G.log = f()
  else
    _G.log = { }
  end
  history = log.history or ''
--print('LOADING', log.filename, log.label, log.scene)
  load_scenario(log.filename, log.label)
end

function load_list()
  while true do
    local ch = tostring(buffer:index(0))
--print('CH:', ch)
    if #ch == 0 then return true end
    if ch == '[' then
      local tag = find_tag('[', ']')
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
          while #tag_body > 0 do
--print('TAG BODY: ', tag_body)
            tag_body = tag_body:gsub('^[%s,]+', '')
            if tag_body:find('^%w') then
              -- word is given
              local pos1, pos2 = tag_body:find('^%w+')
              params_str = params_str .. tag_body:sub(1, pos2)
              tag_body = tag_body:sub(pos2 + 1)
              local pos1, pos2 = tag_body:find('^%s*%=%s*')
              if pos1 then
                -- "property =' is found
                params_str = params_str .. '='
                tag_body = tag_body:sub(pos2 + 1)
              else
                -- "param [property]" is found
                params_str = params_str .. ','
              end
            elseif tag_body:find('^%(') then
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
          end
--          local params_str = tag_body:gsub('%s+', ',')
--          if params_str then params_str = params_str:gsub('%,+', ',') end
--          if params_str then params_str = params_str:gsub('%,?%=%,?', '=') end
          if params_str then
--print('PARAMS: ', params_str)
            local f = loadstring(string.format('return {%s}', params_str))
            if f then
              params = f() or {}
            end
          end
        end

        if tags[tag_name] then
          local done = false
          for i, j in pairs(tags.immediate_tags) do
            if j == tag_name then
              tags[tag_name](params)
              done = true
              break
            end
          end

          if not done then
            table.insert(do_list, function() tags[tag_name](params) end)
          end

          for i, j in pairs(tags.stoppers) do
            if j == tag_name then
              return true
            end
          end
        else
          print(string.format('tags[%s] is not found', tag_name))
        end
      end
    elseif ch == '*' and new_line then
      -- scene setting
      local line = tostring(seek_to_endl())
--      local label = line:match('%*(%w+)')
      local label = line:match('%*([^|]+)|?')
--      local scene  = line:match('%*%w+|(.*)')
      local scene  = line:match('%*[^|]|(.*)')
      if label and scene and #scene > 0 then
--print('SCENE:', log.label, log.scene)
        log.label = label
        log.scene = scene
      end
      log.history = history
    elseif ch == '\n' or ch == '\r' then
      -- nothing to do (no line feed)
      buffer = buffer:sub(1)
--      history = history .. ch
      new_line = true
    elseif ch == ';' then
      -- comment line
      seek_to_endl()
    elseif ch == '\\' then
      -- escaping code
      buffer = buffer:sub(1)
      ch = tostring(buffer:index(0))
      message_reserve_word(ch)
      local f = function()
        message_show_next()
        screen.redraw()
      end
      table.insert(do_list, f)
      buffer = buffer:sub(1)
      if logging then
        history = history .. '\\' .. ch
      end
    else
      -- ordinal character
      message_reserve_word(ch)
--print('RESERVED', ch)
      local f = function()
        message_show_next()
--print('SHOW_NEXT')
        screen.redraw()
      end
      table.insert(do_list, f)
      buffer = buffer:sub(1)
      if logging then
        history = history .. ch
      end
    end
  end
  return true
end


function load_system()
  lev.fs.mkdir(conf.save_dir, true)
  local f = loadfile(conf.save_dir .. '/' .. conf.save_system .. '.lua')
  if f then
    sys = f()
  else
    sys = { }
  end
  sys.count = (sys.count or 0) + 1
end

function proc()
  if status == 'continue' then
    local f = table.remove(do_list, 1)
    if f then
      return f()
    else
      return load_list()
    end
  elseif status == 'stop' then
    return stop()
  elseif status == 'wait' then
    return wait()
  elseif status == 'wait_key' then
    return wait_key()
  end
end

function save_game(id)
  local suffix = ''
  if id then suffix = '_'..id end
  local file = io.open(conf.save_dir .. '/' .. conf.save_game .. suffix .. '.lua', 'w')
  file:write('return ' .. lev.util.serialize(log) .. '\n')
  file:close()
end

function save_system()
  local file = io.open(conf.save_dir .. '/' .. conf.save_system .. '.lua', 'w')
  file:write('return ' .. lev.util.serialize(sys) .. '\n')
  file:close()
end

function seek_to(term)
  local index = buffer:find(term)
  if index < 0 then return '' end

  local value = buffer:sub(0, index)
print('VALUE:', value)
  buffer = buffer:sub(index + #lev.string.unicode(term))
  return value.str
end

function seek_to_endl()
  local line = ''
  while true do
    ch = tostring(buffer:index(0))
    if #ch == 0 or ch == '\r' or ch == '\n' then
      break
    end
    line = line .. ch
    buffer = buffer:sub(1)
  end
  return line
end

function stop()
  return nil
end

function wait()
  if tags.wait_timer.time < tags.wait_until then
    status = 'wait'
  else
    status = 'continue'
  end
end

function wait_key()
  if key_pressed then
    layers_lookup.wait_line.visible = false
    layers_lookup.wait_page.visible = false
    key_pressed = false
    status = 'continue'
  end
end

