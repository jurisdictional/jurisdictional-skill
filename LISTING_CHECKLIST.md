# Listing checklist

How Jurisdictional gets listed where Claude and Grok users find skills and MCP servers.
Written 2026-11-12 from pages fetched that day; each step links the official doc or form it comes from.
Anything not read on an official page is marked **unverified**.
The longer plan, with the milestones and the decisions D1–D9, is `docs/OFFICIAL_SKILL_PLAN.md` in the private jurisdictional repo; this file is the short, current list.

One rule for every listing: the data is ODbL 1.0 with each record under DbCL 1.0 (https://jurisdictional.org/license).
Never describe it as CC0.

## The surfaces

| Surface | What it is | Path in | Who acts |
|---|---|---|---|
| Our own Claude Code marketplace | `.claude-plugin/marketplace.json` in this repo | None; users run `/plugin marketplace add jurisdictional/jurisdictional-skill` | Done |
| Anthropic directory: plugin bundle | One listing that reaches claude.ai, Cowork and Claude Code; also lands in the `claude-community` marketplace | Developer portal, "Plugin bundle" | Ryan |
| Anthropic directory: MCP connector | The remote server listed for claude.ai, Desktop, mobile, Cowork and Claude Code | Developer portal, "MCP connector" | Ryan, after one server fix |
| `claude-plugins-official` | Anthropic's default marketplace | No portal path; "ask an Anthropic partner contact" | Ryan, later |
| MCP Registry | The open metadata registry at registry.modelcontextprotocol.io (preview) | `mcp-publisher` + `server.json` | Ryan (login), prepared below |
| Grok | No third-party catalog submission found; users add the server by URL, and Grok Build reads Claude Code plugins | grok.com custom connector, Grok Build, xAI API | Ryan to confirm |

## Claude

### Done

- Own marketplace: `.claude-plugin/marketplace.json` passes `claude plugin validate --strict .claude-plugin/marketplace.json` (run 2026-11-12). Install is two commands: `/plugin marketplace add jurisdictional/jurisdictional-skill`, `/plugin install jurisdictional@jurisdictional`. Doc: https://code.claude.com/docs/en/plugins/publish (publish through your own marketplace).
- Plugin manifest: `name` is kebab-case with no reserved word; `version`, `description`, `author`, `homepage`, `repository`, `license` and `keywords` set. Field reference: https://code.claude.com/docs/en/plugins/manifest-reference
- `LICENSE` file (MIT) and `license` in `plugin.json`. Checklist item: https://claude.com/docs/plugins/pre-submission-checklist
- README over 40 words with the marketplace install line (the validator's advice check).
- `.mcp.json` points at an `https://` remote server with no headers and no `headersHelper`; sign-in is the server's OAuth (`claude mcp login plugin:jurisdictional:jurisdictional` in a real terminal, then a new session). The directory accepts `headersHelper`, `bin/` and scripts only from Verified organizations (validator feedback, 2026-11-16), so 0.6.0 removed them.
- Skill: `skills/gather/SKILL.md` is 381 lines (limit 500), `name` matches its folder, `description` says what and when. Spec: https://agentskills.io/specification
- Server, checked against production on 2026-11-12:
  - Streamable HTTP at `https://jurisdictional.org/mcp`; `initialize` answers protocol `2025-06-18`; 20 public tools from `tools/list` with no token.
  - OAuth: protected resource metadata at `/.well-known/oauth-protected-resource/api/mcp/message` (`resource` equals the MCP URL), authorization server metadata at `/.well-known/oauth-authorization-server` with `code_challenge_methods_supported: ["S256"]`, `registration_endpoint` (DCR) and `token_endpoint_auth_methods_supported: ["none"]`. Requirements: https://claude.com/docs/connectors/building/authentication
  - Lazy auth: `tools/call` on `propose_change` with no token answers HTTP 401 with `WWW-Authenticate: Bearer resource_metadata="…"`. Doc: https://claude.com/docs/connectors/building/lazy-authentication
  - Every public tool carries `readOnlyHint: true`.
- Listing pages live: https://jurisdictional.org/privacy (200), https://jurisdictional.org/support (200, support@jurisdictional.org), https://jurisdictional.org/skill (200), https://jurisdictional.org/license (200).

### Prepared on 2026-11-12 (uncommitted here; Ryan reviews and commits)

- `.claude-plugin/plugin.json`: added `documentationUrl` (https://jurisdictional.org/skill), `supportUrl` (https://jurisdictional.org/support) and `privacyPolicyUrl` (https://jurisdictional.org/privacy). The directory reads these from `plugin.json`: https://code.claude.com/docs/en/plugins/manifest-reference. This clears the validator's `PRIVACY_URL_MISSING` warning.
- `.gitignore`: added `.DS_Store`, and removed the stray `.DS_Store` from the working tree (it was never committed). The directory cannot list a plugin that contains one (validator finding `ARCHIVE_OS_METADATA_FILE`).
- `README.md`: an "Other assistants" note for Grok, plus Privacy and Support links.
- `/skill` on jurisdictional.org: per-assistant connect and sign-in steps for Claude Code, Grok and any MCP client, and a design pass. Two commits in the jurisdictional worktree, not yet pushed.
- Validator after these changes: `claude plugin validate .` passes; `--strict` fails only on the root `CLAUDE.md` warning, which is expected per `TESTING.md`.
- Icon (2026-11-12): `.claude-plugin/icon.png`, 1024 × 1024 PNG, a white building (dome, flag, colonnade, steps) on blue-600, rendered from `priv/static/images/jurisdictional-icon.svg` in the jurisdictional repo; it fits inside a circle, so a round mask keeps it whole. Ryan to approve before the first portal save.
- Tool titles (2026-11-12): every tool in `tools/list` carries `title`, top-level and in its annotations (jurisdictional commit 2a97b93).
- Publisher (2026-11-12, Ryan): Civic Studio is the maker and publisher; Jurisdictional is the app and publishes the data. `author` and marketplace `owner` are Civic Studio (https://civic.studio); the plugin keeps the name `jurisdictional`.

### Only Ryan can do

Plugin bundle, in order:

1. **Icon.** Prepared, see Done; approve it. A square PNG or JPEG, 512 to 2048 px, under 2 MB, at `.claude-plugin/icon.png` or named by `icon` in `plugin.json`. SVG and WebP are not accepted. The validator says the file becomes the listing icon only once, on the first save or submission in the portal, so pick the final mark first. The only square PNG in the platform repo is `priv/static/images/jurisdictional-logo.png` at 200 × 200, too small; export a 1024 × 1024 version of the mark. Source: `claude plugin validate --strict .` output, 2026-11-12.
2. **Commit the pending work in this repo**: the `plugin.json`, `.gitignore` and `README.md` changes above; the uncommitted "post as you go" edit in `skills/gather/SKILL.md` (its own commit); and the sign-in rewrite requested in `.claude/inbox/from-jurisdictional-2026-11-09-mcp-browser-sign-in.md` (done in 0.6.0: browser sign-in via `claude mcp login`; the token file was dropped for the directory rules). Bump `version` in `plugin.json`; the directory follows commits and a stale version keeps users on old copies.
3. **Decide the write-tool scope (D2 in OFFICIAL_SKILL_PLAN).** Today any signed-in user sees `create_entity` and `import_jurisdiction`, which apply live. The plan recommends listing reads plus `propose_change` only. This is a server change in the jurisdictional repo.
4. **Done (2a97b93): `title` on every tool.** Production tools carry `readOnlyHint` but no `title`; the connector checklist asks for both, and missing annotations are the most common rejection. Server change in `lib/jurisdictional/mcp`. Checklist: https://claude.com/docs/connectors/building/review-criteria
5. **Submit the plugin bundle** at https://claude.ai/directory/manage → Submit new → Plugin bundle. Needs a paid claude.ai plan and a connected GitHub account with push access to `jurisdictional/jurisdictional-skill`. The repo must be public before the listing goes live. Steps are Source, Validate, Listing details, Data handling, Compliance (a contact email plus four acknowledgements), Review and submit. Limits: 10 submissions per organization per 24 hours, one per repo and folder. Docs: https://claude.com/docs/directory/publish and https://claude.com/docs/plugins/submit
6. **Review timeline:** not published (unverified). New listings are reviewed by a person; every version gets automated validation and a security scan.

MCP connector, after steps 3 and 4:

7. **Submit the connector** at https://claude.ai/directory/manage → Submit new → MCP connector. Doc: https://claude.com/docs/connectors/building/submission. Bring:
   - listing text within the limits: name ≤ 100 characters, one-liner ≤ 200, description ≤ 2,000, one to five categories;
   - documentation URL (https://jurisdictional.org/skill or /developers), privacy policy URL (https://jurisdictional.org/privacy), support contact (support@jurisdictional.org), icon;
   - reviewer test account credentials: a seeded non-admin account on production, with sample data;
   - at least three working example prompts (the plan's E1–E6 are candidates, re-verified on the day);
   - confirmation that you ran every tool yourself through MCP Inspector or as a custom connector;
   - the seven compliance acknowledgements and the Anthropic Software Directory Terms and Policy: https://support.claude.com/en/articles/13145358-anthropic-software-directory-policy
   - The listing starts as Community; Anthropic may escalate to Verified. Escalations: mcp-review@anthropic.com. Verification doc: https://claude.com/docs/connectors/verification
8. **Terms of service.** https://jurisdictional.org/terms is 404. The connector submission lists documentation, privacy, support and icon as required; whether a terms URL is required is **unverified**. `termsOfServiceUrl` is an optional `plugin.json` field. Write `/terms` before submitting if you want it on the listing.
9. **Privacy policy content.** Confirm https://jurisdictional.org/privacy states what the API logs (`api_requests` keeps IP and user agent) and the retention period; the connector checklist asks for collection, use, retention and contact.
10. **Publisher identity (D5): decided.** Civic Studio publishes; Jurisdictional is the product. Still open: which GitHub org hosts the plugin repo.

Later:

11. **`claude-plugins-official`:** no public process. The publish doc says to ask an Anthropic partner contact: https://code.claude.com/docs/en/plugins/publish. Pursue after a Verified connector and usage numbers.
12. **Standalone skill listing:** none exists. "Skills aren't a standalone submission type"; the plugin bundle covers it: https://claude.com/docs/directory/publish

## MCP Registry (any client, including Grok Build via `grok mcp add`)

Prepared: a `server.json` for a remote-only server. Docs: https://modelcontextprotocol.io/registry/quickstart and https://modelcontextprotocol.io/registry/remote-servers. The registry is in preview; data resets can happen, so keep this file in the repo and re-publish from it.

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
3. **`version`** should track the server's `serverInfo.version` (production reports `1.0.0`).

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

- D1 listing scope: read-only connector first, or wait for `propose_change` on the listing.
- D2 public write tools: `propose_change` only, or also `create_entity`, `import_jurisdiction` and `gather` for signed-in users.
- D4 endpoint URL: decided and live (2026-11-13, jurisdictional f4e30ff): `https://jurisdictional.org/mcp`, with `/api/mcp/message` as a permanent alias. `.mcp.json` and the docs here point at `/mcp`.
- D5: publisher decided (Civic Studio); GitHub org still open.
- D6 registry namespace: `io.github.jurisdictional` or `org.jurisdictional`.
- D7 privacy: request-log retention period, and whether to add a `/terms` page.
- Whether to spend a contact on the Grok catalog now.
