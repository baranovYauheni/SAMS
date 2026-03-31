# Service Appointment Management System (SAMS) - Documentation

## 1.1. Data Model

During the analysis of the current Salesforce configuration, the metadata of the custom object `Service_Appointment__c` was verified against the first point of the functional requirements.

### Custom Object
- **API Name:** `Service_Appointment__c`
- **Label:** Service Appointment
- **Status:** The object has been successfully created and meets the general configuration requirements.

### Fields
All required fields have been successfully created with the correct data types:
1. **`Customer__c`** — Lookup to the `Contact` object (Relationship Name: `Service_Appointments`).
2. **`Service_Agent__c`** — Lookup to the `User` object.
3. **`Status__c`** — Picklist with a restricted set of values (Restricted: true). Values: `New`, `Confirmed`, `Cancelled`, `Completed`.
4. **`Appointment_Date_Time__c`** — `DateTime` data type.
5. **`Description__c`** — `Text` data type (Length: 255).

### Security & Sharing
- **OWD (Organization-Wide Defaults):** 
  - Configured as `Private` (`<sharingModel>Private</sharingModel>`). Requirement met.
- **Sharing Rules:** 
  - Requirement: "Service agents can only see their own records, managers can see all."
  - Since OWD = Private, agents default to accessing only their own records. The restriction for service agents works correctly.
  - The project includes `Service_Manager` and `Service_Agent` roles. In the Salesforce security model, `Grant Access Using Hierarchies` automatically gives managers access to their subordinates' records, so access is generally covered by the Role Hierarchy.
  - However, the `Service_Appointment__c.sharingRules-meta.xml` file is currently empty. If the business requirement implies that any `Service_Manager` should see the records of *all agents without exception* (and not just their subordinates in the hierarchy), a Criteria-Based Sharing Rule or Owner-Based Sharing Rule should be added to share records from the "All Internal Users" group (or Service Agent role) to the "Service Manager" role.

### Conclusion
The data schema (`Service_Appointment__c`), all core fields, and the basic restricted access model (OWD Private) are configured in full compliance with the requirements. Regarding Sharing Rules, it is recommended to ensure that the current Role Hierarchy is sufficient for the business logic of managers' data visibility, as explicit `SharingRules` are not currently present in the metadata.

## 2.1. LWC Components

The following Lightning Web Components (LWC) have been created for the Service Appointment Management System:

### 1. `appointmentBookingForm`
**Purpose:** A form to create new `Service_Appointment__c` records.
**Features:**
- **Universal Placement:** Designed to be placed on App Pages, Home Pages, Utility Bar, and Contact Record Pages.
- **Context Awareness:** Automatically pre-fills and locks the `Customer__c` field if placed on a Contact Record Page. If placed elsewhere, allows manual selection of a customer.
- **Data Entry & Validation:** Uses standard `lightning-record-edit-form` to capture Agent, Date/Time, Status, and Description, automatically leveraging Salesforce's built-in field validation.

### 2. `agentScheduleTable`
**Purpose:** A table for displaying and managing appointments for a selected Service Agent.
**Features:**
- Agent selector with dynamic filtering by status and date range.
- Inline editing of `Status__c` via a custom picklist cell (`customPicklistCell` sub-component).
- Inline editing of `Appointment_Date_Time__c`.
- Bulk save via `AgentScheduleController.updateAppointments()`.

### 3. `customerAppointmentList`
**Purpose:** A list of all `Service_Appointment__c` records for a selected Contact displayed on the Contact Record Page.
**Features:**
- Automatic loading of appointments for the current Contact via `CustomerAppointmentController.getAppointmentsForCustomer()`.
- Sort toggle (Ascending / Descending) by `Appointment_Date_Time__c`.
- Multi-select cancel action via `CustomerAppointmentController.cancelAppointments()`.

---

## 2.4. Flows

### Subflow: `Check_Contact_Exists`
**Type:** AutoLaunched Flow  
**Purpose:** Checks whether a Contact with a given Id exists in Salesforce. Used as a subflow by `Appointment_Booking_Flow`.

| Variable | Direction | Description |
|---|---|---|
| `contactId` | Input | Id of the Contact to verify |
| `contactExists` | Output | `true` if found, `false` otherwise |
| `contactName` | Output | Full name of the Contact (if found) |

**Logic:** Get Records on Contact by Id → Set output variables. If fault → `contactExists = false`.

---

### Screen Flow: `Appointment_Booking_Flow`
**Type:** Screen Flow  
**Purpose:** Guides users through creating a Service Appointment with built-in validation.

**Steps:**
1. **Input Screen** — collects Customer (Contact Id), Agent (User Id), Date & Time, Description
2. **Subflow** — calls `Check_Contact_Exists` to verify the contact
3. **Error Screen: Contact Not Found** — shown if contact doesn't exist (user can go back)
4. **Get Records** — queries `Service_Appointment__c` for same agent + same date/time (active status)
5. **Decision: Conflict?** — checks if conflicting records found
6. **Error Screen: Scheduling Conflict** — shown if conflict found (Error Handling, req. 2.4)
7. **Create Record** — creates `Service_Appointment__c` with `Status__c = 'New'`
8. **Success Screen** — confirms creation with customer name

---

### After-Save Flow: `Update_Active_Appointments_Count`
**Type:** Record-Triggered (After Save)  
**Object:** `Service_Appointment__c`  
**Trigger:** Create or Update, when `Status__c` or `Customer__c` changes  
**Purpose:** Maintains `Active_Appointments__c` counter on the related Contact.

**Logic:**  
Get count of appointments for this Contact where `Status__c = 'New'` → Update `Contact.Active_Appointments__c`.

**Custom Field Required:** `Contact.Active_Appointments__c` (Number) — created in `objects/Contact/fields/`.

---

## 2.3. Asynchronous Processes


### Batch Apex: `AppointmentReminderBatch`
**Purpose:** Sends email reminders to customers for all `Service_Appointment__c` records scheduled for the next day.

**Implements:** `Database.Batchable<SObject>`, `Database.Stateful`

| Method | Logic |
|---|---|
| `start()` | Returns a `QueryLocator` for all appointments tomorrow with status `New` or `Confirmed` and a non-null Contact email |
| `execute()` | Builds and sends `Messaging.SingleEmailMessage` per appointment. One `Messaging.sendEmail()` call per chunk — bulk safe |
| `finish()` | Logs summary. If any emails failed, sends an alert to the running user |

**`Database.Stateful`** is used to track `emailsSent` and `emailsFailed` counters across all `execute()` chunks.

**Schedule:** Wrapped by `AppointmentReminderScheduler` (implements `Schedulable`):
```apex
// Run daily at 8:00 AM
System.schedule('Daily Appointment Reminders', '0 0 8 * * ?', new AppointmentReminderScheduler());
```

---

### Queueable Apex: `BulkStatusUpdateQueueable`
**Purpose:** Asynchronously bulk-updates `Status__c` on `Service_Appointment__c` records matching a given agent, date, and/or current status.

**Implements:** `Queueable`

**Typical use-case:** Cancel all active appointments for an agent on a specific day:
```apex
System.enqueueJob(new BulkStatusUpdateQueueable(agentId, targetDate));
```

**Full constructor** (for custom scenarios):
```apex
new BulkStatusUpdateQueueable(agentId, targetDate, 'New', 'Confirmed', 200, 0);
// agentId, date, fromStatus, toStatus, batchSize, offset
```

**Chaining:** If the result set equals `batchSize`, a new Queueable job is automatically chained via `System.enqueueJob()` with an incremented offset — handles large datasets without hitting DML limits.

---

### Platform Event: `Change_Service_Appointment__e`
**Purpose:** Publishes a message whenever the `Status__c` field of a `Service_Appointment__c` record changes.


**Fields:**
| Field | Type | Description |
|---|---|---|
| `Appointment_Id__c` | Text | ID of the changed appointment |
| `Old_status__c` | Text | Previous status value |
| `New_Status__c` | Text | New status value |
| `Changed_by_Id__c` | Text | ID of the user who made the change |
| `Changed_on__c` | DateTime | Timestamp of the change |

### Event Flow
```
Service_Appointment__c (after update)
  → ServiceAppointmentTrigger
  → ServiceAppointmentTriggerHandler.onAfterUpdate()
  → EventBus.publish(Change_Service_Appointment__e)
  → AppointmentStatusChangedTrigger (after insert)
  → AppointmentStatusChangedTriggerHandler.onAfterInsert()
  → INSERT Appointment_Status_Log__c
```

### Log Object: `Appointment_Status_Log__c`
Stores a history record for every status change:
- `Service_Appointment__c` — Lookup to the changed record
- `Old_Status__c` — Previous status
- `New_Status__c` — New status
- `Changed_by__c` — Lookup to User who triggered the change
- `Date_Changes__c` — DateTime of the change

---

## 2.6. Triggers

### `ServiceAppointmentTrigger`
- **Object:** `Service_Appointment__c`
- **Events:** `after update`
- **Handler:** `ServiceAppointmentTriggerHandler`
- **Logic:** Detects `Status__c` changes and publishes `Change_Service_Appointment__e` Platform Events in bulk.
- **Bulk-safe:** Collects all events in a `List` before calling `EventBus.publish()` — no DML inside loops.
- **Security:** Handler class uses `with sharing` to respect record-level access.

### `AppointmentStatusChangedTrigger`
- **Object:** `Change_Service_Appointment__e` (Platform Event)
- **Events:** `after insert`
- **Handler:** `AppointmentStatusChangedTriggerHandler`
- **Logic:** For each received event, creates an `Appointment_Status_Log__c` record.
- **Bulk-safe:** Collects log records in a `List` before a single `insert` DML call.

---

## 2.5. Apex, OOP & SOLID

### Architecture Overview

```
«interface»              «interface»
IEventPublisher          IAppointmentService
       ↑                        ↑
PlatformEventPublisher   AppointmentService
       ↑                        ↑
       └──── ServiceAppointmentTriggerHandler (DI constructor)
                                ↑
                   AgentScheduleController (static field)
                   CustomerAppointmentController (static field)

«abstract»
BaseTriggerHandler
       ↑
       ├── ServiceAppointmentTriggerHandler
       └── AppointmentStatusChangedTriggerHandler
```

### Interfaces

#### `IAppointmentService`
Defines the contract for all appointment business operations:
- `getAppointmentsForAgent()`
- `getAppointmentsForCustomer()`
- `updateAppointments()`
- `cancelAppointments()`
- `validateNoDoubleBooking()`

**Used by:** `AgentScheduleController`, `CustomerAppointmentController`, `ServiceAppointmentTriggerHandler` (injected via constructor).

#### `IEventPublisher`
Defines a single method: `publish(List<SObject> events)`.

**Used by:** `ServiceAppointmentTriggerHandler` (injected via constructor).  
**Implemented by:** `PlatformEventPublisher` (wraps `EventBus.publish()`).

### Abstract Class: `BaseTriggerHandler`
Implements the **Template Method** design pattern. Dispatches Trigger context events to virtual hook methods (`onBeforeInsert`, `onBeforeUpdate`, `onAfterInsert`, `onAfterUpdate`).

**Extended by:** `ServiceAppointmentTriggerHandler`, `AppointmentStatusChangedTriggerHandler`.

**Usage in every trigger:**
```apex
new MyHandler().execute(); // delegates to the correct virtual hook
```

### SOLID Principles Applied

| Principle | Implementation |
|---|---|
| **S** — Single Responsibility | `AppointmentService` owns business logic only; `PlatformEventPublisher` publishes events only; controllers only expose `@AuraEnabled` methods; `BaseTriggerHandler` only dispatches Trigger context. |
| **O** — Open/Closed | New notification channel = new class implementing `IEventPublisher`. No existing handler changes. New trigger events = override a virtual method in a subclass. |
| **L** — Liskov Substitution | Any `IEventPublisher` or `IAppointmentService` implementation can replace the concrete class without breaking callers. Mock classes in tests demonstrate this. |
| **I** — Interface Segregation | Two small, focused interfaces instead of one large one: `IAppointmentService` (business logic) and `IEventPublisher` (event publishing). |
| **D** — Dependency Inversion | `ServiceAppointmentTriggerHandler` depends on `IEventPublisher` and `IAppointmentService` — not on `EventBus` or `AppointmentService` directly. Controllers use `@TestVisible private static IAppointmentService` — mockable in tests. |

### Dependency Injection

`ServiceAppointmentTriggerHandler` has two constructors:
```apex
// DI constructor — used in tests to inject mocks
public ServiceAppointmentTriggerHandler(IEventPublisher pub, IAppointmentService svc) { ... }

// Default constructor — wires real implementations for production
public ServiceAppointmentTriggerHandler() {
    this(new PlatformEventPublisher(), new AppointmentService());
}
```

Controllers use `@TestVisible static IAppointmentService` fields:
```apex
@TestVisible
private static IAppointmentService appointmentService = new AppointmentService();
```
This allows test classes to inject mock implementations without modifying production code.

### Test Coverage
- **`AppointmentServiceTest`** — covers `getAppointmentsForCustomer` (ASC/DESC), `cancelAppointments`, `validateNoDoubleBooking` (positive/negative), `updateAppointments`.
- **`ServiceAppointmentTriggerHandlerTest`** — covers status-change event publishing, no-event on same status, and double-booking validation call — using injected mock classes (`MockEventPublisher`, `MockAppointmentService`).

