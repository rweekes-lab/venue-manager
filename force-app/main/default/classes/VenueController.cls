/**
 * Server-side controller for the Venue Manager LWC bundle.
 *
 * Exposes CRUD operations over the Venue__c custom object. All methods run
 * with sharing so the running user's record visibility is respected, and
 * every field access is guarded by CRUD/FLS checks via stripInaccessible.
 */
public with sharing class VenueController {
    // Fields returned to the client. Kept in one place so the SELECT, the
    // return shape, and the security check all stay in sync.
    private static final List<String> VENUE_FIELDS = new List<String>{
        'Id', 'Name', 'Street__c', 'City__c', 'State__c', 'PostalCode__c',
        'Country__c', 'Capacity__c', 'Contact_Name__c', 'Contact_Email__c',
        'Contact_Phone__c', 'Description__c', 'Active__c', 'Opening_Time__c',
        'Closing_Time__c', 'Booking_Rate__c', 'Rate_Unit__c', 'Photo_URL__c',
        'Website_URL__c', 'Has_Parking__c', 'Has_Catering__c', 'Has_AV__c',
        'Is_Accessible__c', 'Tags__c'
    };

    /**
     * Returns venues, optionally filtered by a search term matching the
     * name, city, or tags. Results are ordered by name.
     *
     * @param searchTerm optional case-insensitive substring; null/blank returns all
     * @return list of Venue__c records the user can read
     */
    @AuraEnabled(cacheable=true)
    public static List<Venue__c> getVenues(String searchTerm) {
        // Bind variable is resolved at query time; wrapping in % gives a
        // substring match while the bind prevents SOQL injection.
        String term = String.isBlank(searchTerm) ? '' : '%' + searchTerm.trim() + '%';
        String soql = 'SELECT ' + String.join(VENUE_FIELDS, ', ') + ' FROM Venue__c';
        if (String.isNotBlank(searchTerm)) {
            soql += ' WHERE Name LIKE :term OR City__c LIKE :term OR Tags__c LIKE :term';
        }
        soql += ' ORDER BY Name ASC LIMIT 1000';

        List<Venue__c> records = Database.query(soql);
        return (List<Venue__c>) Security.stripInaccessible(AccessType.READABLE, records).getRecords();
    }

    /**
     * Returns a single venue by Id.
     */
    @AuraEnabled(cacheable=true)
    public static Venue__c getVenue(Id venueId) {
        String soql = 'SELECT ' + String.join(VENUE_FIELDS, ', ') +
            ' FROM Venue__c WHERE Id = :venueId LIMIT 1';
        List<Venue__c> records = Database.query(soql);
        if (records.isEmpty()) {
            throw new AuraHandledException('Venue not found or not accessible.');
        }
        return (Venue__c) Security.stripInaccessible(AccessType.READABLE, records).getRecords()[0];
    }

    /**
     * Inserts or updates a venue. FLS is enforced on the incoming fields so a
     * user cannot write columns they lack edit access to.
     *
     * @param venue the record to persist (Id present = update, absent = insert)
     * @return the saved record re-read from the database
     */
    @AuraEnabled
    public static Venue__c saveVenue(Venue__c venue) {
        if (venue == null) {
            throw new AuraHandledException('No venue provided.');
        }
        try {
            AccessType mode = venue.Id == null ? AccessType.CREATABLE : AccessType.UPDATABLE;
            SObjectAccessDecision decision =
                Security.stripInaccessible(mode, new List<Venue__c>{ venue });
            Venue__c clean = (Venue__c) decision.getRecords()[0];
            upsert clean;
            return getVenue(clean.Id);
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        }
    }

    /**
     * Deletes a venue by Id.
     */
    @AuraEnabled
    public static void deleteVenue(Id venueId) {
        if (!Schema.sObjectType.Venue__c.isDeletable()) {
            throw new AuraHandledException('You do not have permission to delete venues.');
        }
        try {
            delete new Venue__c(Id = venueId);
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        }
    }
}
