/**
 * AppointmentService — concrete implementation of IAppointmentService.
 *
 * SOLID — Single Responsibility Principle (S):
 *   This class is the single owner of all appointment business logic.
 *   Controllers delegate to this service; they do not contain business logic.
 *
 * SOLID — Liskov Substitution Principle (L):
 *   Can replace any IAppointmentService reference transparently,
 *   including in tests where a mock implementation may be injected.
 */
public with sharing class AppointmentService implements IAppointmentService {

    public List<Service_Appointment__c> getAppointmentsForAgent(
        Id agentId,
        String status,
        Date startDate,
        Date endDate
    ) {
        String query =
            'SELECT Id, Name, Customer__c, Customer__r.Name, ' +
            'Appointment_Date_Time__c, Status__c, Description__c ' +
            'FROM Service_Appointment__c ' +
            'WHERE Service_Agent__c = :agentId ';

        if (String.isNotBlank(status)) {
            query += 'AND Status__c = :status ';
        }
        if (startDate != null) {
            DateTime startDt = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
            query += 'AND Appointment_Date_Time__c >= :startDt ';
        }
        if (endDate != null) {
            DateTime endDt = DateTime.newInstance(endDate, Time.newInstance(23, 59, 59, 999));
            query += 'AND Appointment_Date_Time__c <= :endDt ';
        }
        query += 'ORDER BY Appointment_Date_Time__c ASC LIMIT 100';

        return Database.query(query);
    }

    public List<Service_Appointment__c> getAppointmentsForCustomer(
        Id contactId,
        String sortOrder
    ) {
        String order = (sortOrder == 'DESC') ? 'DESC' : 'ASC';
        String query =
            'SELECT Id, Name, Appointment_Date_Time__c, Status__c, Description__c, ' +
            'Service_Agent__c, Service_Agent__r.Name ' +
            'FROM Service_Appointment__c ' +
            'WHERE Customer__c = :contactId ' +
            'ORDER BY Appointment_Date_Time__c ' + order + ' LIMIT 200';
        return Database.query(query);
    }

    public void updateAppointments(List<Map<String, String>> changes) {
        List<Service_Appointment__c> toUpdate = new List<Service_Appointment__c>();

        for (Map<String, String> change : changes) {
            Service_Appointment__c appt = new Service_Appointment__c(
                Id = change.get('Id')
            );
            if (change.containsKey('Status__c') && String.isNotBlank(change.get('Status__c'))) {
                appt.Status__c = change.get('Status__c');
            }
            if (change.containsKey('Appointment_Date_Time__c') &&
                String.isNotBlank(change.get('Appointment_Date_Time__c'))) {
                appt.Appointment_Date_Time__c = (DateTime) JSON.deserialize(
                    '"' + change.get('Appointment_Date_Time__c') + '"',
                    DateTime.class
                );
            }
            toUpdate.add(appt);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void cancelAppointments(List<Id> appointmentIds) {
        List<Service_Appointment__c> toUpdate = new List<Service_Appointment__c>();
        for (Id apptId : appointmentIds) {
            toUpdate.add(new Service_Appointment__c(
                Id = apptId,
                Status__c = 'Cancelled'
            ));
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void validateNoDoubleBooking(
        List<Service_Appointment__c> newRecords,
        Map<Id, Service_Appointment__c> oldMap
    ) {
        Set<Id> agentIds = new Set<Id>();
        DateTime rangeStart = null;
        DateTime rangeEnd = null;

        for (Service_Appointment__c rec : newRecords) {
            if (rec.Status__c == 'Cancelled' || rec.Status__c == 'Completed') continue;
            if (rec.Service_Agent__c == null || rec.Appointment_Date_Time__c == null) continue;

            // For updates: skip if neither agent nor time changed
            if (oldMap != null) {
                Service_Appointment__c old = oldMap.get(rec.Id);
                if (old.Service_Agent__c == rec.Service_Agent__c &&
                    old.Appointment_Date_Time__c == rec.Appointment_Date_Time__c) {
                    continue;
                }
            }

            agentIds.add(rec.Service_Agent__c);

            if (rangeStart == null || rec.Appointment_Date_Time__c < rangeStart) rangeStart = rec.Appointment_Date_Time__c;
            if (rangeEnd   == null || rec.Appointment_Date_Time__c > rangeEnd)   rangeEnd   = rec.Appointment_Date_Time__c;
        }

        if (agentIds.isEmpty()) return;

        // Exclude the records currently being saved (update scenario)
        Set<Id> currentIds = new Set<Id>();
        for (Service_Appointment__c rec : newRecords) {
            if (rec.Id != null) currentIds.add(rec.Id);
        }

        // Single SOQL for all agents and the full time range — bulk safe
        List<Service_Appointment__c> existing = [
            SELECT Id, Service_Agent__c, Appointment_Date_Time__c
            FROM Service_Appointment__c
            WHERE Service_Agent__c IN :agentIds
            AND   Appointment_Date_Time__c >= :rangeStart
            AND   Appointment_Date_Time__c <= :rangeEnd
            AND   Status__c NOT IN ('Cancelled', 'Completed')
            AND   Id NOT IN :currentIds
        ];

        // Build map: agentId → booked DateTimes
        Map<Id, Set<DateTime>> bookedTimes = new Map<Id, Set<DateTime>>();
        for (Service_Appointment__c ex : existing) {
            if (!bookedTimes.containsKey(ex.Service_Agent__c)) {
                bookedTimes.put(ex.Service_Agent__c, new Set<DateTime>());
            }
            bookedTimes.get(ex.Service_Agent__c).add(ex.Appointment_Date_Time__c);
        }

        for (Service_Appointment__c rec : newRecords) {
            if (rec.Status__c == 'Cancelled' || rec.Status__c == 'Completed') continue;
            if (rec.Service_Agent__c == null || rec.Appointment_Date_Time__c == null) continue;

            Set<DateTime> times = bookedTimes.get(rec.Service_Agent__c);
            if (times != null && times.contains(rec.Appointment_Date_Time__c)) {
                rec.Appointment_Date_Time__c.addError(
                    'This agent already has an appointment at this date and time. ' +
                    'Please choose a different time slot.'
                );
            }
        }
    }
}
