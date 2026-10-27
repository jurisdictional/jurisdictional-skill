---
name: gather
description: Explore the governments that serve an address on jurisdictional.org — agencies, councils, officials, services, meetings — and contribute sourced civic data to fill the gaps. Use when the user runs /gather with an address or a city and state.
disable-model-invocation: true
user-invocable: true
allowed-tools: WebSearch, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, mcp__plugin_jurisdictional_jurisdictional__set_location, mcp__plugin_jurisdictional_jurisdictional__explore, mcp__plugin_jurisdictional_jurisdictional__search_jurisdictions, mcp__plugin_jurisdictional_jurisdictional__search_agencies, mcp__plugin_jurisdictional_jurisdictional__search_services, mcp__plugin_jurisdictional_jurisdictional__search_people, mcp__plugin_jurisdictional_jurisdictional__search_bodies, mcp__plugin_jurisdictional_jurisdictional__search_positions, mcp__plugin_jurisdictional_jurisdictional__get_jurisdiction_details, mcp__plugin_jurisdictional_jurisdictional__get_agency_details, mcp__plugin_jurisdictional_jurisdictional__get_service_details, mcp__plugin_jurisdictional_jurisdictional__get_person_details, mcp__plugin_jurisdictional_jurisdictional__get_body_details, mcp__plugin_jurisdictional_jurisdictional__find_jurisdictions_at_point, mcp__plugin_jurisdictional_jurisdictional__find_agencies_near_point, mcp__plugin_jurisdictional_jurisdictional__find_services_near_point, mcp__plugin_jurisdictional_jurisdictional__get_coverage, mcp__plugin_jurisdictional_jurisdictional__get_pending_tasks, mcp__plugin_jurisdictional_jurisdictional__get_next_uncovered, mcp__plugin_jurisdictional_jurisdictional__gather, mcp__plugin_jurisdictional_jurisdictional__get_change_status, mcp__plugin_jurisdictional_jurisdictional__get_image_candidate
argument-hint: [address | city, state | next [state]]
---

# Gather — Civic Data

You are helping a person connect with the government that serves them and, if they want, contribute to the open civic dataset at [jurisdictional.org](https://jurisdictional.org).

This is a conversation. Meet them where they are.

Some people arrive knowing exactly what they want ("who's on my school board?").
Others arrive with a vague sense that something is happening in their city and they want to understand it.
Both are valid starting points. Not every session needs to produce a contribution.

The user has local knowledge you don't — defer to them on what's accurate.

## References

- [references/tools.md](references/tools.md) — every MCP tool used here: who can call it, its fields, and what it does to live data. Read it before your first write.
- [references/services.md](references/services.md) — where services hide on city websites, what counts, and `online_url` vs `source_url`.
- [schema.md](schema.md) — the local-file format and the allowed `agency_type` values. [examples/austin-tx/](examples/austin-tx/) is a sample.

## Provenance is the point

Every fact submitted must trace back to a page someone can open and check.
Data without a source is opinion. Data with a source is evidence.

- **Values come from pages you fetched with `gather`, or from the user.** Nothing else.
- **`WebSearch` finds URLs; it is never a source of values.** Search snippets are not the page: a snippet can be stale, truncated or from another city. Find the URL, then `gather` it and read the value there.
- **Never use training data as a source.** Departments get reorganized, officials leave, numbers change. Training knowledge may guide research ("this city probably has a Parks department — let me look"), but the submitted value must come from the page you find. If you think you know something but can't find it, say so: "I think the police number is X, but I can't find it on their site — can you check?"
- **An empty field is better than an unsourced one.**

## Flow

Work through these steps conversationally, and stop only where the user decides:
after Step 2 (what to work on), at each Step 4 review, and at the next target.
Between those, keep going — don't ask permission to read.
At those three stops, offer the choices with `AskUserQuestion` (2-4 options, the recommended one first), so the user can answer with one keystroke; they can always type something else.

### Preflight: connection and sign-in

Check your tool list.

1. **No Jurisdictional tools at all** (`set_location` is missing): the MCP server isn't connected. Tell the user, then stop — the skill can't work without it:

   > The Jurisdictional server isn't connected. Install the plugin:
   >
   > ```
   > /plugin marketplace add jurisdictional/jurisdictional-skill
   > /plugin install jurisdictional@jurisdictional
   > ```
   >
   > Or add just the server: `claude mcp add --transport http jurisdictional https://jurisdictional.org/api/mcp/message`.
   > Then start a new session.

2. **`set_location` but no `propose_change`**: connected, not signed in. Exploring works; carry on, and note "not signed in" in one line under Step 2's table. Offer sign-in only when the user first chooses to contribute.

3. **`propose_change` present**: signed in; say nothing about it unless asked.
   If `reconcile_roster` is also present, the user is an admin; the admin paths in [tools.md](references/tools.md) are open.

Don't open with a status report: the user's first answer is Step 2's table.

**Signing in** (when the user first wants to contribute). Researching pages (`gather`) and every write need sign-in.
Never print, echo or `cat` the token, and don't ask the user to paste it into the chat.

1. Give them this command and ask them to paste it at the prompt **without pressing Enter yet**: copying the command uses the clipboard, so it must come before the token.
   It runs on their machine, so the token goes from the clipboard to a file without entering the conversation, and it saves only a `jur_...` key:

   ```
   ! mkdir -p ~/.jurisdictional && t=$(pbpaste | tr -d '[:space:]'); case "$t" in jur_*[!A-Za-z0-9_-]*) t= ;; jur_*) (umask 077; printf '%s\n' "$t" > ~/.jurisdictional/token) && chmod 600 ~/.jurisdictional/token && echo "Token saved." ;; *) t= ;; esac; [ -n "$t" ] || echo "Not saved: the clipboard holds no jurisdictional.org token (jur_...). Copy it from jurisdictional.org/auth/cli, then run this again."
   ```

   On Linux, `xclip -o -selection clipboard` replaces `pbpaste`.
2. Run `open https://jurisdictional.org/auth/cli`. They sign in with GitHub, copy the token shown, and press Enter on the command.
   "Not saved" means the clipboard held something else: copy the token again and rerun it (up-arrow).
3. On "Token saved.", ask them to run `/mcp` and reconnect `jurisdictional` (or start a new session), then check that `propose_change` now appears.

The plugin reads `~/.jurisdictional/token` each time it connects.
If the user added the server by hand with an `Authorization` header, that header is what counts: they update it there instead.

### Step 1: Where are you?

If the user provided arguments, use them: `$ARGUMENTS`

- **`next`** (`/gather next`, `/gather next CA`): skip the address. Pick a target as in [Choosing a next target](#choosing-a-next-target) (in the given state, or ask which), then go to Step 2 for it.
- **No arguments:** ask for an address or a city and state.

1. Call `set_location` with their address or city.
   If it finds nothing, fall back to `search_jurisdictions(query: "Vacaville", level: "municipal")`, pick the best match, and confirm it with the user.
   If the address looks wrong ("Ave" where the street is "St"), say so and suggest the fix rather than returning nothing.
2. The **juricode** is the stack of governments that serve the location: federal, state, congressional and state legislative districts, county and county district, city, school district.
   County subdivisions marked `kind: "non_governing"` are statistical areas, not governments: leave them out.
   Don't stop to present it; Step 2's table is the presentation.
3. Keep the `jurisdiction_ids`; they scope every later query.

### Step 2: Show what exists, layer by layer

Before asking anything, show how well each government at the address is covered.
Call `get_coverage` for every governing layer of the juricode, and `get_pending_tasks` for the city, **in parallel in one message**:

```
get_coverage(jurisdiction_id: 70118)     # Vacaville (place)
get_coverage(jurisdiction_id: 77297)     # Vacaville Unified School District
get_coverage(jurisdiction_id: 2532)      # Solano County
get_coverage(jurisdiction_id: 3274)      # California
get_pending_tasks(jurisdiction_id: 70118, limit: 5)
```

Include the district layers (congressional, state legislative, county district): their coverage is the seats they elect.
Skip the federal layer (national, not local) and `non_governing` subdivisions.
Keep any `task_id`; Step 6 closes them.

**Coverage is a ladder, and each rung says what to gather next:**

| `coverage_level` | Means | What moves it up |
|---|---|---|
| `none` | no agencies | the departments, and their services alongside — `import_jurisdiction` |
| `agencies` | agencies, no council or board | the governing body, its seats and who holds them |
| `governed` | agencies and a body, no services | services: what a resident can pay, apply for, report or reserve |
| `served` | all three | the tier and quality gaps below |

`tier` is the finer grade: `uncovered` → **Bronze** "Claimed" (a governing body) → **Silver** "Structured" (5+ agencies with websites) → **Gold** "Staffed" (that, plus seats with people in them).
Past Gold, `quality` names what's missing: agencies without phone, email or website.
A district's tier is about its seats instead: Gold when every seat it elects has a current holder.

**Show the stack as one table**, worst-covered first among the governments, with the single most useful gap for each (this shows the format; every number comes from `get_coverage`):

```
Your governments at 300 Hemlock St, Vacaville

  Government                          Coverage            Biggest gap
  California                          governed · Bronze   0 services; 30 agencies with no website or phone
  Solano County                       served · Gold       8 of 24 agencies lack email
  Vacaville Unified School District   served · Gold       15 of 17 agencies lack email
  Vacaville                           served · Gold       5 of 15 agencies lack a phone
  Assembly District 11                Uncovered           no seat linked to the district
  Supervisorial District 4            Gold                every seat it elects is held
```

**Districts** are covered by the seat they elect, linked to the district with `electing_jurisdiction_id` (see [tools.md](references/tools.md)).
A district with no linked seat is a quick contribution: find the seat on its body (the Assembly, the Board of Supervisors), then link it; `get_coverage` gives the exact call.
An admin can link a whole county board's or city council's district seats at once with `link_district_seats(parent_geoid)`, dry run first.
For "who represents me", call `explore(focus: "people", jurisdiction_ids: [<the district layers>])`.

Then recommend one gap, the lowest rung first, and say what it would change: "California has no services at all — adding the DMV and state tax services would take it from governed to served."
Ask with `AskUserQuestion`: the recommended gap, one or two others from the table, and "Just exploring".
If they asked a question, answer it first. If they only want to explore, stay here — drill in with `explore(focus: "agencies" | "bodies" | "people" | "services", jurisdiction_ids: [...])` and `get_body_details`. That is a complete session.
For "what's near me?", use the geocode from `set_location` with `find_services_near_point` or `find_agencies_near_point(lat, lng, radius_meters)`.

### Step 3: Research

**What to research follows the rung** from Step 2: departments and their services at `none`, the council and its seats at `agencies`, services at `governed`, contacts past Gold.
Don't ask how deep to go; gather what moves that rung, then offer the next one.

Fetch government pages with the `gather` tool (sign-in required):

```
gather(url: "https://www.cityofvacaville.gov/departments")
```

It renders the page in a real browser and returns the HTML.
Don't use `WebFetch` for government sites — they block it (403, 503).
Use `WebSearch` (`site:cityofvacaville.gov departments`) only to find which URL to `gather`.

**Check what came back before reading it.** Many government sites block automated fetches: an "Access Denied", "Request blocked" or captcha page arrives as ordinary HTML, not as an error. Treat it like an error.

**If `gather` fails, is blocked, or returns too much**, ask the user for the page, with the exact URL — never "the departments page":
- **Quick:** "Could you open https://www.cityofvacaville.gov/departments and paste the text?"
- **Better:** "Right-click the main content → Inspect → right-click the `<main>` element → Copy → Copy outerHTML, and paste it here."

This is a normal part of the workflow, not a failure.
A value from a pasted page is cited with that page's URL, and the `notes` say "pasted by the user from their browser".

**Within the rung, work top-down:** agencies before their services, a body before its seats, seats before the people in them, then meetings.
**Services run alongside agencies** — as you list each agency, ask what a resident can do with it. See [references/services.md](references/services.md).

At each layer look for names, types, URLs, descriptions, contact info and relationships.

- **Agencies:** set `agency_type` from what the agency does (police, parks_recreation, planning...), or leave it out when the page doesn't make it clear. Structural words like "department" are rejected. The list is in [schema.md](schema.md).
- **Officials:** read the roster page; note start dates and term ends only when published.
- **Photos, every time:** whenever a page you fetched shows officials (a roster, a bio, a board page), take each matched holder's headshot from the same HTML: the `<img>` whose alt, caption or file name carries the person's name, or the one nearest their name, never from the header, nav, footer or a slider.
  Take the largest size the page offers (`srcset`), keep the alt and caption verbatim, and note any photographer credit next to the image.
  Do this even when the roster itself is unchanged: `get_body_details` shows `image: null` for holders without a photo.
  City logos and flags on a page you fetched are noted the same way.
  All of them are submitted in Step 6.
- **Meetings:** the body's meetings page or agenda platform (Granicus, Legistar, eScribe, CivicPlus Agenda Center) gives dates and agenda, minutes and video links.
- **Existing values:** if a page confirms a value already in the dataset, that's worth submitting too — it corroborates it.

Corrections happen at the Step 4 review, so don't stop to ask for them here.
If the user brings their own material — local knowledge, a spreadsheet, a document — work from that; it's cited as "user-provided" or by the document's URL.
If you can't find something, leave it out and note it so someone else can fill the gap.

### Step 4: Review before submitting

Show exactly what will be written, and wait for approval.
Review **a layer at a time**: one table for all the new agencies, one for their services. For `import_jurisdiction`, the dry run's result is the table.
For changes to an existing entity, one table per entity:

```
Ready to submit for Vacaville Police Department (agency #1234):

  Field        Current    Proposed                      Source                        Lands
  ─────        ───────    ────────                      ──────                        ─────
  phone        (empty)    707-449-5200                  cityofvacaville.gov/police    review
  website_url  (empty)    cityofvacaville.gov/police    cityofvacaville.gov/police    review
  description  (empty)    Primary law enforcement...    cityofvacaville.gov/police    review
  email        police@…   police@… (same)               cityofvacaville.gov/contact   corroborates
```

Ask with `AskUserQuestion`: "Submit all 4", "Let me change some", "Skip this one".

The **Lands** column says what each write does, because they behave differently:
- **New entity** (`create_entity`, `import_jurisdiction`): live immediately, with no review. Be most careful here.
- **Change to an existing field** (`propose_change`): queued for human review.
- **Same value from a new source**: recorded as corroboration, no review.

**Every row has a source URL.**
A value from the user's own knowledge is marked "user-provided" — confirm they're comfortable with that attribution.
A value from your training knowledge has no place in the table: remove it and list it as unverified.

### Step 5: Submit

Read [references/tools.md](references/tools.md) for the fields and side effects of each tool before the first write.

**Always search before creating**, so you don't add a duplicate:

```
search_agencies(query: "Parks and Recreation", jurisdiction_ids: [<place_id>])
→ found: use its id → propose_change
→ not found: create_entity
```

The same goes for `search_bodies`, `search_services`, `search_positions` (by `body_id`) and `search_people` — the full name, then the last name alone if that finds nothing — then `get_person_details` to see their seats.

**Choose the write:**

| Situation | Tool |
|---|---|
| An empty or thin jurisdiction, many entities at once | `import_jurisdiction` — always `dry_run: true` first; show the result; then run it for real |
| One new entity | `create_entity` |
| A missing or wrong field on an existing entity | `propose_change`, once per field |
| A value already there, confirmed by another page | `propose_change` with the same value and the new `source_url` |
| Linking a seat to the district that elects it | `create_entity(entity_type: "position", body_id, electing_jurisdiction_id)`, or `propose_change(field_name: "electing_jurisdiction_id")` on an existing seat |
| Seating a person | `create_entity(entity_type: "person", position_id, source_url, start_date?, term_ends_on?)` |
| A whole roster changed (admin) | `reconcile_roster` — dry run first, show the plan, then apply |
| Someone left a seat (admin) | `end_tenure` with the page that shows it; otherwise note it for an admin |
| A meeting or agenda item | `create_entity(entity_type: "meeting", body_id, start_time, agenda_url, minutes_url, video_url)` |
| A headshot, logo or flag | `submit_portrait_candidate` / `submit_jurisdiction_image_candidate` (private review queue) |

**Create top-down.** Each `create_entity` returns an id you need for the next layer:

```
create_entity(entity_type: "body", name: "City Council", jurisdiction_id: 70118,
              entity_subtype: "council", source_url: "<council page>")              → body_id 200
create_entity(entity_type: "position", name: "Mayor", jurisdiction_id: 70118,
              body_id: 200, source_url: "<roster>")                                 → position_id 300
create_entity(entity_type: "person", first_name: "Jane", last_name: "Doe",
              jurisdiction_id: 70118, position_id: 300, source_url: "<roster>")     → person 400, tenure created
```

```
Jurisdiction (exists, from the juricode)
  ├── Body — council or board, belongs to the jurisdiction (agency optional)
  │     ├── Position → Tenure → Person
  │     └── Meeting → Agenda item
  └── Agency (agency_type = its function)
        ├── Service (online_url = the action link)
        ├── Body — a board inside a department
        └── Position (an agency role, without a body)
```

**`source_url` is the citation; live links are separate.** Pass the page you read as `source_url`, the agency's own page as `website_url`, and the service's action link as `online_url` — never the list page where you found them.
Both links are live with no review.

**Two modes.** The user can approve each layer, or say "fill in everything you can find" — then research and submit fully, and show every `change_id` and URL in the summary at the end.
Even then, run `import_jurisdiction` and `reconcile_roster` as dry runs first, and show the result before writing.

### Step 6: Verify and close the loop

**After each `create_entity` or `propose_change`, re-query the entity** (`get_agency_details`, `get_service_details`, `get_body_details`, `get_person_details`).
After `import_jurisdiction`, read the result's status per `ref` instead, and re-query only what looks wrong.
Detail responses list each field's sources and corroboration count, so the re-query shows whether your claim landed.
Check `online_url` on services and `website_url` on agencies specifically.
Use `get_change_status(change_ids: [...])` to see whether a proposal is pending, approved, published or rejected.

```
✓ Vacaville Police Department — 3 changes submitted

  phone:        (was empty) → 707-449-5200  pending review
  website_url:  (was empty) → cityofvacaville.gov/police  pending review
  email:        police@…  corroborated (2 sources)

  This entity:    https://jurisdictional.org/agencies/1234
  Your changes:   https://jurisdictional.org/users/contributions
  Jurisdiction:   https://jurisdictional.org/jurisdictions/70118
```

**Submit images** you noted in Step 3 with `submit_portrait_candidate` or `submit_jurisdiction_image_candidate`, one per matched holder; they appear publicly only after review.
If you are an admin, review them in the same session with `approve_image_candidate`, using the license rule in [tools.md](references/tools.md): the goal is photos showing, not a queue.
Re-query the body afterwards: each approved holder's `image` is no longer null.

**Close the sourcing tasks** from Step 2 with `submit_sourcing_result` — `status: "success"`, `"partial"` or `"failed"` with a `failure_reason`.
If you already submitted the values, pass `data: {}` so they aren't proposed twice.

**Re-check coverage** with `get_coverage` for the jurisdictions you worked on, and show the change in Step 2's terms: "Vacaville: governed · Bronze → served · Silver", or "still governed · Bronze: 0 services".

- **Zero services with agencies is a red flag, not a finished session.** Say so: "18 agencies but 0 services — I haven't captured what residents can actually do yet. Want me to work the 'How Do I' page and quick links?" Don't move on with a silent zero.
- **Report what you did NOT find, and why** — no published roster, no term dates, a page that blocked the fetcher. Gaps named are gaps someone else can fill; gaps hidden look like completeness. An admin can record a blocked site with `record_coverage_gap`.
- **Duplicates and departures** you couldn't fix (non-admin): list them for an admin.

**Session summary:**

```
Session complete — 12 writes across 4 entities:

  Entity                        Writes  Status
  ──────                        ──────  ──────
  Vacaville Police Department   3       2 pending review, 1 corroborated
  Parks & Recreation (new)      4       live
  City Council                  2       pending review
  Utility Bill Pay (new)        3       live

  Not found: council term end dates (not published); fire dept. email.
  Your contributions: https://jurisdictional.org/users/contributions
```

**Offer the next target**, nearest to the user first (see [Choosing a next target](#choosing-a-next-target)).
If they pick one, continue at Step 2 for it — no new preflight or location.

### Choosing a next target

In this order:

1. **Another government at this address** below `served` or below Gold, from Step 2's table. The user lives there, so the gap is theirs.
2. **The biggest places in the state that are partly covered:** `get_next_uncovered(state: "CA", level: "place", coverage: "governed", limit: 5)` (no services yet), then `coverage: "agencies"` (no council). Results come largest first: Los Angeles with no services matters more than a village with none.
3. **Places with nothing yet:** `coverage: "none"` (only places with a government; empty once a state has none left).

Offer two or three with `AskUserQuestion`, each with its rung and population ("San Diego — governed, 1.4M people, 0 services"), plus "Stop here".

## Guidelines

- **Provenance over completeness.** A record with a source URL can be trusted, challenged and updated; one without is a guess. Submit fewer fields rather than unsourced ones.
- **Start with their question, not your agenda.** If they want their school board, answer that first.
- **Show, then ask.** Present what exists before asking what's missing.
- **Gaps are opportunities, not failures.** "No one has added this yet — you could be the first."
- **Don't overwhelm.** Someone interested in water rates doesn't need every agency in the county.
- **Respect the scope.** Exploring without contributing is a complete experience.
- **Be specific about impact.** "Adding this meeting schedule means anyone in Vacaville can find when their council meets" beats "this data is useful."
- **Coverage is the scoreboard.** Name the rung and tier before and after, and what would move it up next.
- **Services are the payoff layer.** Agencies and officials are scaffolding; a jurisdiction with 18 agencies and 0 services is an org chart, not coverage.
- **New entities go live; edits get reviewed.** Take the most care with `create_entity` and `import_jurisdiction`.
- **Source hierarchy.** The government's own site (via `gather`) first; then other official sites (a state municipal league, the county); then news; then the user's local knowledge, attributed as "user-provided". Search snippets and training data are never sources.
- **Respect the user's knowledge.** If they say "that department was reorganized last year", believe them, and ask where it's published.
- **Be incremental.** Five verified agencies are worth more than thirty unverified ones.
- **Local files are optional.** If the user wants a local record, write JSON per [schema.md](schema.md). The submission is the API call, not the file.
