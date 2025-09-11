import { resolve } from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import type { KobongApiPort, KobongRequest, KobongResponse } from "../../domain/ports/kobong_api";

const pexec = promisify(execFile);

function tryParseJson(raw: string): unknown | undefined {
  const tryOnce = (s: string) => { try { return JSON.parse(s); } catch { return undefined; } };
  // 1) 그대로
  let v = tryOnce(raw);
  if (v !== undefined) return v;
  // 2) BOM 제거
  const noBom = raw.replace(/^\uFEFF/, "");
  v = tryOnce(noBom);
  if (v !== undefined) return v;
  // 3) 앞뒤 잡소리 제거: 첫 '{' 또는 '['부터 끝까지 시도
  const i = noBom.search(/[\{\[]/);
  if (i >= 0) {
    v = tryOnce(noBom.slice(i));
    if (v !== undefined) return v;
  }
  return undefined;
}

export class KobongApiRestAdapter implements KobongApiPort {
  async request(req: KobongRequest): Promise<KobongResponse> {
    const cli = resolve("scripts/acl/kobong-api.mjs");
    const args: string[] = [`--url=${req.url}`];

    if (req.method) args.push(`--method=${req.method}`);
    if (req.timeoutMs) args.push(`--timeout=${req.timeoutMs}`);
    if (req.data != null) args.push(`--data=${req.data}`);
    if (req.headers) {
      for (const [k, v] of Object.entries(req.headers)) {
        args.push(`--hdr=${k}:${v}`);
      }
    }

    try {
      const { stdout } = await pexec(process.execPath, [cli, ...args], { encoding: "utf8" });
      const text = (stdout ?? "").trim();
      const json = tryParseJson(text);
      return { ok: true, bodyText: text, json };
    } catch (e: any) {
      const stderr = e?.stderr?.toString?.() ?? String(e);
      return { ok: false, status: undefined, statusText: "EXEC_ERROR", bodyText: stderr.trim() };
    }
  }
}