/**
 * PlatformEventPublisher — concrete implementation of IEventPublisher.
 *
 * SOLID — Single Responsibility Principle (S):
 *   Responsible only for wrapping EventBus.publish() calls.
 *
 * SOLID — Open/Closed Principle (O):
 *   Adding a new notification channel means creating a new class that
 *   implements IEventPublisher — no existing class needs to change.
 *
 * SOLID — Liskov Substitution Principle (L):
 *   Can replace any IEventPublisher reference transparently.
 */
public with sharing class PlatformEventPublisher implements IEventPublisher {

    public void publish(List<SObject> events) {
        if (events == null || events.isEmpty()) {
            return;
        }
        EventBus.publish(events);
    }
}
