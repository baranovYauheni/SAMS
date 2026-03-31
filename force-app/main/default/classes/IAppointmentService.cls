/**
 * IAppointmentService
 *
 * SOLID — Interface Segregation Principle (I):
 *   Defines the contract for all appointment business operations.
 *
 * SOLID — Dependency Inversion Principle (D):
 *   Controllers and trigger handlers depend on this abstraction,
 *   not on the concrete AppointmentService class.
 */
public interface IAppointmentService {

    List<Service_Appointment__c> getAppointmentsForAgent(
        Id agentId,
        String status,
        Date startDate,
        Date endDate
    );

    List<Service_Appointment__c> getAppointmentsForCustomer(
        Id contactId,
        String sortOrder
    );

    void updateAppointments(List<Map<String, String>> changes);

    void cancelAppointments(List<Id> appointmentIds);

    // Validates no two active appointments for the same agent share the same date/time.
    // Adds a field-level error on Appointment_Date_Time__c for each conflict.
    void validateNoDoubleBooking(
        List<Service_Appointment__c> newRecords,
        Map<Id, Service_Appointment__c> oldMap
    );
}
