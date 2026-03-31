/**
 * AppointmentReminderScheduler — Schedulable wrapper for AppointmentReminderBatch.
 *
 * SOLID — Single Responsibility Principle (S):
 *   Responsible only for scheduling. Does not contain any batch logic.
 */
public with sharing class AppointmentReminderScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AppointmentReminderBatch(), 200);
    }
}
