/** tests/unit/reporting/dsl.parser.spec.ts */
import { describe, it, expect } from "vitest";
import { parseFromDsl } from "../../../domain/dsl/parser";
import { ReportService } from "../../../app/reporting/ReportService";
import { ParserAdapter } from "../../../infra/reporting/ParserAdapter";
import { QueryStub } from "../../../infra/reporting/QueryStub";
import { CsvRenderer } from "../../../infra/reporting/CsvRenderer";

describe("DSL parser v0.1", () => {
  it("parses minimal spec", () => {
    const dsl = [
      "REPORT demo",
      "FIELDS id, name, amount",
      "FORMAT csv",
      "LIMIT 2",
      "SORT amount desc",
    ].join("\\n");

    const spec = parseFromDsl(dsl);
    expect(spec.source).toBe("demo");
    expect(spec.fields.map(f => f.name)).toEqual(["id","name","amount"]);
    expect(spec.format).toBe("csv");
    expect(spec.limit).toBe(2);
    expect(spec.sort?.[0]).toEqual({ field: "amount", dir: "desc" });
  });

  it("runs through ReportService with CSV", async () => {
    const dsl = [
      "REPORT demo",
      "FIELDS id, name, amount",
      "FORMAT csv",
    ].join("\\n");

    const svc = new ReportService(new ParserAdapter(), new QueryStub(), new CsvRenderer());
    const out = await svc.run(dsl);
    const header = (out as string).split("\\n")[0];
    expect(header).toBe("id,name,amount");
  });

  it("throws on missing FORMAT", () => {
    const dsl = [
      "REPORT demo",
      "FIELDS id",
    ].join("\\n");
    expect(() => parseFromDsl(dsl)).toThrow();
  });
});
