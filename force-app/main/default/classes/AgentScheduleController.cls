/**
 * AgentScheduleController — AuraEnabled controller for agentScheduleTable LWC.
 *
 * SOLID — Single Responsibility Principle (S):
 *   Only responsible for exposing @AuraEnabled methods to LWC.
 *   All business logic is delegated to IAppointmentService.
 *
 * SOLID — Dependency Inversion Principle (D):
 *   Depends on IAppointmentService abstraction, not on AppointmentService directly.
 *   @TestVisible allows injecting a mock in unit tests.
 */
public with sharing class AgentScheduleController {

    // D — Dependency Inversion: depends on interface, not concrete class
    @TestVisible
    private static IAppointmentService appointmentService = new AppointmentService();

    @AuraEnabled(cacheable=true)
    public static List<User> getServiceAgents() {
        return [
            SELECT Id, Name, UserRole.Name
            FROM User
            WHERE IsActive = true
            AND UserRole.Name = 'Service Agent'
            ORDER BY Name
            LIMIT 100
        ];
    }

    @AuraEnabled
    public static List<Service_Appointment__c> getAppointments(
        Id agentId,
        String status,
        Date startDate,
        Date endDate
    ) {
        return appointmentService.getAppointmentsForAgent(agentId, status, startDate, endDate);
    }

    @AuraEnabled
    public static void updateAppointments(List<Map<String, String>> changes) {
        appointmentService.updateAppointments(changes);
    }
}
