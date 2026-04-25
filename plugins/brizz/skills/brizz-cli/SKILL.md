---
name: brizz-cli
description: Use the Brizz CLI (`brizz`) to investigate production issues, failed sessions, and analytics for AI agents and LLM apps. Trigger whenever the user asks to investigate failures, debug a production AI agent, summarize what's broken today, look at user complaints, find sessions/issues/evidence, query analytics metrics, or mentions Brizz, brizz-cli, or brz. Also trigger on phrases like "what failed", "what's wrong with the agent", "investigate this user", "show me issues", "summarize last 24h", "top failing sessions", or any request to drill into LLM workload telemetry.
---

# Brizz CLI

`brizz` is a read-only, tenant-scoped analytics CLI over the Brizz product analytics platform. It is designed agent-first: deterministic output, stable exit codes, and a `next-commands` convention that lets you self-navigate from one invocation to the next without memorising command names. Reach for it whenever the user wants to investigate failures, look at issues/sessions/evidence, or pull metrics from a Brizz-instrumented LLM workload.

All commands are read-only — there are no mutations. Run them in loops without fear.

## Before you start

Confirm auth and active scope first. These two calls are cheap and prevent a half-hour of debugging the wrong tenant:

```bash
brizz auth whoami --json     # exit 0 = good, exit 2 = not logged in
brizz describe --json        # shows active tenant + app + platform URL
```

If `whoami` exits with code 2, tell the user: `brizz auth login` (OAuth) or `brizz auth login --api-key <key>` (CI / headless). Do not try to fix auth yourself — the CLI handles it interactively.

If the user mentions a tenant or app you do not see in `describe`, override per-call with `--tenant <slug>` / `--app <name>` rather than persisting a switch.

## The canonical investigation workflow

When the user says "investigate", "what's failing", "what's broken today", or anything in that family, follow this 4-step flow. Every step is one command. Every step's output points at the next.

```bash
# 1. Orient — 24h overview: priority counts, top issues, top sessions, metric trends
brizz summarize --output markdown

# 2. Find the issue — ranked by priority + last-seen
brizz --agent issues list --limit 5

# 3. Investigate one — bundles issue + impacted sessions + evidence + conversation tails
brizz issues investigate <issue-id> --output markdown

# 4. Drill into a session — full conversation, compacted to save tokens
brizz sessions conversation <session-id> --compact --limit 200 --output markdown
```

Step 3 is the heavy hitter — it returns issue metadata, top sessions, evidence rows, conversation snippets from each impacted session, and a "Smoking gun" section with the primary evidence's full trace. For most "why is this broken?" questions, you can stop after step 3.

## Always pass `--agent` (or `--output markdown`)

Without a flag, `brizz` autodetects TTY vs pipe and picks a format. In an agent context that detection is unreliable, so be explicit:

- `--agent` is a convenience switch: forces markdown output, disables the pager, and adds `next-commands` trailers to list commands. It's the fastest way to get LLM-readable output.
- `--output markdown` does the markdown part without the rest. Equivalent for read-only single-shot commands.
- `--output json` / `--json` when you need to programmatically parse fields (e.g., extracting an issue ID to feed into the next command). Markdown is for *reading*; JSON is for *parsing*.

Why this matters: markdown output ends with a fenced block like:

```
next-commands
brizz issues investigate abc123-def456 --output markdown
brizz sessions conversation 0xy-bee --limit 200 --output markdown
```

These are copy-paste-ready. Extract the block, pick the relevant line, run it. This is how the CLI guides you through follow-ups without you having to know what to ask for next.

## Token-efficient flags for agent loops

Conversations and evidence can be long. Use these to keep responses small:

- `--compact` on `sessions conversation` collapses repeated system prompts and truncates large tool payloads. Typical 60–80% reduction. Add `--full` if you need the tool payloads back but still want system-prompt collapsing.
- `--fields a,b,c` projects only the columns/fields you care about. Works for both markdown (column subset) and JSON (field subset).
- `--limit <n>` bounds list size. Default is sensible but worth tightening when you only need the top issue.

For deep dives where token cost is irrelevant — e.g., the user asks to see *everything* about an issue — use:

```bash
brizz issues investigate <id> --full-evidence --primary-session-turns 100 --output markdown
```

`--full-evidence` keeps evidence descriptions/contexts untruncated; `--primary-session-turns` extends the transcript tail on the primary impacted session (default 40, max 200; other sessions stay at 6).

## Exit codes

Stable across all commands. Branch on these, don't parse error messages:

| Code | Meaning        | What to do                                                    |
|------|----------------|---------------------------------------------------------------|
| 0    | Success        | —                                                             |
| 1    | Bad flag/usage | Fix the invocation. Bad time string, missing required flag, etc. |
| 2    | Auth failure   | Tell the user to run `brizz auth login`. Don't retry.         |
| 3    | Not found      | The ID/slug doesn't exist in this tenant. Verify scope.       |
| 4    | Network error  | Retry once. If it keeps failing, the user has a connectivity issue. |
| 5    | Server error   | Retry once. If it persists, escalate to the Brizz team.       |

Flag validation happens before the network call, so a typo in `--from` exits with 1 instantly without burning a request.

## Tenant / app context

Three layers, resolved in order: **flag > env > config > error**.

| Context | Flag        | Env var          | Config field     |
|---------|-------------|------------------|------------------|
| Tenant  | `--tenant`  | `BRIZZ_TENANT`   | `default_tenant` |
| App     | `--app`     | `BRIZZ_APP`      | `default_app`    |

Tenant accepts a slug (`acme-prod`) or UUID — both work, slug gets persisted. The "app" is the OTel `service.name` of the instrumented application. If the user's question is scoped to one app ("checkout assistant is broken"), pass `--app checkout-assistant` even if a default is set — explicit beats inherited.

## Pagination

Cursors are opaque, base64-ish strings. Round-trip them — never parse, slice, or compute them.

```bash
brizz sessions list --limit 10 --json
# response includes: "next_cursor": "b2Zm..."

brizz sessions list --limit 10 --cursor b2Zm... --json
# next page; response either has a new next_cursor or omits it (last page)
```

Keep `--limit` constant while paginating. Changing it mid-pagination yields offset-aligned, not page-aligned, results.

## Time ranges

`--from` and `--to` accept several forms. Pick the friendliest one for the user's intent:

| Form        | Example                | Meaning                  |
|-------------|------------------------|--------------------------|
| Duration    | `1h`, `15m`, `45s`     | now − duration           |
| Days        | `1d`, `7d`             | now − N×24h              |
| Keyword     | `now`, `today`, `yesterday` | self-explanatory     |
| RFC3339     | `2026-04-19T00:00:00Z` | absolute instant         |

Empty `--from` is unbounded (or the command's default). Empty `--to` is now. `--to` before `--from` is rejected.

## When you need more

The CLI ships its own deeper reference — use it whenever the workflow above doesn't cover what you need:

```bash
brizz agent-guide        # full markdown playbook (workflow, flags, exit codes, conventions)
brizz <command> --help   # per-command flag reference
brizz --help             # top-level command tree
```

Treat `brizz agent-guide` as the source of truth for any flag detail this skill doesn't mention. It's embedded in the binary, so it's always in sync with the installed version.

## What this skill is not for

- **Mutations.** `brizz` is read-only. If the user asks to delete or modify data, it's not a brizz task — direct them to the dashboard or backend API.
- **Dashboard scraping or hand-rolled API calls.** If you're tempted to `curl` the Brizz API, run `brizz` first; it almost certainly already has the command.
- **Setup help.** If `brizz` isn't on PATH, point the user at the install instructions at https://github.com/brizzai/brizz-cli — don't try to build from source.
