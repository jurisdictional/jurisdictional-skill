---
name: gather
description: Explore the governments that serve an address on jurisdictional.org — agencies, councils, officials, services, meetings — and contribute sourced civic data to fill the gaps. Use when the user runs /gather with an address or a city and state.
disable-model-invocation: true
user-invocable: true
allowed-tools: WebSearch, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: [address or city, state]
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
- [references/services.md](references/services.md) — where services hide on city websites, what counts, and the `online_url` trap.
- [schema.md](schema.md) — the local-file format and the allowed `agency_type` values. [examples/austin-tx/](examples/austin-tx/) is a sample.

## Provenance is the point

Every fact submitted must trace back to a page someone can open and check.
Data without a source is opinion. Data with a source is evidence.

- **Values come from pages you fetched with `gather`, or from the user.** Nothing else.
- **`WebSearch` finds URLs; it is never a source of values.** Search snippets are not the page: a snippet can be stale, truncated or from another city. Find the URL, then `gather` it and read the value there.
- **Never use training data as a source.** Departments get reorganized, officials leave, numbers change. Training knowledge may guide research ("this city probably has a Parks department — let me look"), but the submitted value must come from the page you find. If you think you know something but can't find it, say so: "I think the police number is X, but I can't find it on their site — can you check?"
- **An empty field is better than an unsourced one.**

## Flow

Work through these steps conversationally. **Pause after each step** for user input. Do not rush ahead.

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

2. **`set_location` but no `propose_change`**: connected, not signed in. Exploring works. Say so, and offer sign-in now or later.

3. **`propose_change` present**: signed in. Say "Signed in to jurisdictional.org — you can explore and contribute."
   If `reconcile_roster` is also present, the user is an admin; the admin paths in [tools.md](references/tools.md) are open.

**Signing in.** Researching pages (`gather`) and every write need sign-in.
Never print, echo or `cat` the token, and don't ask the user to paste it into the chat.

1. Run `open https://jurisdictional.org/auth/cli`. The user signs in with GitHub and copies the token shown.
2. Ask them to run this themselves, so the token goes from the clipboard to a file without entering the conversation:

   ```
   ! mkdir -p ~/.jurisdictional && pbpaste > ~/.jurisdictional/token && chmod 600 ~/.jurisdictional/token
   ```

   On Linux, `xclip -o -selection clipboard` replaces `pbpaste`.
3. Ask them to run `/mcp` and reconnect `jurisdictional` (or start a new session), then check that `propose_change` now appears.

The plugin reads `~/.jurisdictional/token` each time it connects.
If the user added the server by hand with an `Authorization` header, that header is what counts: they update it there instead.

### Step 1: Where are you?

If the user provided arguments, use them: `$ARGUMENTS`

1. Call `set_location` with their address or city.
   If it finds nothing, fall back to `search_jurisdictions(query: "Vacaville", level: "municipal")`, pick the best match, and confirm it with the user.
   If the address looks wrong ("Ave" where the street is "St"), say so and suggest the fix rather than returning nothing.
2. Present the **juricode** — the stack of governments that serve the location: federal, state, congressional district, state legislative districts, county, city, school district, special districts.
   County subdivisions marked `kind: "non_governing"` are statistical areas, not governments: leave them out, or label them as such.
3. Keep the `jurisdiction_ids`; they scope every later query.

### Step 2: Show what exists

Before asking anything, show what's known.

```
explore(focus: "agencies", jurisdiction_ids: [...], limit: 50)
explore(focus: "bodies",   jurisdiction_ids: [...], limit: 50)
explore(focus: "people",   jurisdiction_ids: [...], limit: 50)
explore(focus: "services", jurisdiction_ids: [...], limit: 50)
get_coverage(jurisdiction_id: <place_id>)
get_pending_tasks(jurisdiction_id: <place_id>, limit: 5)
```

`get_coverage` gives counts per layer, missing contacts and ranked recommendations — use it to name *specific* gaps instead of a manual tally.
Keep any `task_id` from `get_pending_tasks`; Step 6 closes them.
For a council or board, `get_body_details(id)` shows its seats and who holds them.

Civic data builds up in layers:

1. **Jurisdictions** — already exist (the juricode)
2. **Agencies** — departments, offices, authorities
3. **Governing bodies** — city council, commissions, boards
4. **Positions** — seats in those bodies (Mayor, Council Member District 1)
5. **People** — who holds each seat now (as tenures)
6. **Services** — what residents can do: pay, apply, report, reserve. Listed last because services attach to agencies, *not* because they matter least — they are what most residents come looking for. Gather them alongside agencies.
7. **Meetings** — when bodies meet, with agenda, minutes and video links.

Summarize from the data:
- "Vacaville has 12 agencies and 1 governing body, but no seats or people yet."
- "Solano County has 8 agencies but no phone numbers or emails. Top gap: contact info."
- "The police department is listed but has no services."

If a jurisdiction is empty, say so directly: "Vacaville has no data yet. The first step is the city departments — everything else builds on them."

Then ask: "Want to help fill any of this in, or keep exploring?"

If they have a question, answer it first. If they only want to explore, stay here — drill in, show who represents them. That is a complete session.

### Step 3: Research

Ask what depth they want:
- **Quick** — name, type, URL, description per entity
- **Full** — contacts, officials, services, meetings

Fetch government pages with the `gather` tool (sign-in required):

```
gather(url: "https://www.cityofvacaville.gov/departments")
```

It renders the page in a real browser and returns the HTML.
Don't use `WebFetch` for government sites — they block it (403, 503).
Use `WebSearch` (`site:cityofvacaville.gov departments`) only to find which URL to `gather`.

**If `gather` fails or returns too much**, ask the user for the page, with the exact URL — never "the departments page":
- **Quick:** "Could you open https://www.cityofvacaville.gov/departments and paste the text?"
- **Better:** "Right-click the main content → Inspect → right-click the `<main>` element → Copy → Copy outerHTML, and paste it here."

This is a normal part of the workflow, not a failure.
A value from a pasted page is cited with that page's URL, and the `notes` say "pasted by the user from their browser".

**Work top-down**, filling the missing layer before going deeper: agencies, then bodies, positions, people, and meetings.
**Services run alongside agencies** — as you list each agency, ask what a resident can do with it. See [references/services.md](references/services.md).

At each layer look for names, types, URLs, descriptions, contact info and relationships.

- **Agencies:** set `agency_type` from what the agency does (police, parks_recreation, planning...), or leave it out when the page doesn't make it clear. Structural words like "department" are rejected. The list is in [schema.md](schema.md).
- **Officials:** read the roster page; note start dates and term ends only when published.
- **Photos and logos:** if a headshot, city logo or flag appears on a page you fetched, note the image URL and the page URL — they are submitted for review in Step 6.
- **Meetings:** the body's meetings page or agenda platform (Granicus, Legistar, eScribe, CivicPlus Agenda Center) gives dates and agenda, minutes and video links.
- **Existing values:** if a page confirms a value already in the dataset, that's worth submitting too — it corroborates it.

Present findings in batches. Ask for corrections before continuing.

Frame contributions around what the user brings:
- **Local knowledge:** "You probably know things about your council that aren't online — want to correct what we have?"
- **Research:** "The county has 8 agencies listed but most are bare. Want to fill in the details?"
- **Meetings:** "We don't have meeting dates for your council. Want to add them, with agenda and video links?"
- **Their own data:** "I have a spreadsheet of every zoning decision from last year" — work with whatever they bring.

If you can't find something, leave it out and note it so someone else can fill the gap.

### Step 4: Review before submitting

Show exactly what will be written, one entity at a time, and wait for approval:

```
Ready to submit for Vacaville Police Department (agency #1234):

  Field        Current    Proposed                      Source
  ─────        ───────    ────────                      ──────
  phone        (empty)    707-449-5200                  cityofvacaville.gov/police
  website_url  (empty)    cityofvacaville.gov/police    cityofvacaville.gov/police
  description  (empty)    Primary law enforcement...    cityofvacaville.gov/police
  email        police@…   police@… (corroborates)       cityofvacaville.gov/contact

Submit these 4? (y/n)
```

Say which kind of write each row is, because they behave differently:
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

The same goes for `search_bodies`, `search_services`, `search_positions` (by `body_id`) and `search_people` (then `get_person_details` to see their seats).

**Choose the write:**

| Situation | Tool |
|---|---|
| An empty or thin jurisdiction, many entities at once | `import_jurisdiction` — always `dry_run: true` first; show the result; then run it for real |
| One new entity | `create_entity` |
| A missing or wrong field on an existing entity | `propose_change`, once per field |
| A value already there, confirmed by another page | `propose_change` with the same value and the new `source_url` |
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
create_entity(entity_type: "person", first_name: "Ron", last_name: "Rowlett",
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

**`source_url` becomes a live field on new entities** — the agency's `website_url`, the service's `online_url`.
Pass the agency's own page and the service's action link, not the list page where you found them.

**Two modes.** The user can approve each entity, or say "fill in everything you can find" — then research and submit fully, and show every `change_id` and URL in the summary at the end.
Even then, run `import_jurisdiction` and `reconcile_roster` as dry runs first, and show the result before writing.

### Step 6: Verify and close the loop

**After each entity, re-query it** (`get_agency_details`, `get_service_details`, `get_body_details`, `get_person_details`).
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

**Submit images** you noted in Step 3 with `submit_portrait_candidate` or `submit_jurisdiction_image_candidate`; they appear publicly only after review.

**Close the sourcing tasks** from Step 2 with `submit_sourcing_result` — `status: "success"`, `"partial"` or `"failed"` with a `failure_reason`.
If you already submitted the values, pass `data: {}` so they aren't proposed twice.

**Re-check coverage** with `get_coverage` and compare it with Step 2.

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

**Offer the next target:**

```
get_next_uncovered(state: "CA", level: "place", limit: 1)
→ "Next uncovered city in CA: Woodland (no agencies yet). Start there?"
```

`coverage: "agencies"` finds places with departments but no council, and `"governed"` finds places with no services — good targets for a shorter session.

**Local files are optional.** If the user wants a local record, write JSON per [schema.md](schema.md). The submission is the API call, not the file.

## Guidelines

- **Provenance over completeness.** A record with a source URL can be trusted, challenged and updated; one without is a guess. Submit fewer fields rather than unsourced ones.
- **Start with their question, not your agenda.** If they want their school board, answer that first.
- **Show, then ask.** Present what exists before asking what's missing.
- **Gaps are opportunities, not failures.** "No one has added this yet — you could be the first."
- **Don't overwhelm.** Someone interested in water rates doesn't need every agency in the county.
- **Respect the scope.** Exploring without contributing is a complete experience.
- **Be specific about impact.** "Adding this meeting schedule means anyone in Vacaville can find when their council meets" beats "this data is useful."
- **Services are the payoff layer.** Agencies and officials are scaffolding; a jurisdiction with 18 agencies and 0 services is an org chart, not coverage.
- **New entities go live; edits get reviewed.** Take the most care with `create_entity` and `import_jurisdiction`.
- **Source hierarchy.** The government's own site (via `gather`) first; then other official sites (a state municipal league, the county); then news; then the user's local knowledge, attributed as "user-provided". Search snippets and training data are never sources.
- **Respect the user's knowledge.** If they say "that department was reorganized last year", believe them, and ask where it's published.
- **Be incremental.** Five verified agencies are worth more than thirty unverified ones.
