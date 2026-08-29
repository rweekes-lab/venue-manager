@isTest
private class EventTicketTriggerHandlerTest {

    private static Venue__c makeVenue(Decimal capacity) {
        Venue__c v = new Venue__c(Name = 'Test Venue', Capacity__c = capacity);
        insert v;
        return v;
    }

    private static Venue_Event__c makeEvent(Id venueId) {
        Venue_Event__c e = new Venue_Event__c(
            Name = 'Test Event',
            Venue__c = venueId,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today()
        );
        insert e;
        return e;
    }

    private static List<Event_Ticket__c> makeTickets(Id eventId, Integer howMany) {
        List<Event_Ticket__c> tickets = new List<Event_Ticket__c>();
        for (Integer i = 0; i < howMany; i++) {
            tickets.add(new Event_Ticket__c(Venue_Event__c = eventId));
        }
        return tickets;
    }

    @isTest
    static void insertWithinCapacity_succeedsAndSyncsCount() {
        Venue__c venue = makeVenue(3);
        Venue_Event__c event = makeEvent(venue.Id);

        Test.startTest();
        insert makeTickets(event.Id, 2);
        Test.stopTest();

        Venue_Event__c refreshed = [SELECT Tickets_Sold__c FROM Venue_Event__c WHERE Id = :event.Id];
        System.assertEquals(2, refreshed.Tickets_Sold__c, 'Tickets_Sold__c should equal the ticket count');
    }

    @isTest
    static void insertExceedingCapacity_throwsAndRollsBack() {
        Venue__c venue = makeVenue(1);
        Venue_Event__c event = makeEvent(venue.Id);

        Test.startTest();
        Boolean threw = false;
        try {
            insert makeTickets(event.Id, 2);
        } catch (DmlException e) {
            threw = true;
            System.assert(
                e.getMessage().contains('exceeds venue capacity of 1'),
                'Expected capacity error, got: ' + e.getMessage()
            );
        }
        Test.stopTest();

        System.assert(threw, 'Expected a DmlException when exceeding capacity');
        System.assertEquals(0, [SELECT COUNT() FROM Event_Ticket__c], 'Insert should have fully rolled back');
    }

    @isTest
    static void bulkInsertAcrossEvents_countsSyncIndependently() {
        Venue__c venue = makeVenue(100);
        Venue_Event__c eventA = makeEvent(venue.Id);
        Venue_Event__c eventB = makeEvent(venue.Id);

        List<Event_Ticket__c> tickets = new List<Event_Ticket__c>();
        tickets.addAll(makeTickets(eventA.Id, 80));
        tickets.addAll(makeTickets(eventB.Id, 70));

        Test.startTest();
        insert tickets;
        Test.stopTest();

        Map<Id, Venue_Event__c> refreshed = new Map<Id, Venue_Event__c>(
            [SELECT Tickets_Sold__c FROM Venue_Event__c WHERE Id IN :new List<Id>{ eventA.Id, eventB.Id }]
        );
        System.assertEquals(80, refreshed.get(eventA.Id).Tickets_Sold__c);
        System.assertEquals(70, refreshed.get(eventB.Id).Tickets_Sold__c);
    }

    @isTest
    static void deleteTickets_decrementsCount() {
        Venue__c venue = makeVenue(5);
        Venue_Event__c event = makeEvent(venue.Id);
        List<Event_Ticket__c> tickets = makeTickets(event.Id, 3);
        insert tickets;

        Test.startTest();
        delete tickets[0];
        Test.stopTest();

        Venue_Event__c refreshed = [SELECT Tickets_Sold__c FROM Venue_Event__c WHERE Id = :event.Id];
        System.assertEquals(2, refreshed.Tickets_Sold__c);
    }

    @isTest
    static void reparentTicket_updatesBothEventCounts() {
        Venue__c venue = makeVenue(5);
        Venue_Event__c eventA = makeEvent(venue.Id);
        Venue_Event__c eventB = makeEvent(venue.Id);
        List<Event_Ticket__c> tickets = makeTickets(eventA.Id, 2);
        insert tickets;

        Test.startTest();
        tickets[0].Venue_Event__c = eventB.Id;
        update tickets[0];
        Test.stopTest();

        Map<Id, Venue_Event__c> refreshed = new Map<Id, Venue_Event__c>(
            [SELECT Tickets_Sold__c FROM Venue_Event__c WHERE Id IN :new List<Id>{ eventA.Id, eventB.Id }]
        );
        System.assertEquals(1, refreshed.get(eventA.Id).Tickets_Sold__c);
        System.assertEquals(1, refreshed.get(eventB.Id).Tickets_Sold__c);
    }

    @isTest
    static void eventWithoutVenue_ticketsAllowedAndCountSynced() {
        Venue_Event__c event = new Venue_Event__c(
            Name = 'No Venue Event',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today()
        );
        insert event;

        Test.startTest();
        insert makeTickets(event.Id, 10);
        Test.stopTest();

        Venue_Event__c refreshed = [SELECT Tickets_Sold__c FROM Venue_Event__c WHERE Id = :event.Id];
        System.assertEquals(10, refreshed.Tickets_Sold__c, 'No venue means no capacity to enforce against');
    }

    @isTest
    static void eventWithVenueButNullCapacity_ticketsAllowed() {
        Venue__c venue = new Venue__c(Name = 'Capacity Unknown Venue');
        insert venue;
        Venue_Event__c event = makeEvent(venue.Id);

        Test.startTest();
        insert makeTickets(event.Id, 5);
        Test.stopTest();

        Venue_Event__c refreshed = [SELECT Tickets_Sold__c FROM Venue_Event__c WHERE Id = :event.Id];
        System.assertEquals(5, refreshed.Tickets_Sold__c, 'Null capacity means no capacity to enforce against');
    }
}
