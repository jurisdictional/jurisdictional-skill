# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code plugin for [jurisdictional.org](https://jurisdictional.org) containing the `gather` skill — a conversational interface for exploring local government structure and contributing civic data.

The skill uses the Jurisdictional MCP API (`set_location`, `explore`, `search_*`, `get_*_details`, `propose_change`) for live data, supplemented by `WebSearch`/`WebFetch` for gap-filling from government websites.

## Repository Structure

- `.claude-plugin/plugin.json` — Plugin manifest (name, version, author, keywords)
- `.mcp.json` — MCP server config pointing to `https://jurisdictional.org/api/mcp/message`
- `skills/gather/SKILL.md` — The skill definition: explore → find gaps → research → submit
- `skills/gather/schema.md` — Data model specification (one file per entity)
- `skills/gather/examples/austin-tx/` — Example output in data-repo format

## Key Concepts

- **Juricode**: Given an address, returns every jurisdiction (federal → local) that governs that location. Foundation of the skill.
- **MCP tools**: 15+ API tools including `set_location`, `explore`, `search_agencies`, `propose_change`, etc.
- **Data repo format**: One JSON file per entity with `_meta` provenance block. Cross-references use filename slugs. Used for local file output; submissions go via `propose_change` API.
- **Sourcing tasks**: The platform generates tasks (discover_agencies, extract_services, extract_meeting_schedule, etc.) that contributors can pick up.
- **Auth**: Exploration is unauthenticated. Contributions require `JURISDICTIONAL_TOKEN` env var or token at `~/.jurisdictional/token`, obtained via browser-based GitHub OAuth at `/auth/cli`.

## When Modifying the Skill

- The skill is invoked via `/gather [address or city, state]`. Arguments are passed as `$ARGUMENTS`.
- Steps 1-3 are exploration (no auth needed). Steps 4-6 are contribution (auth required).
- The skill pauses for user review at each step — don't remove pause points.
- `disable-model-invocation: true` means the skill only runs when user-invoked.
- The civic topics list and contribution types should stay in sync with the platform's collaborate page and sourcing task types.
