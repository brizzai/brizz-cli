---
name: brizz-setup
description: Get from zero to a working Brizz connection — install the `brizz` CLI, authenticate, confirm the MCP server is reachable, and pick the right access path for the task. Trigger when the user installs or first opens the Brizz plugin, when `brizz` is missing from PATH, when a Brizz command exits with an auth error, when the user asks how to log in, switch tenant, or connect Claude Code to Brizz, or when a Brizz question can't be answered because nothing is connected yet.
---

# Set up Brizz access

This plugin gives you two independent ways into a Brizz workspace. They are not
alternatives to choose between once — each answers a different kind of question, and a
normal session uses both.

| Path | Needs | Best at |
|---|---|---|
| **MCP server** (`brizz_*` tools) | OAuth in the client, nothing installed | Structured queries, issue and session lookups, the server's own investigation runbooks |
| **`brizz` CLI** | A binary on PATH plus `brizz auth login` | Terminal work, piping and scripting, `--agent` output you can chain, anything you want to run in a loop |

The MCP server ships with this plugin and needs no install, so **prefer it when you only
need to read something**. Reach for the CLI when the user is working in a terminal, wants
to script a sweep, or asks for it by name.

## Confirm what you already have

Run these before concluding anything is missing. Both are cheap.

```bash
brizz auth whoami --json     # exit 0 = authenticated, exit 2 = not logged in
brizz describe --json        # active tenant, app, and platform URL
```

For the MCP path, call `brizz_whoami` instead — it returns the identity behind the current
token. If that tool isn't available at all, the plugin's MCP server hasn't connected yet;
tell the user to open `/mcp` and authorize Brizz. Don't try to fix an MCP connection from
the shell.

## Install the CLI

Only needed for the CLI path.

```bash
brew install brizzai/tap/brizz-cli                                          # macOS
curl -fsSL https://raw.githubusercontent.com/brizzai/brizz-cli/master/install.sh | sh   # macOS & Linux
```

On Windows, download `brizz-cli_*_Windows_x86_64.zip` from
https://github.com/brizzai/brizz-cli/releases, extract it, and add `brizz.exe` to PATH.

Never build from source to work around a failed install, and never hand-roll API calls
against the platform because the binary is missing — say what failed and let the user
choose.

## Authenticate

```bash
brizz auth login                    # opens a browser for OAuth
brizz auth login --api-key <key>    # CI or headless
```

Auth is interactive and the CLI owns it. If `whoami` exits 2, surface the command and stop
— do not retry, and do not attempt to log in on the user's behalf.

## Set the working scope

Brizz is tenant-scoped, and a query against the wrong tenant looks exactly like a query
that found nothing. Resolution order is **flag > env > config**:

| Context | Flag | Env var | Config field |
|---|---|---|---|
| Tenant | `--tenant` | `BRIZZ_TENANT` | `default_tenant` |
| App | `--app` | `BRIZZ_APP` | `default_app` |

The "app" is the OTel `service.name` of the instrumented application. When the user's
question names one — "checkout assistant is broken" — pass `--app checkout-assistant`
explicitly even if a default is set.

## Verify the whole path end to end

One command proves auth, scope, and that telemetry is actually arriving:

```bash
brizz sessions list --limit 5 --output markdown
```

| What you see | What it means |
|---|---|
| Rows | Everything works. Move on to the task. |
| Empty list, exit 0 | Connected, but this tenant/app has no sessions in the window. Widen `--from`, or check the app is instrumented. |
| Exit 2 | Not authenticated. `brizz auth login`. |
| Exit 3 | The tenant or app slug doesn't exist in this workspace. Re-check `brizz describe`. |

An empty list is the common one, and it is almost never a bug in the CLI. If the app has
never sent telemetry, setup isn't finished — use the **brizz-instrument** skill, which
covers getting spans flowing in the first place.

## Where to go next

- Data exists, user wants to know what's wrong → **brizz-investigate** skill (investigation workflow, flags, exit codes)
- No data yet, or a service looks sparse → **brizz-instrument** skill
- Deeper questions once connected → the MCP server ships its own runbooks; list them with `brizz_list_skills`
