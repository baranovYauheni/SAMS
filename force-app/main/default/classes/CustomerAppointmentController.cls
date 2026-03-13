public with sharing class CustomerAppointmentController {

    @AuraEnabled
    public static List<Service_Appointment__c> getAppointmentsForCustomer(Id contactId, String sortOrder) {
        String order = (sortOrder == 'DESC') ? 'DESC' : 'ASC';
        String query = 'SELECT Id, Name, Appointment_Date_Time__c, Status__c, Description__c, ' +
                       'Service_Agent__c, Service_Agent__r.Name ' +
                       'FROM Service_Appointment__c ' +
                       'WHERE Customer__c = :contactId ' +
                       'ORDER BY Appointment_Date_Time__c ' + order +
                       ' LIMIT 200';
        return Database.query(query);
    }

    @AuraEnabled
    public static void cancelAppointments(List<Id> appointmentIds) {
        List<Service_Appointment__c> toUpdate = new List<Service_Appointment__c>();
        for (Id apptId : appointmentIds) {
            toUpdate.add(new Service_Appointment__c(
                Id = apptId,
                Status__c = 'Cancelled'
            ));
        }
        update toUpdate;
    }
}
