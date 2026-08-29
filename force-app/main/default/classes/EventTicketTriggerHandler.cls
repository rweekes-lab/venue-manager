/**
 * Handler for EventTicketTrigger. Keeps Venue_Event__c.Tickets_Sold__c in sync with the
 * live count of its Event_Ticket__c children, and blocks any insert/update/undelete that
 * would push that count above the parent Venue's Capacity__c.
 *
 * Runs without sharing: the ticket count for a Venue Event must be accurate and enforced
 * consistently regardless of the running user's record-level access to sibling tickets.
 */
public without sharing class EventTicketTriggerHandler {

    public static void handle(List<Event_Ticket__c> newList, List<Event_Ticket__c> oldList) {
        Set<Id> eventIds = new Set<Id>();
        collectEventIds(newList, eventIds);
        collectEventIds(oldList, eventIds);
        if (eventIds.isEmpty()) {
            return;
        }

        Map<Id, Integer> countByEvent = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Venue_Event__c vid, COUNT(Id) cnt
            FROM Event_Ticket__c
            WHERE Venue_Event__c IN :eventIds
            GROUP BY Venue_Event__c
        ]) {
            countByEvent.put((Id) ar.get('vid'), (Integer) ar.get('cnt'));
        }

        Map<Id, Venue_Event__c> eventsById = new Map<Id, Venue_Event__c>([
            SELECT Id, Venue__c, Venue__r.Capacity__c, Tickets_Sold__c
            FROM Venue_Event__c
            WHERE Id IN :eventIds
        ]);

        List<Venue_Event__c> toUpdate = new List<Venue_Event__c>();
        for (Id eventId : eventIds) {
            Venue_Event__c evt = eventsById.get(eventId);
            if (evt == null) {
                continue;
            }
            Integer count = countByEvent.containsKey(eventId) ? countByEvent.get(eventId) : 0;

            // Deletes only ever reduce the count, so capacity can't be exceeded by one.
            Boolean overCapacity = !Trigger.isDelete && evt.Venue__c != null && evt.Venue__r.Capacity__c != null
                    && count > evt.Venue__r.Capacity__c;
            if (overCapacity) {
                // Block here and skip the sync below - writing an over-capacity count to
                // Tickets_Sold__c would itself trip Venue_Event__c's own validation rule
                // and surface that generic message instead of this specific one.
                flagOverCapacity(newList, eventId, count, evt.Venue__r.Capacity__c.intValue());
                continue;
            }

            if (evt.Tickets_Sold__c != count) {
                evt.Tickets_Sold__c = count;
                toUpdate.add(evt);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private static void collectEventIds(List<Event_Ticket__c> tickets, Set<Id> eventIds) {
        if (tickets == null) {
            return;
        }
        for (Event_Ticket__c t : tickets) {
            if (t.Venue_Event__c != null) {
                eventIds.add(t.Venue_Event__c);
            }
        }
    }

    private static void flagOverCapacity(List<Event_Ticket__c> newList, Id eventId, Integer count, Integer capacity) {
        for (Event_Ticket__c t : newList) {
            if (t.Venue_Event__c == eventId) {
                t.addError('Cannot sell ' + count + ' tickets: exceeds venue capacity of ' + capacity + '.');
            }
        }
    }
}
