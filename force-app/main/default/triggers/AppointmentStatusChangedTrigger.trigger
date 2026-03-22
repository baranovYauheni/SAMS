trigger AppointmentStatusChangedTrigger on Change_Service_Appointment__e (after insert) {
    AppointmentStatusChangedTriggerHandler handler = new AppointmentStatusChangedTriggerHandler();

    if (Trigger.isAfter && Trigger.isInsert) {
        handler.onAfterInsert(Trigger.New);
    }
}