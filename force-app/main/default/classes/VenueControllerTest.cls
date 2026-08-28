@isTest
private class VenueControllerTest {

    private static Venue__c buildVenue(String name, String city) {
        return new Venue__c(
            Name = name,
            City__c = city,
            State__c = 'CA',
            Capacity__c = 250,
            Contact_Email__c = 'host@example.com',
            Active__c = true,
            Rate_Unit__c = 'Per Hour',
            Booking_Rate__c = 150,
            Tags__c = 'rooftop, outdoor'
        );
    }

    @TestSetup
    static void setup() {
        insert new List<Venue__c>{
            buildVenue('Grand Hall', 'San Francisco'),
            buildVenue('Riverside Pavilion', 'Sacramento'),
            buildVenue('The Loft', 'San Francisco')
        };
    }

    @isTest
    static void testGetVenuesAll() {
        Test.startTest();
        List<Venue__c> venues = VenueController.getVenues(null);
        Test.stopTest();
        System.assertEquals(3, venues.size(), 'Expected all seeded venues');
        System.assertEquals('Grand Hall', venues[0].Name, 'Expected ordering by name ASC');
    }

    @isTest
    static void testGetVenuesSearchByCity() {
        Test.startTest();
        List<Venue__c> venues = VenueController.getVenues('San Francisco');
        Test.stopTest();
        System.assertEquals(2, venues.size(), 'Expected only SF venues');
    }

    @isTest
    static void testGetVenuesSearchByTag() {
        List<Venue__c> venues = VenueController.getVenues('rooftop');
        System.assertEquals(3, venues.size(), 'All seeded venues carry the rooftop tag');
    }

    @isTest
    static void testGetVenueById() {
        Venue__c seeded = [SELECT Id FROM Venue__c WHERE Name = 'The Loft' LIMIT 1];
        Venue__c fetched = VenueController.getVenue(seeded.Id);
        System.assertEquals('The Loft', fetched.Name);
    }

    @isTest
    static void testGetVenueNotFound() {
        Boolean threw = false;
        try {
            // A syntactically valid Id that matches no record.
            VenueController.getVenue('a00000000000000AAA');
        } catch (Exception e) {
            threw = true;
        }
        System.assert(threw, 'Expected an exception for a missing venue');
    }

    @isTest
    static void testInsertVenue() {
        Venue__c v = buildVenue('New Arena', 'Oakland');
        Test.startTest();
        Venue__c saved = VenueController.saveVenue(v);
        Test.stopTest();
        System.assertNotEquals(null, saved.Id, 'Insert should return an Id');
        System.assertEquals(4, [SELECT COUNT() FROM Venue__c]);
    }

    @isTest
    static void testUpdateVenue() {
        Venue__c seeded = [SELECT Id, Capacity__c FROM Venue__c WHERE Name = 'Grand Hall' LIMIT 1];
        seeded.Capacity__c = 999;
        Venue__c saved = VenueController.saveVenue(seeded);
        System.assertEquals(999, saved.Capacity__c, 'Update should persist new capacity');
    }

    @isTest
    static void testSaveNullThrows() {
        Boolean threw = false;
        try {
            VenueController.saveVenue(null);
        } catch (Exception e) {
            threw = true;
        }
        System.assert(threw, 'Saving null should throw');
    }

    @isTest
    static void testDeleteVenue() {
        Venue__c seeded = [SELECT Id FROM Venue__c WHERE Name = 'The Loft' LIMIT 1];
        Test.startTest();
        VenueController.deleteVenue(seeded.Id);
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM Venue__c]);
    }
}
