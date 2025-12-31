-- Hyper+S: Toggle sidebar in supported apps
-- Uses global hotkey with app check (more reliable than window.filter)
local hyperSHotkey
hyperSHotkey = hs.hotkey.bind({'ctrl', 'alt', 'cmd', 'shift'}, 's', function()
  local app = hs.application.frontmostApplication()
  if not app then return end

  local name = app:name()
  if name == 'Slack' then
    hs.eventtap.keyStroke({'cmd', 'shift'}, 'd')
  elseif name == 'Linear' then
    hs.eventtap.keyStroke({}, '[')
  else
    -- Disable hotkey, pass through, re-enable with safety guarantees
    hyperSHotkey:disable()
    pcall(function()
      hs.eventtap.keyStroke({'ctrl', 'alt', 'cmd', 'shift'}, 's')
    end)
    -- Timer delay avoids rapid-tap interleaving
    hs.timer.doAfter(0, function() hyperSHotkey:enable() end)
  end
end)
