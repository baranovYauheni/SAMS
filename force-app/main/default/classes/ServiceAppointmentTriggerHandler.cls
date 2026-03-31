/**
 * ServiceAppointmentTriggerHandler — extends BaseTriggerHandler.
 *
 * SOLID — Single Responsibility Principle (S):
 *   Handles trigger events for Service_Appointment__c only.
 *   Business logic is fully delegated to IAppointmentService and IEventPublisher.
 *
 * SOLID — Dependency Inversion Principle (D):
 *   Depends on IAppointmentService and IEventPublisher abstractions,
 *   not on AppointmentService or EventBus directly.
 *
 * SOLID — Liskov Substitution Principle (L):
 *   Extends BaseTriggerHandler and overrides only the needed hooks.
 */
public with sharing class ServiceAppointmentTriggerHandler extends BaseTriggerHandler {

    // D — Dependency Inversion: fields reference interfaces, not concrete classes
    private IEventPublisher eventPublisher;
    private IAppointmentService appointmentService;

    // DI constructor — used in unit tests to inject mocks
    public ServiceAppointmentTriggerHandler(
        IEventPublisher eventPublisher,
        IAppointmentService appointmentService
    ) {
        this.eventPublisher     = eventPublisher;
        this.appointmentService = appointmentService;
    }

    // O — Open/Closed: swap publisher or service via DI without changing this class
    public ServiceAppointmentTriggerHandler() {
        this(new PlatformEventPublisher(), new AppointmentService());
    }

    protected override void onBeforeInsert(List<SObject> newRecords) {
        appointmentService.validateNoDoubleBooking(
            (List<Service_Appointment__c>) newRecords,
            null
        );
    }

    protected override void onBeforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        appointmentService.validateNoDoubleBooking(
            (List<Service_Appointment__c>) newRecords,
            (Map<Id, Service_Appointment__c>) oldMap
        );
    }

    protected override void onAfterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        List<Change_Service_Appointment__e> events = new List<Change_Service_Appointment__e>();

        for (Service_Appointment__c newAppt : (List<Service_Appointment__c>) newRecords) {
            Service_Appointment__c oldAppt = (Service_Appointment__c) oldMap.get(newAppt.Id);
            if (newAppt.Status__c != oldAppt.Status__c) {
                events.add(new Change_Service_Appointment__e(
                    Appointment_Id__c = String.valueOf(newAppt.Id),
                    Old_status__c     = oldAppt.Status__c,
                    New_Status__c     = newAppt.Status__c,
                    Changed_by_Id__c  = UserInfo.getUserId(),
                    Changed_on__c     = System.now()
                ));
            }
        }

        eventPublisher.publish(events);
    }
}