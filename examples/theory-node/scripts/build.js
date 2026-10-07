"use strict";

const fs = require("node:fs");
const path = require("node:path");

const project = path.resolve(__dirname, "..");
const output = path.join(project, "dist");
fs.mkdirSync(output, { recursive: true });
fs.copyFileSync(path.join(project, "server.js"), path.join(output, "server.js"));
console.log("Build selesai: dist/server.js");
