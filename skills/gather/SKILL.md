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

If B: proceed. Steps 1-4 work without auth. The skill will prompt again at Step 6 if they decide to contribute.

### Step 1: Where Are You?

If the user provided arguments, use them: `$ARGUMENTS`

1. Use the `set_location` MCP tool with their address or city
2. Present the **juricode** — the stack of governments that serve their location:
   - Federal government
   - State
   - Congressional district
   - State legislature
   - County
   - City / place
   - School district
   - Any special districts
3. Say: "These are the governments that make decisions about where you live. Which ones are you interested in?"
4. Store the `jurisdiction_ids` — you'll use them to scope every subsequent query

If the user has multiple addresses (home, work, property), they can set a different location anytime.

### Step 2: What Are You Interested In?

Understand what the user cares about. Present selections as lettered options so the user can respond with just letters.

**First question — governance layers.** Build this from the `set_location` response. Call `AskUserQuestion` with lettered options listing each jurisdiction returned, plus "All of them" at the end. The user picks one or more letters. Example format:

> Which governments are you interested in? Pick one or more letters.
>
> A) United States (federal)
> B) California (state)
> C) CA Congressional District 4
> D) CA Senate District 3
> E) Solano County
> F) City of Vacaville
> G) Vacaville Unified School District
> H) All of them

**Second question — civic topics.** Call `AskUserQuestion` again:

> What topics interest you? Pick one or more, or type your own.
>
> A) Elections & voting
> B) Budget & finance
> C) Planning & zoning
> D) Education
> E) Water & utilities
> F) Housing
> G) Public safety
> H) Transportation
> I) Environment
> J) Public health
> K) Economic development
> L) Civil rights
> M) Something else — I'll describe it

The user can pick multiple letters ("B, E, G"), or describe a specific situation ("I've been collecting city council meeting transcripts"). If they describe something specific, work with that directly — don't force them into a category.

### Step 3: Explore and Find Gaps

Use the MCP tools to show what jurisdictional.org already knows, and what's missing.

**Data hierarchy.** Civic data builds up in layers — you can't fill in people without positions, positions without bodies, bodies without agencies, agencies without jurisdictions. The order of work is:

1. **Jurisdictions** — already exist (that's the juricode from Step 1)
2. **Agencies** — city departments, offices, authorities
3. **Governing bodies** — city council, commissions, boards
4. **Positions** — seats in those bodies (Mayor, Council Member Seat 1, etc.)
5. **People** — who holds those positions right now (as tenures)
6. **Services + open data** — programs, permits, budgets

Use `explore` with each focus type scoped to the user's `jurisdiction_ids` to assess coverage at each layer:

```
explore(focus: "agencies", jurisdiction_ids: [...], limit: 50)
explore(focus: "bodies", jurisdiction_ids: [...], limit: 50)
explore(focus: "people", jurisdiction_ids: [...], limit: 50)
explore(focus: "services", jurisdiction_ids: [...], limit: 50)
```

Also use `get_pending_tasks` to show platform-prioritized work:

```
get_pending_tasks(jurisdiction_id: <id>, limit: 5)
```

Present a summary of coverage per layer:
- "Vacaville has 12 agencies, 2 governing bodies, but no positions or people yet."
- "The police department is listed but has no services or contact info."
- "The platform specifically needs help with: [pending tasks]"

If a jurisdiction is completely empty, say so directly and propose starting from the top: "Vacaville has no data yet. Want to start by finding the city departments? That's the foundation everything else builds on."

Then ask: "Want to help fill any of this in, or keep exploring?"

If the user just wants to explore, stay here. Answer their questions, drill into topics, show them who represents them. That's a complete experience.

If they want to contribute, continue to Step 4.

### Step 4: Research and Fill Gaps

Based on what's missing, use `WebSearch` and `WebFetch` to research the official government website.

**When `WebFetch` gets blocked** (403, Cloudflare, bot detection) — this is common with government sites. Don't retry the same URL. Instead:

1. **`WebSearch` first.** Search for `site:cityofvacaville.gov departments` — search snippets and cached content often have what you need without hitting the site directly.

2. **Wikipedia and other public sources.** Wikipedia often lists major departments, council structure, and key officials with citations.

3. **Ask the user for the page content.** Say: "That site is blocking me. Could you open [URL] in your browser and paste the page content here? Just the text is fine, or HTML if you have it." Most users already have their browser open. This is the fastest path — don't overthink it.

**Follow the data hierarchy.** Work top-down — fill the layer that's missing before moving deeper:

1. **Agencies first** — find the departments page on the official website. Build the full list.
2. **Bodies next** — city council, planning commission, boards. Often on a "Government" or "Boards & Commissions" page.
3. **Positions** — seats within each body (Mayor, Council Member District 1, etc.)
4. **People** — who currently holds each position, with start dates if available.
5. **Services + open data** — permits, programs, budgets, meeting schedules.

At each layer, look for names, types, URLs, descriptions, contact info, and any relationships to other entities.

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

### Step 5: Review Before Submitting

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

Always show what's changing, what the source is, and let the user approve before calling the API. One entity at a time — don't batch multiple entities into a single approval.

### Step 6: Authenticate (if not already signed in)

If the user signed in at Step 0, skip this. Otherwise, check for a token now:

```bash
echo ${JURISDICTIONAL_TOKEN} 2>/dev/null; cat ~/.jurisdictional/token 2>/dev/null
```

If no token, say: "To submit these, you'll need to sign in." Then run `open https://jurisdictional.org/auth/cli` and ask for the token.

### Step 7: Submit and Verify

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

**How to get entity IDs:**
- For existing entities: `search_agencies`, `get_agency_details`, etc. return `id` in the response
- For new entities: use `create_entity` first, then `propose_change` to fill in fields:

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

**Local files are optional.** If the user wants a local record, write JSON files per the schema. But the submission is the `propose_change` call — not the file.

**Tracking contributions.** Use `get_change_status` with the `change_id` values from `propose_change` to check status at any point in the session. Each response includes a direct URL to verify on the site. The contributions page at jurisdictional.org updates in real time — the user can have it open in a browser and watch changes appear as they're submitted from this session.

**Two modes.** The user can work through each entity conversationally (review before submit) or say "fill in everything you can find" — in which case research and submit maximally, showing the full session summary at the end with all `change_id`s and URLs.

## Guidelines

- **Start with their question, not your agenda.** If they want to know who their school board members are, answer that first. Don't lead with "what do you want to contribute?"
- **Show, then ask.** Present what exists before asking what's missing.
- **Gaps are opportunities, not failures.** Frame missing data positively: "No one has added this yet — you could be the first."
- **Don't overwhelm.** A person interested in water rates doesn't need to see every agency in the county.
- **Respect the scope.** If they want to explore without contributing, that's a complete experience.
- **Be specific about impact.** "Adding this meeting schedule means anyone in Vacaville can find when their council meets" is better than "this data is useful."
- **Don't guess.** Missing data is better than wrong data.
- **Prefer official sources.** Government `.gov` websites first, then Wikipedia, then news.
- **Respect the user's knowledge.** If they say "that department was reorganized last year", believe them.
- **Be incremental.** Five verified agencies are more valuable than thirty unverified ones.
