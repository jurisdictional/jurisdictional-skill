# PLAN

Tasks for this repo live in GitHub Issues on the jurisdictional platform repo (private), https://github.com/civicstudio/jurisdictional/issues, as user stories.
The longer plan and decisions D1–D9 are in that repo's `docs/OFFICIAL_SKILL_PLAN.md` (milestone M6, "Skill and plugin rework").
This file says what's done here and links the open issues, so no second plan forks.

## Now

Directory submission: https://github.com/civicstudio/jurisdictional/issues/279 (Ryan decides D1, D6 and the D2 details, then submits; D5 is decided: the plugin stays at `jurisdictional/jurisdictional-skill`, Ryan 2026-11-17, confirmed 2026-11-18).
Installed on Ryan's machine from this checkout (`claude plugin marketplace add <this repo>`), so edits here are the live skill.

Open issues for this repo (moved from this file and the inbox on 2026-11-20):
- https://github.com/civicstudio/jurisdictional/issues/279 — submit the plugin bundle and the MCP connector to the directory.
- https://github.com/civicstudio/jurisdictional/issues/280 — the TESTING.md scenarios not yet run live (T1, T3, T7, T9–T15, website pages), with T12 on Vacaville Economic Development's phone and T14 on the `services_missing` queue.
- https://github.com/civicstudio/jurisdictional/issues/281 — an admin county run: `<kind>_page` absences (`plan_page` included), `register_meeting_source`, meeting venue fields.
- https://github.com/civicstudio/jurisdictional/issues/282 — Vacaville Unified's website, and its roster recheck after 2026-12-11.
- https://github.com/civicstudio/jurisdictional/issues/283 — decided 2026-11-20: schools are places in their district; the skill says so (0.6.15), and a `/gather` run on Vacaville Unified (TESTING.md T13) closes it.
- https://github.com/civicstudio/jurisdictional/issues/284 — later: a model-invocable, read-only `juricode` skill.

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
- Page kinds `notices`, `alerts` and `plan`, meeting venue fields with the `timezone`, `status` and `external_id` rules that keep hand-entered meetings from failing or duplicating, `agency_description_missing` and `services_missing`, core resident services as tags and absences, schools as places, the eight meeting-feed vendors with `event_names` and `set_meeting_source_status`, the agency-website source rule, county and league directories as accepted second sources, TESTING.md T13–T15, and the directory validator's three holds addressed (0.6.15, 2026-11-20).

Record of runs (history; open work is in the issues above):
- First live run, 2026-11-17 (Ryan, signed in as admin, `/gather 300 Hemlock St, Vacaville, CA`; every layer served · Gold, so the session worked quality gaps on the VUSD Board of Education, body 4):
  - Pass: T2 (the Step 2 table across 10 layers, `AskUserQuestion` at each stop); T4 in part (signed in, and the session opened with no status report); T5 (roster and emails read from the district's own page, the emails decoded from its `data-cfemail`); T6 (`reconcile_roster` dry run, then apply); T8 (verified by re-query after writing).
  - Written: `reconcile_roster` body 4, 7 confirms with source, `verified_on`, term ends and leadership roles; `propose_changes` for 7 trustee emails (pending review); `submit_image` for 7 headshots (ids 11288–11294, candidates); `send_feedback` (feedback id 1, the first through the skill).
  - Friction, fixed in 0.6.12: Step 2 had no recommendation when every layer is Gold; a county showing 0 elected seats read as "officials not showing".
  - Platform gaps sent to jurisdictional 2026-11-18, one handoff each: school trustee areas, `reconcile_roster` start dates, `explore(people)` body null, body 5's contacts, the county people view, and the school-district headshot license.
- Tool-level read path checked on prod 2026-10-27 (300 Hemlock St, Vacaville), passing: 12-layer juricode with the census county division tagged `non_governing`; coverage for all 10 governing layers in one batch; every district seat linked and held; `explore(people)` over the districts returns all six representatives; `get_next_uncovered` returns no census-designated places; full-name `search_people` works.

Setup, optional, per machine: register the Common Crawl archive server (`claude mcp add --scope user mcc -- ~/workspace/municipal-common-crawl/.venv/bin/mcc mcp`, with `mcc serve` running) so the `mcc_*` path in Step 3 is live.
