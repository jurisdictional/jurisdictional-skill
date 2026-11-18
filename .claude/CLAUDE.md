# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
Start with [PLAN.md](../PLAN.md).
This file lives in `.claude/` (Claude Code reads it there as project memory) so the plugin root carries no `CLAUDE.md`, which the plugin validator warns about.

## What This Is

A Claude Code plugin for [jurisdictional.org](https://jurisdictional.org) containing the `gather` skill — a conversational interface for exploring local government structure and contributing sourced civic data.

The skill is a thin client of the Jurisdictional MCP server (`~/workspace/jurisdictional`, `lib/jurisdictional/mcp/tools/`).
The server's live `tools/list` is the source of truth for tool names, fields and enums; when it and this repo disagree, fix this repo.

## Repository Structure

- `.claude-plugin/plugin.json` — plugin manifest (bump `version` on every release)
- `.claude-plugin/marketplace.json` — single-plugin marketplace: `/plugin marketplace add jurisdictional/jurisdictional-skill`
- `.mcp.json` — the remote MCP server, URL only; sign-in is the server's OAuth (`claude mcp login plugin:jurisdictional:jurisdictional` in a real terminal, then a new session)
- `skills/gather/SKILL.md` — the flow: preflight → location → what exists → research → review → submit → verify
- `skills/gather/references/tools.md` — what each MCP tool does to live data, and who can call it
- `skills/gather/references/services.md` — gathering services
- `skills/gather/schema.md` + `examples/austin-tx/` — local-file format; must validate against `jurisdictional-data/schemas/`
- `TESTING.md` — scenarios with checks

## Key Concepts

- **Juricode**: given an address, every jurisdiction (federal → local) that governs that location.
- **Access tiers**: no token → 21 public read tools. Signed in → `claim_work`, `release_work`, `gather`, `propose_change`, `create_entity`, `import_jurisdiction`, image candidates, `send_feedback`. Admin → `reconcile_roster`, `end_tenure`, `merge_entities`, `delete_entity`, coverage reports.
- **Auth**: the server implements MCP authorization (OAuth with dynamic client registration). Read tools are public; a write without a token gets HTTP 401 with `WWW-Authenticate`, but anonymous connects never 401, so `/mcp` doesn't offer Authenticate: sign in with `claude mcp login plugin:jurisdictional:jurisdictional` in a real terminal, then start a new session (verified 2026-11-16). The plugin ships no scripts, `bin/`, or `headersHelper`: the directory accepts those only from Verified organizations, so keep it that way.
- **Directory rules (unverified org)**: `allowed-tools` stays at `Read, Grep, Glob`; only Markdown, JSON, text and images in the plugin; no line that downloads and runs a script in any shipped file (link the vendor's install page instead); quote YAML frontmatter values that start with `[` or contain `#`.
- **Writes**: `create_entity` and `import_jurisdiction` apply live; `propose_change` queues for review, or corroborates when the value is unchanged.
- **Provenance**: values come only from the government's own page — fetched with `gather`, an archived capture (`mcc_read` from the local Common Crawl server in `~/workspace/municipal-common-crawl`, or `gather`'s archived copy; cited with the capture date), the user's browser, or the user's paste — or from the user's own knowledge. Never search snippets or training data.

## When Modifying the Skill

- Invoked via `/gather [address or city, state]`; arguments arrive as `$ARGUMENTS`. `disable-model-invocation: true` keeps it user-invoked.
- Keep the three stops (after Step 2, each Step 4 review, the next target) and the Step 4 review table; no other pauses.
- Keep SKILL.md under 500 lines; put detail in `references/` (one level deep).
- Check enums against the live schemas: `curl -s -X POST https://jurisdictional.org/mcp -H 'content-type: application/json' -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'`.
- Validate: `claude plugin validate .`, and ajv against `jurisdictional-data/schemas/` for the examples (see the commit that fixed them).
