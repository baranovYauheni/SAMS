/**
 * CustomerAppointmentController — AuraEnabled controller for customerAppointmentList LWC.
 *
 * SOLID — Single Responsibility Principle (S):
 *   Only responsible for exposing @AuraEnabled methods to LWC.
 *   All business logic is delegated to IAppointmentService.
 *
 * SOLID — Dependency Inversion Principle (D):
 *   Depends on IAppointmentService abstraction, not on AppointmentService directly.
 *   @TestVisible allows injecting a mock in unit tests.
 */
public with sharing class CustomerAppointmentController {

    // D — Dependency Inversion: depends on interface, not concrete class
    @TestVisible
    private static IAppointmentService appointmentService = new AppointmentService();

    @AuraEnabled
    public static List<Service_Appointment__c> getAppointmentsForCustomer(
        Id contactId,
        String sortOrder
    ) {
        return appointmentService.getAppointmentsForCustomer(contactId, sortOrder);
    }

    @AuraEnabled
    public static void cancelAppointments(List<Id> appointmentIds) {
        appointmentService.cancelAppointments(appointmentIds);
    }
}
