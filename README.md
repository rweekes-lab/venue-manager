# Venue Manager

A Lightning Web Component bundle for managing event venues in **any** Salesforce org. Users can search, create, edit, and delete venues from a single Lightning page, tab, or record page.

## What's included

| Layer | Component | Purpose |
|-------|-----------|---------|
| Data | `Venue__c` custom object (22 custom fields) | Stores venue records |
| Apex | `VenueController` | CRUD with sharing + FLS/CRUD enforcement |
| Apex | `VenueControllerTest` | Unit tests (100% of controller) |
| LWC | `venueManager` | Orchestrator: search, list, modal, toasts, Apex calls |
| LWC | `venueList` | Presentational venue cards, emits edit/delete |
| LWC | `venueForm` | Modal create/edit form |
| Access | `Venue_Manager_Access` permission set | CRUD + FLS + tab visibility |
| UI | `Venue__c` tab + `All Venues` list view | Standard navigation |

Only `venueManager` is exposed to App Builder — drop it on any App Page, Home Page, Record Page, or a custom Tab.

## Venue fields

- **Core:** Name, Street, City, State/Province, Postal Code, Country, Capacity, Contact Name/Email/Phone, Description, Active
- **Scheduling & pricing:** Opening Time, Closing Time, Booking Rate, Rate Unit (Per Hour/Day/Event)
- **Media & links:** Photo URL, Website/Map URL
- **Amenities & tags:** Parking, Catering, A/V, Wheelchair Accessible, Tags (comma-separated)

## Deploy

### To a scratch org
```bash
sf org create scratch -f config/project-scratch-def.json -a venue-scratch -d
sf project deploy start -o venue-scratch
sf org assign permset -n Venue_Manager_Access -o venue-scratch
sf org open -o venue-scratch
```

### To a sandbox / production org
```bash
sf org login web -a myOrg
sf project deploy start -o myOrg
sf org assign permset -n Venue_Manager_Access -o myOrg
```

Then in the target org: add the **Venue Manager** component to a Lightning App/Home/Record page in the Lightning App Builder, or navigate to the **Venues** tab.

## Run tests

**Apex:**
```bash
sf apex run test -o myOrg -l RunLocalTests -w 10 -c
```

**LWC (Jest):**
```bash
npm install
npm run test:unit
```

## Design notes

- **Runs in any org** — no dependencies on org-specific objects; everything ships in this package.
- **Security** — `VenueController` is `with sharing` and every read/write is filtered through `Security.stripInaccessible`, so field- and record-level security are respected. SOQL uses bind variables (no injection).
- **Separation of concerns** — `venueManager` owns state and server calls; `venueList` and `venueForm` are reusable presentational children that communicate via events.
- **Search** is debounced (300ms) and matches name, city, or tags.
