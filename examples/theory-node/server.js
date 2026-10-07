"use strict";

const http = require("node:http");
const port = Number(process.env.PORT || 3000);

if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error("PORT harus berupa bilangan bulat antara 1 dan 65535.");
}

const server = http.createServer((req, res) => {
  const pathname = new URL(req.url, "http://localhost").pathname;
  res.setHeader("Content-Type", "application/json; charset=utf-8");

  if (req.method !== "GET") {
    res.writeHead(405, { Allow: "GET" });
    res.end(JSON.stringify({ error: "Method not allowed" }));
    return;
  }

  if (pathname === "/health") {
    res.writeHead(200);
    res.end(JSON.stringify({ status: "ok" }));
    return;
  }

  if (pathname === "/") {
    res.writeHead(200);
    res.end(JSON.stringify({
      message: "Docker Core: aplikasi Node.js berhasil berjalan",
      node: process.version,
      environment: process.env.NODE_ENV || "development",
      port,
    }));
    return;
  }

  res.writeHead(404);
  res.end(JSON.stringify({ error: "Not found" }));
});

server.listen(port, "0.0.0.0", () => {
  console.log(`HTTP server listening on 0.0.0.0:${port}`);
});

process.on("SIGTERM", () => {
  server.close(() => process.exit(0));
});
