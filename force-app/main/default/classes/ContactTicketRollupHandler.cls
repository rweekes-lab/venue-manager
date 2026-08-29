/**
 * Keeps Contact.Tickets_Purchased__c in sync with the live count of its
 * Event_Ticket__c children linked via Contact__c.
 *
 * Runs without sharing: the ticket count for a Contact must be accurate
 * regardless of the running user's record-level access to sibling tickets.
 */
public without sharing class ContactTicketRollupHandler {

    public static void handle(List<Event_Ticket__c> newList, List<Event_Ticket__c> oldList) {
        Set<Id> contactIds = new Set<Id>();
        collectContactIds(newList, contactIds);
        collectContactIds(oldList, contactIds);
        if (contactIds.isEmpty()) {
            return;
        }

        // Lock the parent rows before counting children so concurrent trigger
        // transactions (e.g. parallel Bulk API batches) touching the same
        // Contact serialize instead of racing on stale COUNT() snapshots.
        List<Contact> contacts = [
            SELECT Id, Tickets_Purchased__c
            FROM Contact
            WHERE Id IN :contactIds
            FOR UPDATE
        ];

        Map<Id, Integer> countByContact = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Contact__c cid, COUNT(Id) cnt
            FROM Event_Ticket__c
            WHERE Contact__c IN :contactIds
            GROUP BY Contact__c
        ]) {
            countByContact.put((Id) ar.get('cid'), (Integer) ar.get('cnt'));
        }

        List<Contact> toUpdate = new List<Contact>();
        for (Contact c : contacts) {
            Integer count = countByContact.containsKey(c.Id) ? countByContact.get(c.Id) : 0;
            if (c.Tickets_Purchased__c != count) {
                c.Tickets_Purchased__c = count;
                toUpdate.add(c);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private static void collectContactIds(List<Event_Ticket__c> tickets, Set<Id> contactIds) {
        if (tickets == null) {
            return;
        }
        for (Event_Ticket__c t : tickets) {
            if (t.Contact__c != null) {
                contactIds.add(t.Contact__c);
            }
        }
    }
}
