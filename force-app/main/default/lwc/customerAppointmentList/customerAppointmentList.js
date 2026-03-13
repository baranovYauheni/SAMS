import { LightningElement, api, track } from 'lwc';
import getAppointmentsForCustomer from '@salesforce/apex/CustomerAppointmentController.getAppointmentsForCustomer';
import cancelAppointments from '@salesforce/apex/CustomerAppointmentController.cancelAppointments';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CustomerAppointmentList extends LightningElement {
    @api recordId;

    @track appointments = [];
    @track isLoading = false;
    @track error;

    sortOrder = 'ASC';
    get sortLabel() {
        return this.sortOrder === 'ASC' ? '↑ Date (Oldest first)' : '↓ Date (Newest first)';
    }
    get sortIconName() {
        return this.sortOrder === 'ASC' ? 'utility:arrowup' : 'utility:arrowdown';
    }

    connectedCallback() {
        this.loadAppointments();
    }

    loadAppointments() {
        this.isLoading = true;
        getAppointmentsForCustomer({
            contactId: this.recordId,
            sortOrder: this.sortOrder
        })
            .then(result => {
                this.appointments = result.map(record => ({
                    ...record,
                    agentName: record.Service_Agent__r ? record.Service_Agent__r.Name : '—',
                    isCancellable: record.Status__c !== 'Cancelled' && record.Status__c !== 'Completed',
                    statusClass: this.getStatusClass(record.Status__c),
                    recordUrl: `/lightning/r/Service_Appointment__c/${record.Id}/view`,
                    formattedDate: record.Appointment_Date_Time__c
                        ? new Date(record.Appointment_Date_Time__c).toLocaleString('en-US', {
                            month: 'short', day: 'numeric', year: 'numeric',
                            hour: '2-digit', minute: '2-digit'
                        })
                        : '—'
                }));
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.showToast('Error', error.body?.message ?? error.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    getStatusClass(status) {
        const map = {
            'New': 'slds-badge slds-badge_lightest',
            'Confirmed': 'slds-badge slds-theme_success',
            'Completed': 'slds-badge',
            'Cancelled': 'slds-badge slds-theme_error'
        };
        return map[status] || 'slds-badge slds-badge_lightest';
    }

    handleToggleSort() {
        this.sortOrder = this.sortOrder === 'ASC' ? 'DESC' : 'ASC';
        this.loadAppointments();
    }

    handleCancel(event) {
        const appointmentId = event.target.dataset.id;

        cancelAppointments({ appointmentIds: [appointmentId] })
            .then(() => {
                this.showToast('Cancelled', 'The appointment has been cancelled.', 'success');
                this.loadAppointments();
            })
            .catch(error => {
                this.showToast('Error', error.body?.message ?? error.message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get isEmpty() {
        return !this.isLoading && this.appointments.length === 0;
    }
}