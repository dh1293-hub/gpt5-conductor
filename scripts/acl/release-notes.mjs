#!/usr/bin/env node
// scripts/acl/release-notes.mjs — v1.0 (ACL Adapter + Fallback)
// Contract:
//   input : --tag=<vX.Y.Z> (optional), --out=<path> (optional)
//   output: writes notes file, prints its path to stdout, exit 0; non-zero on error.

import { execSync } from "node:child_process";
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import process from "node:process";

function sh(cmd){ return execSync(cmd, { encoding: "utf8" }).trim(); }
function esc(s){ return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"); }

function latestTag(){ try { return sh("git describe --tags --abbrev=0"); } catch { return null; } }
function tagList(){ try { return sh("git tag --sort=-v:refname").split("\n").map(s=>s.trim()).filter(Boolean); } catch { return []; } }
function prevTag(curr){ const tags = tagList(); if(!curr) return tags.length>1?tags[1]:null; const i=tags.indexOf(curr); return (i>=0 && i+1<tags.length)?tags[i+1]:null; }

function extractFromChangelog(ver){
  try{
    const cl = readFileSync("CHANGELOG.md","utf8").replace(/\r/g, "");
    const rx = new RegExp(
      "^\\s*#{2,6}\\s*\\[?"+esc(ver)+"\\]?\\s*(?:\\([^)]*\\))?\\s*$\\n" +
      "([\\s\\S]*?)" +
      "(?=^\\s*#{2,6}\\s|\\s*\\Z)",
      "m"
    );
    const m = cl.match(rx);
    return m ? m[1].trim() : null;
  } catch { return null; }
}\\s*\\[?"+esc(ver)+"\\]?\\s*(?:\\([^)]*\\))?\\s*$[\\r\\n]+([\\s\\S]*?)(?=^\\s*#{2,6}\\s|\\Z)", "m");
    const m = cl.match(rx);
    return m ? m[1].trim() : null;
  } catch { return null; }
}

function notesFromGit(prev, curr){
  let raw;
  if(prev) raw = sh(`git log --pretty=format:%s||%h ${prev}..${curr}`);
  else     raw = sh(`git log --pretty=format:%s||%h --max-count=200`);
  const lines = raw ? raw.split("\n") : [];
  if(lines.length===0) return "- No changes recorded.";
  return lines.map(l=>{ const [s,h]=l.split("||"); return `- ${s} (${h})`; }).join("\n");
}

function main(){
  const args = process.argv.slice(2);
  const tagArg = (args.find(a=>a.startsWith("--tag="))||"").split("=")[1];
  const outArg = (args.find(a=>a.startsWith("--out="))||"").split("=")[1];

  const tag = tagArg || latestTag();
  if(!tag){ console.error("No git tag found."); process.exit(2); }
  const ver  = tag.replace(/^v/,"");
  const prev = prevTag(tag);

  let body = extractFromChangelog(ver);            // 1차: CHANGELOG (##~###### 허용)
  if(!body) body = notesFromGit(prev, tag);        // 2차: 비상 폴백 git-log

  const notes = `# ${tag}\n\n${body}`;
  const outPath = outArg || join("out","release_notes",`${tag}.md`);
  const dir = dirname(outPath);
  if(!existsSync(dir)) mkdirSync(dir, { recursive: true });
  writeFileSync(outPath, notes, { encoding: "utf8" });

  console.log(outPath);
}
main();
