# PLAN

Tasks for this repo are tracked in the jurisdictional platform repo (private), in `docs/PLAN.md` under the listing item that links `docs/OFFICIAL_SKILL_PLAN.md` (milestone M6, "Skill and plugin rework").
This file only says what's done here and what's next, so no second plan forks.

## Now

Directory submission (plugin 0.6.6, 2026-11-17). `claude plugin validate --strict .` passes with no warnings, every listing URL answers, and every production tool carries its title and hints; Ryan answers D1, D6 and the D2 details and submits (LISTING_CHECKLIST.md, "Ready to submit?").
Installed on Ryan's machine from this checkout (`claude plugin marketplace add <this repo>`), so edits here are the live skill.

Done in this repo:
- Coverage-led contributor flow (0.5.0): every layer graded by rung and tier, three stops with `AskUserQuestion`, `/gather next [state]`; districts graded by their seats.
- Directory-ready (0.6.0): no scripts, `bin/` or `headersHelper`; `allowed-tools: Read, Grep, Glob`; badge icon; listing URLs in `plugin.json`, including `termsOfServiceUrl`.
- Sign-in is the server's OAuth: `claude mcp login plugin:jurisdictional:jurisdictional` in a real terminal, then a new session (verified 2026-11-16). `/mcp` doesn't offer Authenticate, because anonymous connects never 401.
- Work claiming with `claim_work` / `release_work` (0.6.2); feedback via `send_feedback`.
- Browser and paste captures sent as `capture` on writes (0.6.1, 0.6.3).
- Photographer credits approved, not held; parks, libraries, schools and community centers as places (0.6.3).
- Service `service_type` + `actions`; `propose_change` needs `source_url` (0.6.4).
- Website pages by kind with `create_entity` page (0.6.5).
- Listing pass (0.6.6): repo guidance moved to `.claude/CLAUDE.md` so strict validation passes; README says what the plugin sends; tools.md lists 21 public tools and `send_feedback`.
- Function-only `agency_type`; examples validate against the data-repo schemas.
- SKILL.md written against the live tools, detail in `references/`; under 500 lines.
- Own marketplace, LICENSE, README, `TESTING.md` scenarios.

Next:
- Done in jurisdictional 2026-11-17: `/terms` (7dbf572d) and the sign-in wording on `/skill`, `docs/API.md` and `llms.txt` (25fb8a6f).
- Waiting on jurisdictional: the privacy page gaps (handoff 2026-11-17).
- Done in jurisdictional 2026-11-17: tool descriptions without internal names (3e5df62e); `delete_entity` and `merge_entities` listed to admins only, `gather` read-only, overwriting admin tools destructive (034af4d8).
- Decided by Ryan: D5 keeps `jurisdictional/jurisdictional-skill` (2026-11-17, confirmed 2026-11-18); D2's direction is proposal-first, with every contributor change reviewed (2026-11-18), and its details are still open.
- Open for Ryan: D1, D6, and the D2 details.
- Ryan: submit the plugin bundle, then the MCP connector.
- Run TESTING.md T1–T12 in a live interactive session and record the results here.
  It also covers live checks for captures in review, services with both fields, and a city's meetings and budget pages.
  Tool-level read path checked on prod 2026-10-27 (300 Hemlock St, Vacaville), passing: 12-layer juricode with the census county division tagged `non_governing`; coverage for all 10 governing layers in one batch; every district seat linked and held; `explore(people)` over the districts returns all six representatives; `get_next_uncovered` returns no census-designated places; full-name `search_people` works.
- Later (each waits on a decision in OFFICIAL_SKILL_PLAN §6): a model-invocable, read-only `juricode` skill for "who represents me" (needs M2 on the server); 1.0.0.
- Optional, per machine: register the Common Crawl archive server (`claude mcp add --scope user mcc -- ~/workspace/municipal-common-crawl/.venv/bin/mcc mcp`, with `mcc serve` running) so the `mcc_*` path in Step 3 is live.
