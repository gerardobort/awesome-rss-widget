--[[

  RSS Reader  - Awesome WM Widget
  This widget reads from a RSS xml feed, and shows one item at once
  You can scroll down/up over the widget to move across items or just do click over one
  to open it with your default web browser.
  Tested with awesome v3.4.5
  
  @requires lua5.1 and liblua5.1-socket2 package

  @author Gerardo Bort
  @email gerardobort@gmail.com

]]

function rssReader(action, widget, cache)
  if "update" == action then
    local url = "http://rss.slashdot.org/Slashdot/slashdot"
    local http = require("socket.http")
    local body, c, h = http.request(url)
    cache.items = {}
    if 200 == c then
      local i = 1
      for item in string.gmatch(body, "<item[^>]*>(.-)</item>") do
        local Y,mm,dd, h,m,s = string.match(item,
          "<dc:date[^>]*>(%d%d%d%d)--(%d%d)--(%d%d)%S(%d%d):(%d%d):(%d%d).-</dc:date>")
        cache.items[i] = {
          title = string.match(item, "<title[^>]*>(.-)</title>"),
          link = string.match(item, "<link[^>]*>(.-)</link>"),
          description = string.match(item, "<description[^>]*>(.-)</description>"),
          date = os.time{year=Y, month=mm, day=dd, hour=h, min=m, sec=s, isdst=false}
        }
        i = i + 1
      end
      if (cache.body ~= body) then
        naughty.notify({
          title      = "RSS updated!",
          text       = #cache.items .. " RSS items loaded",
          timeout    = 5,
          position   = "bottom_right",
          fg         = beautiful.fg_focus,
          bg         = beautiful.bg_focus
        })
        cache.body = body
      end
    end
  elseif "show-next" == action then
    if cache.i < # cache.items then
      cache.i = cache.i + 1
    end
  elseif "show-prev" == action then
    if cache.i > 1 then
      cache.i = cache.i - 1
    end
  end

  for i, item in ipairs(cache.items) do
    if cache.i == i then
      if "open" == action then
        awful.util.spawn("x-www-browser " .. item.link)
      else
        widget.text = " " .. i
          .. " | <i>" .. os.date("%c", item.date) .. "</i> <b>" .. item.title .. "</b> | " 
          .. string.sub(item.description, 0, 170) .. "..."
      end
      break
    end
  end
end
wg_rss = widget({
  type = "textbox", name = "wg_rss", align = "right"
})
wg_cache = {body = "", items = {}, i = 1}
wg_rss:buttons({
	button({ }, 1, function () rssReader("open", wg_rss, wg_cache) end),
	button({ }, 4, function () rssReader("show-prev", wg_rss, wg_cache) end),
	button({ }, 5, function () rssReader("show-next", wg_rss, wg_cache) end)
})
rssReader("update", wg_rss, wg_cache)
awful.hooks.timer.register(10, function () rssReader("update", wg_rss, wg_cache) end)

