#!/usr/bin/env bun
/**
 * cli.ts — beautiful, zero-dependency CLI skeleton (Bun native fetch + ANSI).
 *
 * Copy this, then replace the TODO(website-to-cli) blocks with the real
 * endpoints from `analyze-har.ts`. No `npm install` needed to look good.
 *
 * Contract:
 *   - default output is pretty and colored (TTY only);
 *   - `--json` prints exact, uncolored JSON so it pipes into jq;
 *   - secrets come from .env / process.env, never hardcoded.
 *
 *   bun cli.ts search "fast food"
 *   bun cli.ts search "fast food" --json | jq '.[0]'
 */

// --- Config / auth (from .env — see .env.example) ------------------------

const BASE_URL = process.env.BASE_URL ?? ""; // TODO(website-to-cli): set or require
const AUTH = {
  // TODO(website-to-cli): fill from the API map's `auth:` headers.
  // cookie: process.env.COOKIE,
  // bearer: process.env.TOKEN,
  // apiKey: process.env.API_KEY,
};

// --- Terminal styling (TTY + NO_COLOR aware) -----------------------------

const useColor = process.stdout.isTTY && !process.env.NO_COLOR;
const sgr = (code: string) => (s: string | number) =>
  useColor ? `\x1b[${code}m${s}\x1b[0m` : String(s);
const style = {
  bold: sgr("1"),
  dim: sgr("2"),
  red: sgr("31"),
  green: sgr("32"),
  yellow: sgr("33"),
  cyan: sgr("36"),
  accent: sgr("38;5;39"), // primary field
};

/** Visible width, ignoring ANSI escapes. */
const width = (s: string) => s.replace(/\x1b\[[0-9;]*m/g, "").length;

/** Left-aligned column table. rows: array of string cells (already styled ok). */
function table(rows: string[][]): string {
  if (!rows.length) return "";
  const cols = rows[0].length;
  const w = Array.from({ length: cols }, (_, i) => Math.max(...rows.map((r) => width(r[i] ?? ""))));
  return rows
    .map((r) => r.map((cell, i) => cell + " ".repeat(w[i] - width(cell))).join("  ").trimEnd())
    .join("\n");
}

/** Async spinner; auto no-op when output isn't a TTY. */
async function spinner<T>(label: string, work: Promise<T>): Promise<T> {
  if (!process.stderr.isTTY) return work;
  const frames = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏";
  let i = 0;
  const t = setInterval(() => {
    process.stderr.write(`\r${style.cyan(frames[i++ % frames.length])} ${label}`);
  }, 80);
  try {
    return await work;
  } finally {
    clearInterval(t);
    process.stderr.write("\r\x1b[K"); // clear the line
  }
}

function fail(msg: string): never {
  console.error(style.red("✗ ") + msg);
  process.exit(1);
}

// --- API helper ----------------------------------------------------------

async function api<T = any>(path: string, init: RequestInit = {}): Promise<T> {
  if (!BASE_URL) fail("BASE_URL not set — copy .env.example to .env and fill it in.");
  const headers: Record<string, string> = {
    accept: "application/json",
    ...(init.headers as Record<string, string>),
  };
  // TODO(website-to-cli): attach auth the way the captured requests did.
  // if (AUTH.cookie) headers.cookie = AUTH.cookie;
  // if (AUTH.bearer) headers.authorization = `Bearer ${AUTH.bearer}`;
  // if (AUTH.apiKey) headers["x-api-key"] = AUTH.apiKey;

  const res = await fetch(new URL(path, BASE_URL), { ...init, headers });
  if (!res.ok) fail(`${res.status} ${res.statusText} — ${path}`);
  return res.json() as Promise<T>;
}

// --- Commands ------------------------------------------------------------
// One function per feature. Return data; let run() decide pretty vs --json.

// TODO(website-to-cli): replace with a real endpoint + response type.
interface Result {
  name: string;
  rating: string;
  eta: string;
  deliveryFee: string;
}

async function search(query: string): Promise<Result[]> {
  // TODO(website-to-cli): real path + params from the API map.
  const data = await spinner(
    `searching "${query}"`,
    api<{ results: Result[] }>(`/v1/search?q=${encodeURIComponent(query)}`),
  );
  return data.results;
}

function renderSearch(rows: Result[]): string {
  if (!rows.length) return style.dim("No results.");
  const body = table(
    rows.map((r) => [
      style.accent(style.bold(r.name)),
      style.green(r.rating),
      style.dim(r.eta),
      style.dim(r.deliveryFee),
    ]),
  );
  return `${body}\n\n${style.dim(`${rows.length} result(s).`)}`;
}

// --- Router --------------------------------------------------------------

const COMMANDS: Record<
  string,
  { run: (arg: string) => Promise<unknown>; render: (data: any) => string; usage: string }
> = {
  search: { run: (q) => search(q), render: renderSearch, usage: 'search "<query>"' },
  // TODO(website-to-cli): add list / get / etc.
};

async function main() {
  const argv = process.argv.slice(2);
  const json = argv.includes("--json");
  const [name, ...rest] = argv.filter((a) => !a.startsWith("--"));
  const cmd = COMMANDS[name];

  if (!cmd) {
    console.error(style.bold("Commands:"));
    for (const [n, c] of Object.entries(COMMANDS)) console.error(`  ${style.cyan(n)}  ${style.dim(c.usage)}`);
    console.error(style.dim("\nAdd --json to any command to pipe into jq."));
    process.exit(name ? 1 : 0);
  }

  const data = await cmd.run(rest.join(" "));
  if (json) console.log(JSON.stringify(data, null, 2));
  else console.log(cmd.render(data));
}

main().catch((e) => fail(e instanceof Error ? e.message : String(e)));
