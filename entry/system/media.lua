require 'lev.image'
require 'lev.package'

media = media or { }

function media.build_animation(prefix, time)
  local a = lev.animation()
  i = 1
  while true do
    local path = string.format("%s%d", prefix, i)
    local img = media.find_image(path)
    if not img then
      path = string.format("%s%02d", prefix, i)
      img = media.find_image(path)
    end
    if not img then break end
--print('APPENDING!', path)
    a:append(img, time)
    i = i + 1
  end
  return a
end

function media.find_image(path)
  if not path then return nil end
  local f = lev.package.resolve(path)
  f = f or lev.package.resolve(path .. '.png')
  f = f or lev.package.resolve(path .. '.bmp')
  if not f then return nil end
--print('IMAGE FOUND!', path)
  return lev.bitmap(f)
end

