import type { KobongApiPort, KobongRequest, KobongResponse } from "../domain/ports/kobong_api";
import { KobongApiRestAdapter } from "../infra/adapters/kobong_api_rest";

export async function kobongFetch(req: KobongRequest, port?: KobongApiPort): Promise<KobongResponse> {
  const enabled = String(process.env.KOBONG_API_ENABLED || "").toLowerCase() === "true";
  if (!enabled) {
    throw new Error("KOBONG_API_DISABLED");
  }
  const p = port ?? new KobongApiRestAdapter();
  return p.request(req);
}