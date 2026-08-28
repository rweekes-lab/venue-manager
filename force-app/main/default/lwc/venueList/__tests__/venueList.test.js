import { createElement } from 'lwc';
import VenueList from 'c/venueList';

const SAMPLE = [
    {
        Id: 'a01',
        Name: 'Grand Hall',
        City__c: 'San Francisco',
        State__c: 'CA',
        Capacity__c: 500,
        Active__c: true,
        Has_Parking__c: true,
        Has_AV__c: true,
        Tags__c: 'rooftop, historic'
    }
];

describe('c-venue-list', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    function createComponent(props = {}) {
        const element = createElement('c-venue-list', { is: VenueList });
        Object.assign(element, props);
        document.body.appendChild(element);
        return element;
    }

    it('renders the empty state when there are no venues', () => {
        const element = createComponent({ venues: [], hasVenues: false });
        return Promise.resolve().then(() => {
            const heading = element.shadowRoot.querySelector('h3');
            expect(heading.textContent).toBe('No venues yet');
        });
    });

    it('renders a card per venue with derived city/state', () => {
        const element = createComponent({ venues: SAMPLE, hasVenues: true });
        return Promise.resolve().then(() => {
            const cards = element.shadowRoot.querySelectorAll('article.venue-card');
            expect(cards.length).toBe(1);
            expect(element.shadowRoot.textContent).toContain('San Francisco, CA');
        });
    });

    it('dispatches an edit event carrying the venue id', () => {
        const element = createComponent({ venues: SAMPLE, hasVenues: true });
        const handler = jest.fn();
        element.addEventListener('edit', handler);
        return Promise.resolve().then(() => {
            const icons = [
                ...element.shadowRoot.querySelectorAll('lightning-button-icon')
            ];
            const editBtn = icons.find((i) => i.title === 'Edit');
            editBtn.click();
            expect(handler).toHaveBeenCalled();
            expect(handler.mock.calls[0][0].detail.venueId).toBe('a01');
        });
    });

    it('dispatches a delete event carrying the venue id', () => {
        const element = createComponent({ venues: SAMPLE, hasVenues: true });
        const handler = jest.fn();
        element.addEventListener('delete', handler);
        return Promise.resolve().then(() => {
            const icons = [
                ...element.shadowRoot.querySelectorAll('lightning-button-icon')
            ];
            const delBtn = icons.find((i) => i.title === 'Delete');
            delBtn.click();
            expect(handler.mock.calls[0][0].detail.venueId).toBe('a01');
        });
    });
});
