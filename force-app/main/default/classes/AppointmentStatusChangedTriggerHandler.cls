/**
 * AppointmentStatusChangedTriggerHandler — extends BaseTriggerHandler.
 *
 * SOLID — Single Responsibility Principle (S):
 *   Responsible only for converting Platform Event data
 *   into Appointment_Status_Log__c records.
 *
 * SOLID — Liskov Substitution Principle (L):
 *   Correctly extends BaseTriggerHandler by overriding only onAfterInsert.
 */
public with sharing class AppointmentStatusChangedTriggerHandler extends BaseTriggerHandler {

    protected override void onAfterInsert(List<SObject> newRecords) {
        List<Appointment_Status_Log__c> logsToInsert = new List<Appointment_Status_Log__c>();

        for (Change_Service_Appointment__e evt : (List<Change_Service_Appointment__e>) newRecords) {
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
