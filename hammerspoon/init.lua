-- Hyper+S: Toggle sidebar in supported apps
-- Uses global hotkey with app check (more reliable than window.filter)
hs.hotkey.bind({'ctrl', 'alt', 'cmd', 'shift'}, 's', function()
  local app = hs.application.frontmostApplication()
  if not app then return end

  local name = app:name()
  if name == 'Slack' then
    hs.eventtap.keyStroke({'cmd', 'shift'}, 'd')
  elseif name == 'Linear' then
    hs.eventtap.keyStroke({}, '[')
  end
end)
