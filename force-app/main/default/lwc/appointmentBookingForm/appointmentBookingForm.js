import { LightningElement, api } from 'lwc';
import SERVICE_APPOINTMENT from "@salesforce/schema/Service_Appointment__c";
import CUSTOMER_FIELD from "@salesforce/schema/Service_Appointment__c.Customer__c";
import AGENT_FIELD from "@salesforce/schema/Service_Appointment__c.Service_Agent__c";
import DATE_FIELD from "@salesforce/schema/Service_Appointment__c.Appointment_Date_Time__c";
import STATUS_FIELD from "@salesforce/schema/Service_Appointment__c.Status__c";
import DESCRIPTION_FIELD from "@salesforce/schema/Service_Appointment__c.Description__c";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AppointmentBookingForm extends LightningElement {
    @api recordId;
    @api objectApiName;

    appointmentObject = SERVICE_APPOINTMENT.objectApiName;

    fields = {
        customer: CUSTOMER_FIELD.fieldApiName,
        agent: AGENT_FIELD.fieldApiName,
        date: DATE_FIELD.fieldApiName,
        status: STATUS_FIELD.fieldApiName,
        description: DESCRIPTION_FIELD.fieldApiName
    };

    get isContactRecord() {
        return this.objectApiName === 'Contact' && this.recordId;
    }

    handleSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Super! 🔥',
                message: 'Record created successfully! ID: ' + event.detail.id,
                variant: 'success',
            })
        );

        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach(field => {
                if (field.fieldName !== this.fields.customer || !this.isContactRecord) {
                    field.reset();
                }
            });
        }
    }
}
