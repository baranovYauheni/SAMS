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

The following Lightning Web Components (LWC) have been created and planned for the Service Appointment Management System:

### 1. `appointmentBookingForm`
**Purpose:** A form to create new `Service_Appointment__c` records.
**Features:**
- **Universal Placement:** Designed to be placed on App Pages, Home Pages, Utility Bar, and Contact Record Pages.
- **Context Awareness:** Automatically pre-fills and locks the `Customer__c` field if placed on a Contact Record Page. If placed elsewhere, allows manual selection of a customer.
- **Data Entry & Validation:** Uses standard `lightning-record-edit-form` to capture Agent, Date/Time, Status, and Description, automatically leveraging Salesforce's built-in field validation.
- **User Feedback:** Displays a success toast notification upon record creation and resets the form for the next entry (while keeping the pre-filled context if applicable).

### 2. `agentScheduleTable`
**Purpose:** Displays and manages appointments for a selected Service Agent.
**Features:**
- **Data Table:** Shows scheduled appointments (Customer Name, Date/Time, Status, Description) in a `lightning-datatable`.
- **Filtering:** Includes functionality to filter appointments by Date range and Status.
- **Inline Editing:** Allows agents from the UI to quickly update the 'Status' or 'Date/Time' directly within the table interface.

### 3. `customerAppointmentList` (Planned)
**Purpose:** Displays a list of all appointments for a specific customer.
**Features:**
- **Contextual View:** Automatically pulls the `recordId` from the Contact Record Page to fetch and filter appointments.
- **Sorting:** Allows sorting the list of appointments by Date.
- **Quick Actions:** Includes a "Cancel" button to quickly change the status of an appointment to 'Cancelled' without reloading the page.
