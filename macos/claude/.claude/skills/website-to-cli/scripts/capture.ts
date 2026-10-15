#!/usr/bin/env bun
/**
 * capture.ts — record a website's real network traffic to a HAR.
 *
 * Records everything (with response bodies) to a HAR and saves the session so
 * you can re-capture later without logging in again.
 *
 *   bun add -D playwright && bunx playwright install chromium   # first time
 *   bun scripts/capture.ts https://example.com --out capture/example
 *
 * Two modes:
 *   default   headed browser; you log in and click through the features, then
 *             press Enter. Best for anything behind auth or interaction.
 *   --auto N  headless; load the URL, wait N seconds for XHRs to settle, save.
 *             Non-interactive — for public flows and agent-driven capture.
 *
 * Flags:
 *   --out <prefix>   output path prefix (default: capture/<hostname>)
 *   --state <file>   reuse a saved storageState.json (skip login)
 *   --auto <sec>     headless, record for <sec> seconds, no interaction
 *
 * Only calls you actually trigger end up in the HAR — exercise EVERY feature
 * you want in the CLI. Produces <prefix>.har and <prefix>.storageState.json.
 */
import { chromium } from "playwright";
import { mkdirSync } from "node:fs";
import { dirname } from "node:path";

const argv = process.argv.slice(2);
const url = argv.find((a) => !a.startsWith("--"));
if (!url) {
  console.error("usage: capture.ts <url> [--out prefix] [--state file] [--auto sec]");
  process.exit(1);
}
const flag = (name: string) => {
  const i = argv.indexOf(name);
  return i >= 0 ? argv[i + 1] : undefined;
};

const prefix = flag("--out") ?? `capture/${new URL(url).hostname}`;
const harPath = `${prefix}.har`;
const statePath = `${prefix}.storageState.json`;
mkdirSync(dirname(harPath), { recursive: true });

const autoSec = flag("--auto");
const auto = autoSec !== undefined;

const browser = await chromium.launch({ headless: auto });
const context = await browser.newContext({
  storageState: flag("--state"), // undefined = fresh session
  recordHar: { path: harPath, content: "embed" }, // embed response bodies
});
const page = await context.newPage();
await page.goto(url, { waitUntil: "domcontentloaded" });

if (auto) {
  console.log(`\n  Recording (auto, ${autoSec}s) → ${harPath}`);
  await page.waitForLoadState("networkidle").catch(() => {}); // best-effort
  await page.waitForTimeout((Number(autoSec) || 0) * 1000); // catch late XHRs
} else {
  console.log(`\n  Recording → ${harPath}`);
  console.log("  Log in and exercise every feature you want in the CLI.");
  console.log("  Press Enter here when done.\n");
  await new Promise<void>((resolve) => {
    process.stdin.resume();
    process.stdin.once("data", () => resolve());
  });
}

await context.storageState({ path: statePath }); // save cookies + localStorage
await context.close(); // flushes the HAR
await browser.close();
console.log(`\n  Saved ${harPath}`);
console.log(`  Saved ${statePath} (session — keep out of git)`);
console.log(`\n  Next: bun scripts/analyze-har.ts ${harPath}\n`);
process.exit(0);
