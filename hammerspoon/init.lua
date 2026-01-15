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

-- Ghostty font size per monitor
-- Detects screen changes and offers to adjust font size via notification

local function getTargetFontSize()
  local mainScreen = hs.screen.mainScreen()
  local frame = mainScreen:frame()
  -- 4K monitor is larger; MacBook screen is smaller
  if frame.w >= 3840 or frame.h >= 2160 then
    return 16, "4K"
  else
    return 13, "MacBook"
  end
end

local function applyGhosttyFontSize(size)
  local ghostty = hs.application.get("com.mitchellh.ghostty")
  if ghostty then
    local key = size == 13 and "1" or "2"
    hs.eventtap.keyStroke({"ctrl", "alt", "cmd", "shift"}, key, 0, ghostty)
    hs.alert.show("Ghostty → " .. size .. "pt", 1)
  else
    hs.alert.show("Ghostty not running", 1)
  end
end

local ghosttyScreen = {
  lastScreenName = nil,
  debounceTimer = nil,
}

local function handleScreenChange()
  local size, screenName = getTargetFontSize()
  if screenName == ghosttyScreen.lastScreenName then return end
  ghosttyScreen.lastScreenName = screenName

  hs.alert.show("Ghostty: " .. screenName .. " → " .. size .. "pt\nPress Hyper+Enter to apply", 5)
end

-- Hyper+Enter: Apply detected Ghostty font size
hs.hotkey.bind({"ctrl", "alt", "cmd", "shift"}, "return", function()
  local size, _ = getTargetFontSize()
  applyGhosttyFontSize(size)
end)

-- Debounce: screen events often fire multiple times in rapid succession
local screenWatcher = hs.screen.watcher.new(function()
  if ghosttyScreen.debounceTimer then
    ghosttyScreen.debounceTimer:stop()
  end
  ghosttyScreen.debounceTimer = hs.timer.doAfter(1, handleScreenChange)
end)
screenWatcher:start()

-- Debug: Hyper+G to manually trigger Ghostty font size prompt
hs.hotkey.bind({"ctrl", "alt", "cmd", "shift"}, "g", function()
  ghosttyScreen.lastScreenName = nil
  handleScreenChange()
end)
