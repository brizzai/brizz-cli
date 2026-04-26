# Changelog

All notable changes to the Brizz CLI are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
