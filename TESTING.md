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

- The first answer is Step 2's table; "not signed in" is one line under it, and nothing blocks.
- The juricode comes from `set_location`; no layer is invented.
- A `non_governing` county subdivision is not presented as a government.

### T2 — The first screen is every government's coverage

*As a resident, before I'm asked anything, I see how well each government at my address is covered and what's missing.*

- `get_coverage` runs for every governing layer (place, school district, county, state, and the districts) in one parallel batch, plus `get_pending_tasks`.
- One table, worst-covered first, with rung and tier ("governed · Bronze") and one specific gap per row ("0 services; 30 agencies with no website or phone").
- District layers are graded by their seats; one with no linked seat is offered as a quick contribution (link it with `electing_jurisdiction_id`).
- "Who represents me?" is answered with `explore(focus: "people")` over the district layers, naming the representative for each.
- It recommends the lowest rung and says what it would change; the choice is an `AskUserQuestion` that includes "Just exploring".

### T3 — Exploring is a complete session

*As someone who only asks "who's on my city council?", I get an answer and no push to contribute.*

- Uses `get_body_details` or `search_people`; names come from the API.
- No contribution pitch after the user says "just exploring".

### T4 — Sign-in never exposes the token

*As a contributor, I sign in without my token appearing in the conversation.*

- The skill gives the save command first (paste, don't run), then opens `/auth/cli`; it never runs `cat` or `echo` on the token.
- Pressing Enter with the command itself still on the clipboard prints "Not saved…" and leaves any existing token file alone.
- A token file holding anything but a `jur_...` key still connects, anonymously (the helper sends no header).
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

- Approval is per layer (one table for all new agencies), not a y/n per entity; the only stops are after Step 2, each review, and the next target.
- Each entity is re-queried after writing; the summary marks live / pending review / corroborated.
- `get_change_status` is used for proposals; every link in the summary (entity pages, `/users/contributions`, the jurisdiction) opens and shows the submitted data.

### T9 — The session reports what it didn't find

*As the next contributor, I can pick up where the last session stopped.*

- `get_coverage` runs again at the end; agencies with zero services is called out, not reported as done.
- The summary lists what couldn't be found, and why.
- Open sourcing tasks are closed with `submit_sourcing_result` (`data: {}` when values were already submitted).
- The rung and tier are reported before → after ("governed · Bronze → served · Silver").
- The next target comes from the user's own address first; then `coverage: "governed"` places, largest first; never a census-designated place (`kind: "non_governing"`).

### T10 — Edge cases

1. `/gather` with no arguments asks for a location.
2. `/gather 300 Hemlock Ave, Vacaville, CA` ("Ave" is wrong) suggests the fix or says the address wasn't found — not a silent empty answer.
3. `/gather Faketown, ZZ` fails gracefully.
4. "Stop" mid-research stops without writing.
5. "That's wrong, the fire department moved" — the skill defers and asks where it's published.
6. A second session for the same city sees the first session's entities.

### T11 — A regular contributor jumps straight to work

*As someone who has done this before, `/gather next CA` takes me to the most useful place in California.*

- No address is asked for; the options are partly covered places by population (Los Angeles, San Diego, San Jose with 0 services), not Acalanes Ridge or Acampo.
- Picking one goes straight to Step 2 for it; finishing it offers the next one in the same session.

### T12 — Limits and failures are said plainly

*As a contributor whose key hits its daily limit, I'm told when it resets and what's left, not shown a stack of errors.*

- On an error with `data.reason: "rate_limited"`, the skill stops calling tools, gives the reset time in local terms, offers `upgrade_url` or `signup_url`, and lists what wasn't done.
- On `gather timed out`, `gather empty render`, `Domain not allowed`, or an "Access Denied" page returned as content, it asks for the page instead of retrying or extracting from it.
- Before creating a person it searches the full name, then the last name alone.

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
| T11 | | |
| T12 | | |
