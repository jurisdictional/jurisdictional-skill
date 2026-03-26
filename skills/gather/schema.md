# Jurisdictional Data Schema

There are two contribution formats: the **data repo format** (preferred) and the legacy **bundle format**.

## Data Repo Format (Preferred)

One entity per file, with a `_meta` provenance block.
Cross-references use filename slugs (not database IDs).
Files are validated against JSON Schemas in `schemas/` of the data repo.

### Jurisdiction File

`jurisdictions/states/california.json`:

```json
{
  "_meta": {
    "source": "https://www.ca.gov",
    "retrieved_at": "2026-03-01",
    "contributor": "your-github-username"
  },
  "name": "California",
  "level": "state",
  "geoid": "06",
  "state_abbr": "CA",
  "parent": "united-states",
  "wikipedia_url": "https://en.wikipedia.org/wiki/California"
}
```

### Agency File

`agencies/austin-police-department.json`:

```json
{
  "_meta": {
    "source": "https://www.austintexas.gov/police",
    "retrieved_at": "2026-03-01",
    "contributor": "your-github-username"
  },
  "name": "Austin Police Department",
  "agency_type": "department",
  "jurisdiction": "austin-tx",
  "url": "https://www.austintexas.gov/police",
  "description": "Primary law enforcement agency for the City of Austin",
  "phone": "512-974-5000",
  "email": "police@austintexas.gov",
  "city": "Austin",
  "state": "TX",
  "zip": "78701"
}
```

### Service File

`services/file-a-police-report.json`:

```json
{
  "_meta": {
    "source": "https://www.austintexas.gov/police/report",
    "retrieved_at": "2026-03-01",
    "contributor": "your-github-username"
  },
  "name": "File a Police Report",
  "agency": "austin-police-department",
  "url": "https://www.austintexas.gov/police/report",
  "category": "application",
  "eligibility": "Must be a victim or witness of a non-emergency crime",
  "cost": "0",
  "description": "File a non-emergency police report online or in person"
}
```

### Person File

`people/robin-henderson.json`:

```json
{
  "_meta": {
    "source": "https://www.austintexas.gov/police/chief",
    "retrieved_at": "2026-03-01",
    "contributor": "your-github-username"
  },
  "first_name": "Robin",
  "last_name": "Henderson",
  "email": "chief@austintexas.gov"
}
```

### Position File

`positions/austin-police-chief.json`:

```json
{
  "_meta": {
    "source": "https://www.austintexas.gov/police/chief",
    "retrieved_at": "2026-03-01",
    "contributor": "your-github-username"
  },
  "label": "Chief of Police",
  "role": "executive",
  "person": "robin-henderson",
  "agency": "austin-police-department",
  "start_date": "2023-06-01"
}
```

### Domain File

`domains/austintexas-gov.json`:

```json
{
  "_meta": {
    "source": "https://raw.githubusercontent.com/cisagov/dotgov-data/main/current-full.csv",
    "retrieved_at": "2026-03-01",
    "contributor": "your-github-username"
  },
  "domain": "austintexas.gov",
  "jurisdiction": "austin-tx"
}
```

## Field Mapping: Data Repo → App Schema

Some data repo fields differ from the app's database schema.
The importer handles translation automatically.

| Entity  | Data Repo Field | App Schema Field            |
|---------|----------------|-----------------------------|
| Agency  | `url`          | `website_url`               |
| Agency  | `city`+`state`+`zip` | `address` (concatenated) |
| Service | `url`          | `online_url`                |
| Service | `category`     | `service_type`              |
| Service | `eligibility`  | `eligibility_requirements`  |
| Domain  | `domain`       | `domain_name`               |

## Cross-Reference Slugs

Entities reference each other by filename slug (without `.json`):

- Agency `"jurisdiction": "austin-tx"` → resolves to jurisdiction with slug `austin-tx`
- Service `"agency": "austin-police-department"` → resolves to agency with that slug
- Position `"person": "robin-henderson"` → resolves to person with that slug
- Position `"agency": "..."`, `"body": "..."` → resolves to agency/body
- Domain `"agency": "..."`, `"jurisdiction": "..."` → resolves to agency/jurisdiction
- Jurisdiction `"parent": "texas"` → resolves to parent jurisdiction

## `_meta` Block (Required)

Every file must include a `_meta` block:

| Field        | Required | Description                              |
|-------------|----------|------------------------------------------|
| source      | yes      | Primary URL of the data source           |
| retrieved_at| yes      | Date the data was retrieved (YYYY-MM-DD) |
| contributor | no       | GitHub username or script path           |
| notes       | no       | Additional source URLs or context        |

## File Naming Convention

- Lowercase, hyphen-separated: `austin-police-department.json`
- Include state abbreviation for sub-state entities: `springfield-il.json`
- Domains: replace dots with hyphens: `austintexas-gov.json`

## Directory Structure

```
jurisdictions/
  federal/united-states.json
  states/california.json
  counties/los-angeles-county-ca.json
  places/austin-tx.json
agencies/austin-police-department.json
services/file-a-police-report.json
bodies/austin-city-council.json
people/robin-henderson.json
positions/austin-police-chief.json
domains/austintexas-gov.json
```

