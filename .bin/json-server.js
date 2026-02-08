#!/usr/bin/env node

const http = require("http");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const PORT = process.env.PORT || 51741;
const BASE_DIR =
  process.env.JSON_SERVER_DIR ||
  path.join(process.env.HOME, "projects", "personal-notes", "captures");

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function contentHash(data) {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify(data))
    .digest("hex")
    .slice(0, 12);
}

function mdPath(dir, name) {
  return path.join(dir, `${name || "capture"}.md`);
}

function isDuplicate(filepath, hash) {
  if (!fs.existsSync(filepath)) return false;
  return fs.readFileSync(filepath, "utf-8").includes(`<!-- hash:${hash} -->`);
}

function appendEntry(filepath, data, hash) {
  const ts = new Date().toISOString();
  const entry = [
    `<!-- hash:${hash} -->`,
    `## ${ts}`,
    "",
    "```json",
    JSON.stringify(data, null, 2),
    "```",
    "",
  ].join("\n");

  if (!fs.existsSync(filepath)) {
    fs.writeFileSync(filepath, `# Captures\n\n${entry}`);
  } else {
    fs.appendFileSync(filepath, entry);
  }
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (c) => chunks.push(c));
    req.on("end", () => resolve(Buffer.concat(chunks).toString()));
    req.on("error", reject);
  });
}

function respond(res, status, body) {
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body));
}

const server = http.createServer(async (req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.writeHead(204);
    return res.end();
  }

  // GET / — list capture files
  if (req.method === "GET" && req.url === "/") {
    ensureDir(BASE_DIR);
    const files = fs.readdirSync(BASE_DIR).filter((f) => f.endsWith(".md"));
    return respond(res, 200, { dir: BASE_DIR, files });
  }

  // POST — append JSON to md file
  // POST /         → captures/capture.md
  // POST /logs     → captures/logs.md
  // POST /metrics  → captures/metrics.md
  if (req.method === "POST") {
    try {
      const body = await readBody(req);
      const data = JSON.parse(body);
      const hash = contentHash(data);

      const name = req.url.replace(/^\/+|\/+$/g, "") || "capture";
      ensureDir(BASE_DIR);
      const filepath = mdPath(BASE_DIR, name);

      if (isDuplicate(filepath, hash)) {
        console.log(`duplicate skipped [${hash}] → ${filepath}`);
        return respond(res, 200, { duplicate: true, file: filepath, hash });
      }

      appendEntry(filepath, data, hash);
      console.log(`appended [${hash}] → ${filepath}`);
      return respond(res, 201, { saved: filepath, hash });
    } catch (err) {
      return respond(res, 400, { error: err.message });
    }
  }

  respond(res, 404, { error: "not found" });
});

server.listen(PORT, () => {
  console.log(`json-server listening on http://localhost:${PORT}`);
  console.log(`saving to ${BASE_DIR}`);
});
