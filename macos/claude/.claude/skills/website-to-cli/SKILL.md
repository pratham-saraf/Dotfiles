---
name: website-to-cli
description: >-
  Turn any website into a fast, beautiful command-line client. Use when the user
  wants a CLI that replicates a site's features by capturing its network traffic
  (HAR), recovering the private/undocumented API behind it, and generating a
  typed terminal client that calls those endpoints directly instead of driving a
  browser every time. Triggers on "make a CLI for <site>", "reverse-engineer this
  site's API", "website to CLI", "build a client from the network requests", or
  pointing at a HAR file and asking for a client.
---

# Website → CLI

Drive a browser, record what the site's frontend actually calls, recover the
private API from that recording, then generate a beautiful CLI that hits those
endpoints directly. The browser is used **once** to learn the API; the resulting
CLI never needs it again (faster, scriptable, pipeable to `jq`).

Three phases: **Capture → Analyze → Build.**

## Before you start: responsible use

This recovers a site's *undocumented* API and automates it. Before capturing a
site the user does **not** own or operate, confirm they're allowed to
(their own account, a public/permitted API, a sanctioned test target). Surface
that this may conflict with the site's Terms of Service, and never bypass
paywalls, rate limits, bot defenses, or auth you weren't given. For the user's
own sites/accounts, proceed. Keep captured cookies/tokens out of the generated
code and out of git — they go in `.env` (see Phase 3).

## Phase 1 — Capture the traffic (HAR)

Goal: a `.har` file containing the real API calls, plus the auth material
(cookies / tokens / headers) needed to replay them.

Use the capture driver — it opens a headed browser, lets you (or an agent) log
in and click through the exact features you want in the CLI, records everything
to a HAR, and saves the logged-in session:

```bash
bun add -D playwright && bunx playwright install chromium   # first time only
bun scripts/capture.ts https://example.com --out capture/example
```

While the browser is open, **exercise every feature the CLI should have** —
search, open a list, view a detail, apply a filter. Each user action fires the
XHR/`fetch` calls you're trying to record. Press Enter in the terminal when
done. You get `capture/example.har` + `capture/example.storageState.json`.

**Running headless / as an agent?** You can't press Enter, so use `--auto <sec>`:
it loads the URL, records for `<sec>` seconds, and saves — no interaction. Since
the HAR only holds calls that actually fired, capture each flow by pointing it at
the page that triggers it (run it once per URL — search page, detail page, etc.):

```bash
bun scripts/capture.ts "https://example.com/search?q=foo" --out capture/search --auto 4
bun scripts/capture.ts "https://example.com/item/123"     --out capture/detail --auto 4
```

Alternatives when Playwright isn't the right fit:
- **Already have a browser session:** in DevTools → Network, tick "Preserve
  log", do the actions, then right-click → **Save all as HAR with content**.
- **An agent-controlled browser / MCP browser** that supports HAR export: point
  it at the site, have it perform the flows, export the HAR.

See `reference/capture.md` for login persistence, CDP attach, and gotchas.

## Phase 2 — Analyze the HAR → API map

Run the analyzer. It strips out static assets, analytics, and tracking, then
groups the remaining JSON calls into a clean endpoint map: method, path
template (`/users/:id`), query params, request-body shape, and response shape.

```bash
bun scripts/analyze-har.ts capture/example.har          # human report
bun scripts/analyze-har.ts capture/example.har --json    # machine-readable
```

Read the report and decide, per feature:
- **Base URL + which endpoints** power each feature the user wants.
- **Auth mechanism** — cookie session, `Authorization: Bearer`, a CSRF/anti-
  forgery header, an API key in a header or query param. Look at the headers on
  the real API calls in the report (`--json` includes them).
- **Pagination / params** — page/cursor/limit params, sort/filter keys.
- **Response shape** — the fields worth showing vs. the noise.

Don't guess endpoints that weren't in the capture. If a needed feature's call is
missing, go back to Phase 1 and exercise it.

## Phase 3 — Build the beautiful CLI

Start from the template and fill in the real endpoints:

```bash
cp templates/cli.ts cli.ts
```

`templates/cli.ts` is a zero-dependency Bun CLI (native `fetch`, ANSI colors —
no `npm install` to look good). It already provides:
- a typed `api()` fetch helper that injects auth from `.env`;
- a subcommand router;
- a `table()` renderer, colors, and a `spinner`, all TTY-aware;
- a **dual output contract**: pretty by default, raw JSON with `--json` so
  output pipes cleanly into `jq` (as in the reference screenshot).

Wire it up:
1. One subcommand per feature (`search`, `list`, `get`, …), each calling the
   real endpoint(s) from the API map.
2. Type the request params and the response fields you use.
3. Auth: read cookies / token / key from `process.env`; write a `.env.example`
   listing the vars; add `.env`, `*.har`, `*.storageState.json` to
   `.gitignore`. Never hardcode secrets or paste captured cookies into the code.
4. Make it beautiful — follow `reference/beautiful-cli.md`. Bold the primary
   field, dim secondary info, align columns, and always keep `--json` exact and
   uncolored for piping.

Verify against the live site before calling it done: run a real command, confirm
the output matches what the website shows, and check `--json | jq` works.

```bash
echo 'BASE_URL=...' > .env       # + auth vars from the API map
bun cli.ts search "fast food"
bun cli.ts search "fast food" --json | jq '.[0]'
```

## Files in this skill

- `scripts/capture.ts` — headed-browser HAR + session recorder (Playwright).
- `scripts/analyze-har.ts` — HAR → endpoint map (filters noise; `--json`, `--all`, `--self-test`).
- `templates/cli.ts` — zero-dep beautiful Bun CLI skeleton to copy and fill in.
- `reference/capture.md` — capture recipes, auth/session persistence, gotchas.
- `reference/beautiful-cli.md` — the terminal aesthetic + output contract.
