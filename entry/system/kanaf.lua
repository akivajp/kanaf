require 'lev.fs'
require 'lev.package'
require 'lev.string'
require 'lev.util'

lev.require 'system/backlog'
lev.require 'system/tags'

-- record variables
log = { }
sys = { }
tmp = { }
args = { }

--module('kanaf', package.seeall)
kanaf = kanaf or { }
kanaf.current = { }

-- functions

-- push current status to the call stack, and jump to the target
-- target - formatted as "filename#label" format
function kanaf.call(target, args)
--  print('CALLING', target, args)
  target = tostring(target)
  local filename = target:match('^([^#]+)')
  local label = target:match('^[^#]*#(.*)')

  if #kanaf.call_stack > 100 then
    kanaf.warning('Stack over flow !')
    return false
  end

  if not filename then
    filename = current.filename or conf.first_load
  end
  local found = lev.package.resolve(filename)
              or lev.package.resolve(filename .. '.knf')
              or lev.package.resolve(filename .. '.txt')
  if not found then
    kanaf.warning('Neither "%s.knf" nor "%s.txt" is not found.', filename, filename)
    return false
  end

  local infile = io.open(tostring(found), 'r')
--  local infile = lev.fs.open(tostring(found), 'r')
  if not infile then
    kanaf.warning("can't open the file \"%s\".", tostring(found))
    return false
  end
  local content = infile:read('*a')
  local count = 0
--  if target then
  if label then
--    target = target:gsub('^%*', '')
    local pos  = content:find('^[\t ]*#[\t ]*'..label..'[%s%|]')
    pos = pos or content:find('\n[\t ]*#[\t ]*'..label..'[%s%|]')
    if pos then
      count = #lev.string.unicode(content:sub(1, pos - 1))
    else
      kanaf.warning('Label "%s" is not found on file "%s"', label, filename)
      return false
    end
  end

  local prev = kanaf.current
  table.insert(kanaf.call_stack, lev.util.copy_table(kanaf.current))

  current.buffer = lev.string.unicode(content)
  current.filename = filename
  current.bufname = filename
  current.new_line = true
  current.status = 'continue'
  current.line = 1
  current.pos = 1
  if args then
    current.args = args
    _G.args = args
  end
  kanaf.seek_count(count)
--  print('CALLED!', current.filename, label)
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
  kanaf.seek_count(1)

  local count = 1
  ch = tostring(current.buffer:index(0))
  kanaf.seek_count(1)
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
    kanaf.seek_count(1)
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

function kanaf.get_pos()
  return string.format('%s[%s:%s]', current.bufname, current.line, current.pos)
end

-- init the data
function kanaf.init()
  -- state variables
  kanaf.call_stack = { }
  backlog.init()
  layers.select.init()
  kanaf.logging = false
  kanaf.key_pressed = false

  -- tag parser definition
  local parser = lev.string.compiler()
  parser:compile('(? $noparen =) [^\\(\\)]')
  parser:compile('(? $inparen =) ((? $coparen)|(? $noparen))+')
  parser:compile('(? $coparen =) \\((? $inparen)\\)')
  parser:compile("(? $squots =) \'[^\']*\'")
  parser:compile('(? $dquots =) \"[^\"]*\"')
  parser:compile('(? $exposed =) [^\\s,\'\"\\(\\)=]+')
  parser:compile('(? $value =)' ..
                 '  (? $exposed) | (? $squots) | (? $dquots) | (? $coparen)')
  kanaf.re_param = parser:compile('((? $exposed))\\s*(=\\s*((? $value)))?')

  -- current status
  kanaf.current = { }
  kanaf.current.buffer = lev.string.create()
  current = kanaf.current
  current.line = 1
  current.pos = 1
  current.args = args

  -- load first
  kanaf.load_system()
  kanaf.load_scenario(conf.first_load)
end

-- load file and init
-- target - formatted as "filename#label" format
--function kanaf.load_scenario(filename, target)
function kanaf.load_scenario(target)
  target = tostring(target)
  local filename = target:match('^([^#]+)')
  local label = target:match('^[^#]*#(.*)')

  if not filename then
    filename = current.filename or conf.first_load
  end
  local found = lev.package.resolve(filename)
              or lev.package.resolve(filename .. '.knf')
              or lev.package.resolve(filename .. '.txt')
  if not found then
--    local msg =
--      string.format('warning at %s : Neither "%s.knf" nor "%s.txt" is not found.',
--                    kanaf.get_pos(), filename, filename)
--    lev.debug.print(msg)
    kanaf.warning('Neigher "%s.knf" nor "%s.txt" is not found.', filename, filename)
    return false
  end

  local infile = io.open(tostring(found), 'r')
--  local infile = lev.fs.open(tostring(found), 'r')
  if not infile then
    kanaf.warning('can\t open the file "%s".', tostring(found))
    return false
  end
  local content = infile:read('*a')
  local count = 0
  if label then
    local pos  = content:find('^[\t ]*#[\t ]*'..label..'[%s%|]')
    pos = pos or content:find('\n[\t ]*#[\t ]*'..label..'[%s%|]')
    if pos then
      count = #lev.string.unicode(content:sub(1, pos - 1))
    else
      kanaf.warning('label "%s" is not found on file "%s"', label, filename)
      print('FILENAME, LABEL:', current.filename, label)
      return false
    end
  end

  current.buffer = lev.string.unicode(content)
  current.content = content
  current.filename = filename
  current.bufname = filename
  current.new_line = true
  current.status = 'continue'
  current.line = 1
  current.pos = 1
--print("\n\nLOAD! COUNT:", count)
  kanaf.seek_count(count)
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
  local last_status = current
  kanaf.init()
  kanaf.history = log.history or { '' }
  kanaf.logging = log.logging or false
  -- status resuming before the loading
  kanaf.current = last_status
  current = last_status
  -- loading
  layers.hide_sub('fg')
  kanaf.load_scenario(log.filename .. '#' .. log.label)
end

function kanaf.load_system()
  lev.fs.mkdir(conf.save_dir, true)
  local f = loadfile(conf.save_dir .. '/' .. conf.save_system .. '.lua')
  if f then
    sys = f()
  else
    sys = { }
  end
  sys.play_count = (sys.play_count or 0) + 1
  sys.passed_labels = sys.passed_labels or { }
end

-- extract the tag and parse it
-- return 1 : tag name
-- return 2 : tag parameters
function kanaf.parse_tag(tag)
--print('TAG:', tag)
  local code = tag:match('^%[(.*)%]$')
  if code then
    local f = loadstring(code)
    if f then f() end
  else
    local tag_name = tag:match('^%s*([^%s,\'\"%(]+)') or ''
--print('TAG NAME:', tag_name)
    local tag_body = tag:match('^%s*[^%s,\'\"%(]+[%s,]+(.*)$')
--print('TAG BODY: ', tag_body)
    local params = {}

    if tag_body then
      local params_str = ''
      local match  = lev.string.gmatch(tag_body, kanaf.re_param)
      if match then
        for i, j in ipairs(match) do
          if j[3].pos >= 0 then
            local value = j[3].str
            if value == 'nil' then
              -- property with nil
              -- no appends
            elseif value:sub(1,1) == "'" then
              -- property with 'string'
              -- append: ["property"]='string'
              params_str = params_str .. string.format('["%s"]=%s, ', j[1].str, j[3].str)
            elseif value:sub(1,1) == '"' then
              -- property with "string"
              -- append: ["property"]="string"
              params_str = params_str .. string.format('["%s"]=%s, ', j[1].str, j[3].str)
            elseif value:sub(1,1) == '(' then
              -- property with (expression)
              -- append: ["property"]=(expression)
              params_str = params_str .. string.format('["%s"]=%s, ', j[1].str, j[3].str)
            else
              -- property with exposed
              -- append: ["property"]="exposed"
              params_str = params_str .. string.format('["%s"]="%s", ', j[1].str, j[3].str)
            end
          else
            -- property without value
            -- append: ["property"]=true,
            params_str = params_str .. string.format('["%s"]=true, ', j[1].str)
          end
        end
      end
      if params_str then
--print('PARAMS: ', params_str)
        local f = loadstring(string.format('return {%s}', params_str))
        if f then
          params = f() or {}
        else
          local msg = string.format('warning at %s : Tag syntax error', kanaf.get_pos())
          lev.debug.print(msg)
          return nil
        end
      end
    end

    return tag_name, params
  end
end

function kanaf.proc_next()
--print('STATUS:', current.status)

  if kanaf.fullscreen then
    screen:set_fullscreen(true)
  else
    screen:set_fullscreen(false)
  end

  if current.status == 'continue' then
    kanaf.proc_token()
    if kanaf.skip_mode then
      kanaf.skip_once = true
    end
    while current.status == 'continue' and kanaf.skip_once do
      kanaf.proc_token()
    end
    if kanaf.skip_auto and log.label and
       sys.passed_labels[log.filename..'#'..log.label] then
--print('AUTO SKIP!')
      kanaf.skip_once = true
    else
      kanaf.skip_once = false
    end
  elseif current.status == 'stop' then
    return kanaf.stop()
  elseif current.status == 'wait' then
    return kanaf.wait()
  elseif current.status == 'wait_key' then
    return kanaf.wait_key()
  elseif current.status == 'wait_sound' then
    return kanaf.wait_sound()
  end
end

-- processing one token of the scenario
function kanaf.proc_token()
  while current.status == 'continue' do
    local ch = tostring(current.buffer:index(0))
--print('BUFNAME:', current.bufname, 'LINE:', current.line, 'POS:', current.pos)
--print('CH:', ch)
    if #ch == 0 then
      current.status = 'stop'
      return true
    end
    if ch == '[' then
      current.new_line = false
      local tag = kanaf.find_tag('[', ']')
      local tag_name, params = kanaf.parse_tag(tag)
--print('TAG:', tag_name)
      params = params or { }
      if tags[tag_name] then
        if lev.util.find_member(tags.controls, tag_name) then
          tags[tag_name](params)
        elseif params.cond ~= false then
          tags[tag_name](params)
        end
      elseif tags.macros[tag_name] then
        -- macro execution on stack
        if #kanaf.call_stack > 100 then
          local msg = string.format('warning at %s : Stack over flow !', kanaf.get_pos())
          lev.debug.print(msg)
          return false
        end
        kanaf.push(tag_name, tags.macros[tag_name])
        current.args = params
        args = params
      elseif tag_name then
        local msg = string.format('warning at %s : Tag "%s" (or macro) is not found',
                                  kanaf.get_pos(), tostring(tag_name))
        lev.debug.print(msg)
      end
    elseif (ch == ' ' or ch == '\t') and current.new_line then
      -- ignoring line top spaces as indent
      kanaf.seek_count(1)
    elseif ch == '#' and current.new_line then
      -- label setting
      local line = tostring(kanaf.seek_to_endl())
      local label = line:match('#[\t ]*([^|\t ]+)[\t ]*|?')
      local scene  = line:match('#[^|]*|[\t ]*(.*)')
--print("LABEL:", label)
--print("SCENE:", scene)
      if label and scene and #scene > 0 then
        if log.label then
          -- marking old labels as passed on system
          local full = log.filename .. '#' .. log.label
          sys.passed_labels[full] = true
        end
        log.label = label
        log.scene = scene
        log.history = kanaf.history
        log.logging = kanaf.logging
        log.filename = current.filename
        kanaf.save_system()
      end
    elseif ch == '\n' or ch == '\r' then
      -- line feed
      current.new_line = true
      kanaf.seek_count(1)
    elseif ch == '/' and current.buffer:index(1):cmp('/') then
      -- comment line
      current.new_line = true
      kanaf.seek_to_endl()
    elseif ch == '/' and current.buffer:index(1):cmp('*') then
      -- comment line
      kanaf.seek_to('*/')
      kanaf.seek_count(2)
    elseif ch == '\\' then
      -- escaping code
      current.new_line = false
      kanaf.seek_count(1)
      ch = tostring(current.buffer:index(0))
      message.reserve_word(ch)
      message.show_next()
      kanaf.seek_count(1)
      if kanaf.logging then
        backlog.add('\\' .. ch)
      end
      return true
    else
      current.new_line = false
      local auto_fill = true
      if ch == '、' or ch == '。' then
        auto_fill = false
      end
      message.reserve_word(ch, auto_fill)
      message.show_next()
      kanaf.seek_count(1)
      if kanaf.logging then
        backlog.add(ch)
      end
      return true
    end
  end
end

function kanaf.push(name, buffer)
  table.insert(kanaf.call_stack, lev.util.copy_table(current))
  kanaf.current.bufname =
    string.format('%s[%s:%s:%s]', kanaf.current.bufname, kanaf.current.line,
                  kanaf.current.pos, name)
  current.line = 1
  current.pos = 1
  current.buffer = lev.string.unicode(tostring(buffer) .. '[return]')
  current.status = 'continue'
  return true
end

function kanaf.ret()
  local c = table.remove(kanaf.call_stack)
  if not c then
    print("error: call stack has no records")
    return false
  end

  kanaf.current = c
  current = kanaf.current
  args = current.args
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

function kanaf.seek_count(count)
  for i = 1, count do
    local ch = tostring(current.buffer:index(0))
    current.buffer = current.buffer:sub(1)
    if #ch == 0 then
      return true
    elseif ch == '\n' then
      current.line = current.line + 1
      current.pos = 1
    else
      current.pos = current.pos + 1
    end
  end
  return true
end

function kanaf.seek_to(term)
  local index = current.buffer:find(term)
  if index > 0 then
    kanaf.seek_count(index)
  end
end

function kanaf.seek_to_endl()
  local line = ''
  while true do
    ch = tostring(current.buffer:index(0))
    if #ch == 0 or ch == '\r' or ch == '\n' then
      break
    end
    line = line .. ch
    kanaf.seek_count(1)
  end
  return line
end

function kanaf.seek_to_endmacro()
  local str = tostring(current.buffer)

  local next_end = str:find('^%[%s*endmacro[^%]]*%]') or
                   str:find('[^%\\]%[%s*endmacro[^%]]*%]')

  if not next_end then
    local msg =
      string.format('warning at %s : no [endmacro] corresponding with [macro]',
                    kanaf.get_pos())
    lev.debug.print(msg)
    return nil
  end

  local str = str:sub(1, next_end - 1)
  kanaf.seek_count(#lev.string.unicode(str))
  return str
end

function kanaf.seek_to_next_condition()
  local str = tostring(current.buffer)

  local next_else = str:find('^%[%s*else[^%]]*%]') or
                    str:find('[^%\\]%[%s*else[^%]]*%]')
  local next_end = str:find('^%[%s*endif[^%]]*%]') or
                   str:find('[^%\\]%[%s*endif[^%]]*%]')

  if not next_end then
    local msg =
      string.format('warning at %s : no [endif] corresponding with [if]',
                    kanaf.get_pos())
    lev.debug.print(msg)
    return false
  end

  local offset = next_end
  if next_else and next_else < next_end then
    offset = next_else
  end

  local count = #lev.string.unicode(str:sub(1, offset - 1))
  kanaf.seek_count(count)
end

function kanaf.skip_other_conditions()
  local str = tostring(current.buffer)

  local next_else = str:find('^%[%s*else[^%]]*%]') or
                    str:find('[^%\\]%[%s*else[^%]]*%]')
  local next_end = str:find('^%[%s*endif[^%]]*%]') or
                   str:find('[^%\\]%[%s*endif[^%]]*%]')

  if not next_end then
    local msg =
      string.format('warning at %s : no [endif] coressponding with [if]',
                    kanaf.get_pos())
    lev.debug.print(msg)
    return false
  end

  if next_else and next_else < next_end then
    local skip = str:sub(next_else, next_end - 1):gsub('[^\n]', '')
    str = str:sub(1, next_else - 1) .. skip .. str:sub(next_end)
    current.buffer = lev.string.unicode(str)
  end
  return true
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
  if kanaf.skip_auto and log.label and
     sys.passed_labels[log.filename..'#'..log.label] then
    kanaf.key_pressed = true
  end
  if kanaf.key_pressed then
    layers.lookup['top.wait_line'].visible = false
    layers.lookup['top.wait_page'].visible = false
    kanaf.key_pressed = false
    current.status = 'continue'
  end
end

function kanaf.wait_sound()
  if not mixer then
    current.status = 'continue'
  end
  if tags.wait_slot > 0 then
    if mixer:slot(tags.wait_slot).is_playing == false then
      current.status = 'continue'
      tags.wait_slot = 0
    end
  end
end

function kanaf.warning(format, ...)
  local msg = string.format(format, ...)
  local msg = string.format('warning at %s : %s', kanaf.get_pos(), msg)
  lev.debug.print(msg)
end

