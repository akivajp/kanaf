lev.require 'system/layers'

layers = layers or { }
layers.select = layers.select or { }

local select = layers.select

function select.init()
  if not layers.lookup['text.select.map'] then
    layers.create('text.select.map')
  end
  select.bg = layers.lookup['text.select']
  select.bg.visible = false
  select.bg.img = lev.bitmap(lev.package.resolve(conf.select_bg))
  select.bg.alpha = 200
  select.fg = layers.lookup['text.select.map']
  select.fg.img = lev.map()
  select.h = conf.frame_h
  select.w = conf.frame_w
  select.item_base = lev.bitmap(lev.package.resolve(conf.select_item_base))
  select.item_hover = lev.bitmap(lev.package.resolve(conf.select_item_hover))
  select.items = nil
end

function select.add_item(text, label)
--print('ADDING', text, label)
  select.items = select.items or { }
  local item = { }
  item.text = text
  item.label = label
  table.insert(select.items, item)
  return true
end

function select.clear()
  select.items = nil
  select.fg.img:clear()
  select.bg.visible = false
end

function select.hide()
  select.bg.visible = false
end

function select.show()
--print('SHOW SELECT')
  if not select.items then return false end
  local hspace = select.h / (#select.items + 1)
  local y = - select.item_base.h / 2
  local item_x = (select.w - select.item_base.w) / 2
  local map = select.fg.img
  message.hide()
  for i, j in pairs(select.items) do
    y = y + hspace
    local on_lclick = function()
      select.clear()
      message.show()
      kanaf.load_scenario(j.label)
      kanaf.logging = true
    end
    map:map_link { select.item_base, select.item_hover,
                   item_x, y, on_lclick = on_lclick }
    local img = lev.layout()
    img.font.size = conf.select_font_size
    img:reserve_word(j.text)
    img:complete()
--    local text_y = y + (select.item_base.h / 4)
    local text_x = (select.w - img.w) / 2
    map:map_image(img, text_x, y + (select.item_base.h - img.h) / 2)
  end
  select.fg.visible = true
  select.bg.visible = true
--print('END SHOW SELECT')
end

