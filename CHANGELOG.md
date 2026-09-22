# Changelog

All notable changes to the Brizz CLI are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.4] — 2026-09-22

- **`brizz` now identifies itself to the Brizz API** as `brizz-cli/0.3.4`, and appends the AI agent it is running inside when there is one — `brizz-cli/0.3.4 (claude-code)`.
- The agent name follows your usage-log setting: `brizz config telemetry disable`, `DO_NOT_TRACK=1` or `--no-telemetry` drops it. The version is always sent.
- Dependency updates.

## [0.3.3] — 2026-09-12

- **`--fields`, `--json-fields` and `--columns` now accept the field names that appear in JSON output**, alongside the short column names.
- Projected values on `intents list` match the JSON payload.
- Clearer handling of an unrecognised field name.

## [0.3.2] — 2026-08-30

- **`--json` and `--output` now beat an auto-detected agent mode.** Inside Claude Code, or with `BRIZZ_AGENT=1`, they were silently replaced with markdown. Passing `--agent` yourself still forces markdown.
- Inside Claude Code, `brizz` advertises the Brizz plugin so the session can offer a one-time install. Prints nothing in a normal terminal; `BRIZZ_NO_PLUGIN_HINT=1` opts out.

## [0.3.1] — 2026-08-09

`sessions conversation` now reads the same transcript the dashboard and the MCP do, and `issues prompt --output json` returns the prompt rather than the whole issue export.

- **`--limit` and `--cursor` on `sessions conversation` now count conversation turns, not spans.** A page of 100 is 100 turns; previously one span could expand into several. A cursor minted by an older CLI still decodes but points somewhere different — re-page from the start.
- **`sessions conversation` hides system prompts by default**, following your organization's conversation preference, which is off unless you turn it on. Pass `--system-prompts` to show them for one call, or `--no-system-prompts` to hide them when the preference is on. Only the top-level prompt is shown, matching the dashboard.
- **`--raw` no longer accepts `--issue` or a `--limit` above 200**, both of which it previously accepted and quietly ignored. `--raw` resolves no issues — pass `--finding-span` there — and the endpoint it reads caps a page at 200.
- `sessions conversation` and its browse view read the materialized transcript, so filtering and ordering run across the whole session rather than one page. Display duplicates no longer leak across a page boundary, and turns arrive in the dashboard's order.
- Finding markers are resolved server-side. A finding whose own turn is hidden as a duplicate is marked on the turn that replaced it, and one that cannot be placed is named with its span id — with the flag that recovers it — instead of being dropped in silence.
- `--around-finding` pages to the finding when it falls outside the current window. It previously returned the whole transcript with nothing marked whenever the finding sat past the first page.
- Conversation output now says what it is not showing: a session still being processed (with a retry hint), a transcript past the per-read cap, and findings it could not place.
- `--issue` no longer downloads the whole AI export just to read finding spans.
- `issues prompt --output json` returns the prompt payload — `system_prompt_captured`, the per-agent `prompts`, and an `agents` roster — instead of the whole issue export. Markdown, terminal and error output are unchanged.

## [0.3.0] — 2026-07-30

Issue investigation follows the backend's own handoff document, and the full system prompt is one command away.

- `brizz issues prompt <issue-id|prefix>` — print the complete system prompt(s) captured while the issue occurred, one block per agent. `issues investigate` only points at the prompt; reach for this when the hypothesis is about prompt wording. Markdown when piped or in agent mode, a card on a terminal, `--output json` for structured.
- `issues investigate` no longer appends its own follow-up-command section. The backend export now carries a single canonical "Investigate with the Brizz CLI" block with `--app` pinned on every command — older CLIs rendered two sections whose commands disagreed.
- `issues evidence --error-type` takes exactly one value and now fails with a clear message when given several. The findings filter has no OR operator, so a comma-separated list previously matched nothing and returned an empty result instead of an error.
- `sessions list` shows the session title when the backend has one.

## [0.2.4] — 2026-07-05

- `BRIZZ_API_KEY` environment variable — supply a personal API key per command without persisting it to `~/.brizz/config.yaml`, for CI and headless agents. It takes precedence over the stored credential when set; `brizz auth login` (browser) and `brizz auth login --api-key` are unchanged when it is not. `brizz auth whoami` reports which source the active key came from.

## [0.2.3] — 2026-06-14

Investigation by intent: survey user-intent clusters and drill into the issues within each.

- `brizz intents list` — intent clusters ranked by open-issue count, with top keywords; leaf clusters by default (`--include-parents` for category rows), `--search` filters by label.
- `brizz intents investigate <intent>` — agent-ready bundle (TTY card / markdown / JSON) with an issue breakdown by type / severity / status, top issues, and follow-up commands; resolves an intent by full ID, UUID prefix, exact label, or substring.
- `brizz issues list --intent <name|id>` — scope an issue list to one intent cluster.

## [0.2.2] — 2026-06-04

Converged `issues investigate` into an AI-handoff bundle; conversations mark finding turns.

- `brizz issues investigate <id>` emits a full AI-handoff bundle (context, type concept block, agent setup, evidence, marked conversation snippets) — markdown when piped or in agent mode, a compact summary on a terminal; `--output json` for structured.
- `brizz sessions conversation --issue <id>` marks finding turns (`← finding`); `--around-finding` windows around the first.
- Fixes: warn on a failed `--issue` findings lookup (instead of silent no-op); clean finding-marker render on empty-message turns.

## [0.2.1] — 2026-04-26

UX polish across context, sessions, issues, evidence, and metrics.

- Evidence is now strictly issue-scoped: `brizz issues evidence <issue-id|prefix>`.
- `brizz issues list` defaults to 20 rows; status pills normalized.
- New: `brizz metrics list`, `issues investigate --summary`, hyperlinked ticket in `issues view`.
- Fixes: clearer tenant errors, UUID guards, dashboard-parity conversation filter.

## [0.2.0] — 2026-04-26

Initial public release. Read-focused analytics CLI for AI agents and humans.

### Added

- `brizz auth` — OAuth login or `--api-key`
- `brizz summarize`, `sessions`, `issues` — read & investigate analytics
- `--agent` mode — markdown output + next-command suggestions
- Multi-platform binaries: macOS, Linux, Windows
