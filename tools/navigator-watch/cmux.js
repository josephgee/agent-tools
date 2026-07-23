#!/usr/bin/env node
"use strict";

// Minimal client for the cmux control socket (JSON-lines, protocol v9).
// Speaks just enough of the protocol for the navigator watcher: identify,
// list-workspaces, read-screen, send, send-key.
//
// Socket resolution, in order (matches cmux):
//   1. --socket <path>              explicit override
//   2. $CMUX_TUI_SOCKET / $CMUX_MUX_SOCKET   set by cmux for processes it launches
//      (so anything started inside a cmux pane, incl. Claude Code hooks, just works)
//   3. $XDG_RUNTIME_DIR/cmux-tui-<uid>/<session>.sock
//   4. $TMPDIR/cmux-tui-<uid>/<session>.sock
//   5. /tmp/cmux-tui-<uid>/<session>.sock
// Default session is "main". The cmux control socket is always served; nothing
// needs to be enabled.
//
// Usage:
//   cmux.js [--session <name>] [--socket <path>] identify
//   cmux.js [...] list
//   cmux.js [...] read-screen --surface <id>
//   cmux.js [...] send --surface <id> --text "hello"
//   cmux.js [...] send --surface <id> --text "hello" --enter    # append CR to submit
//   cmux.js [...] send --surface <id> --text "multi\nline" --paste  # bracketed paste
//   cmux.js [...] send-key --surface <id> --keys enter
//
// For multi-line payloads, prefer `send --paste` (keeps embedded newlines literal
// instead of submitting early) followed by a separate `send-key --keys enter`.
//
// Output is the raw JSON `data` from the response, printed as JSON.
// Exit code is non-zero on protocol error.

const net = require("net");
const os = require("os");
const path = require("path");
const fs = require("fs");

function parseArgs(argv) {
  const args = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith("--")) {
      const key = a.slice(2);
      const next = argv[i + 1];
      if (next === undefined || next.startsWith("--")) {
        args[key] = true; // boolean flag
      } else {
        args[key] = next;
        i++;
      }
    } else {
      args._.push(a);
    }
  }
  return args;
}

function defaultSocketPath(session) {
  // Prefer the socket cmux exports to its child processes.
  const fromEnv = process.env.CMUX_TUI_SOCKET || process.env.CMUX_MUX_SOCKET;
  if (fromEnv) return fromEnv;

  const uid = typeof process.getuid === "function" ? process.getuid() : "0";
  const base = `cmux-tui-${uid}`;
  const file = `${session}.sock`;
  const roots = [process.env.XDG_RUNTIME_DIR, process.env.TMPDIR, "/tmp"].filter(Boolean);
  // Return the first candidate that exists; fall back to the first root's path.
  for (const root of roots) {
    const p = path.join(root, base, file);
    if (fs.existsSync(p)) return p;
  }
  return path.join(roots[0] || os.tmpdir(), base, file);
}

// Scan the candidate roots for any cmux control sockets, to help when the
// derived path doesn't match (wrong session name, unexpected root, etc.).
function findCmuxSockets() {
  const roots = [...new Set(
    [process.env.XDG_RUNTIME_DIR, process.env.TMPDIR, "/tmp"]
      .filter(Boolean)
      .map((r) => r.replace(/\/+$/, ""))
  )];
  const found = new Set();
  for (const root of roots) {
    let dirs;
    try {
      dirs = fs.readdirSync(root);
    } catch {
      continue;
    }
    for (const d of dirs) {
      if (!d.startsWith("cmux-tui-")) continue;
      const dir = path.join(root, d);
      let files;
      try {
        files = fs.readdirSync(dir);
      } catch {
        continue;
      }
      for (const f of files) {
        if (f.endsWith(".sock")) found.add(path.join(dir, f));
      }
    }
  }
  return [...found];
}

// Send one request, resolve with its `data` (ignores any interleaved event
// lines that lack our request id). One connection per invocation — simple and
// sufficient for the watcher's occasional calls.
function request(socketPath, cmd) {
  return new Promise((resolve, reject) => {
    if (!fs.existsSync(socketPath)) {
      const found = findCmuxSockets();
      let msg = `cmux socket not found: ${socketPath}`;
      if (found.length) {
        msg +=
          `\nFound these cmux sockets instead — pass one with --socket, or use its ` +
          `session name with --session:\n  ` + found.join("\n  ");
      } else {
        msg +=
          `\nNo cmux sockets found under $XDG_RUNTIME_DIR/$TMPDIR/tmp. Is cmux running? ` +
          `If you're inside a cmux pane, $CMUX_TUI_SOCKET should be set (echo it to check).`;
      }
      reject(new Error(msg));
      return;
    }
    const id = 1;
    const conn = net.createConnection(socketPath);
    let buf = "";
    let done = false;
    const finish = (fn, arg) => {
      if (done) return;
      done = true;
      conn.end();
      fn(arg);
    };
    conn.on("connect", () => {
      conn.write(JSON.stringify({ id, ...cmd }) + "\n");
    });
    conn.on("data", (chunk) => {
      buf += chunk.toString("utf8");
      let nl;
      while ((nl = buf.indexOf("\n")) >= 0) {
        const line = buf.slice(0, nl);
        buf = buf.slice(nl + 1);
        if (!line.trim()) continue;
        let msg;
        try {
          msg = JSON.parse(line);
        } catch {
          continue; // ignore unparseable
        }
        if (msg.id !== id) continue; // skip event lines
        if (msg.ok) finish(resolve, msg.data ?? {});
        else finish(reject, new Error(msg.error || "cmux error"));
        return;
      }
    });
    conn.on("error", (err) => finish(reject, err));
    conn.on("close", () => {
      if (!done) finish(reject, new Error("connection closed before response"));
    });
  });
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const verb = args._[0];
  const session = args.session || "main";
  const socketPath = args.socket || defaultSocketPath(session);

  if (!verb) {
    console.error("usage: cmux.js [--session s] [--socket p] <identify|list|read-screen|send|send-key> [...]");
    process.exit(2);
  }

  let cmd;
  switch (verb) {
    case "identify":
      cmd = { cmd: "identify" };
      break;
    case "list":
      cmd = { cmd: "list-workspaces" };
      break;
    case "read-screen":
      cmd = { cmd: "read-screen", surface: Number(args.surface) };
      break;
    case "send": {
      let text = args.text === true ? "" : args.text || "";
      if (args.enter) text += "\r";
      cmd = { cmd: "send", surface: Number(args.surface), text };
      if (args.paste) cmd.paste = true;
      break;
    }
    case "send-key":
      cmd = {
        cmd: "send-key",
        surface: Number(args.surface),
        keys: String(args.keys || "").split(","),
      };
      break;
    default:
      console.error(`unknown verb: ${verb}`);
      process.exit(2);
  }

  if ((verb === "read-screen" || verb === "send" || verb === "send-key") && !Number.isFinite(cmd.surface)) {
    console.error(`${verb} requires --surface <id>`);
    process.exit(2);
  }

  try {
    const data = await request(socketPath, cmd);
    process.stdout.write(JSON.stringify(data) + "\n");
  } catch (err) {
    console.error(`cmux.js: ${err.message}`);
    process.exit(1);
  }
}

main();
