/** infra/reporting/ParserAdapter.ts */
import type { ParsePort } from "../../domain/reporting/ports";
import { parseToSpec } from "../../domain/dsl/ast";

export class ParserAdapter implements ParsePort {
  parse(dsl: string) { return parseToSpec(dsl); }
}



