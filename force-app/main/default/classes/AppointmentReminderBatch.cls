/**
 * AppointmentReminderBatch — Batch Apex for next-day appointment email reminders.
 *
 * SOLID — Single Responsibility Principle (S):
 *   Responsible only for querying next-day appointments and sending reminder emails.
 *
 * Database.Stateful: tracks emailsSent / emailsFailed counters across execute() chunks.
 */
public with sharing class AppointmentReminderBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    private Integer emailsSent   = 0;
    private Integer emailsFailed = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime tomorrowStart = DateTime.newInstance(Date.today().addDays(1), Time.newInstance(0,  0, 0, 0));
        DateTime tomorrowEnd   = DateTime.newInstance(Date.today().addDays(1), Time.newInstance(23, 59, 59, 999));

        return Database.getQueryLocator([
            SELECT Id,
                   Name,
                   Appointment_Date_Time__c,
                   Status__c,
                   Description__c,
                   Customer__c,
                   Customer__r.Name,
                   Customer__r.Email,
                   Service_Agent__c,
                   Service_Agent__r.Name
            FROM Service_Appointment__c
            WHERE Appointment_Date_Time__c >= :tomorrowStart
            AND   Appointment_Date_Time__c <= :tomorrowEnd
            AND   Status__c IN ('New', 'Confirmed')
            AND   Customer__r.Email != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Service_Appointment__c> scope) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Service_Appointment__c appt : scope) {
            if (String.isBlank(appt.Customer__r.Email)) continue;

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ appt.Customer__r.Email });
            email.setSubject('Reminder: Your appointment is tomorrow');
            email.setPlainTextBody(buildEmailBody(appt));
            email.setSaveAsActivity(false);
            emails.add(email);
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);
                for (Messaging.SendEmailResult r : results) {
                    if (r.isSuccess()) {
                        emailsSent++;
                    } else {
                        emailsFailed++;
                        System.debug('Email send failed: ' + r.getErrors());
                    }
                }
            } catch (Exception e) {
                emailsFailed += emails.size();
                System.debug('Batch email error: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('AppointmentReminderBatch complete. Sent: ' + emailsSent + ' | Failed: ' + emailsFailed);

        if (emailsFailed > 0) {
            try {
                Messaging.SingleEmailMessage adminAlert = new Messaging.SingleEmailMessage();
                adminAlert.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
                adminAlert.setSubject('SAMS Reminder Batch — ' + emailsFailed + ' email(s) failed');
                adminAlert.setPlainTextBody(
                    'Batch job AppointmentReminderBatch completed.\n' +
                    'Emails sent successfully: ' + emailsSent + '\n' +
                    'Emails failed: ' + emailsFailed + '\n' +
                    'Please check debug logs for details.'
                );
                adminAlert.setSaveAsActivity(false);
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ adminAlert }, false);
            } catch (Exception e) {
                System.debug('Admin alert failed: ' + e.getMessage());
            }
        }
    }

    private String buildEmailBody(Service_Appointment__c appt) {
        String agentName = appt.Service_Agent__r != null ? appt.Service_Agent__r.Name : 'your assigned agent';
        String apptTime  = appt.Appointment_Date_Time__c.format('MMMM d, yyyy \'at\' h:mm a');

        return 'Dear ' + appt.Customer__r.Name + ',\n\n' +
               'This is a reminder that you have a service appointment scheduled for tomorrow.\n\n' +
               'Appointment Details:\n' +
               '  Date & Time : ' + apptTime + '\n' +
               '  Agent       : ' + agentName + '\n' +
               (String.isNotBlank(appt.Description__c)
                   ? '  Notes       : ' + appt.Description__c + '\n'
                   : '') +
               '\nIf you need to reschedule or cancel, please contact us as soon as possible.\n\n' +
               'Best regards,\nService Appointment Management System';
    }
}
