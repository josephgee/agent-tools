-- navigator-watch: Hammerspoon hotkey binding for the voice path.
--
-- Copy the relevant bits into your ~/.hammerspoon/init.lua (or `require` this
-- file from there). Reload Hammerspoon's config after editing.
--
-- No editing needed here per pane: speak.sh reads the surface id from a cache
-- file that watch.sh writes when you start it for a project (from inside that
-- cmux pane, where auto-detection actually works). It does NOT auto-detect by
-- itself when launched here — Hammerspoon has no ancestry link to any cmux
-- pane, and cmux's "current workspace" resolution is scoped to the caller's
-- own pane, so live detection can't work from here. If there's no cache yet,
-- run watch.sh once (or ./refresh-surface.sh) from inside the target pane.
--
-- Two styles are shown; pick one:
--   1. Toggle: tap the hotkey to start recording, tap again to stop + send.
--   2. Push-to-talk: hold the hotkey to record, release to stop + send.
--
-- This exists so you can talk to the navigator without switching focus away from
-- your IDE. Since Hammerspoon launches speak.sh OUTSIDE cmux (no process ancestry
-- link to the app), cmux's default "cmux processes only" socket access mode will
-- refuse this connection. Setting CMUX_SOCKET_MODE=allowAll here, in Hammerspoon's
-- own subprocess, does NOT fix that -- access mode is enforced by the cmux app
-- (the server), not chosen by the connecting client. You need to set the access
-- mode to allowAll for the cmux APP itself, once, persistently: open cmux's
-- Settings UI and switch the socket access mode there. (allowAll means any local
-- process can reach the socket, not just ones cmux spawned -- an intentional
-- trade-off for this hands-free-from-IDE path; reasonable on a personal machine,
-- worth thinking about on a shared one.)

local SPEAK = os.getenv("HOME") .. "/workspace/agent-tools/tools/navigator-watch/speak.sh"

local function speak(mode)
  hs.task.new("/bin/bash", nil, { "-c", SPEAK .. " " .. mode }):start()
end

-- ---- Style 1: toggle on Cmd+Alt+N -----------------------------------------
hs.hotkey.bind({ "cmd", "alt" }, "N", function()
  speak("toggle")
end)

-- ---- Style 2: push-to-talk on Cmd+Alt+M (uncomment to use) -----------------
-- hs.hotkey.bind({ "cmd", "alt" }, "M",
--   function() speak("start") end,   -- pressed
--   function() speak("stop") end)    -- released
