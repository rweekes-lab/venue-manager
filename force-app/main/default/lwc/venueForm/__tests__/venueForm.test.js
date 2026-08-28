import { createElement } from 'lwc';
import VenueForm from 'c/venueForm';

describe('c-venue-form', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    function createComponent(props = {}) {
        const element = createElement('c-venue-form', { is: VenueForm });
        Object.assign(element, props);
        document.body.appendChild(element);
        return element;
    }

    it('shows the New Venue title for a blank record', () => {
        const element = createComponent({ venue: {} });
        return Promise.resolve().then(() => {
            const title = element.shadowRoot.querySelector('.slds-modal__title');
            expect(title.textContent).toBe('New Venue');
        });
    });

    it('shows the Edit Venue title when the record has an Id', () => {
        const element = createComponent({ venue: { Id: 'a01', Name: 'Grand Hall' } });
        return Promise.resolve().then(() => {
            const title = element.shadowRoot.querySelector('.slds-modal__title');
            expect(title.textContent).toBe('Edit Venue');
        });
    });

    it('dispatches cancel when Cancel is clicked', () => {
        const element = createComponent({ venue: {} });
        const handler = jest.fn();
        element.addEventListener('cancel', handler);
        return Promise.resolve().then(() => {
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            const cancel = [...buttons].find((b) => b.label === 'Cancel');
            cancel.click();
            expect(handler).toHaveBeenCalled();
        });
    });

    it('does not mutate the original record passed in', () => {
        const original = { Id: 'a01', Name: 'Grand Hall' };
        const element = createComponent({ venue: original });
        return Promise.resolve().then(() => {
            // The component works on a clone; the source object is untouched.
            expect(element.venue).not.toBe(original);
            expect(element.venue.Name).toBe('Grand Hall');
        });
    });
});
