import { LightningElement, track, wire } from 'lwc';
import getServiceAgents from '@salesforce/apex/AgentScheduleController.getServiceAgents';
import getAppointments from '@salesforce/apex/AgentScheduleController.getAppointments';
import updateAppointments from '@salesforce/apex/AgentScheduleController.updateAppointments';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AgentScheduleTable extends LightningElement {
    @track agentOptions = [];
    @track appointments = [];     // Displayed rows (includes local draft changes)
    @track error;

    // Keeps track of which rows were edited and what changed
    // Structure: { [recordId]: { Id, Status__c?, Appointment_Date_Time__c? } }
    changedRecords = {};

    selectedAgentId = '';
    selectedStatus = '';
    startDate = null;
    endDate = null;

    // True when there are unsaved edits
    get hasPendingChanges() {
        return Object.keys(this.changedRecords).length > 0;
    }

    // Status picklist options (matches Status__c field values)
    get statusOptions() {
        return [
            { label: 'New', value: 'New' },
            { label: 'Confirmed', value: 'Confirmed' },
            { label: 'Completed', value: 'Completed' },
            { label: 'Cancelled', value: 'Cancelled' }
        ];
    }

    // Filter combobox options (includes "All")
    get statusFilterOptions() {
        return [{ label: 'All', value: '' }, ...this.statusOptions];
    }

    // ── Wire: load agent list ────────────────────────────────────────
    @wire(getServiceAgents)
    wiredAgents({ error, data }) {
        if (data) {
            this.agentOptions = data.map(user => ({ label: user.Name, value: user.Id }));
        } else if (error) {
            this.error = error;
        }
    }

    // ── Load appointments imperatively ────────────────────────────────
    loadAppointments() {
        if (!this.selectedAgentId) {
            this.appointments = [];
            return;
        }
        this.changedRecords = {};

        getAppointments({
            agentId: this.selectedAgentId,
            status: this.selectedStatus,
            startDate: this.startDate,
            endDate: this.endDate
        })
        .then(result => {
            this.appointments = result.map(record => ({
                ...record,
                customerName: record.Customer__r ? record.Customer__r.Name : '',
                // Format DateTime for the datetime-local input (needs "YYYY-MM-DDTHH:MM" format)
                dateInputValue: record.Appointment_Date_Time__c
                    ? record.Appointment_Date_Time__c.slice(0, 16)  // trim seconds/ms
                    : ''
            }));
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
            this.appointments = [];
            this.showToast('Error loading records', error.body?.message ?? error.message, 'error');
        });
    }

    // ── Cell edit handlers ────────────────────────────────────────────

    // Status combobox changed inside a cell
    handleStatusCellChange(event) {
        const rowId = event.target.dataset.id;
        const newValue = event.detail.value;

        // Update displayed value immediately (optimistic UI)
        this.appointments = this.appointments.map(a =>
            a.Id === rowId ? { ...a, Status__c: newValue } : a
        );

        // Track the change
        this.changedRecords = {
            ...this.changedRecords,
            [rowId]: { ...this.changedRecords[rowId], Id: rowId, Status__c: newValue }
        };
    }

    // Date input changed inside a cell
    handleDateCellChange(event) {
        const rowId = event.target.dataset.id;
        const newValue = event.target.value;  // "YYYY-MM-DDTHH:MM"

        // Update displayed value immediately
        this.appointments = this.appointments.map(a =>
            a.Id === rowId ? { ...a, dateInputValue: newValue } : a
        );

        // Track the change (convert to ISO string for Apex)
        const isoValue = newValue ? new Date(newValue).toISOString() : null;
        this.changedRecords = {
            ...this.changedRecords,
            [rowId]: { ...this.changedRecords[rowId], Id: rowId, Appointment_Date_Time__c: isoValue }
        };
    }

    // ── Save / Cancel ─────────────────────────────────────────────────

    handleSaveAll() {
        const changes = Object.values(this.changedRecords);

        updateAppointments({ changes })
        .then(() => {
            this.showToast('Saved!', changes.length + ' record(s) updated successfully.', 'success');
            this.loadAppointments();   // Reload from server
        })
        .catch(error => {
            this.showToast('Error saving', error.body?.message ?? error.message, 'error');
        });
    }

    handleCancelChanges() {
        this.loadAppointments();   // Discard local drafts, reload from server
    }

    // ── Filter handlers ───────────────────────────────────────────────

    handleAgentChange(event) {
        this.selectedAgentId = event.detail.value;
        this.loadAppointments();
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        this.loadAppointments();
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
        this.loadAppointments();
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
        this.loadAppointments();
    }

    // ── Utility ───────────────────────────────────────────────────────
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
