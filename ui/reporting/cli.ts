import { MemoryReportEngine } from "../../infra/reporting/memory_report_engine";
import { ReportService } from "../../app/reporting/report_service";

export async function demo(): Promise<string> {
  const engine = new MemoryReportEngine();
  const svc = new ReportService(engine);
  const dsl = "SELECT name,amount FROM sales WHERE VIP";
  const datasets = {
    sales: [
      { name: "Kim", amount: 100, tag: "VIP" },
      { name: "Lee", amount: 50, tag: "REG" },
      { name: "Park", amount: 70, tag: "VIP" },
    ]
  };
  const res = await svc.run(dsl, datasets);
  return res.content;
}
if (require.main === module) {
  demo().then(csv => console.log(csv)).catch(err => { console.error(err); process.exit(1); });
}