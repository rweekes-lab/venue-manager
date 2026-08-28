import { LightningElement, api, track } from 'lwc';

const RATE_UNIT_OPTIONS = [
    { label: 'Per Hour', value: 'Per Hour' },
    { label: 'Per Day', value: 'Per Day' },
    { label: 'Per Event', value: 'Per Event' }
];

/**
 * Modal form for creating or editing a single venue. Works on a local copy of
 * the record and emits a `save` event with the edited object; the parent owns
 * persistence. Emits `cancel` when dismissed.
 */
export default class VenueForm extends LightningElement {
    @track record = {};
    rateUnitOptions = RATE_UNIT_OPTIONS;

    // Copy the incoming record so edits stay local until save.
    @api
    get venue() {
        return this.record;
    }
    set venue(value) {
        this.record = value ? { ...value } : {};
    }

    @api isSaving = false;

    get isEdit() {
        return Boolean(this.record && this.record.Id);
    }

    get header() {
        return this.isEdit ? 'Edit Venue' : 'New Venue';
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        const type = event.target.type;
        const value =
            type === 'checkbox' ? event.target.checked : event.target.value;
        this.record = { ...this.record, [field]: value };
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleSave() {
        if (!this.reportValidity()) {
            return;
        }
        // Normalize empty strings to null so we don't write blank text.
        const cleaned = { ...this.record };
        Object.keys(cleaned).forEach((k) => {
            if (cleaned[k] === '') {
                cleaned[k] = null;
            }
        });
        this.dispatchEvent(new CustomEvent('save', { detail: { venue: cleaned } }));
    }

    // Validate all lightning-input/-textarea/-combobox fields in the form.
    reportValidity() {
        const inputs = [
            ...this.template.querySelectorAll(
                'lightning-input, lightning-textarea, lightning-combobox'
            )
        ];
        return inputs.reduce((valid, input) => {
            const fieldValid = input.reportValidity();
            return valid && fieldValid;
        }, true);
    }
}
