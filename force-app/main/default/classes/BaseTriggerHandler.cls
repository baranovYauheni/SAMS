/**
 * BaseTriggerHandler — Abstract base class for all Apex trigger handlers.
 *
 * SOLID — Single Responsibility Principle (S):
 *   Responsible only for dispatching Trigger context events to the correct
 *   virtual hook method. Does not contain any business logic.
 *
 * SOLID — Open/Closed Principle (O):
 *   Open for extension: subclasses override only the hooks they need.
 *   Closed for modification: the execute() dispatch logic never needs to change.
 *
 * SOLID — Liskov Substitution Principle (L):
 *   Any subclass can replace BaseTriggerHandler without breaking the execute() contract.
 *
 * Design Pattern: Template Method —
 *   execute() defines the algorithm skeleton; subclasses fill in specific steps.
 */
public abstract class BaseTriggerHandler {

    public void execute() {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) onBeforeInsert(Trigger.new);
            if (Trigger.isUpdate) onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isAfter) {
            if (Trigger.isInsert) onAfterInsert(Trigger.new);
            if (Trigger.isUpdate) onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }

    protected virtual void onBeforeInsert(List<SObject> newRecords) {}
    protected virtual void onBeforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {}
    protected virtual void onAfterInsert(List<SObject> newRecords) {}
    protected virtual void onAfterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {}
}
