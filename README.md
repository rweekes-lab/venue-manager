# Venue Manager

A Salesforce app for managing event venues, their events, and ticket sales in **any** Salesforce org. Users can search, create, edit, and delete venues from a Lightning Web Component, then track events and ticket sales against them with automatic capacity enforcement.

This repo ships **metadata only** — objects, fields, code, layouts, the permission set, and UI. No Venue, Venue Event, Event Ticket, or Contact records are included or created by a deploy; whoever installs it starts with an empty app on top of their org's existing Contacts.

## What's included

| Layer | Component | Purpose |
|-------|-----------|---------|
| Data | `Venue__c` custom object (22 custom fields) | Stores venue records |
| Data | `Venue_Event__c` custom object | An event at a venue; rolls up `Tickets_Sold__c` |
| Data | `Event_Ticket__c` custom object | A ticket, linked to a `Venue_Event__c` and a `Contact__c` |
| Data | `Contact.Tickets_Purchased__c` (custom field) | Rollup of tickets purchased, added to the standard Contact object |
| Apex | `VenueController` (+ test) | CRUD with sharing + FLS/CRUD enforcement |
| Apex | `EventTicketTriggerHandler` (+ test) | Enforces venue capacity, keeps `Tickets_Sold__c` in sync |
| Apex | `ContactTicketRollupHandler` (+ test) | Keeps `Contact.Tickets_Purchased__c` in sync |
| LWC | `venueManager` | Orchestrator: search, list, modal, toasts, Apex calls |
| LWC | `venueList` | Presentational venue cards, emits edit/delete |
| LWC | `venueForm` | Modal create/edit form |
| Access | `Venue_Manager_Access` permission set | CRUD + FLS + tab visibility across all of the above |
| UI | `Venue_Manager` app, `Venue__c`/`Venue_Manager_Home` tabs, Venue/Venue Event/Event Ticket record pages and layouts | Standard navigation |

Only `venueManager` is exposed to App Builder — drop it on any App Page, Home Page, Record Page, or a custom Tab.

**Not included by design:** a page layout for the standard Contact object. This org's own Contact layout is entangled with quick actions and fields from unrelated managed packages, so it isn't portable. If you want the Event Tickets related list on Contact, add it to your org's Contact layout after installing (Setup → Object Manager → Contact → Page Layouts → add the `Event_Ticket__c.Contact__c` related list).

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
