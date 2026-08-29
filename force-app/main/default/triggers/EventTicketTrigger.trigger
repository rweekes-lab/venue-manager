trigger EventTicketTrigger on Event_Ticket__c (after insert, after update, after delete, after undelete) {
    EventTicketTriggerHandler.handle(Trigger.new, Trigger.old);
}
