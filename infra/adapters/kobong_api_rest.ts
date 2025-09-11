import { resolve } from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import type { KobongApiPort, KobongRequest, KobongResponse } from "../../domain/ports/kobong_api";

const pexec = promisify(execFile);

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
      const text = stdout.trim();
      let json: unknown | undefined;
      try { json = JSON.parse(text); } catch {}
      return { ok: true, bodyText: text, json };
    } catch (e: any) {
      const stderr = e?.stderr?.toString?.() ?? String(e);
      return { ok: false, status: undefined, statusText: "EXEC_ERROR", bodyText: stderr.trim() };
    }
  }
}