/** infra/reporting/JsonRenderer.ts */
import type { RenderPort } from "../../domain/reporting/ports";
import type { ReportSpec } from "../../domain/reporting/types";

export class JsonRenderer implements RenderPort {
  async render(records: Record<string, unknown>[], _spec: ReportSpec): Promise<Buffer> {
    const text = JSON.stringify(records);
    return Buffer.from(text, "utf8");
  }
}



