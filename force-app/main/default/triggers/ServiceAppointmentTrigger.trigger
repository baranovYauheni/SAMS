trigger ServiceAppointmentTrigger on Service_Appointment__c (after update) {
    ServiceAppointmentTriggerHandler handler = new ServiceAppointmentTriggerHandler();

    if (Trigger.isAfter && Trigger.isUpdate) {
        handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}