public with sharing class AppointmentStatusChangedTriggerHandler {

    public void onAfterInsert(List<Change_Service_Appointment__e> events) {
        List<Appointment_Status_Log__c> logsToInsert = new List<Appointment_Status_Log__c>();

        for (Change_Service_Appointment__e evt : events) {
            logsToInsert.add(new Appointment_Status_Log__c(
                Service_Appointment__c = (Id) evt.Appointment_Id__c,
                Old_Status__c          = evt.Old_status__c,
                New_Status__c          = evt.New_Status__c,
                Changed_by__c          = (Id) evt.Changed_by_Id__c,
                Date_Changes__c        = evt.Changed_on__c
            ));
        }

        if (!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }
    }
}
