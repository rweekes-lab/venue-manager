import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

/**
 * Presentational list of venues rendered as cards. Emits `edit` and `delete`
 * events (carrying the venue Id) up to the parent, and navigates to a venue's
 * record page when its name is clicked. Holds no data of its own.
 */
export default class VenueList extends NavigationMixin(LightningElement) {
    @api venues = [];
    @api hasVenues = false;

    // Decorate each venue with view-only display helpers for the template.
    get decoratedVenues() {
        return (this.venues || []).map((v) => {
            const cityState = [v.City__c, v.State__c].filter(Boolean).join(', ');
            const amenities = [];
            if (v.Has_Parking__c) amenities.push('Parking');
            if (v.Has_Catering__c) amenities.push('Catering');
            if (v.Has_AV__c) amenities.push('A/V');
            if (v.Is_Accessible__c) amenities.push('Accessible');
            return {
                ...v,
                cityState,
                amenities,
                hasAmenities: amenities.length > 0,
                tagList: v.Tags__c
                    ? v.Tags__c.split(',').map((t) => t.trim()).filter(Boolean)
                    : [],
                statusLabel: v.Active__c ? 'Active' : 'Inactive',
                statusClass: v.Active__c
                    ? 'slds-badge slds-badge_success'
                    : 'slds-badge'
            };
        });
    }

    handleNavigate(event) {
        // Let the browser handle modifier-clicks (open in new tab) natively.
        if (event.metaKey || event.ctrlKey) {
            return;
        }
        event.preventDefault();
        const venueId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: venueId,
                objectApiName: 'Venue__c',
                actionName: 'view'
            }
        });
    }

    handleEdit(event) {
        const venueId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('edit', { detail: { venueId } }));
    }

    handleDelete(event) {
        const venueId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('delete', { detail: { venueId } }));
    }

    handleOpenSite(event) {
        const url = event.currentTarget.dataset.url;
        if (url) {
            window.open(url, '_blank', 'noopener');
        }
    }
}
