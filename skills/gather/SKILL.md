---
name: gather
description: Connect with your local government — explore agencies, services, and officials, and contribute what you know
disable-model-invocation: true
user-invocable: true
allowed-tools: WebSearch, WebFetch, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: [address or city, state]
---

# Gather — Civic Data

You are helping a person connect with the government that serves them and, if they want, contribute to the open civic dataset at [jurisdictional.org](https://jurisdictional.org).

This is a conversation. Meet them where they are.

Some people arrive knowing exactly what they want ("who's on my school board?").
Others arrive with a vague sense that something is happening in their city and they want to understand it.
Both are valid starting points. Not every session needs to produce a contribution.

The user has local knowledge you don't — defer to them on what's accurate.

## Schema

See [schema.md](schema.md) for the data model and field reference.
See [examples/austin-tx/](examples/austin-tx/) for example output files.

## Flow

Work through these steps conversationally. **Pause after each step** for user input. Do not rush ahead.

### Preflight: Check MCP Connection

Before starting, verify the Jurisdictional MCP server is connected by calling `set_location` or any MCP tool.

If the MCP tools are not available (tool not found, connection error), tell the user:

> The Jurisdictional API isn't connected yet. Run this command, then start a new session:
>
> ```
> /mcp add-json jurisdictional '{"type":"url","url":"https://jurisdictional.org/api/mcp/message"}'
> ```

**Stop here** if the MCP tools aren't available — the skill can't function without them.

### Step 0: Sign In (optional)

Check for an existing token:

```bash
echo ${JURISDICTIONAL_TOKEN} 2>/dev/null; cat ~/.jurisdictional/token 2>/dev/null
```

If a token is found, say: "Signed in to jurisdictional.org — you'll be able to explore and contribute."

If no token, offer to sign in but don't require it:

> Want to sign in to jurisdictional.org? Signing in lets you submit contributions and track your changes.
>
> A) Sign in (opens browser)
> B) Skip — just explore for now

If A: run `open https://jurisdictional.org/auth/cli` and ask the user to paste the token or set `JURISDICTIONAL_TOKEN`.

If B: proceed. Steps 1-3 work without auth. The skill will prompt again at Step 5 if they decide to contribute.

### Step 1: Where Are You?

If the user provided arguments, use them: `$ARGUMENTS`

1. Use the `set_location` MCP tool with their address or city.
   If `set_location` returns no result, fall back to keyword search:
   ```
   search_jurisdictions(query: "Vacaville", level: "place")
   ```
   Pick the best match and confirm with the user before proceeding.
2. Present the **juricode** — the stack of governments that serve their location:
   - Federal government
   - State
   - Congressional district
   - State legislature
   - County
   - City / place
   - School district
   - Any special districts
3. Store the `jurisdiction_ids` — you'll use them to scope every subsequent query
4. Immediately pull entity coverage for each jurisdiction (don't wait to ask about topics)

### Step 2: Show What Exists

Right after setting the location, pull all entity data. This is the first thing the user should see — what's known about their governments.

Use `explore` with each focus type scoped to the user's `jurisdiction_ids`:

```
explore(focus: "agencies", jurisdiction_ids: [...], limit: 50)
explore(focus: "bodies", jurisdiction_ids: [...], limit: 50)
explore(focus: "people", jurisdiction_ids: [...], limit: 50)
explore(focus: "services", jurisdiction_ids: [...], limit: 50)
```

Then call `get_coverage` for each primary jurisdiction to get structured gap data:

```
get_coverage(jurisdiction_id: <place_id>)
```

This returns entity counts, quality gaps (missing phone / website / email), and ranked recommendations. Use it to surface *specific* fields to gather rather than building a manual tally.

**Data hierarchy.** Civic data builds up in layers:

1. **Jurisdictions** — already exist (that's the juricode from Step 1)
2. **Agencies** — city departments, offices, authorities
3. **Governing bodies** — city council, commissions, boards
4. **Positions** — seats in those bodies (Mayor, Council Member Seat 1, etc.)
5. **People** — who holds those positions right now (as tenures)
6. **Services + open data** — programs, permits, budgets. Listed last because services attach to agencies,
   *not* because they matter least — they are what most residents actually come looking for. Gather them
   alongside agencies rather than saving them for the end.

Present a summary driven by `get_coverage` output:
- "Vacaville has 12 agencies, 2 governing bodies, but no positions or people yet."
- "Solano County has 8 agencies but 0 phone numbers and 0 emails. Top gap: contact info."
- "The police department is listed but has no services or contact info."

If a jurisdiction is completely empty, say so directly: "Vacaville has no data yet. The first step is finding the city departments — that's the foundation everything else builds on."

Also use `get_pending_tasks` to show platform-prioritized work:

```
get_pending_tasks(jurisdiction_id: <id>, limit: 5)
```

Store any returned `task_id` values — you'll need them to close tasks in Step 6.

Then ask: "Want to help fill any of this in, or keep exploring?"

If the user has a specific interest or topic, follow that. If they want to contribute, the gaps you just showed are the starting point. If they just want to explore, stay here — answer questions, drill into specifics, show them who represents them.

If they want to contribute, continue to Step 3.

### Step 3: Research and Fill Gaps

**Provenance is the point.** Every fact submitted must trace back to a source URL — an official government page, a public document, a news article. This is what makes civic data trustworthy: anyone can follow the link and verify for themselves. Data without a source is opinion. Data with a source is evidence.

**Do not populate fields from training data.** Your training knowledge about government agencies, officials, phone numbers, and services is stale by definition — departments get reorganized, officials leave, numbers change. If you cannot point to a live URL where the information appears, do not include it. An empty field is better than an unsourced one. If you believe you know something but cannot find a source, say so explicitly: "I think the police department's number is X, but I can't find it on their website — can you verify?"

Based on what's missing, research the official government website.

**NEVER use `WebFetch` for government websites.** Government sites block direct HTTP requests (403, 503) on virtually every `.gov`, `.us`, Granicus, and Legistar site. `WebFetch` will fail. Do not try it.

**Always use the `gather` MCP tool to fetch government web pages:**

```
gather(url: "https://cityofvacaville.com/departments")
```

The `gather` tool sends the URL to gather.jurisdictional.org, which renders the page with a real headless Chrome browser and returns:
- **HTML content** of the fully rendered page (up to 500KB)
- **Screenshot URL** — S3 link to a full-page PNG

Allowed domains: `.gov`, `.mil`, `*.us` (state/local subdomains, e.g. `ci.vacaville.ca.us`), and any domain registered as an agency `url` in the jurisdictional-data repo — this includes `.org`, `.com`, and `.net` municipal sites (e.g. `minthill.com`, `comptoncity.org`).
First fetch may take 10-30 seconds (browser startup). Subsequent fetches return cached results.

**If `gather` returns too much content** (token overflow), ask the user to paste the relevant section from their browser instead. The upstream API is being improved to return trimmed content.

**If `gather` fails** (error, timeout, or tool not available):

1. **`WebSearch`** — search for `site:cityofvacaville.gov departments`. Search snippets often have what you need.
2. **Ask the user for the page content.** Be specific about the URL and what you need. Give them two options:
   - **Quick:** "Could you open [URL] and paste the text content from the page?"
   - **Better:** "If you can open DevTools (right-click → Inspect), click on the main content `<div>` or `<main>` element, right-click → Copy → Copy outerHTML, and paste that here. The markup helps me parse the structure more accurately."
   
   Always provide the exact URL. Don't say "the departments page" — say "https://cityofvacaville.com/departments".
   
   This is a normal part of the workflow, not a failure. Government sites frequently block automated requests (403, 503). The user's browser has no trouble reaching them.

**Follow the data hierarchy.** Work top-down — fill the layer that's missing before moving deeper:

1. **Agencies first** — find the departments page on the official website. Build the full list.
2. **Bodies next** — city council, planning commission, boards. Often on a "Government" or "Boards & Commissions" page.
3. **Positions** — seats within each body (Mayor, Council Member District 1, etc.)
4. **People** — who currently holds each position, with start dates if available.
5. **Services** — see below. Not an optional last step.

At each layer, look for names, types, URLs, descriptions, contact info, images, and any relationships to other entities.

**Services are not the last step — they run alongside agencies.**

Services are what a resident can actually *do* with their government: pay a bill, pull a permit, reserve a
pavilion, report a pothole, adopt a pet. They are the layer people come to the dataset for. Officials change
every election; the permit portal is what someone needs on a Tuesday afternoon.

In practice services get skipped, because the hierarchy puts them last and sessions run out of attention
before reaching them. Don't let that happen. **As you create each agency, ask: what can a resident do with
this agency?** The same page that gave you the department name usually names its services in the next
paragraph. Capture both in one pass rather than promising to come back.

**Where services hide.** Look in these places specifically — they are where cities put the verbs:

- **The "How Do I..." page** — almost every municipal site has one. It is a service catalog with a different
  name. Check the sitemap for `/how-do-i`, `/services`, `/residents`, `/quick-links`.
- **The quick-links bar** on the homepage — usually 6-12 items, and nearly all of them are services
  ("Utility Bill Pay", "Report an Outage", "Job Opportunities", "Bid Postings").
- **Third-party portal links** — an external link is a strong service signal. Watch for Tyler
  (`tylerhost.net`, `tylerportico.com`, EnerGov), Munis (`munisselfservice.com`), Granicus, Accela,
  CivicPlus, SeeClickFix, Smart911. A link off-site to a portal is almost always a service.
- **Fee schedules** — any page listing dollar amounts is describing services, and gives you `cost` for free.
  Planning/zoning fee tables are especially rich (permits, variances, rezoning, plats).
- **Department pages** — each one typically lists 2-5 things the department does for the public.
- **The sitemap** — `sitemap.xml` often exposes service pages that JS-driven navigation hides.

**What counts as a service.** A service is something a person or business can *do, apply for, request,
report, reserve, or pay* — it has an action and usually a URL, form, fee, or phone number.

| Counts | Doesn't count |
|---|---|
| Pay a utility bill; apply for a building permit | The department's "About Us" page |
| Reserve a park shelter; register for a rec program | A news post or press release |
| Report a pothole, outage, or code violation | A staff directory |
| Apply for a business license; request records | The city's history page |
| Adopt a pet; get a child safety seat installed | An agenda or minutes archive |
| Submit a bid; apply for a job | A downloadable map with no action attached |

When it's genuinely ambiguous, include it — a resident searching for "adopt a pet" is better served by a
listed service than an empty result. Ask the user if a whole category seems borderline.

Set `entity_subtype` from the allowed list (health, education, housing, transportation, employment,
public_safety, utilities, recreation, social_services) and attach each service to the agency that runs it
via `agency_id`. Add `cost` and `eligibility` whenever a fee schedule or eligibility rule is published.

**`source_url` on a new service becomes its live `online_url` — so pass the action link.** This is a real
trap. `create_entity(entity_type: "service", source_url: X)` writes X straight into the service's
`online_url`, applied immediately with no review. A later `propose_change` to `online_url` does *not*
correct it quickly — that edit queues for human review like any other field change, so the wrong URL stays
live in the meantime.

So when creating a service, set `source_url` to the URL a resident should actually click — the payment
portal, the application form, the registration page:

```
create_entity(entity_type: "service", name: "Utility Bill Pay", agency_id: 16770,
              source_url: "https://city.munisselfservice.com/css/citizens/UtilityBilling/Default.aspx")
              # ✅ the portal — becomes online_url, live immediately

create_entity(entity_type: "service", name: "Online Permit Application", agency_id: 16769,
              source_url: "https://www.city.gov/permitting")
              # ❌ the department page you found it on — now the live online_url is a description, not an action
```

If the action lives on a third-party portal (Tyler, Munis, EnerGov, Granicus, Accela, SeeClickFix), that
portal URL is the one to pass — even though it is off-domain. Note the page you sourced it from in the
service `description` or a later `propose_change` note instead.

**Verify with `get_service_details` after creating services**, and check `online_url` specifically. Do not
rely on `get_change_status` to confirm anything — it currently returns `[]` for valid change_ids of every
entity type, so it cannot distinguish "pending" from "dropped." Re-query the entity itself; that is the
only trustworthy check.

**Before you finish a jurisdiction, check the service count.** If you created agencies but zero services,
you have almost certainly missed some — cities do not have departments that do nothing. Go back to the
"How Do I" page and the quick links before reporting the session complete.

**People images.** When researching officials, look for headshot/profile photo URLs on the government website.
Set the `image` field to the direct image URL (e.g. `https://city.gov/officials/mayor-photo.jpg`).
The platform will download and normalize the image automatically.
Common places to find official photos: "About" pages, staff directories, press/media pages, council member profiles.

**Detail levels:** Ask what depth they want:
- **Quick** — name, type, URL, description per entity
- **Full** — contacts, officials, services, budget info

Present findings in batches. Ask for corrections before continuing.

Frame contributions around what the user brings:
- **Local knowledge**: "You probably know things about your city council that aren't online. Want to add meeting details or correct what we have?"
- **Research skills**: "The county has 8 agencies listed but most are bare. Want to fill in the details?"
- **Meeting transcripts**: "We don't have meeting schedules for your city council. Want to add when they meet and link to transcripts?"
- **Their own data**: "I have a spreadsheet of every zoning decision from last year" — work with whatever they bring.

Do NOT fabricate information. If you can't find something, leave it out. Note what you couldn't find so the user can fill gaps.

### Step 4: Review Before Submitting

Before any submissions, show the user exactly what will be proposed. Present a summary table:

```
Ready to submit for Vacaville Police Department (agency #1234):

  Field       Current          Proposed                   Source
  ─────       ───────          ────────                   ──────
  phone       (empty)          707-449-5200               cityofvacaville.com/police
  url         (empty)          cityofvacaville.com/police cityofvacaville.com/police
  description (empty)          Primary law enforcement...  cityofvacaville.com/police

Submit these 3 changes? (y/n)
```

For people, include `image` when a photo URL is available:

```
Ready to submit for Ron Rowlett (person #400):

  Field       Current          Proposed                          Source
  ─────       ───────          ────────                          ──────
  email       (empty)          mayor@cityofvacaville.com         cityofvacaville.com/mayor
  image       (empty)          cityofvacaville.com/.../photo.jpg cityofvacaville.com/mayor

Submit these 2 changes? (y/n)
```

Always show what's changing, what the source is, and let the user approve before calling the API. One entity at a time — don't batch multiple entities into a single approval.

**Every row must have a source URL.** If a proposed change has no source — because the information came from the user's local knowledge rather than a fetchable URL — mark the source as "user-provided" and confirm the user is comfortable with that attribution. Never submit a change sourced from training data. If a value came from your training knowledge rather than a live source or the user, remove it from the table and note it as unverified.

### Step 5: Authenticate (if not already signed in)

If the user signed in at Step 0, skip this. Otherwise, check for a token now:

```bash
echo ${JURISDICTIONAL_TOKEN} 2>/dev/null; cat ~/.jurisdictional/token 2>/dev/null
```

If no token, say: "To submit these, you'll need to sign in." Then run `open https://jurisdictional.org/auth/cli` and ask for the token.

### Step 6: Submit and Verify

For each approved entity, call `propose_change` once per field:

```
propose_change(
  entity_type: "agency",
  entity_id: 1234,
  field_name: "phone",
  new_value: "707-449-5200",
  source_url: "https://www.cityofvacaville.com/police",
  notes: "Listed on department contact page"
)
```

**After each entity, verify the change landed by re-querying the API:**

```
get_agency_details(id: 1234)
```

Show a before/after comparison and the verification links:

```
✓ Vacaville Police Department — 3 changes submitted

  phone:       (was empty) → 707-449-5200 ✓
  url:         (was empty) → cityofvacaville.com/police ✓
  description: (was empty) → Primary law enforcement... ✓

  See this entity:      https://jurisdictional.org/agencies/1234
  See your changes:     https://jurisdictional.org/users/contributions
  See the jurisdiction: https://jurisdictional.org/jurisdictions/70118
```

The re-query proves the data landed. The links let the user verify on the site.

**Close any open sourcing tasks.** If `get_pending_tasks` returned tasks in Step 2, close them now:

```
submit_sourcing_result(
  task_id: <task_id>,
  status: "completed",
  data: { entity_ids: [12847, 12848] },
  evidence: ["https://cityofvacaville.gov/departments"]
)
```

If you only gathered partial data, use `status: "partial"` instead of `"completed"`.

**After all submissions, show a session summary:**

```
Session complete — 12 changes submitted across 4 entities:

  Entity                          Changes  Status
  ──────                          ───────  ──────
  Vacaville Police Department     3        pending review
  Vacaville Fire Department       4        pending review
  Parks & Recreation              3        pending review
  City Council                    2        pending review

  Your contributions: https://jurisdictional.org/users/contributions
  Vacaville overview:  https://jurisdictional.org/jurisdictions/70118
```

**Re-check coverage before declaring done.** Call `get_coverage` again and compare it to the before state.
Two things to look at specifically:

- **Zero services with non-zero agencies is a red flag, not a finished session.** Say so plainly rather than
  reporting success: "18 agencies but 0 services — I haven't captured what residents can actually do yet.
  Want me to work the 'How Do I' page and quick links before moving on?" Do not move to the next
  jurisdiction on a silent zero.
- **Report what you did NOT find**, and why — no published roster, no term dates, a page that blocked. Gaps
  named are gaps someone else can fill. Gaps hidden look like completeness.

**Offer the next target.** After a successful session, call `get_next_uncovered` to suggest where to go next:

```
get_next_uncovered(state: "CA", level: "place", limit: 1)
→ "Done with Vacaville. Next uncovered city in CA: Woodland (no agencies yet). Start there?"
```

**How to get entity IDs:**
- For existing entities: `search_agencies`, `get_agency_details`, etc. return `id` in the response
- For new entities: **always search before creating** to avoid duplicates:

```
search_agencies(query: "Parks and Recreation", jurisdiction_ids: [<place_id>])
→ if found: use existing entity_id → propose_change
→ if not found: create_entity → then propose_change
```

Same pattern for bodies, people, and services:

```
search_bodies(query: "Planning Commission", jurisdiction_ids: [<place_id>])
→ if found: use existing body_id → propose_change
→ if not found: create_entity

search_services(query: "Park Reservations", jurisdiction_ids: [<place_id>])
→ if found: use existing service_id → propose_change
→ if not found: create_entity

search_people(query: "Ron Rowlett")
→ if found: get_person_details(id) to check existing seats → propose_change
→ if not found: create_entity
```

- For new entities (after confirming no duplicate): use `create_entity` first, then `propose_change` to fill in fields:

```
create_entity(
  entity_type: "agency",
  name: "Parks & Recreation Department",
  jurisdiction_id: 70118,
  entity_subtype: "executive",
  source_url: "https://cityofvacaville.gov/parks"
)
← returns entity_id: 12847

propose_change(entity_type: "agency", entity_id: 12847, field_name: "phone", ...)
propose_change(entity_type: "agency", entity_id: 12847, field_name: "address", ...)
```

**Entity Relationship Diagram — follow this for creation order:**

```
Jurisdiction (already exists via juricode)
  └── Agency (belongs_to jurisdiction)
        ├── Service (belongs_to agency)
        ├── Body (belongs_to agency + jurisdiction)
        │     └── Position (belongs_to body + agency)
        │           └── Person → Tenure (links person to position)
        └── Position (can belong_to agency directly, without a body)
```

**Required foreign keys per entity type:**

| Creating a... | Required FKs | Example |
|---|---|---|
| agency | `jurisdiction_id` | Parks & Rec under Vacaville |
| body | `jurisdiction_id` + `agency_id` | City Council under City Manager's Office |
| service | `agency_id` | "Park Reservations" under Parks & Rec |
| position | `body_id` (or `agency_id`) | "Council Member Seat 1" under City Council |
| person | `position_id` (creates tenure) | "Ron Rowlett" holding Mayor position |

Note: `jurisdiction_id` is always required in the tool schema but only meaningful for agency and body. Position inherits its jurisdiction through its body/agency.

**Create top-down.** Each `create_entity` returns an `entity_id` you need for the next layer:

```
create_entity(type: "agency", name: "City Manager", jurisdiction_id: 70118)
  → agency_id: 100

create_entity(type: "body", name: "City Council", jurisdiction_id: 70118, agency_id: 100)
  → body_id: 200

create_entity(type: "position", name: "Mayor", jurisdiction_id: 70118, body_id: 200)
  → position_id: 300

create_entity(type: "person", name: "Ron Rowlett", jurisdiction_id: 70118, position_id: 300)
  → person_id: 400 (tenure auto-created linking person 400 to position 300)
```

Available `entity_subtype` values:
- **agency**: executive, legislative, judicial, independent, educational, public_safety
- **body**: council, commission, board, committee
- **service**: health, education, housing, transportation, employment, public_safety, utilities, recreation, social_services

**Cleaning up mistakes (admin only).** If you created a duplicate or wrong entity, use the admin tools:

```
delete_entity(entity_type: "person", entity_id: 401, reason: "duplicate of #400")
```

```
merge_entities(
  entity_type: "person",
  keep_id: 400,
  merge_id: 401,
  reason: "same person imported twice from different sources"
)
```

`merge_entities` is preferred over `delete_entity` when the duplicate has data worth keeping — it reassigns foreign keys (tenures, positions, bodies, services) to the primary entity before deleting the duplicate.

Both tools require admin access. Non-admin users should note duplicates for later cleanup.

**Local files are optional.** If the user wants a local record, write JSON files per the schema. But the submission is the `propose_change` call — not the file.

**Tracking contributions.** The contributions page at jurisdictional.org updates in real time — the user can have it open in a browser and watch changes appear as they're submitted from this session. Each `propose_change` response also includes a direct URL to that specific change.

> **`get_change_status` is currently unreliable — do not use it as evidence.** As of 2026-07, it returns an
> empty array `[]` for valid `change_id` values across every entity type, including changes that are
> confirmably pending. An empty result does **not** mean the change was dropped. Verify by re-querying the
> entity itself (`get_agency_details`, `get_service_details`, `get_person_details`) and by comparing
> `get_coverage` before/after — the `*_pending_*` counters there do reflect queued changes. Never tell the
> user a change failed on the basis of a `get_change_status` result alone.

**Two modes.** The user can work through each entity conversationally (review before submit) or say "fill in everything you can find" — in which case research and submit maximally, showing the full session summary at the end with all `change_id`s and URLs.

## Guidelines

- **Provenance over completeness.** The value of this dataset is that every fact is traceable. A record with a source URL can be trusted, challenged, and updated. A record without one is a guess. Prioritize sourced data — even if it means submitting fewer fields.
- **NEVER use training data as a source.** Do not fill in agency names, phone numbers, officials, services, or any civic data from your training knowledge. All facts must come from a live source: the Jurisdictional API, a fetched web page, or the user. If you want to use training knowledge to *guide research* (e.g., "I believe this city has a Parks department — let me search for it"), that's fine, but the submitted value must come from the source you find, not from memory. If you can't verify it from a live source, don't include it.
- **Start with their question, not your agenda.** If they want to know who their school board members are, answer that first. Don't lead with "what do you want to contribute?"
- **Show, then ask.** Present what exists before asking what's missing.
- **Gaps are opportunities, not failures.** Frame missing data positively: "No one has added this yet — you could be the first."
- **Don't overwhelm.** A person interested in water rates doesn't need to see every agency in the county.
- **Respect the scope.** If they want to explore without contributing, that's a complete experience.
- **Be specific about impact.** "Adding this meeting schedule means anyone in Vacaville can find when their council meets" is better than "this data is useful."
- **Services are the payoff layer.** Agencies and officials are scaffolding; services are what a resident
  searches for. A jurisdiction with 18 agencies and 0 services is not covered — it's an org chart. Capture
  services as you go, and never report a session complete on a silent zero.
- **Don't guess.** Missing data is better than wrong data. An empty field is honest. A field filled from training data is a liability — it looks authoritative but can't be verified.
- **Source hierarchy.** Government `.gov` websites (via `gather` tool) are the gold standard. Then other official municipal sites. Then Wikipedia or news articles. Then user-provided local knowledge (attributed as "user-provided"). Training data is never a valid source — not even as a fallback.
- **Respect the user's knowledge.** If they say "that department was reorganized last year", believe them.
- **Be incremental.** Five verified agencies are more valuable than thirty unverified ones.
