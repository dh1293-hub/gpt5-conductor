#!/usr/bin/env node
// Safe TypeScript version checker (CJS, tolerant, never hard-crash)
const fs = require("fs");
const { execSync } = require("child_process");

function readJsonSafe(p) {
  try {
    if (!fs.existsSync(p)) return null;
    let s = fs.readFileSync(p, "utf8");
    if (s.charCodeAt(0) === 0xFEFF) s = s.slice(1);        // strip BOM
    s = s.replace(/\/\*[\s\S]*?\*\//g, "").replace(/(^|[^:])\/\/.*$/gm, "$1"); // strip comments
    return JSON.parse(s);
  } catch { return null; }
}
function log(level, msg){ console.log(`[TS-CHECK][${level}] ${msg}`); }

let actual = "";
try { actual = execSync("npx tsc -v", { stdio: ["ignore","pipe","ignore"] }).toString().trim(); }
catch { log("WARN", "tsc not found (npx tsc -v failed); skipping"); process.exit(0); }

const m = /Version\s+([\d.]+)/.exec(actual);
if (!m) { log("WARN", `unable to parse tsc version from: ${actual}`); process.exit(0); }
const ver = m[1];

function cmp(a,b){ const pa=a.split(".").map(Number), pb=b.split(".").map(Number);
  for (let i=0;i<3;i++){ const x=pa[i]||0, y=pb[i]||0; if(x>y) return 1; if(x<y) return -1; } return 0; }

const MIN = "5.0.0";
if (cmp(ver, MIN) < 0) { log("ERROR", `TypeScript ${ver} < required ${MIN}`); process.exit(2); }
log("OK", `TypeScript ${ver} (>= ${MIN})`);
process.exit(0);