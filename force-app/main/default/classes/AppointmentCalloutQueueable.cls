public with sharing class AppointmentCalloutQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<Service_Appointment__c> appointments;

    public AppointmentCalloutQueueable(List<Service_Appointment__c> appointments) {
        this.appointments = appointments;
    }

    public void execute(QueueableContext context) {
        if(appointments == null || appointments.isEmpty()) return;

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Webhook_Site');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        
        String jsonBody = JSON.serialize(appointments);
        request.setBody(jsonBody);
        
        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
                System.debug(LoggingLevel.ERROR, 'Callout failed with status: ' + response.getStatus());
                
                List<Integration_Log__c> logs = new List<Integration_Log__c>();
                for (Service_Appointment__c appt : this.appointments) {
                    logs.add(new Integration_Log__c(
                        Service_Appointment__c = appt.Id,
                        Status_Code__c         = response.getStatusCode(),
                        Endpoint__c            = 'callout:Webhook_Site',
                        Response_Body__c       = response.getBody() != null ? response.getBody().abbreviate(32000) : '',
                        Request_Payload__c     = jsonBody.abbreviate(32000)
                    ));
                }
                insert logs;
            } else {
                System.debug('Callout Success: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception in AppointmentCalloutQueueable: ' + e.getMessage());
            
            List<Integration_Log__c> logs = new List<Integration_Log__c>();
            for (Service_Appointment__c appt : this.appointments) {
                logs.add(new Integration_Log__c(
                    Service_Appointment__c = appt.Id,
                    Status_Code__c         = 500,
                    Endpoint__c            = 'callout:Webhook_Site',
                    Response_Body__c       = e.getMessage().abbreviate(32000),
                    Request_Payload__c     = jsonBody.abbreviate(32000)
                ));
            }
            insert logs;
        }
    }
}
