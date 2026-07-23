-- navigator-watch: Hammerspoon hotkey binding for the voice path.
--
-- Copy the relevant bits into your ~/.hammerspoon/init.lua (or `require` this
-- file from there). Reload Hammerspoon's config after editing.
--
-- No per-pane setup needed: speak.sh auto-detects the surface running claude
-- in whichever cmux workspace is currently focused (see lib/resolve-surface.sh).
-- If you ever have multiple ambiguous claude-like surfaces open at once,
-- detection will fail loudly (see speak.sh's stderr) rather than guess wrong —
-- pass --surface explicitly below if that becomes a regular problem for you.
--
-- Two styles are shown; pick one:
--   1. Toggle: tap the hotkey to start recording, tap again to stop + send.
--   2. Push-to-talk: hold the hotkey to record, release to stop + send.
--
-- This exists so you can talk to the navigator without switching focus away from
-- your IDE. Since Hammerspoon launches outside cmux, the cmux socket is reachable
-- only if cmux's access mode is allowAll (set CMUX_SOCKET_MODE=allowAll below).

local SPEAK = os.getenv("HOME") .. "/workspace/agent-tools/tools/navigator-watch/speak.sh"

local function speak(mode)
  local cmd = "CMUX_SOCKET_MODE=allowAll " .. SPEAK .. " " .. mode
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
