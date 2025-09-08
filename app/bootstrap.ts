/**
 * Minimal bootstrap for build sanity (Stage 8 patch).
 * - zero deps / stable console JSON
 */
function main() {
  const payload = {
    timestamp: new Date().toISOString(),
    module: "app",
    action: "bootstrap",
    outcome: "ok",
  };
  console.log(JSON.stringify(payload));
}
main();
export {}; // keep module scope
