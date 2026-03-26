# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code plugin containing the `gather` skill, which guides users through crowdsourcing civic data about U.S. government structure — jurisdictions, agencies, services, officials — into a standard open data format for [jurisdictional.org](https://jurisdictional.org).

This is **not** a traditional codebase with build/test commands. It's a plugin consisting of a skill definition (markdown prompt), a schema reference, and example data that Claude Code executes as an interactive workflow.

## Repository Structure

- `.claude-plugin/plugin.json` — Plugin manifest (name, version, description)
- `skills/gather/SKILL.md` — The main skill prompt defining the 5-phase workflow (Identify → Survey → Detail → Structure → Submit)
- `skills/gather/schema.md` — Data model specification for the data repo format (one file per entity)
- `skills/gather/examples/austin-tx/` — Example output in data-repo format (one file per entity)

## Key Concepts

- **Data repo format**: One JSON file per entity with `_meta` provenance block. Cross-references use filename slugs (not IDs). Entity types: jurisdictions, agencies, services, people, positions, domains, bodies.
- **Field mapping**: Data repo uses different field names than the app schema (e.g., `url` → `website_url`, `category` → `service_type`). The importer handles translation.
- **Slug convention**: Lowercase, hyphen-separated. Sub-state entities include state abbreviation (e.g., `austin-tx`). Domains replace dots with hyphens.

## When Modifying the Skill

- The skill is invoked via `/gather [city, state]`. Arguments are passed as `$ARGUMENTS` in SKILL.md.
- The skill pauses after each of 5 phases for user review — don't remove these pause points.
- `disable-model-invocation: true` in SKILL.md frontmatter means the skill only runs when user-invoked.
- The target data repo is [jurisdictional-data](https://github.com/jurisdictional/jurisdictional-data) and uses `mix data.commit` and `mix data.import` commands.
