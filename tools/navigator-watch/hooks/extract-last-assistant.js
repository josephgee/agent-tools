#!/usr/bin/env node
"use strict";

// Reads a Claude Code hook payload as JSON on stdin, locates the session
// transcript (JSONL), and prints the plain text of the LAST assistant message.
//
// Used by on-stop.sh to feed the agent's spoken reply to a TTS engine.
// Prints nothing (exit 0) if there's no assistant text to speak.

const fs = require("fs");

function readStdin() {
  try {
    return fs.readFileSync(0, "utf8");
  } catch {
    return "";
  }
}

function textFromMessage(msg) {
  if (!msg || !msg.content) return "";
  if (typeof msg.content === "string") return msg.content;
  if (Array.isArray(msg.content)) {
    return msg.content
      .filter((b) => b && b.type === "text" && typeof b.text === "string")
      .map((b) => b.text)
      .join("\n")
      .trim();
  }
  return "";
}

function main() {
  const raw = readStdin();
  if (!raw.trim()) return;

  let payload;
  try {
    payload = JSON.parse(raw);
  } catch {
    return;
  }

  const transcript = payload.transcript_path;
  if (!transcript || !fs.existsSync(transcript)) return;

  const lines = fs.readFileSync(transcript, "utf8").split("\n");
  let lastText = "";
  for (const line of lines) {
    if (!line.trim()) continue;
    let entry;
    try {
      entry = JSON.parse(line);
    } catch {
      continue;
    }
    // Transcript entries vary in shape across versions; handle the common ones.
    const type = entry.type || (entry.message && entry.message.role);
    if (type === "assistant" || (entry.message && entry.message.role === "assistant")) {
      const t = textFromMessage(entry.message || entry);
      if (t) lastText = t;
    }
  }

  if (lastText) process.stdout.write(lastText);
}

main();
