---
name: brizz-instrument
description: Add Brizz telemetry to an AI application, or fix an app that is sending nothing or sending it wrong. Trigger when the user asks to install or set up the Brizz SDK, instrument an agent or LLM app, send their first session, wire a framework (LangChain, Vercel AI, Vercel eve, Agno, Strands, LiveKit, MCP servers, Google GenAI, Claude Code, Langfuse), attach users/organizations/events/feedback to sessions, or when a Brizz service shows no sessions, no user identity, or missing tool spans and the cause is upstream in their own code.
---

# Instrument an app with Brizz

Everything else in Brizz assumes spans are arriving. This skill covers the step before that:
getting a codebase to emit them, and fixing it when what arrives is incomplete.

Work against the **published docs** — they are public markdown, version-matched to what
ships, and the same source the dashboard's own setup flow reads from:

```
https://platform.brizz.dev/llms.txt              # index of every page, ~14 KB
https://platform.brizz.dev/docs/<slug>.md        # one page, as markdown
https://platform.brizz.dev/llms-full.txt         # all 142 pages inlined, ~460 KB
```

Fetch `llms.txt`, then open the page for the user's actual stack. Two fetches, a few
thousand tokens. This skill carries only what is stable across stacks and the mistakes that
cost the most time.

Reach for `llms-full.txt` only when you need to search across the whole corpus at once — an
error string whose page you can't guess, or a term you want every mention of. It is the
entire documentation set in one file, so read it from disk with a grep rather than pulling
half a million characters into context.

## Establish three things before writing code

1. **Runtime** — Python 3.10+ or Node 18+. Decides the package *and* the failure mode below.
2. **Framework** — plain provider clients, or LangChain, Vercel AI, Vercel eve, Agno,
   Strands, LiveKit, an MCP server, Google GenAI, or an existing Langfuse tracer. Each has
   its own page under `docs/sdks/`, and in Node several need explicit wiring that nothing
   warns you about. Guessing here is how an install ends up silent.
3. **Credential** — a workspace issues either a **Server DSN** or an **API key**, not both.
   Ask which they were given; don't assume.

Then find where AI calls actually happen — client construction and the request/response
boundary. That boundary is what a session wraps.

## Credential

**Prefer the Server DSN when the workspace issues one.** It is a single string carrying the
credential, the ingestion endpoint, and the service name:

```
https://<credential>@<ingest-host>/<service-name>
```

```bash
export BRIZZ_DSN="https://<credential>@<ingest-host>/<service-name>"
```

```python
Brizz.initialize(dsn=os.environ["BRIZZ_DSN"])          # Python
```
```typescript
Brizz.initialize({ dsn: process.env.BRIZZ_DSN });      // Node
```

There is no `app_name` with a DSN — the service name is already in the string. That is the
whole difference; sessions, users, and events are identical afterwards.

With an API key instead, set `BRIZZ_API_KEY` and pass the service name yourself as
`app_name` / `appName`. Get it right on the first run: it is the name the service is known
by in every later query, and changing it splits the history in two.

A DSN contains a credential. Treat it like a password — environment variable only, never
committed, never shipped to a browser.

## Install and initialize

```bash
pip install brizz        # Python 3.10+
npm install @brizz/sdk   # Node 18+
```

**Python — initialization order is load-bearing.** Auto-instrumentation hooks libraries at
import time, so `Brizz.initialize()` must run *before* you import them:

```python
import os
from brizz import Brizz

Brizz.initialize(dsn=os.environ["BRIZZ_DSN"])

from openai import OpenAI          # after, always
```

**Node — the module list is load-bearing instead.** Hand Brizz the libraries explicitly and
import order stops mattering:

```typescript
import 'dotenv/config';
import { Brizz } from '@brizz/sdk';
import OpenAI from 'openai';

Brizz.initialize({
  dsn: process.env.BRIZZ_DSN,
  instrumentModules: { openAI: OpenAI },   // every AI library the app uses
});
```

These are two different rules, and applying the Python one to Node wastes time on import
order while the real cause is a library missing from `instrumentModules`. Both fail the same
way from the outside: the app runs, nothing errors, no spans appear.

With `dotenv`, load the environment *before* importing the SDK — `load_dotenv()` first in
Python, `import 'dotenv/config'` first in Node — or the credential reads as empty.

## Wrap a session

A session is the unit of analysis in the dashboard. Group an interaction into one:

```python
from brizz import start_session

with start_session("session-123"):
    ...
```
```typescript
import { withSessionId } from '@brizz/sdk';

await withSessionId('session-123', runAgent)();
```

## Framework wiring that is not automatic

In Python most frameworks instrument themselves once `initialize()` runs. Node is where
things need saying out loud — check the framework's page, and expect one of these:

| Stack | What it needs |
|---|---|
| Vercel AI SDK | `experimental_telemetry: { isEnabled: true }` on each `generateText` / `streamText` call |
| LangChain (JS) | `instrumentModules: { langchain: { callbackManagerModule } }` |
| Google GenAI | Build the client from `instrumentGoogleGenAI(genai)` — `@google/genai` is ESM-only, so `instrumentModules` does not apply |
| Vercel eve | Register Brizz in `instrumentation.ts`, with `BRIZZ_DSN` set |
| Claude Code | No SDK — it emits OpenTelemetry natively, configured with environment variables |
| Browser | `@brizz/browser` and a **client** DSN. The server SDK must never run in a browser |

## Verify it landed

Instrumentation isn't done until a session is visible from outside the app:

```bash
brizz sessions list --limit 5 --output markdown
```

or over MCP, `brizz_list_services` then `brizz_search_sessions`. In the dashboard it is
**Sessions** in the sidebar, filtered to the service — a stale service filter there hides a
session that arrived perfectly well.

Spans are batched, so wait 5–10 seconds before believing an empty result.

When nothing shows up, work down this list in order:

1. **Credential is in the process** that actually ran, not just your shell. Print it from
   inside the app if unsure.
2. **Ordering (Python) or `instrumentModules` (Node).** A Node warning reading
   *"Module loaded before instrumentation"* names this exactly: move `initialize()` to the
   top of the entry file, and list the library.
3. **Server-side only.** A browser needs `@brizz/browser`.
4. **Debug logging** — `BRIZZ_LOG_LEVEL=debug` in Node, the `brizz` logger at `DEBUG` in
   Python. The SDK then says what it is sending and where.
5. **401** — an invalid credential, or a proxy stripping the `Authorization` header.

Only after all five should you suspect the platform.

## Enrichment — what turns spans into analytics

Raw spans give a transcript. User-level views, org rollups, funnels, feedback, and quality
metrics need identity and events attached. The pages under `docs/instrument/` cover
identifying users and organizations, message IDs, custom events, feedback, and recorded
metrics.

Add each one when the user asks for the analysis that needs it — not all at once up front.

## A service that is already instrumented but sparse

Telemetry arriving with no user, no tool spans, or no events is a diagnosable state, not a
fresh install. Connect over MCP and run the server's `fix-instrumentation` runbook
(`brizz_get_skill`), which reads the Telemetry Health Center and names the specific gap.
Come back here to make the code change it identifies.
