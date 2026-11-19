# Listing checklist

How Jurisdictional gets listed where Claude and Grok users find skills and MCP servers.
Written 2026-11-12 from pages fetched that day, brought up to date 2026-11-17; each step links the official doc or form it comes from.
Anything not read on an official page is marked **unverified**.
The longer plan, with the milestones and the decisions D1–D9, is `docs/OFFICIAL_SKILL_PLAN.md` in the private jurisdictional repo; this file is the short, current list.

One rule for every listing: the data is ODbL 1.0 with each record under DbCL 1.0 (https://jurisdictional.org/license).
Never describe it as CC0.

## Ready to submit?

Yes for the plugin bundle, once Ryan answers the open decisions below; the connector follows the same day if D1 allows it.
Checked 2026-11-17, plugin 0.6.6.

Done:

- `claude plugin validate --strict .` and `--strict .claude-plugin/marketplace.json` both pass with no warnings.
- Listing URLs in `plugin.json` all answer 200: homepage, documentation (`/skill`), support, privacy, terms, repository; author URL https://civic.studio.
- Every tool on production has a `title` and its hint: 21 anonymous tools, all `readOnlyHint: true`; signed-in writes carry `readOnlyHint: false` with `destructiveHint`, and admin-only tools are listed to admins only.
- Tool descriptions are free of internal names (jurisdictional 3e5df62e, 034af4d8).
- Work leases (`claim_work`, https://github.com/civicstudio/jurisdictional/issues/157 closed) and `send_feedback` are live, and the skill uses both.
- `/terms` is live; `/terms` and `/privacy` agree on 90 days for request logs, and the server prunes them on that schedule (D7 settled).
- The README says everything the plugin sends and where, for the security scan.
- Endpoint is `https://jurisdictional.org/mcp`; publisher is Civic Studio.

Only Ryan can do, in order:

1. Decide D1: list the MCP connector now with its write tools, or read-only first.
2. D2, direction decided by Ryan 2026-11-18: changes come through proposals. Signed-in contributors' writes are reviewed before they go live; the details (admins, trusted contributors, `CONTRIBUTION_DAILY_CAP`) are still being settled.
3. Done (Ryan, 2026-11-17, confirmed 2026-11-18), D5: the plugin stays at `jurisdictional/jurisdictional-skill`; Civic Studio is the publisher.
4. Decide D6: registry namespace `org.jurisdictional` (DNS check) or `io.github.jurisdictional` (GitHub login).
5. Done (https://github.com/civicstudio/jurisdictional/pull/162, merged by Ryan 2026-11-19, live): `/privacy` has a contact (support@jurisdictional.org), what sign-in keeps, and retention for captures, feedback and juricode searches.
6. Approve the icon at `.claude-plugin/icon.png` (1024 × 1024, upscaled from a 200 px source); the first portal save fixes it as the listing icon.
7. Submit the plugin bundle at https://claude.ai/directory/manage → Submit new → Plugin bundle, run Validate, and fix any Blocking finding.
8. Run every tool through MCP Inspector or as a custom connector, then submit the MCP connector at the same portal with a seeded non-admin test account and three example prompts.
9. Publish the MCP Registry entry (below) once D6 is set.

## The surfaces

| Surface | What it is | Path in | Who acts |
|---|---|---|---|
| Our own Claude Code marketplace | `.claude-plugin/marketplace.json` in this repo | None; users run `/plugin marketplace add jurisdictional/jurisdictional-skill` | Done |
| Anthropic directory: plugin bundle | One listing that reaches claude.ai, Cowork and Claude Code; also lands in the `claude-community` marketplace | Developer portal, "Plugin bundle" | Ryan |
| Anthropic directory: MCP connector | The remote server listed for claude.ai, Desktop, mobile, Cowork and Claude Code | Developer portal, "MCP connector" | Ryan, after D1 |
| `claude-plugins-official` | Anthropic's default marketplace | No portal path; "ask an Anthropic partner contact" | Ryan, later |
| MCP Registry | The open metadata registry at registry.modelcontextprotocol.io (preview) | `mcp-publisher` + `server.json` | Ryan (login), prepared below |
| Grok | No third-party catalog submission found; users add the server by URL, and Grok Build reads Claude Code plugins | grok.com custom connector, Grok Build, xAI API | Ryan to confirm |

## Claude

### Done

- Own marketplace: `.claude-plugin/marketplace.json` passes `claude plugin validate --strict .claude-plugin/marketplace.json` (2026-11-17). Install is two commands: `/plugin marketplace add jurisdictional/jurisdictional-skill`, `/plugin install jurisdictional@jurisdictional`. Doc: https://code.claude.com/docs/en/plugins/publish
- Plugin: `claude plugin validate --strict .` passes with no warnings (2026-11-17). The repo's Claude Code guidance moved from the root `CLAUDE.md` to `.claude/CLAUDE.md`, which Claude Code still reads as project memory; the validator warns about a root `CLAUDE.md` in a plugin.
- Plugin manifest: `name` is kebab-case with no reserved word; `version`, `description`, `author` (Civic Studio, https://civic.studio), `homepage`, `repository`, `license`, `keywords`, `documentationUrl`, `supportUrl`, `privacyPolicyUrl` and `termsOfServiceUrl` set. Field reference: https://code.claude.com/docs/en/plugins/manifest-reference
- `LICENSE` (MIT), README well over 40 words with the install line and a "What the plugin sends" section. Checklist: https://claude.com/docs/plugins/pre-submission-checklist
- No `.DS_Store`, scripts, `bin/`, `headersHelper`, launchers or lockfiles; only Markdown, JSON, plain text and one PNG. `.mcp.json` is one `type: http` server at an `https://` URL with no headers. The directory accepts `headersHelper`, `bin/` and scripts only from Verified organizations (validator feedback, 2026-11-16).
- Icon: `.claude-plugin/icon.png`, 1024 × 1024 PNG, 365 KB, transparent background; slightly soft, upscaled (Lanczos) from `priv/static/images/jurisdictional-logo.png` (200 × 200). Swap in an export from the original vector if one turns up, before the first portal save.
- Skill: `skills/gather/SKILL.md` is 417 lines (limit 500) and keeps its three stops (after Step 2, each Step 4 review, the next target); `name` matches its folder; `description` says what and when. Spec: https://agentskills.io/specification
- Leases (jurisdictional 6e4c6e93, skill 0.6.2): `claim_work` hands out gather targets with an 8-hour lease and `release_work` hands them back; SKILL.md's "Choosing a next target" and `/gather next` claim with it, and Step 6 releases what the session won't finish. https://github.com/civicstudio/jurisdictional/issues/157 is closed.
- Feedback (jurisdictional cdf0ab52): `send_feedback` for signed-in users; the skill offers it at the next-target stop, only with text the user approved.
- Terms (jurisdictional 7dbf572d, https://github.com/civicstudio/jurisdictional/pull/158): https://jurisdictional.org/terms answers 200, linked from the footer and `/skill`.
- D7, request-log retention: settled at 90 days. `/privacy` says "Each request is kept for 90 days, then deleted", `/terms` says the same, and the server's daily rollup deletes raw rows after 90 days, keeping daily totals.
- Server, checked against production on 2026-11-17:
  - Streamable HTTP at `https://jurisdictional.org/mcp` (`/api/mcp/message` stays as an alias); `initialize` answers protocol `2025-06-18`, `serverInfo.version` `1.0.0`; 21 tools from `tools/list` with no token.
  - OAuth: protected resource metadata at `/.well-known/oauth-protected-resource/mcp` (`resource` equals the MCP URL), authorization server metadata at `/.well-known/oauth-authorization-server` with `code_challenge_methods_supported: ["S256"]`, `registration_endpoint` (DCR) and `token_endpoint_auth_methods_supported: ["none"]`. Requirements: https://claude.com/docs/connectors/building/authentication
  - Lazy auth: `tools/call` on `propose_change` with no token answers HTTP 401 with `WWW-Authenticate: Bearer resource_metadata="…/oauth-protected-resource/mcp"`. Doc: https://claude.com/docs/connectors/building/lazy-authentication
- Connector review criteria (https://claude.com/docs/connectors/building/review-criteria), checked 2026-11-17:
  - Every tool carries `title`, top-level and in its annotations (jurisdictional 2a97b93).
  - Anonymous: all 21 tools `readOnlyHint: true`.
  - Signed in: additive writes (`propose_change`, `create_entity`, `import_jurisdiction`, `submit_image`, `claim_work`, `send_feedback` and the rest) carry `readOnlyHint: false, destructiveHint: false`; `gather` reads a page and changes nothing, so it carries `readOnlyHint: true, openWorldHint: true`.
  - Admin only: tools that delete or write over values on file (`delete_entity`, `merge_entities`, `end_tenure`, `reconcile_roster`, `review_change`, `update_image_credit`, `submit_meeting_pull`) carry `destructiveHint: true`. `delete_entity` and `merge_entities` are now listed to admins only, so a reviewer's non-admin account sees no tool that always refuses (jurisdictional 034af4d8).
  - Descriptions: no local paths, repo scripts, admin tool names or internal coinages left (jurisdictional 3e5df62e). No catch-all request tool; names under 64 characters; no instructions to call other software.
- Listing pages live (200 on 2026-11-17): https://jurisdictional.org/privacy, https://jurisdictional.org/support (support@jurisdictional.org), https://jurisdictional.org/terms, https://jurisdictional.org/skill, https://jurisdictional.org/license.
- Publisher (D5, the company half): Civic Studio is the maker and publisher; Jurisdictional is the app and publishes the data. `author` and marketplace `owner` are Civic Studio; the plugin keeps the name `jurisdictional`.

### Plugin bundle (Ryan)

1. **Icon.** Approve `.claude-plugin/icon.png` or replace it: a square PNG or JPEG, 512 to 2048 px, under 2 MB. SVG and WebP are not accepted. The file becomes the listing icon only once, on the first save or submission in the portal.
2. **Submit** at https://claude.ai/directory/manage → Submit new → Plugin bundle. Needs a paid claude.ai plan and a connected GitHub account with push access to `jurisdictional/jurisdictional-skill` (public). Steps: Source, Validate, Listing details, Data handling, Compliance (a contact email plus four acknowledgements), Review and submit. Limits: 10 submissions per organization per 24 hours, one per repo and folder. Docs: https://claude.com/docs/directory/publish and https://claude.com/docs/plugins/submit
3. **Review timeline:** not published (**unverified**). New listings are reviewed by a person; every version gets automated validation and a security scan.
4. Raise `version` in `plugin.json` with every change; the directory follows commits, and a stale version keeps users on old copies.

### MCP connector (Ryan, after D1)

1. Done (https://github.com/civicstudio/jurisdictional/pull/162, merged by Ryan 2026-11-19, live): `/privacy` has a contact (support@jurisdictional.org), what sign-in keeps, and retention for captures, feedback and juricode searches.
2. **Test every tool** through MCP Inspector (https://modelcontextprotocol.io/docs/tools/inspector) and as a custom connector in Claude; the portal's Test & launch step asks you to confirm it.
3. **Submit** at https://claude.ai/directory/manage → Submit new → MCP connector. Doc: https://claude.com/docs/connectors/building/submission. Bring:
   - listing text within the limits: name ≤ 100 characters, one-liner ≤ 200, description ≤ 2,000, one to five categories;
   - documentation URL (https://jurisdictional.org/skill), privacy policy URL (https://jurisdictional.org/privacy), support contact (support@jurisdictional.org), icon;
   - a seeded non-admin test account on production, for a Verified review;
   - at least three working example prompts (the plan's E1–E6 are candidates, re-verified on the day);
   - the compliance acknowledgements and the Anthropic Software Directory Policy: https://support.claude.com/en/articles/13145358-anthropic-software-directory-policy
   - The listing starts as Community; Anthropic may escalate to Verified. Escalations: mcp-review@anthropic.com. Verification doc: https://claude.com/docs/connectors/verification

### Later

- **`claude-plugins-official`:** no public process. The publish doc says to ask an Anthropic partner contact: https://code.claude.com/docs/en/plugins/publish. Pursue after a Verified connector and usage numbers.
- **Standalone skill listing:** none exists. "Skills aren't a standalone submission type"; the plugin bundle covers it: https://claude.com/docs/directory/publish

## MCP Registry (any client, including Grok Build via `grok mcp add`)

Prepared: a `server.json` for a remote-only server. Docs: https://modelcontextprotocol.io/registry/quickstart and https://modelcontextprotocol.io/registry/remote-servers. The registry is in preview; data resets can happen, so keep this file in the repo and re-publish from it.
The `name` below assumes the GitHub namespace; change it to `org.jurisdictional/jurisdictional` if D6 picks the domain.

```json
{
  "$schema": "https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json",
  "name": "io.github.jurisdictional/jurisdictional",
  "title": "Jurisdictional",
  "description": "Every U.S. government at an address: layers, agencies, boards, officials, services.",
  "repository": {
    "url": "https://github.com/jurisdictional/jurisdictional-skill",
    "source": "github"
  },
  "version": "1.0.0",
  "remotes": [
    {
      "type": "streamable-http",
      "url": "https://jurisdictional.org/mcp"
    }
  ]
}
```

Only Ryan can do:

1. **Namespace (D6).** `io.github.jurisdictional/…` needs only `mcp-publisher login github` as the `jurisdictional` GitHub org. `org.jurisdictional/…` needs DNS or HTTP verification of jurisdictional.org: https://modelcontextprotocol.io/registry/authentication. The remote-servers doc recommends the domain form when the URL is on a domain you control.
2. **Publish:** install `mcp-publisher` (`brew install mcp-publisher`), `mcp-publisher validate`, `mcp-publisher login github` (or DNS), `mcp-publisher publish`. Keep `description` at or under 100 characters (the one above is 83). Verify with `curl "https://registry.modelcontextprotocol.io/v0.1/servers?search=jurisdictional"`.
3. **`version`** tracks the server's `serverInfo.version` (production reports `1.0.0`).

## Grok

What xAI documents today, all fetched 2026-11-12:

- **grok.com custom connectors.** Users add any public MCP server: grok.com/connectors → New Connector → Custom → enter the URL and "complete any required authentication". "Connectors are available to all Grok users." On Grok Business and Enterprise a team admin provisions it first in the console (Grok Business → Connectors → + Add Connector → Other). Docs: https://docs.x.ai/grok/connectors and https://docs.x.ai/grok/connector-management
- **Connector catalog.** The connectors page describes a catalog of pre-configured OAuth connectors (Box, GitHub, Notion, Linear) and says more are added regularly. It does not say how a vendor is added. The catalog page itself (https://docs.x.ai/grok/connectors/catalog) returned 404 to our fetch. **No submission path found**; the only contact named for connector help is SpaceXSI sales on the Business/Enterprise page, with no address shown.
- **Grok Build (terminal agent).** `grok mcp add --transport http <name> <url>`, optional repeatable `--header "Name: Value"`; config in `~/.grok/config.toml` as `[mcp_servers.<name>]` with `url` and `headers`; `${VAR}` expands in `url` and `headers`; `/mcps` in a session, `i` to authenticate OAuth servers, `grok mcp doctor`. Docs: https://docs.x.ai/build/features/mcp-servers and https://docs.x.ai/build/settings
- **Grok Build reads Claude Code plugins.** The features page says "Grok automatically reads Claude Code marketplaces, plugins, skills, MCPs, agents, hooks", plugins "extend Grok with additional skills, agents, hooks, MCP servers, and LSP servers", marketplaces come from `[[marketplace.sources]]` in `~/.grok/config.toml`, and there is a Marketplace tab in the TUI. Skill frontmatter keys `user-invocable`, `disable-model-invocation`, `argument-hint` and `allowed-tools` are all recognized, and extra keys are ignored. Doc: https://docs.x.ai/build/features/skills-plugins-marketplaces
- **xAI API.** A `tools` entry `{"type": "mcp", "server_url", "server_label", "server_description?", "allowed_tools?", "authorization?", "headers?"}` in the Responses API; only Streamable HTTP and SSE transports; `require_approval` and `connector_id` are not supported. Doc: https://docs.x.ai/developers/tools/remote-mcp

Done:

- Production already serves Grok: xAI's remote MCP tool and grok.com connectors require a public Streamable HTTP server, which `https://jurisdictional.org/mcp` is. Grok has been contributing through the HTTP endpoint for weeks (`GROK_CLI_GUIDANCE.md`, `docs/GROK_BRIEF.md`).
- `/skill` and `llms.txt` carry the three Grok paths with sign-in.

Nearest real equivalent of a listing, in order of value:

1. **Our Claude Code marketplace is the Grok Build marketplace.** Nothing to submit; the same repo serves both, per the features page above. **Unverified:** whether Grok Build's `/mcps` → `i` completes our OAuth sign-in for the plugin's server, and the exact `[[marketplace.sources]]` entry format, which the fetched page does not show.
2. **MCP Registry entry** (above), which any client can search.
3. **A documented custom-connector URL**, which `/skill` now is.

Only Ryan can do:

1. **Confirm on grok.com** with his account: add the connector, ask "who governs 300 Hemlock St, Vacaville, CA", and record whether Grok offers a sign-in for the server (the docs don't list the auth methods a custom connector supports). Screenshot the connector card for the marketing lane.
2. **Confirm in Grok Build:** install it following xAI's own instructions (https://docs.x.ai/build/overview), add `jurisdictional/jurisdictional-skill` as a marketplace source, and check whether the plugin's server connects anonymously and whether `/mcps` → `i` signs in against our lazily-authenticated server. Record the result in `TESTING.md`.
3. **Ask xAI about the catalog.** No form exists; the route is a business contact. Decide whether to pursue it now or after the Anthropic listing. **Unverified** that a catalog slot is open to third parties at all.
4. **Enterprise angle:** cities on Grok Business/Enterprise can be told the one-line admin step (Connectors → Other → our URL). Fits the verified-city idea.

## Open questions for Ryan (decisions, not tasks)

- **D1, connector scope:** list the MCP connector now with its signed-in write tools, or list it read-only first and add writes later?
- **D2, public write tools:** direction decided (Ryan, 2026-11-18): changes come through proposals, reviewed before they go live. Still open: whether admins and trusted contributors keep live writes, and whether to turn on `CONTRIBUTION_DAILY_CAP`.
- **D5, GitHub org:** decided: the plugin stays at `jurisdictional/jurisdictional-skill` (Ryan, 2026-11-17, confirmed 2026-11-18).
- **D6, registry namespace:** `org.jurisdictional` (DNS or HTTP check, matches the server's domain) or `io.github.jurisdictional` (GitHub login only)?
- Whether to spend a contact on the Grok catalog now.

Settled:

- D4 endpoint URL (2026-11-13, jurisdictional f4e30ff): `https://jurisdictional.org/mcp`, with `/api/mcp/message` as a permanent alias.
- D7 request-log retention (2026-11-17): 90 days, the same in `/privacy`, `/terms` and the server's pruning; daily totals kept longer. A `/terms` page is live.
