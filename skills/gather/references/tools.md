# Jurisdictional MCP tools — what each one does when contributing

Read 2026-10-23 from the live `tools/list` and the server code.
The tool list itself is the source of truth: if a schema here disagrees with the one Claude sees, the live schema wins.

## Who sees what

| Access | Tools |
|---|---|
| **Anyone** (no token; 19 tools) | `set_location`, `explore`, `search_*` (jurisdictions, agencies, services, people, bodies, positions), `get_*_details` (jurisdiction, agency, service, person, body), `find_*_at_point`/`_near_point`, `get_coverage`, `get_pending_tasks`, `get_next_uncovered` |
| **Signed in** | `gather`, `propose_change`, `create_entity`, `import_jurisdiction`, `import_civicplus_directory`, `get_change_status`, `submit_sourcing_result`, `submit_portrait_candidate`, `submit_jurisdiction_image_candidate`, `get_image_candidate` |
| **Admin** | `delete_entity`, `merge_entities`, `reconcile_roster`, `end_tenure`, `record_coverage_gap`, `list_data_sources`, `get_coverage_stats`, `get_integrity_report`, and other read-only reports |

If `propose_change` is not in your tool list, the user is not signed in.
If `reconcile_roster` is not in it, they are not an admin — use the non-admin path noted below.

## Reading

- `set_location(address | latitude+longitude)` → geocode and the juricode: every jurisdiction layer at the point.
  County subdivisions carry `kind`: `governing`, `non_governing` (a statistical area that governs nothing) or `unclassified`.
  Don't present a `non_governing` layer as a government, and don't gather for it.
- `search_jurisdictions(query, level)` — `level` is `federal`, `state`, `county` or `municipal`.
- `get_jurisdiction_details(id | ocd_id)` — also takes an Open Civic Data id.
- `get_coverage(jurisdiction_id)` → counts per layer, missing-contact counts, ranked recommendations.
- `get_pending_tasks(jurisdiction_id, task_type?)` — task types: discover_agencies, extract_agency_contacts, discover_bodies, extract_officials, extract_services, extract_meeting_schedule, verify_stale_data, resolve_url, extract_budget.
- `get_next_uncovered(state, level, coverage)` — `coverage`: `none` (no agencies, the default), `agencies` (agencies but no council or board), `governed` (agencies and a body but no services), `served`.
- `get_body_details(id, as_of?)` → the body's seats and current holders, with tenure ids.
  Check it before gathering a roster from a website.
- `get_*_details` return each field's sources and a corroboration count.

## Fetching pages: `gather(url)`

Signed in only.
Renders the page in a headless browser and returns its HTML.
Allowed: `.gov`, `.mil`, `.us`, `.org`, `.com`, and some civic-data and agenda-platform domains.
The first fetch of a site can take 10-30 seconds.

## Writing

### `propose_change` — fix or fill one field on an existing entity

```
propose_change(entity_type: "agency", entity_id: 1234, field_name: "phone",
               new_value: "707-449-5200", source_url: "https://www.cityofvacaville.gov/police",
               notes: "Listed on the department contact page")
```

- Creates a **pending** change for human review, and returns its `change_id` and a URL.
- `entity_type`: jurisdiction, agency, body, service, position, person.
- `field_name` must be a real field; a wrong name fails and lists the valid ones.
  Agency URL is `website_url`; service URL is `online_url`.
- **Corroboration:** proposing a field's *current* value with a new `source_url` is recorded as an applied, corroborating claim (status `corroborated`, no review).
  Corroboration counts independent sources by host, so a second site confirming a value is a real contribution.
- `agency_type` values are checked; see [schema.md](../schema.md).

### `create_entity` — one new entity

Always search first (`search_agencies`, `search_bodies`, `search_services`, `search_people`, `search_positions`).
Every field set on the new row is recorded as a claim citing `source_url`, and is **live immediately**, with no review.

| entity_type | Needs | Notes |
|---|---|---|
| agency | `jurisdiction_id` | `entity_subtype` = agency_type (function only, or omit). With the default source, `source_url` **becomes `website_url`** — pass the agency's own page, not a list of departments. |
| body | `jurisdiction_id` | Omit `agency_id` for a council or board: it belongs to the jurisdiction. `entity_subtype` = legislative_type (council, commission, board). `source_url` becomes the body's `source`. |
| service | `jurisdiction_id`, `agency_id` | `source_url` **becomes `online_url`** — see [services.md](services.md). `cost`, `eligibility`. |
| position | `jurisdiction_id`, `body_id` (or `agency_id`) | A position with the same label under the same body is returned, not duplicated. |
| person | `jurisdiction_id`; `position_id` to seat them | Use `first_name`/`last_name` exactly as published. With `position_id`, a tenure is created and **`source_url` is required** (the roster or bio page). `start_date` and `term_ends_on` only when the source publishes them. Re-creating a person who already holds the seat refreshes that tenure's source instead of adding a second one. |
| meeting | `jurisdiction_id`, `body_id`, `start_time` | `agenda_url`, `minutes_url`, `video_url`, `status` (scheduled, completed, cancelled, postponed), `external_id` (eScribe GUID, Granicus clip id). |
| agenda_item | `jurisdiction_id`, `meeting_id` | |

`source_key` names the source's registry entry, default `municipal_official_sites` (a government's own site).
When the page is not the government's own site — a state municipal league profile, a county directory — say so in `notes`, and ask an admin for the right key (`list_data_sources`).
Only the default key sets an agency's `website_url` from `source_url`.

### `import_jurisdiction` — a whole city in one call

For an empty or thin jurisdiction: agencies, their bodies and services, and jurisdiction-level bodies, in one transaction.

```
import_jurisdiction(jurisdiction_id: 70118, dry_run: true,
  bodies: [{ref: "council", name: "Vacaville City Council", legislative_type: "council",
            url: "...", source: "<roster page>"}],
  agencies: [{ref: "pd", name: "Vacaville Police Department", agency_type: "police",
              website_url: "...", phone: "...",
              services: [{ref: "pd-report", name: "File a Police Report", service_type: "public_safety",
                          online_url: "<the form>"}]}])
```

- Always run `dry_run: true` first and show the user the result.
- Retry-safe: an item whose name already exists in its scope comes back `existing`, not duplicated.
  Existing rows are left unchanged — use `propose_change` to fix them.
- All or nothing; unknown fields are rejected and every error is listed by path.
- Agency fields: name, description, agency_type, website_url, phone, email, address, bodies, services.
  Body: name, description, legislative_type, url, source, meeting_url, phone, email, address.
  Service: name, description, service_type, online_url, eligibility_requirements, cost, contact_info.
- It records no per-field source claims, unlike `create_entity`.
  Every value must still come from a page you fetched, and the Step 4 review table must name it.
- Positions and people are not part of it: seat officials afterwards with `create_entity` or `reconcile_roster`.

`import_civicplus_directory` is for admins working from the jurisdictional repo's import script; skip it in conversation.

### Rosters (admin): `reconcile_roster`, `end_tenure`

`reconcile_roster(body_id, source_url, as_of, members: [{position_id, first_name, last_name, start_date?, term_ends_on?}], vacant_position_ids?)` brings a body's seat holders in line with its published roster.
It defaults to `dry_run: true`: run it, show the user the plan per seat (confirm, fill, replace, vacate, unlisted), then run it with `dry_run: false`.
Seats missing from the roster are left alone, never ended implicitly.

`end_tenure(tenure_id, end_date, source_url)` records that someone left a seat; tenure ids come from `get_body_details`.

Not an admin: seat each person with `create_entity(entity_type: "person", position_id, source_url)`, and report departures in the session summary for an admin to record.

### Images: `submit_portrait_candidate`, `submit_jurisdiction_image_candidate`

Officials' photos and city logos and flags go into a private review queue, never straight onto a page.
Only submit an image you saw on a page you fetched with `gather` — never one from search results.

```
submit_portrait_candidate(person_id: 400, source_url: "<image file URL>",
  source_page_url: "<the page it appeared on>", discovered_at: "2026-10-23T18:04:05Z",
  alt_text: "<the img alt, verbatim>", caption: "<nearby caption, verbatim>")

submit_jurisdiction_image_candidate(jurisdiction_id: 70118, kind: "logo" | "flag", source_url, source_page_url, discovered_at)
```

`get_image_candidate(image_id)` shows its review status.

### Closing the loop

- `submit_sourcing_result(task_id, status: "success" | "partial" | "failed", data, evidence, failure_reason?)` closes a task from `get_pending_tasks`.
  Each `data` key is read as a field on the task's entity and proposed as a change (`{"phone": "707-449-5200"}`), so only put fields of that entity there.
  When you already submitted the values with `propose_change` or `create_entity`, pass `data: {}` so nothing is proposed twice.
  `evidence`: `{"source_url": "<page>"}`.
  `failed` needs a `failure_reason` ("no published roster", "site blocks the fetcher").
- `get_change_status(change_ids: [...])` → pending, approved, published or rejected for each; `not_found` for an unknown id.
- `record_coverage_gap(jurisdiction_id, reason, evidence_url, detail)` (admin) marks a jurisdiction as blocked so `get_next_uncovered` skips it.
  Reasons: cloudflare_challenge, no_website, dead_host, parked_domain, takeover, blocked_403, no_department_links, other.

### Cleanup (admin)

- `merge_entities(entity_type, keep_id, merge_id, reason)` — person, position, agency, body.
  Prefer it over deleting when the duplicate has data: it moves tenures, positions, bodies and services to the kept row.
- `delete_entity(entity_type, entity_id, reason)` — also deletes dependents such as tenures.

Not an admin: list duplicates in the session summary for an admin.
