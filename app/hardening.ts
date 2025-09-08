import { appendFileSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { randomUUID } from "node:crypto";
import { hrtime } from "node:process";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";

type LogLevel = "DEBUG" | "INFO" | "WARN" | "ERROR" | "FATAL";

const LOG_DIR = "logs";
const LOG_FILE = `${LOG_DIR}/hardening.log`;

function ensureLogDir() {
  if (!existsSync(LOG_DIR)) mkdirSync(LOG_DIR, { recursive: true });
}

// Simple PII masking: emails + common token patterns
export function maskPII(input: string): string {
  let out = input;
  // email
  out = out.replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, "***@***");
  // token/api keys like: token=xxxx, bearer xxxxx, sk-xxxxx, 16+ hex/base62
  out = out.replace(/\b(sk-[A-Za-z0-9_\-]{12,}|bearer\s+[A-Za-z0-9_\-]{12,}|token\s*=\s*[A-Za-z0-9_\-]{12,})\b/gi, "***");
  out = out.replace(/\b[A-F0-9]{16,}\b/gi, "***");
  return out;
}

function log(level: LogLevel, message: string, extra: Record<string, unknown> = {}) {
  ensureLogDir();
  const now = new Date().toISOString();
  const entry = {
    timestamp: now,
    tz: "Asia/Seoul",
    level,
    traceId: currentTraceId,
    module: "hardening",
    action: extra["action"] ?? null,
    outcome: extra["outcome"] ?? null,
    durationMs: extra["durationMs"] ?? null,
    errorCode: extra["errorCode"] ?? null,
    app: { name: "gpt5-conductor", ver: process.env.npm_package_version ?? null },
    host: { pid: process.pid },
    message: maskPII(message),
  };
  appendFileSync(LOG_FILE, JSON.stringify(entry) + "\n", { encoding: "utf-8" });
}

let currentTraceId = randomUUID();

// ESM 환경에서 "직접 실행" 판별
const isMain = (() => {
  try {
    const thisFile = fileURLToPath(import.meta.url);
    const argv1 = process.argv[1] ? resolve(process.argv[1]) : "";
    return thisFile === argv1;
  } catch {
    return false;
  }
})();

function parseArgs(argv: string[]) {
  // e.g. --mode=baseline | fault  --inject=pii,crash
  const args: Record<string, string> = {};
  argv.forEach((a) => {
    const m = a.match(/^--([^=]+)=(.*)$/);
    if (m) args[m[1]] = m[2];
  });
  return {
    mode: (args["mode"] ?? "baseline") as "baseline" | "fault",
    inject: new Set((args["inject"] ?? "").split(",").filter(Boolean)),
  };
}

function probeFilesystem(): { ok: boolean; path: string } {
  const testPath = `${LOG_DIR}/_probe_${Date.now()}.txt`;
  writeFileSync(testPath, "probe", { encoding: "utf-8" });
  return { ok: existsSync(testPath), path: testPath };
}

function probeTimer(): { ok: boolean; ns: bigint } {
  const t0 = hrtime.bigint();
  for (let i = 0; i < 1e5; i++); // spin
  const dt = hrtime.bigint() - t0;
  return { ok: dt > 0n, ns: dt };
}

function probeMemory(): { rss: number } {
  const rss = process.memoryUsage().rss;
  return { rss };
}

function baseline() {
  const t0 = hrtime.bigint();
  log("INFO", "Baseline start", { action: "baseline_start" });

  const fsr = probeFilesystem();
  log("INFO", `FS probe ok=${fsr.ok} path=${fsr.path}`, { action: "probe_fs", outcome: fsr.ok ? "ok" : "fail" });

  const tim = probeTimer();
  log("INFO", `Timer ns=${tim.ns.toString()}`, { action: "probe_timer", outcome: tim.ok ? "ok" : "fail" });

  const mem = probeMemory();
  log("INFO", `Memory rss=${mem.rss}`, { action: "probe_mem", outcome: "ok" });

  const dMs = Number(hrtime.bigint() - t0) / 1_000_000;
  log("INFO", "Baseline done", { action: "baseline_done", outcome: "ok", durationMs: Math.round(dMs) });
  return 0;
}

function fault(inject: Set<string>) {
  const t0 = hrtime.bigint();
  log("WARN", "Fault mode start", { action: "fault_start" });

  if (inject.has("pii")) {
    log("INFO", "contact: john.doe@example.com token=sk-ABCDEF1234567890", { action: "inject_pii" });
  }

  if (inject.has("crash")) {
    try {
      throw new Error("Simulated crash");
    } catch (e: any) {
      const dMs = Number(hrtime.bigint() - t0) / 1_000_000;
      log("ERROR", `Crash: ${String(e?.message ?? e)}`, {
        action: "inject_crash",
        outcome: "fail",
        errorCode: "HARDENING_FAKE_CRASH",
        durationMs: Math.round(dMs),
      });
      return 9; // fatal-like exit for test
    }
  }

  const dMs = Number(hrtime.bigint() - t0) / 1_000_000;
  log("INFO", "Fault mode done", { action: "fault_done", outcome: "ok", durationMs: Math.round(dMs) });
  return 0;
}

if (isMain) {
  ensureLogDir();
  const { mode, inject } = parseArgs(process.argv.slice(2));
  currentTraceId = randomUUID();
  const code = mode === "baseline" ? baseline() : fault(inject);
  process.exit(code);
}
