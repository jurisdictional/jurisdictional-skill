# Gathering services

Services are what a resident can actually *do* with their government: pay a bill, pull a permit, reserve a pavilion, report a pothole, adopt a pet.
They are the layer people come to the dataset for.
Officials change every election; the permit portal is what someone needs on a Tuesday afternoon.

In practice services get skipped, because the hierarchy puts them last and sessions run out of attention before reaching them.
**As you create each agency, ask: what can a resident do with this agency?**
The same page that gave you the department name usually names its services in the next paragraph.
Capture both in one pass rather than promising to come back.

## Where services hide

Look in these places specifically — they are where cities put the verbs:

- **The "How Do I..." page** — almost every municipal site has one.
  It is a service catalog with a different name.
  Check the sitemap for `/how-do-i`, `/services`, `/residents`, `/quick-links`.
- **The quick-links bar** on the homepage — usually 6-12 items, and nearly all of them are services ("Utility Bill Pay", "Report an Outage", "Job Opportunities", "Bid Postings").
- **Third-party portal links** — an external link is a strong service signal.
  Watch for Tyler (`tylerhost.net`, `tylerportico.com`, EnerGov), Munis (`munisselfservice.com`), Granicus, Accela, CivicPlus, SeeClickFix, Smart911.
  A link off-site to a portal is almost always a service.
- **Fee schedules** — any page listing dollar amounts is describing services, and gives you `cost` for free.
  Planning and zoning fee tables are especially rich (permits, variances, rezoning, plats).
- **Department pages** — each one typically lists 2-5 things the department does for the public.
- **The sitemap** — `sitemap.xml` often exposes service pages that JS-driven navigation hides.

## What counts as a service

A service is something a person or business can *do, apply for, request, report, reserve, or pay* — it has an action and usually a URL, form, fee, or phone number.

| Counts | Doesn't count |
|---|---|
| Pay a utility bill; apply for a building permit | The department's "About Us" page |
| Reserve a park shelter; register for a rec program | A news post or press release |
| Report a pothole, outage, or code violation | A staff directory |
| Apply for a business license; request records | The city's history page |
| Adopt a pet; get a child safety seat installed | An agenda or minutes archive |
| Submit a bid; apply for a job | A downloadable map with no action attached |

When it's genuinely ambiguous, include it — a resident searching for "adopt a pet" is better served by a listed service than an empty result.
Ask the user if a whole category seems borderline.

## Fields

- `entity_subtype` (the service's `service_type`): health, education, housing, transportation, employment, public_safety, utilities, recreation, social_services.
- `agency_id`: the agency that runs it. Required.
- `cost`: a plain number in dollars (`"50"`, `"12.50"`). Put tiered or conditional fees in `description`.
- `eligibility`: who may use it, as published.

## `source_url` becomes the live `online_url` — pass the action link

`create_entity(entity_type: "service", source_url: X)` writes X straight into the service's `online_url`, applied immediately with no review.
A later `propose_change` to `online_url` queues for review like any other field change, so a wrong URL stays live in the meantime.

So set `source_url` to the URL a resident should actually click — the payment portal, the application form, the registration page:

```
create_entity(entity_type: "service", name: "Utility Bill Pay", agency_id: 16770, jurisdiction_id: 70118,
              source_url: "https://city.munisselfservice.com/css/citizens/UtilityBilling/Default.aspx")
              # ✅ the portal — becomes online_url, live immediately

create_entity(entity_type: "service", name: "Online Permit Application", agency_id: 16769, jurisdiction_id: 70118,
              source_url: "https://www.city.gov/permitting")
              # ❌ the department page you found it on — now the live online_url is a description, not an action
```

If the action lives on a third-party portal, that portal URL is the one to pass — even though it is off-domain.
Name the page you found it on in `description`.

After creating services, call `get_service_details` and check `online_url` specifically.

## Before you finish a jurisdiction

Check the service count.
If you created agencies but zero services, you have almost certainly missed some — cities do not have departments that do nothing.
Go back to the "How Do I" page and the quick links before reporting the session complete.
