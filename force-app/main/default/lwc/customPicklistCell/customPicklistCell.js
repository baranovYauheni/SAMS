import { LightningElement, api } from 'lwc';

export default class CustomPicklistCell extends LightningElement {
    @api value;
    @api recordId;
    @api options = [];

    handleChange(event) {
        const newValue = event.detail.value;
        this.dispatchEvent(
            new CustomEvent('statuschange', {
                detail: {
                    recordId: this.recordId,
                    value: newValue
                },
                bubbles: true,
                composed: true
            })
        );
    }
}