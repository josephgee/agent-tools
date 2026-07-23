-- navigator-watch: example Hammerspoon hotkey binding for the voice path.
--
-- Copy the relevant bits into your ~/.hammerspoon/init.lua (or `require` this
-- file from there). Reload Hammerspoon's config after editing.
--
-- Two styles are shown; pick one:
--   1. Toggle: tap the hotkey to start recording, tap again to stop + send.
--   2. Push-to-talk: hold the hotkey to record, release to stop + send.
--
-- Adjust SPEAK and SURFACE to your setup.

-- This exists so you can talk to the navigator without switching focus away from
-- your IDE. Since Hammerspoon launches outside cmux, the cmux socket is reachable
-- only if cmux's access mode is allowAll (set CMUX_SOCKET_MODE=allowAll below).

local SPEAK   = os.getenv("HOME") .. "/workspace/agent-tools/tools/navigator-watch/speak.sh"
local SURFACE = "4"      -- cmux surface id running the navigator agent (cmux list-panels --json)

local function speak(mode)
  local cmd = "CMUX_SOCKET_MODE=allowAll " .. SPEAK .. " --surface " .. SURFACE .. " " .. mode
  hs.task.new("/bin/bash", nil, { "-c", cmd }):start()
end

-- ---- Style 1: toggle on Cmd+Alt+N -----------------------------------------
hs.hotkey.bind({ "cmd", "alt" }, "N", function()
  speak("toggle")
end)

-- ---- Style 2: push-to-talk on Cmd+Alt+M (uncomment to use) -----------------
-- hs.hotkey.bind({ "cmd", "alt" }, "M",
--   function() speak("start") end,   -- pressed
--   function() speak("stop") end)    -- released
