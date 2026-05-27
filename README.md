# brizz-cli

Distribution repo for the [Brizz](https://brizz.ai) command-line interface.

The `brizz` CLI lets AI agents (Claude Code, Cursor, etc.) and humans read Brizz analytics — sessions, issues, and more — straight from the terminal.

This repo hosts compiled binaries, install scripts, and the Claude Code plugin manifest.

## Install

### macOS & Linux (shell — recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/brizzai/brizz-cli/master/install.sh | sh
```

### macOS (Homebrew)

```bash
brew install brizzai/tap/brizz-cli
```

### Windows

Download `brizz-cli_*_Windows_x86_64.zip` from the [Releases](https://github.com/brizzai/brizz-cli/releases) page, extract, and add `brizz.exe` to your `PATH`.

### macOS: "Apple could not verify brizz"

If you downloaded the binary directly from the [Releases](https://github.com/brizzai/brizz-cli/releases) page (rather than via the installer script or Homebrew), macOS Gatekeeper may block first execution with an "Apple could not verify" dialog. Remove the quarantine attribute:

```bash
xattr -d com.apple.quarantine $(which brizz)
```

Then re-run `brizz`. The shell installer and Homebrew paths above handle this automatically.

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

## Reporting issues

https://github.com/brizzai/brizz-cli/issues

## License

Proprietary — see [LICENSE](./LICENSE).
