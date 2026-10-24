# PLAN

Tasks for this repo are tracked in the jurisdictional platform repo (private), in `docs/PLAN.md` under the listing item that links `docs/OFFICIAL_SKILL_PLAN.md` (milestone M6, "Skill and plugin rework").
This file only says what's done here and what's next, so no second plan forks.

## Now

Contributor flow current with the MCP server as of 2026-10-23 (plugin 0.3.2).
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
- Run TESTING.md T1–T10 in a live session and record the results here.
