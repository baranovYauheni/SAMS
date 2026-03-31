/**
 * IEventPublisher
 *
 * SOLID — Interface Segregation Principle (I):
 *   A small, focused interface responsible for one thing: publishing events.
 *
 * SOLID — Dependency Inversion Principle (D):
 *   High-level modules depend on this abstraction, not on EventBus directly.
 *   Allows mock injection in tests.
 */
public interface IEventPublisher {
    void publish(List<SObject> events);
}
