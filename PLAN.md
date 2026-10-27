# PLAN

Tasks for this repo are tracked in the jurisdictional platform repo (private), in `docs/PLAN.md` under the listing item that links `docs/OFFICIAL_SKILL_PLAN.md` (milestone M6, "Skill and plugin rework").
This file only says what's done here and what's next, so no second plan forks.

## Now

Coverage-led contributor flow (plugin 0.5.0, 2026-10-27; districts graded by their seats): every layer of the address graded by rung and tier, three stops with `AskUserQuestion`, next targets that have a government, `/gather next [state]`.
Installed on Ryan's machine from this checkout (`claude plugin marketplace add <this repo>`), so edits here are the live skill.

Done in this repo:
- Function-only `agency_type`; examples validate against the data-repo schemas.
- Anonymous connection works (headers helper; no 401 without a token, or with a malformed token file).
- Sign-in command saves only a `jur_...` key and says whether it did.
- Server fixes from our 2026-10-23 handoffs are live (jurisdictional `5ccf962`, `12ee07c`, `fc2375a`, `0847c70`); the skill uses `online_url` / `website_url`, `import_jurisdiction` `source_url`, and `evidence.source_url`.
- SKILL.md rewritten against the live tools, detail in `references/`; under 500 lines.
- Own marketplace, LICENSE, README for people arriving from jurisdictional.org.
- `TESTING.md` scenarios.

Next (from M6, each waits on a decision in OFFICIAL_SKILL_PLAN §6):
- A model-invocable, read-only `juricode` skill for "who represents me" (needs M2 on the server).
- OAuth instead of the token file, once the server has it (M8).
- 1.0.0 and the directory submission (M7).
- Run TESTING.md T1–T12 in a live interactive session and record the results here.
  Tool-level read path checked on prod 2026-10-27 (300 Hemlock St, Vacaville), passing: 12-layer juricode with the census county division tagged `non_governing`; coverage for all 10 governing layers in one batch; every district seat linked and held; `explore(people)` over the districts returns all six representatives; `get_next_uncovered` returns no census-designated places (CA `none` is empty; `governed` gives Oceanside, Garden Grove, Lancaster); full-name `search_people` works. Not run: the conversation itself (stops, tables, wording), writes, and the browser fallback.
- Browser fallback shipped (0.5.0). Waiting on jurisdictional: accept a captured page (HTML, sha256, captured_at) as evidence on writes, so a browser capture keeps a server-side copy (handoff 2026-10-27).
- Optional, per machine: register the Common Crawl archive server (`claude mcp add --scope user mcc -- ~/workspace/municipal-common-crawl/.venv/bin/mcc mcp`, with `mcc serve` running) so the `mcc_*` path in Step 3 is live.
- gather_ex: fetches timed out on 2026-10-25, and cityofvacaville.gov's firewall returned "Access Denied" on 2026-10-26; the paste fallback covers both.
