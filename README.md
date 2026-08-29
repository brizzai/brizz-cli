# brizz-cli

Distribution repo for the [Brizz](https://brizz.ai) command-line interface.

The `brizz` CLI lets AI agents (Claude Code, Cursor, etc.) and humans read Brizz analytics — sessions, issues, and more — straight from the terminal.

This repo hosts compiled binaries, install scripts, and the Claude Code plugin manifest.

## Install

### macOS (Homebrew)

```bash
brew install brizzai/tap/brizz-cli
```

### macOS & Linux (shell)

```bash
curl -fsSL https://raw.githubusercontent.com/brizzai/brizz-cli/master/install.sh | sh
```

### Windows

Download `brizz-cli_*_Windows_x86_64.zip` from the [Releases](https://github.com/brizzai/brizz-cli/releases) page, extract, and add `brizz.exe` to your `PATH`.

## Quick start

```bash
brizz auth login          # opens browser for OAuth
brizz sessions list       # recent sessions
brizz issues list         # surfaced issues
brizz sessions browse     # interactive: view / conversation / investigate / web
```

Run `brizz --help` to see all commands.

## Claude Code plugin

```bash
claude plugin marketplace add brizzai/brizz-cli
claude plugin install brizz@brizzai
```

Installing the plugin also registers the hosted **Brizz MCP server**
(`https://platform.brizz.dev/mcp`), so Claude Code can query sessions, issues, and metrics
without the CLI. Authorize it from `/mcp` on first use.

It ships three skills:

| Skill | For |
|---|---|
| `brizz-setup` | Install the CLI, authenticate, set tenant/app scope, verify the connection |
| `brizz-instrument` | Add the Brizz SDK to an app, or fix one that sends nothing |
| `brizz-investigate` | Investigate sessions, issues, and evidence with `brizz` |

## Reporting issues

https://github.com/brizzai/brizz-cli/issues

## License

The contents of this repository — the install script, the Claude Code plugin
and its skills, and the documentation — are MIT licensed; see [LICENSE](./LICENSE).

The compiled `brizz` binaries on the [Releases](https://github.com/brizzai/brizz-cli/releases)
page are distributed under separate commercial terms.
