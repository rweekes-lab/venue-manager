@isTest
private class ContactTicketRollupHandlerTest {

    private static Contact makeContact(String firstName, String lastName) {
        Contact c = new Contact(FirstName = firstName, LastName = lastName);
        insert c;
        return c;
    }

    private static List<Event_Ticket__c> makeTickets(Id contactId, Integer howMany) {
        List<Event_Ticket__c> tickets = new List<Event_Ticket__c>();
        for (Integer i = 0; i < howMany; i++) {
            tickets.add(new Event_Ticket__c(Contact__c = contactId));
        }
        return tickets;
    }

    @isTest
    static void insertTickets_syncsCount() {
        Contact c = makeContact('Ada', 'Lovelace');

        Test.startTest();
        insert makeTickets(c.Id, 3);
        Test.stopTest();

        Contact refreshed = [SELECT Tickets_Purchased__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(3, refreshed.Tickets_Purchased__c);
    }

    @isTest
    static void bulkInsertAcrossContacts_countsSyncIndependently() {
        Contact a = makeContact('Grace', 'Hopper');
        Contact b = makeContact('Alan', 'Turing');

        List<Event_Ticket__c> tickets = new List<Event_Ticket__c>();
        tickets.addAll(makeTickets(a.Id, 5));
        tickets.addAll(makeTickets(b.Id, 2));

        Test.startTest();
        insert tickets;
        Test.stopTest();

        Map<Id, Contact> refreshed = new Map<Id, Contact>(
            [SELECT Tickets_Purchased__c FROM Contact WHERE Id IN :new List<Id>{ a.Id, b.Id }]
        );
        System.assertEquals(5, refreshed.get(a.Id).Tickets_Purchased__c);
        System.assertEquals(2, refreshed.get(b.Id).Tickets_Purchased__c);
    }

    @isTest
    static void deleteTicket_decrementsCount() {
        Contact c = makeContact('Katherine', 'Johnson');
        List<Event_Ticket__c> tickets = makeTickets(c.Id, 3);
        insert tickets;

        Test.startTest();
        delete tickets[0];
        Test.stopTest();

        Contact refreshed = [SELECT Tickets_Purchased__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(2, refreshed.Tickets_Purchased__c);
    }

    @isTest
    static void reparentTicket_updatesBothContactCounts() {
        Contact a = makeContact('Margaret', 'Hamilton');
        Contact b = makeContact('Dorothy', 'Vaughan');
        List<Event_Ticket__c> tickets = makeTickets(a.Id, 2);
        insert tickets;

        Test.startTest();
        tickets[0].Contact__c = b.Id;
        update tickets[0];
        Test.stopTest();

        Map<Id, Contact> refreshed = new Map<Id, Contact>(
            [SELECT Tickets_Purchased__c FROM Contact WHERE Id IN :new List<Id>{ a.Id, b.Id }]
        );
        System.assertEquals(1, refreshed.get(a.Id).Tickets_Purchased__c);
        System.assertEquals(1, refreshed.get(b.Id).Tickets_Purchased__c);
    }

    @isTest
    static void ticketWithoutContact_allowedAndNoRollupTouched() {
        Test.startTest();
        insert new Event_Ticket__c(Attendee_Name__c = 'No Contact Here');
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Event_Ticket__c]);
    }
}
