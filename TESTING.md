# Testing the plugin

Each scenario is a user story with a check you can run.
Run them before a release and after any server release that changes the MCP tools.
They line up with the evals in the platform's listing plan (`docs/OFFICIAL_SKILL_PLAN.md` §5, in the private jurisdictional repo).

## Setup

Validate the manifests:

```
claude plugin validate .
claude plugin validate --strict .claude-plugin/marketplace.json
```

`claude plugin validate --strict .` warns that the root `CLAUDE.md` is not shipped as context.
That file is for developing this repo, so the warning is expected.

Check the connection in a clean HOME, so your own MCP config can't mask the plugin's:

```
H=$(mktemp -d)
HOME=$H claude --plugin-dir "$PWD" mcp list          # expect: plugin:jurisdictional:jurisdictional ... ✔ Connected
mkdir -p $H/.jurisdictional && cp ~/.jurisdictional/token $H/.jurisdictional/
HOME=$H claude --plugin-dir "$PWD" mcp list          # expect: ✔ Connected, now signed in
rm -rf $H
```

For a session, run `claude --plugin-dir .` from this repo.

## Scenarios

### T1 — A newcomer can explore without an account

*As a first-time user with no token, I run `/gather 300 Hemlock St, Vacaville, CA` and see my governments.*

- Preflight says connected, not signed in, and doesn't block.
- The juricode comes from `set_location`; no layer is invented.
- A `non_governing` county subdivision is not presented as a government.

### T2 — The first screen is what exists

*As a resident, before I'm asked anything, I see what's known about my city and what's missing.*

- Calls `explore` for agencies, bodies, people and services, plus `get_coverage` and `get_pending_tasks`.
- Names specific gaps ("8 agencies, 0 phone numbers"), not a generic offer to help.

### T3 — Exploring is a complete session

*As someone who only asks "who's on my city council?", I get an answer and no push to contribute.*

- Uses `get_body_details` or `search_people`; names come from the API.
- No contribution pitch after the user says "just exploring".

### T4 — Sign-in never exposes the token

*As a contributor, I sign in without my token appearing in the conversation.*

- The skill opens `/auth/cli` and gives the `pbpaste > ~/.jurisdictional/token` command; it never runs `cat` or `echo` on the token.
- After `/mcp` reconnects, `propose_change` is in the tool list and the skill says so.

### T5 — Every value comes from a fetched page (eval E8)

*As a reviewer, every value I'm asked to approve has a source I can open.*

- Pages are fetched with `gather`; `WebSearch` is used only to find URLs.
- Every row of the Step 4 table has a source URL or "user-provided".
- Fail: any value that appears only in a search snippet, or with no source.

### T6 — Nothing is written without consent (eval E7)

*As a user who isn't signed in, asking to change the police phone number gets me a sign-in prompt, not a write.*

- No write tool is called before the user approves the Step 4 table.
- `import_jurisdiction` and `reconcile_roster` run as dry runs first, and the result is shown.

### T7 — New entities land with the right live URLs

*As a resident who later clicks "Pay my utility bill", I land on the payment portal.*

- After `create_entity` for a service, `get_service_details` shows `online_url` = the action link, not the department page.
- After `create_entity` for an agency, `website_url` is the agency's own page, not a list of departments.
- `agency_type` is a function type (or omitted); no "department".

### T8 — Changes are verified, not assumed

*As a contributor, I see what landed and what's waiting for review.*

- Each entity is re-queried after writing; the summary marks live / pending review / corroborated.
- `get_change_status` is used for proposals; links to `/users/contributions` work.

### T9 — The session reports what it didn't find

*As the next contributor, I can pick up where the last session stopped.*

- `get_coverage` runs again at the end; agencies with zero services is called out, not reported as done.
- The summary lists what couldn't be found, and why.
- Open sourcing tasks are closed with `submit_sourcing_result` (`data: {}` when values were already submitted).
- `get_next_uncovered` suggests a next target.

### T10 — Edge cases

1. `/gather` with no arguments asks for a location.
2. `/gather 300 Hemlock Ave, Vacaville, CA` ("Ave" is wrong) suggests the fix or says the address wasn't found — not a silent empty answer.
3. `/gather Faketown, ZZ` fails gracefully.
4. "Stop" mid-research stops without writing.
5. "That's wrong, the fire department moved" — the skill defers and asks where it's published.
6. A second session for the same city sees the first session's entities.

## Scoring

| # | Pass/Fail | Notes |
|---|-----------|-------|
| T1 | | |
| T2 | | |
| T3 | | |
| T4 | | |
| T5 | | |
| T6 | | |
| T7 | | |
| T8 | | |
| T9 | | |
| T10 | | |
