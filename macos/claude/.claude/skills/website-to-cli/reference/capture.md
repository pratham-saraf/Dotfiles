# Capture recipes

Goal of Phase 1: a `.har` with the real API calls **and** the auth material to
replay them.

## Default: the capture driver

`scripts/capture.ts` records a HAR with embedded response bodies and saves the
logged-in session. The critical part is **exercising the features** — the HAR
only contains calls you triggered, so click through search, lists, detail views,
filters, pagination, anything the CLI must do.

```bash
bun add -D playwright && bunx playwright install chromium   # first time
bun scripts/capture.ts https://example.com --out capture/example
```

## Re-capture without logging in again

`capture.ts` writes `<prefix>.storageState.json` (cookies + localStorage). Reuse
it to skip login on later captures:

```bash
bun scripts/capture.ts https://example.com/other --out capture/example2 \
  --state capture/example.storageState.json
```

## No Playwright: DevTools HAR export

1. Open DevTools → **Network**. Tick **Preserve log** and **Disable cache**.
2. Do the actions in the site.
3. Right-click the request list → **Save all as HAR with content** (the "with
   content" variant keeps response bodies, which the analyzer needs for shapes).

## Attach to a browser you're already logged into (CDP)

Launch Chrome with a debugging port, then connect Playwright to that session —
useful when login is painful (SSO, 2FA) and you're already signed in.

```bash
# macOS example
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --remote-debugging-port=9222 --user-data-dir="$HOME/.chrome-capture"
```

```ts
const browser = await chromium.connectOverCDP("http://localhost:9222");
const context = browser.contexts()[0];
// Note: recordHar must be set at context creation, so for CDP capture prefer
// DevTools "Save all as HAR" instead, or route via a recording context.
```

## Agent-controlled / MCP browser

If an agent-driven browser or MCP browser tool that supports HAR export is
available, point it at the site, have it perform each flow, and export the HAR.
Then jump straight to Phase 2.

## Auth: what to grab, where it goes

From the analyzer's `auth:` line per endpoint you'll see one of:

- **Cookie session** — replay the `cookie` header. Copy the session cookies into
  `.env` as one string; send them as the `cookie` request header.
- **Bearer token** — `authorization: Bearer <token>`. Often in localStorage;
  `storageState.json` captures it.
- **API key** — a header like `x-api-key` or a query param.
- **CSRF / anti-forgery** — a header like `x-csrf-token` paired with a cookie;
  some sites require reading a token from an earlier response or a meta tag.

Rules:
- Secrets go in `.env`; the code reads `process.env`. Never hardcode.
- `.gitignore` must include `.env`, `*.har`, `*.storageState.json`.
- Tokens expire. If the CLI starts returning 401/403, re-capture to refresh.

## Gotchas

- **Empty HAR** → you didn't trigger the feature; the calls never happened.
- **No response bodies** → export "with content" / keep `content: "embed"`.
- **Too much noise** → the analyzer filters analytics + static by default; use
  `--all` only when you suspect a real call is being filtered.
- **GraphQL** → one endpoint (`/graphql`), many operations. Read the request
  bodies (the analyzer prints `body:` shape); each `operationName` + `query` is
  effectively a separate CLI command.
