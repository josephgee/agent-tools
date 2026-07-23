-- navigator-watch: example Hammerspoon hotkey binding for the voice path.
--
-- Copy the relevant bits into your ~/.hammerspoon/init.lua (or `require` this
-- file from there). Reload Hammerspoon's config after editing.
--
-- Two styles are shown; pick one:
--   1. Toggle: tap the hotkey to start recording, tap again to stop + send.
--   2. Push-to-talk: hold the hotkey to record, release to stop + send.
--
-- Adjust SPEAK, SURFACE, and SESSION to your setup.

local SPEAK   = os.getenv("HOME") .. "/workspace/agent-tools/tools/navigator-watch/speak.sh"
local SURFACE = "4"      -- cmux surface (pane) id running the navigator agent
local SESSION = "main"

local function speak(mode)
  hs.task.new("/bin/bash", nil,
    { SPEAK, "--surface", SURFACE, "--session", SESSION, mode }):start()
end

-- ---- Style 1: toggle on Cmd+Alt+N -----------------------------------------
hs.hotkey.bind({ "cmd", "alt" }, "N", function()
  speak("toggle")
end)

-- ---- Style 2: push-to-talk on Cmd+Alt+M (uncomment to use) -----------------
-- hs.hotkey.bind({ "cmd", "alt" }, "M",
--   function() speak("start") end,   -- pressed
--   function() speak("stop") end)    -- released
