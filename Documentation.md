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

## 2.3. Asynchronous Processes — Platform Event

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
