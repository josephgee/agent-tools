#!/usr/bin/env node
"use strict";

// Minimal client for the cmux control socket (JSON-lines, protocol v9).
// Speaks just enough of the protocol for the navigator watcher: identify,
// list-workspaces, read-screen, send, send-key.
//
// Socket resolution (matches cmux docs): $TMPDIR/cmux-tui-<uid>/<session>.sock
// Override with --socket <path>. Default session is "main".
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
  const tmp = process.env.TMPDIR || os.tmpdir();
  const uid = typeof process.getuid === "function" ? process.getuid() : "0";
  return path.join(tmp, `cmux-tui-${uid}`, `${session}.sock`);
}

// Send one request, resolve with its `data` (ignores any interleaved event
// lines that lack our request id). One connection per invocation — simple and
// sufficient for the watcher's occasional calls.
function request(socketPath, cmd) {
  return new Promise((resolve, reject) => {
    if (!fs.existsSync(socketPath)) {
      reject(new Error(`cmux socket not found: ${socketPath}`));
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
