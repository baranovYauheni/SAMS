public with sharing class ServiceAppointmentTriggerHandler {
    public void onAfterUpdate(List<Service_Appointment__c> newAppts, Map<Id, Service_Appointment__c> oldApptMap) {

        List<Change_Service_Appointment__e> events = new List<Change_Service_Appointment__e>();

        for(Service_Appointment__c newAppt : newAppts){
            Service_Appointment__c oldAppt = oldApptMap.get(newAppt.Id);
            if(newAppt.Status__c != oldAppt.Status__c){
                events.add(new Change_Service_Appointment__e(
                    Appointment_Id__c = String.valueOf(newAppt.Id),
                    Old_status__c     = oldAppt.Status__c,
                    New_Status__c     = newAppt.Status__c,
                    Changed_by_Id__c  = UserInfo.getUserId(),
                    Changed_on__c     = System.now()
                ));
            }
        }

        if(!events.isEmpty()){
            EventBus.publish(events);
        }
    }
}