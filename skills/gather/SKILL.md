---
name: gather
description: Research and structure civic data about a city or jurisdiction — agencies, services, contacts — from public sources into a standard open data format
disable-model-invocation: true
user-invocable: true
allowed-tools: WebSearch, WebFetch, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: [city, state]
---

# Jurisdictional — Civic Data Contribution

You are helping a person document the government structure of their jurisdiction. Think of this like building a pull request for a civic dataset: research, structure, review, submit.

The user is your collaborator. They have local knowledge you don't — defer to them on what's accurate. Your job is to do the legwork of finding and structuring public information, then let them correct and complete it.

## Schema

See [schema.md](schema.md) for the full data model and field reference.

See [examples/austin-tx/](examples/austin-tx/) for a complete example in data-repo format (one file per entity).

## Phases

Work through these phases in order. **Pause after each phase** for user review before continuing. Do not rush ahead.

### Phase 1: Identify the Jurisdiction

If the user provided arguments, use them: `$ARGUMENTS`

1. Confirm the jurisdiction with the user: "I'll research **[City, State]** — is that right?"
2. Ask for their GitHub username (for `_meta.contributor` on all output files)
3. Search for the official government website
4. Search for the Wikipedia article
5. Look for a Census GEOID if possible
6. Note the official `.gov` domain (e.g. `austintexas.gov`) — this will become a domain file in Phase 4
7. Present what you found and ask the user to confirm or correct:
   - Official name
   - Government website and domain
   - Wikipedia URL
   - Level (municipal, county, state, etc.)
   - Any notes about governance structure (e.g. "council-manager", "strong mayor")

**Output:** A summary of the jurisdiction identity. Wait for user confirmation.

### Phase 2: Survey Agencies

1. From the official government website, find the list of departments/agencies. Look for:
   - "Departments" or "Agencies" page
   - Organizational chart
   - "Government" or "City Hall" directory
2. Compile a list of agencies with:
   - Name
   - Agency type (department, bureau, commission, board, authority, office, division)
   - Website URL
3. Also identify **governing bodies** — city council, county commission, board of supervisors, etc. These are tracked separately from agencies. For each body, note:
   - Name (e.g. "Austin City Council")
   - Type (council, commission, board)
   - Website URL
   - Number of members / districts if apparent
4. Present the agencies and bodies to the user in a table and ask:
   - "Are any of these wrong or outdated?"
   - "Are there agencies or bodies missing from this list?"
   - "Any of these that should be skipped (not relevant)?"

**Output:** A confirmed list of agencies and bodies to detail. Wait for user input.

### Phase 3: Detail Each Agency and Body

Before starting, ask the user what level of detail they want:

- **Quick** — Name, type, URL, and a one-line description for each agency. Best for initial contributions or large jurisdictions.
- **Full** — Everything: contacts, officials, services, budget info. Takes longer and works best for a focused set of agencies.

If the user chose "quick", gather just those fields for all agencies and move to Phase 4.

If the user chose "full" (or for a subset they want fully detailed):

1. Visit the agency's website
2. Look for:
   - Description / mission statement
   - Contact info (phone, email, address)
   - Head official (name and title)
   - Budget information
   - Employee count
   - Key services offered
3. For each service found, capture:
   - Name and type
   - Description
   - Online URL
   - Cost
   - Processing time
   - Eligibility and requirements

Work through agencies in batches of 3-5. After each batch, show the user what you found and ask for corrections before continuing.

Do NOT fabricate information. If you can't find something, leave the field out. Note what you couldn't find so the user can fill gaps.

### Phase 4: Structure and Write

Write **one file per entity** in the data repo format (see schema.md for both the bundle format and the flat-file format).

1. Write individual JSON files to the current directory:
   - `jurisdictions/{level}/{slug}.json` — the jurisdiction (level is `federal`, `states`, `counties`, or `places`)
   - `agencies/{slug}.json` — one file per agency
   - `services/{slug}.json` — one file per service
   - `people/{slug}.json` — one file per person (if officials were found)
   - `positions/{slug}.json` — one file per position
   - `bodies/{slug}.json` — one file per legislative/governing body (if found)
   - `domains/{slug}.json` — one file per `.gov` domain found (jurisdiction's official domain at minimum)
2. Each file must include a `_meta` block with source URL, retrieved_at date, and contributor
3. Use cross-reference slugs (not IDs) for relationships:
   - Agency → `"jurisdiction": "austin-tx"`
   - Service → `"agency": "austin-police-department"`
   - Position → `"agency": "...", "person": "..."`
4. Use data-repo field names (see schema.md field mapping table)
5. Validate the output:
   - Check that every cross-reference slug points to a file that exists (e.g., if a service references `"agency": "austin-police-department"`, verify `agencies/austin-police-department.json` was written)
   - Check that every file has a valid `_meta` block with `source` and `retrieved_at`
   - If `~/workspace/jurisdictional-data` exists and has JSON schemas, run: `mix data.import --file={file} --dry-run` to validate against the schema
   - Report any validation errors to the user
6. Show the user a summary:
   - Number of files written per entity type
   - List of cross-reference slugs used
   - Any fields that are incomplete or missing
   - Validation results (pass/fail)
7. Ask: "Want to review the files, or is there anything to add or fix?"

### Phase 5: Submit to Data Repo (Optional)

Ask: "Want to submit these files to the jurisdictional-data repo, or keep them local for now?"

If the user wants to submit:

1. Check if `~/workspace/jurisdictional-data` exists. If not, offer to clone it:
   ```
   gh repo fork jurisdictional/jurisdictional-data --clone \
     --clone-dir ~/workspace/jurisdictional-data
   ```
2. Copy entity files into the data repo:
   ```
   cp -r jurisdictions/ agencies/ services/ bodies/ people/ positions/ domains/ \
     ~/workspace/jurisdictional-data/
   ```
3. Create a branch and open a PR:
   ```
   cd ~/workspace/jurisdictional-data
   git checkout -b add-{jurisdiction-slug}
   git add .
   git commit -m "Add {jurisdiction name} civic data"
   gh pr create --title "Add {jurisdiction name}" \
     --body "Contributed via jurisdictional/gather skill"
   ```

If the user has the Elixir tooling available, they can alternatively use:
```
mix data.commit agencies/{slug}.json --entity-type=agencies \
  --branch=add-{jurisdiction-slug} --pr
```

## Guidelines

- **Cite everything.** Every fact should trace to a source URL. In data-repo format, each file has a single `_meta.source` — use the primary source URL for that entity. If multiple sources informed the data, note additional URLs in a `_meta.notes` field.
- **Don't guess.** If you can't find a phone number, leave it out. Missing data is better than wrong data.
- **Prefer official sources.** Government `.gov` websites first, then Wikipedia, then news/other.
- **Respect the user's knowledge.** If they say "that department was reorganized last year", believe them and adjust.
- **Keep it conversational.** This is a collaboration, not a form to fill out.
- **Be incremental.** Small, verified contributions are more valuable than comprehensive but unverified ones. It's fine to submit a jurisdiction with just 5 agencies and no services — that's still useful.
