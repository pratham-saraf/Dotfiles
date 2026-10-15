# The beautiful-CLI aesthetic

The goal is the look in the reference: dense, monospaced, quietly colored, and
scannable — and machine-friendly at the same time. `templates/cli.ts` already
implements all of this; this file is the "why" so you keep it consistent as you
add commands.

## The one rule: dual output contract

Every command emits **one of two things**, never a mix:

- **Pretty** (default, only when `stdout.isTTY`): colored, aligned, human.
- **`--json`**: exact JSON, **no color**, so `cli.ts search x --json | jq` works.

Compute the data once; branch on `--json` at the very end. Never sprinkle color
codes into data that might be piped.

## Color: restraint, with meaning

Color carries information; it isn't decoration. A working palette:

- **Primary field** (the name/title) → bold + accent color.
- **Good/metric** (rating, "$0 fee", success) → green.
- **Secondary** (eta, ids, counts, help) → dim.
- **Warn / attention** (auth, offers) → yellow.
- **Error** → red, prefixed `✗`, to **stderr**.

Auto-disable color when piped or when `NO_COLOR` is set (the template's `useColor`
does this). Colored bytes in a pipe corrupt `jq` and grep.

## Layout

- **Align columns** — measure visible width ignoring ANSI (`table()` does this)
  so colored cells still line up.
- **One row per item**, most-important field first, left to right by importance.
- **Footer summary** — end lists with a dim one-liner: count, and when useful a
  synthesized takeaway (the reference ends with "Best combination of speed and
  rating: …"). It's the payoff of having the data locally.
- **Whitespace over borders.** Two spaces between columns beats box-drawing.

## Feedback

- **Spinner on latency**, to **stderr** (never stdout — it must not pollute
  piped output), auto-off when not a TTY. The template's `spinner()` handles it.
- **Fail loud, fail early** — non-zero exit, `✗` + message to stderr, so scripts
  can trust the exit code.

## Stream discipline (so it composes in pipes)

- **stdout** = the result, and only the result.
- **stderr** = spinners, progress, errors.
- **exit code** = 0 success, non-zero failure.

This is what lets `cli.ts search "fast food" --json | jq '.[] | select(...)'`
work exactly like the reference screenshot.

## Ergonomics worth adding

- `--json` on everything (done in the router).
- `-h`/no-args prints the command list (done).
- Read secrets from `.env`; print a clear error naming the missing var.
- Keep commands verb-shaped and few: `search`, `list`, `get`. Resist flags for
  things a second subcommand expresses more clearly.
