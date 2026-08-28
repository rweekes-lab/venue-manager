import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getVenues from '@salesforce/apex/VenueController.getVenues';
import saveVenue from '@salesforce/apex/VenueController.saveVenue';
import deleteVenue from '@salesforce/apex/VenueController.deleteVenue';

/**
 * Top-level Venue Manager. Owns the list of venues and the edit dialog,
 * wiring the child list and form components together and talking to Apex.
 */
export default class VenueManager extends LightningElement {
    @track searchTerm = '';
    @track selectedVenue = null; // the record being edited/created, or null
    @track showForm = false;
    isSaving = false;

    // Cached wire result so we can imperatively refresh after DML.
    wiredVenuesResult;
    @track venues = [];
    error;

    @wire(getVenues, { searchTerm: '$searchTerm' })
    wiredVenues(result) {
        this.wiredVenuesResult = result;
        if (result.data) {
            this.venues = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = this.reduceError(result.error);
            this.venues = [];
        }
    }

    get hasVenues() {
        return this.venues && this.venues.length > 0;
    }

    get venueCount() {
        return this.venues ? this.venues.length : 0;
    }

    handleSearch(event) {
        // Debounce so we don't fire a wire on every keystroke.
        window.clearTimeout(this.searchDelay);
        const value = event.target.value;
        this.searchDelay = setTimeout(() => {
            this.searchTerm = value;
        }, 300);
    }

    handleNew() {
        this.selectedVenue = {}; // empty record → insert
        this.showForm = true;
    }

    handleEdit(event) {
        const venueId = event.detail.venueId;
        const match = this.venues.find((v) => v.Id === venueId);
        // Clone so in-flight edits don't mutate the list before save.
        this.selectedVenue = match ? { ...match } : {};
        this.showForm = true;
    }

    handleCloseForm() {
        this.showForm = false;
        this.selectedVenue = null;
    }

    async handleSave(event) {
        this.isSaving = true;
        const record = event.detail.venue;
        try {
            await saveVenue({ venue: record });
            this.toast('Success', 'Venue saved.', 'success');
            this.showForm = false;
            this.selectedVenue = null;
            await refreshApex(this.wiredVenuesResult);
        } catch (e) {
            this.toast('Error saving venue', this.reduceError(e), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    async handleDelete(event) {
        const venueId = event.detail.venueId;
        // eslint-disable-next-line no-alert
        const confirmed = window.confirm('Delete this venue? This cannot be undone.');
        if (!confirmed) {
            return;
        }
        try {
            await deleteVenue({ venueId });
            this.toast('Deleted', 'Venue removed.', 'success');
            await refreshApex(this.wiredVenuesResult);
        } catch (e) {
            this.toast('Error deleting venue', this.reduceError(e), 'error');
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // Flattens the various shapes an Apex/LDS error can take into a string.
    reduceError(error) {
        if (Array.isArray(error.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        if (error.body && typeof error.body.message === 'string') {
            return error.body.message;
        }
        return error.message || 'Unknown error';
    }
}
