# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
Start with [PLAN.md](PLAN.md).

## What This Is

A Claude Code plugin for [jurisdictional.org](https://jurisdictional.org) containing the `gather` skill — a conversational interface for exploring local government structure and contributing sourced civic data.

The skill is a thin client of the Jurisdictional MCP server (`~/workspace/jurisdictional`, `lib/jurisdictional/mcp/tools/`).
The server's live `tools/list` is the source of truth for tool names, fields and enums; when it and this repo disagree, fix this repo.

## Repository Structure

- `.claude-plugin/plugin.json` — plugin manifest (bump `version` on every release)
- `.claude-plugin/marketplace.json` — single-plugin marketplace: `/plugin marketplace add jurisdictional/jurisdictional-skill`
- `.mcp.json` — the MCP server, with `headersHelper` → `bin/jurisdictional-headers.sh`
- `bin/jurisdictional-headers.sh` — sends `Authorization: Bearer <~/.jurisdictional/token>` when the file holds a `jur_...` key, `{}` otherwise
- `skills/gather/SKILL.md` — the flow: preflight → location → what exists → research → review → submit → verify
- `skills/gather/references/tools.md` — what each MCP tool does to live data, and who can call it
- `skills/gather/references/services.md` — gathering services
- `skills/gather/schema.md` + `examples/austin-tx/` — local-file format; must validate against `jurisdictional-data/schemas/`
- `TESTING.md` — scenarios with checks

## Key Concepts

- **Juricode**: given an address, every jurisdiction (federal → local) that governs that location.
- **Access tiers**: no token → 19 public read tools. Signed in → `gather`, `propose_change`, `create_entity`, `import_jurisdiction`, image candidates. Admin → `reconcile_roster`, `end_tenure`, `merge_entities`, `delete_entity`, coverage reports.
- **Auth**: no header or an empty bearer gets the public tools; an unknown key gets HTTP 401 for the whole connection, so the helper sends no header unless the file holds a `jur_...` key. Plugin helpers don't see `TOKEN`-like env vars, so the token lives in `~/.jurisdictional/token` (from `/auth/cli`).
- **Writes**: `create_entity` and `import_jurisdiction` apply live; `propose_change` queues for review, or corroborates when the value is unchanged.
- **Provenance**: values come only from pages fetched with `gather`, or from the user. Never search snippets or training data.

## When Modifying the Skill

- Invoked via `/gather [address or city, state]`; arguments arrive as `$ARGUMENTS`. `disable-model-invocation: true` keeps it user-invoked.
- Keep the pause points and the Step 4 review table.
- Keep SKILL.md under 500 lines; put detail in `references/` (one level deep).
- Check enums against the live schemas: `curl -s -X POST https://jurisdictional.org/api/mcp/message -H 'content-type: application/json' -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'`.
- Validate: `claude plugin validate .`, and ajv against `jurisdictional-data/schemas/` for the examples (see the commit that fixed them).
