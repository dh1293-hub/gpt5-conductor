import { createJsonlLogger } from "../infra/logging/jsonlLogger.js";
import { StubHttpClient } from "../infra/adapters/index.js";
import { InMemoryKVS } from "../infra/adapters/index.js";

async function main() {
  const logger = createJsonlLogger({ defaultModule: "app.bootstrap" });
  const http = new StubHttpClient();
  const kvs = new InMemoryKVS();

  const t0 = Date.now();
  await kvs.set("hello", { user: "minsu@example.com", phone: "+82 10-1234-5678" }, 60);
  const val = await kvs.get("hello");

  const res = await http.send({ url: "https://example.com", method: "GET" });

  await logger.log({
    module: "app.bootstrap",
    level: "INFO",
    action: "startup",
    message: "Bootstrap complete",
    outcome: "OK",
    durationMs: Date.now() - t0,
    meta: { kvsValue: val, httpStatus: res.status }
  });
}

main().catch(async (err) => {
  const logger = createJsonlLogger({ defaultModule: "app.bootstrap" });
  await logger.log({
    module: "app.bootstrap",
    level: "ERROR",
    action: "startup",
    message: (err as Error).message,
    errorCode: "BOOTSTRAP_FAIL"
  });
  process.exit(1);
});
