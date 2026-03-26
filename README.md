# jurisdictional-skill

A [Claude Code plugin](https://docs.anthropic.com/en/docs/claude-code) for crowdsourcing civic data about U.S. government structure.

The `gather` skill guides you through researching and structuring civic data — jurisdictions, agencies, services, officials — from public sources into a standard open data format.
The schema is based on the [jurisdictional.org](https://jurisdictional.org) data model.

## How it works

```mermaid
flowchart TD
    subgraph inputs["Inputs"]
        user["User: city name + local knowledge"]
        gov["Government .gov websites"]
        wiki["Wikipedia"]
        census["Census GEOID data"]
    end

    subgraph phases["Phases"]
        p1["Phase 1: Identify\nConfirm jurisdiction, contributor,\nofficial website, domain, GEOID"]
        p2["Phase 2: Survey\nList agencies + governing bodies\nfrom official website"]
        p3["Phase 3: Detail\nQuick or Full depth per agency:\ncontacts, officials, services"]
        p4["Phase 4: Structure\nWrite one JSON file per entity,\nvalidate cross-references"]
        p5["Phase 5: Submit\nFork data repo, open PR\n(optional)"]
    end

    subgraph outputs["Outputs — one file per entity"]
        j["jurisdictions/places/austin-tx.json"]
        a["agencies/austin-police-department.json"]
        s["services/file-a-police-report.json"]
        b["bodies/austin-city-council.json"]
        p["people/robin-henderson.json"]
        pos["positions/austin-police-chief.json"]
        d["domains/austintexas-gov.json"]
    end

    user --> p1
    gov --> p1
    gov --> p2
    gov --> p3
    wiki --> p1
    census --> p1
    p1 -->|"user confirms"| p2
    p2 -->|"user confirms"| p3
    p3 -->|"user confirms"| p4
    p4 -->|"user confirms"| p5
    p4 --> j & a & s & b & p & pos & d
    p5 -->|PR| repo["jurisdictional/jurisdictional-data"]
```

Each phase pauses for user review before continuing.
The user's local knowledge fills gaps and corrects what web research gets wrong.

## Install

Clone the repo into your Claude Code plugins directory:

```bash
git clone https://github.com/jurisdictional/gather-skill.git ~/.claude/plugins/gather-skill
```

Then run `/reload-plugins` in Claude Code.

## Usage

```
/gather Austin, TX
```

The skill will:

1. **Identify** the jurisdiction — confirm name, website, governance type, GEOID, `.gov` domain
2. **Survey** agencies and governing bodies from the official government website
3. **Detail** each agency — quick (name/type/url/description) or full (contacts, officials, services, budget)
4. **Structure** data into individual JSON files with `_meta` provenance and cross-reference validation
5. **Submit** to [jurisdictional-data](https://github.com/jurisdictional/jurisdictional-data) via PR (optional)

## Data format

One JSON file per entity, cross-referenced by filename slug:

```
jurisdictions/places/austin-tx.json
agencies/austin-police-department.json
services/file-a-police-report.json
bodies/austin-city-council.json
people/robin-henderson.json
positions/austin-police-chief.json
domains/austintexas-gov.json
```

Every file includes a `_meta` block with source URL, retrieval date, and contributor.

See [schema.md](skills/gather/schema.md) for the full specification and [examples/austin-tx/](skills/gather/examples/austin-tx/) for a complete sample.

## Contributing

The best way to contribute is to run the skill for your city and submit the resulting data.

Contributions to the skill itself are also welcome — see [SKILL.md](skills/gather/SKILL.md) for the prompt and phase definitions.
