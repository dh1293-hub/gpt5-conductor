#!/usr/bin/env node
import process from "node:process";

function parseArgs(argv){
  const out = { method:"GET", url:"", headers:{}, data:null, timeout:15000 };
  for (const a of argv) {
    if (a.startsWith("--url="))    out.url = a.slice(6);
    else if (a.startsWith("--method=")) out.method = a.slice(9).toUpperCase();
    else if (a.startsWith("--hdr=")) {
      const kv = a.slice(6).split(":");
      const k  = kv.shift().trim(); const v = kv.join(":").trim();
      if (k) out.headers[k] = v;
    } else if (a.startsWith("--data=")) {
      out.data = a.slice(7);
      if (!out.headers["Content-Type"]) out.headers["Content-Type"] = "application/json; charset=utf-8";
    } else if (a.startsWith("--timeout=")) out.timeout = parseInt(a.slice(10),10);
  }
  if (!out.headers["Accept"]) out.headers["Accept"]="application/json";
  return out;
}

async function call({method,url,headers,data,timeout}){
  const ac = new AbortController();
  const t  = setTimeout(()=>ac.abort(), timeout);
  try{
    const res = await fetch(url, {
      method,
      headers,
      body: data ? (/^\s*[\[{]/.test(data) ? data : String(data)) : null,
      signal: ac.signal
    });
    const ct = res.headers.get("content-type")||"";
    const text = await res.text();
    let out;
    if (ct.includes("json")) {
      try { out = JSON.stringify(JSON.parse(text), null, 2) } catch { out = text }
    } else out = text;
    if (!res.ok) {
      console.error(`[ERROR] HTTP ${res.status} ${res.statusText}\n` + out);
      process.exit(1);
    }
    console.log(out);
  } finally { clearTimeout(t); }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = parseArgs(process.argv.slice(2));
  if (!args.url) { console.error("Usage: kobong-api.mjs --url=... [--method=GET|POST|...] [--hdr=K:V] [--data=JSON] [--timeout=15000]"); process.exit(2); }
  call(args);
}

export default call;