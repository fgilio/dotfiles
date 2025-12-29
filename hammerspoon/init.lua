-- Slack: Remap Hyper+S to toggle sidebar (Cmd+Shift+D)
-- Uses global hotkey with app check (more reliable than window.filter)
hs.hotkey.bind({'ctrl', 'alt', 'cmd', 'shift'}, 's', function()
  local app = hs.application.frontmostApplication()
  if app and app:name() == 'Slack' then
    hs.eventtap.keyStroke({'cmd', 'shift'}, 'd')
  end
end)
