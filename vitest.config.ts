import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["tests/**/*.test.ts"],
    globals: true,
    reporters: ["default"],
    coverage: {
      provider: "v8",
      reportsDirectory: "coverage",
      reporter: ["text", "html", "lcov"],
      all: false,
      thresholds: { lines: 70, functions: 70, branches: 60, statements: 70 },
    },
    testTimeout: 15000
  },
});
