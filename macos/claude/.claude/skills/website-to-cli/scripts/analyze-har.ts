#!/usr/bin/env bun
/**
 * analyze-har.ts — turn a HAR capture into a clean API map.
 *
 * Strips static assets, analytics, and tracking, then groups the remaining
 * JSON/XHR calls by (method + path template) and reports query params, request
 * body shape, response shape, auth-relevant headers, and an example URL.
 *
 *   bun scripts/analyze-har.ts capture/site.har            # human report
 *   bun scripts/analyze-har.ts capture/site.har --json      # machine-readable
 *   bun scripts/analyze-har.ts capture/site.har --all        # keep everything
 *   bun scripts/analyze-har.ts --self-test                   # verify the logic
 *
 * Runs under bun, node (with a TS loader), or tsx. No dependencies.
 */
import { readFileSync } from "node:fs";
import assert from "node:assert";

// --- Noise filters -------------------------------------------------------

const STATIC_EXT =
  /\.(js|mjs|cjs|css|map|png|jpe?g|gif|svg|webp|avif|ico|woff2?|ttf|otf|eot|mp4|webm|mp3|wav|pdf)(\?|$)/i;

const NOISE_HOST =
  /(google-analytics|googletagmanager|doubleclick|google\.com\/(ads|pagead)|analytics\.|segment\.(io|com)|sentry\.io|amplitude|mixpanel|fullstory|hotjar|facebook\.(com|net)|connect\.facebook|bat\.bing|clarity\.ms|newrelic|nr-data|datadog|cloudflareinsights|intercom|optimizely|branch\.io|braze|onetrust|cookielaw|snowplow|heap(analytics)?\.|statsig|launchdarkly\.com\/events)/i;

// Headers worth surfacing because they usually carry auth / routing.
const AUTH_HEADER =
  /^(authorization|cookie|x-csrf|x-xsrf|x-api-key|api-key|x-auth|x-access-token|x-session|x-requested-with|x-client|apikey|token)/i;

// --- Shape / path helpers (pure — covered by --self-test) ----------------

export function pathTemplate(pathname: string): string {
  return pathname
    .split("/")
    .map((seg) => {
      if (!seg) return seg;
      if (/^\d+$/.test(seg)) return ":id";
      if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(seg))
        return ":uuid";
      if (/^[0-9a-f]{24,}$/i.test(seg)) return ":hash";
      // long mixed token that clearly isn't a route name
      if (seg.length > 16 && /\d/.test(seg) && /[a-z]/i.test(seg) && !/[.\-]/.test(seg))
        return ":id";
      return seg;
    })
    .join("/");
}

export function shape(v: unknown, depth = 0): string {
  if (v === null) return "null";
  // Arrays are transparent containers — they don't add an object-nesting level.
  if (Array.isArray(v)) return v.length ? `[${shape(v[0], depth)}]` : "[]";
  const t = typeof v;
  if (t === "object") {
    if (depth >= 3) return "{…}";
    const keys = Object.keys(v as object).slice(0, 24);
    const more = Object.keys(v as object).length > 24 ? ", …" : "";
    return `{ ${keys.map((k) => `${k}: ${shape((v as any)[k], depth + 1)}`).join(", ")}${more} }`;
  }
  return t; // string | number | boolean | undefined | function
}

function tryJson(text: string | undefined): unknown {
  if (!text) return undefined;
  try {
    return JSON.parse(text);
  } catch {
    return undefined;
  }
}

// --- Types ---------------------------------------------------------------

interface Group {
  method: string;
  host: string;
  template: string;
  count: number;
  statuses: Set<number>;
  queryKeys: Set<string>;
  bodyShape?: string;
  respShape?: string;
  authHeaders: Set<string>;
  example: string;
}

interface Entry {
  request?: {
    method?: string;
    url?: string;
    headers?: { name: string; value: string }[];
    queryString?: { name: string; value: string }[];
    postData?: { mimeType?: string; text?: string; params?: { name: string }[] };
  };
  response?: {
    status?: number;
    content?: { mimeType?: string; text?: string; encoding?: string };
  };
  _resourceType?: string;
}

// --- Core ----------------------------------------------------------------

function isApiEntry(e: Entry, all: boolean): boolean {
  const url = e.request?.url ?? "";
  if (!url) return false;
  if (all) return true;
  if (NOISE_HOST.test(url)) return false;
  if (STATIC_EXT.test(url)) return false;
  const rt = (e._resourceType ?? "").toLowerCase();
  if (rt === "xhr" || rt === "fetch") return true;
  const respMime = e.response?.content?.mimeType ?? "";
  if (/json/i.test(respMime)) return true;
  const reqMime = e.request?.postData?.mimeType ?? "";
  if (/json/i.test(reqMime)) return true;
  const accept =
    e.request?.headers?.find((h) => h.name.toLowerCase() === "accept")?.value ?? "";
  if (/application\/json/i.test(accept) && !STATIC_EXT.test(url)) return true;
  return false;
}

export function analyze(har: any, all = false): Group[] {
  const entries: Entry[] = har?.log?.entries ?? [];
  const groups = new Map<string, Group>();

  for (const e of entries) {
    if (!isApiEntry(e, all)) continue;
    const method = (e.request?.method ?? "GET").toUpperCase();
    let u: URL;
    try {
      u = new URL(e.request!.url!);
    } catch {
      continue;
    }
    const template = pathTemplate(u.pathname);
    const key = `${method} ${u.host}${template}`;

    let g = groups.get(key);
    if (!g) {
      g = {
        method,
        host: u.host,
        template,
        count: 0,
        statuses: new Set(),
        queryKeys: new Set(),
        authHeaders: new Set(),
        example: e.request!.url!,
      };
      groups.set(key, g);
    }
    g.count++;
    if (e.response?.status) g.statuses.add(e.response.status);

    for (const [k] of u.searchParams) g.queryKeys.add(k);
    for (const q of e.request?.queryString ?? []) g.queryKeys.add(q.name);

    for (const h of e.request?.headers ?? []) {
      if (AUTH_HEADER.test(h.name)) g.authHeaders.add(h.name.toLowerCase());
    }

    if (!g.bodyShape && e.request?.postData) {
      const pd = e.request.postData;
      const body = tryJson(pd.text);
      if (body !== undefined) g.bodyShape = shape(body);
      else if (pd.params?.length) g.bodyShape = `form{ ${pd.params.map((p) => p.name).join(", ")} }`;
    }

    if (!g.respShape && e.response?.content) {
      const c = e.response.content;
      if (c.encoding !== "base64" && /json/i.test(c.mimeType ?? "")) {
        const body = tryJson(c.text);
        if (body !== undefined) g.respShape = shape(body);
      }
    }
  }

  return [...groups.values()].sort(
    (a, b) => a.host.localeCompare(b.host) || a.template.localeCompare(b.template),
  );
}

// --- Rendering -----------------------------------------------------------

const c = {
  dim: (s: string) => `\x1b[2m${s}\x1b[0m`,
  bold: (s: string) => `\x1b[1m${s}\x1b[0m`,
  cyan: (s: string) => `\x1b[36m${s}\x1b[0m`,
  green: (s: string) => `\x1b[32m${s}\x1b[0m`,
  yellow: (s: string) => `\x1b[33m${s}\x1b[0m`,
};

function report(groups: Group[]): string {
  if (!groups.length) return c.dim("No API-like calls found. Try --all to see everything.");
  const out: string[] = [];
  let host = "";
  for (const g of groups) {
    if (g.host !== host) {
      host = g.host;
      out.push("", c.bold(c.cyan(host)));
    }
    const statuses = [...g.statuses].sort().join(",");
    out.push(
      `  ${c.green(g.method.padEnd(6))} ${g.template}  ${c.dim(`(${g.count}× · ${statuses})`)}`,
    );
    if (g.queryKeys.size) out.push(c.dim(`      query:  ${[...g.queryKeys].join(", ")}`));
    if (g.bodyShape) out.push(c.dim(`      body:   ${g.bodyShape}`));
    if (g.respShape) out.push(c.dim(`      resp:   ${g.respShape}`));
    if (g.authHeaders.size)
      out.push(c.yellow(`      auth:   ${[...g.authHeaders].join(", ")}`));
    // Exact captured URL — copy from here so you don't mis-transcribe keys/ids.
    out.push(c.dim(`      e.g.:   ${g.example}`));
  }
  out.push(
    "",
    c.dim(`${groups.length} endpoint(s). Re-run with --json for the raw map, --all to include filtered noise.`),
  );
  return out.join("\n");
}

function toJson(groups: Group[]) {
  return groups.map((g) => ({
    method: g.method,
    host: g.host,
    template: g.template,
    count: g.count,
    statuses: [...g.statuses].sort(),
    queryKeys: [...g.queryKeys],
    bodyShape: g.bodyShape,
    respShape: g.respShape,
    authHeaders: [...g.authHeaders],
    example: g.example,
  }));
}

// --- Self-test -----------------------------------------------------------

function selfTest() {
  assert.equal(pathTemplate("/api/users/12345/orders"), "/api/users/:id/orders");
  assert.equal(
    pathTemplate("/v1/store/1597d3a7-ed69-4f80-9c2c-2f5627ba24c2"),
    "/v1/store/:uuid",
  );
  assert.equal(pathTemplate("/p/5f2b1c9e4d7a8b3c1e0f9a2d"), "/p/:hash");
  assert.equal(pathTemplate("/search/fast%20food"), "/search/fast%20food");
  assert.equal(shape({ a: 1, b: "x", c: [{ d: true }] }), "{ a: number, b: string, c: [{ d: boolean }] }");
  assert.equal(shape([]), "[]");
  assert.equal(shape(null), "null");

  const har = {
    log: {
      entries: [
        {
          _resourceType: "fetch",
          request: {
            method: "GET",
            url: "https://api.example.com/v1/search?q=food&limit=10",
            headers: [{ name: "Authorization", value: "Bearer x" }],
            queryString: [{ name: "q", value: "food" }],
          },
          response: {
            status: 200,
            content: { mimeType: "application/json", text: '{"results":[{"name":"A"}]}' },
          },
        },
        {
          // analytics — must be filtered out
          request: { method: "POST", url: "https://api.segment.io/v1/t", headers: [] },
          response: { status: 200, content: { mimeType: "application/json", text: "{}" } },
        },
        {
          // static asset — must be filtered out
          request: { method: "GET", url: "https://cdn.example.com/app.js", headers: [] },
          response: { status: 200, content: { mimeType: "application/javascript" } },
        },
      ],
    },
  };
  const g = analyze(har);
  assert.equal(g.length, 1, "only the real API call survives filtering");
  assert.equal(g[0].template, "/v1/search");
  assert.deepEqual([...g[0].queryKeys].sort(), ["limit", "q"]);
  assert.ok(g[0].authHeaders.has("authorization"));
  assert.equal(g[0].respShape, "{ results: [{ name: string }] }");
  console.log("self-test ok");
}

// --- Entry ---------------------------------------------------------------

function main() {
  const args = process.argv.slice(2);
  if (args.includes("--self-test")) return selfTest();

  const file = args.find((a) => !a.startsWith("--"));
  if (!file) {
    console.error("usage: analyze-har.ts <capture.har> [--json] [--all] [--self-test]");
    process.exit(1);
  }
  const har = JSON.parse(readFileSync(file, "utf8"));
  const groups = analyze(har, args.includes("--all"));
  if (args.includes("--json")) console.log(JSON.stringify(toJson(groups), null, 2));
  else console.log(report(groups));
}

main();
