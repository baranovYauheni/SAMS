public with sharing class AgentScheduleController {

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
    public static List<Service_Appointment__c> getAppointments(Id agentId, String status, Date startDate, Date endDate) {

        String query = 'SELECT Id, Name, Customer__c, Customer__r.Name, Appointment_Date_Time__c, Status__c, Description__c ' +
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
            // End of the day
            DateTime endDt = DateTime.newInstance(endDate, Time.newInstance(23, 59, 59, 999));
            query += 'AND Appointment_Date_Time__c <= :endDt ';
        }

        query += 'ORDER BY Appointment_Date_Time__c ASC LIMIT 100';

        return Database.query(query);
    }

    @AuraEnabled
    public static void updateAppointments(List<Map<String, String>> changes) {
        List<Service_Appointment__c> toUpdate = new List<Service_Appointment__c>();

        for (Map<String, String> change : changes) {
            Service_Appointment__c appt = new Service_Appointment__c(Id = change.get('Id'));

            if (change.containsKey('Status__c') && String.isNotBlank(change.get('Status__c'))) {
                appt.Status__c = change.get('Status__c');
            }
            if (change.containsKey('Appointment_Date_Time__c') && String.isNotBlank(change.get('Appointment_Date_Time__c'))) {
                appt.Appointment_Date_Time__c = (DateTime) JSON.deserialize(
                    '"' + change.get('Appointment_Date_Time__c') + '"', DateTime.class
                );
            }

            toUpdate.add(appt);
        }

        update toUpdate;
    }
}
