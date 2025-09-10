#!/usr/bin/env node
import { execSync } from "node:child_process";
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import process from "node:process";

const sh    = (c) => execSync(c, { encoding: "utf8" }).trim();
const trySh = (c) => { try { return sh(c); } catch { return ""; } };
const esc   = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

function latestTag() { const out = trySh("git describe --tags --abbrev=0"); return out || null; }
function tagList()   { const out = trySh("git tag --sort=-v:refname"); return out ? out.split("\n").map(s=>s.trim()).filter(Boolean) : []; }
function prevTag(curr){
  const tags = tagList();
  if (!curr) return tags.length>1 ? tags[1] : null;
  const i = tags.indexOf(curr);
  return (i>=0 && i+1<tags.length) ? tags[i+1] : null;
}

function extractFromChangelog(ver){
  try{
    const cl = readFileSync("CHANGELOG.md","utf8").replace(/\r/g, "");
    const rx = new RegExp("^\\s*#{2,6}\\s*\\[?"+esc(ver)+"\\]?\\s*(?:\\([^)]*\\))?\\s*$\\n([\\s\\S]*?)(?=^\\s*#{2,6}\\s|\\s*\\Z)", "m");
    const m = cl.match(rx);
    return m ? m[1].trim() : null;
  } catch { return null; }
}

function notesFromGit(prev, curr){
  let raw = "";
  if (prev) raw = trySh(`git log --pretty=format:%s||%h ${prev}..${curr}`);
  else      raw = trySh(`git log --pretty=format:%s||%h --max-count=200`);
  const lines = raw ? raw.split("\n").filter(Boolean) : [];
  if (lines.length === 0) return "- No changes recorded.";
  return lines.map(l => { const [s,h] = l.split("||"); return `- ${s} (${h||"—"})`; }).join("\n");
}

function main(){
  const args = process.argv.slice(2);
  const tagArg = (args.find(a=>a.startsWith("--tag="))||"").split("=")[1];
  const outArg = (args.find(a=>a.startsWith("--out="))||"").split("=")[1];

  const tag = tagArg || latestTag();
  if (!tag) { console.error("No git tag."); process.exit(2); }
  const ver  = tag.replace(/^v/,"");
  const prev = prevTag(tag);

  let body = extractFromChangelog(ver);      // 1차: CHANGELOG
  if (!body) body = notesFromGit(prev, tag); // 2차: git-log 폴백

  const notes   = `# ${tag}\n\n${body}`;
  const outPath = outArg || join("out","release_notes",`${tag}.md`);
  const dir     = dirname(outPath);
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  writeFileSync(outPath, notes, { encoding: "utf8" });
  console.log(outPath);
}
main();