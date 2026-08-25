import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getOpportunityInfo  from '@salesforce/apex/CloneProposalFormController.getOpportunityInfo';
import cloneRecord         from '@salesforce/apex/CloneProposalFormController.cloneRecord';
import searchOpportunities from '@salesforce/apex/CloneProposalFormController.searchOpportunities';

export default class CloneProposalForm extends NavigationMixin(LightningElement) {
    @api recordId;

    @track isLoading          = true;
    @track isClosed           = false;
    @track oppName            = '';
    @track oppStage           = '';
    @track newOpportunityId   = null;
    @track newOpportunityName = '';
    @track oppError           = false;
    @track cloning            = false;
    @track errorMessage       = null;
    @track customerNameId     = null;

    // Search
    @track searchTerm    = '';
    @track searchResults = [];
    @track showDropdown  = false;
    @track searching     = false;
    searchTimeout        = null;

    @wire(getOpportunityInfo, { proposalFormId: '$recordId' })
    wiredOppInfo({ data, error }) {
        if (data) {
            this.isClosed       = data.isClosed;
            this.oppName        = data.opportunityName || '';
            this.oppStage       = data.stageName || '';
            this.customerNameId = data.customerNameId || null;

            if (!data.isClosed) {
                setTimeout(() => {
                    this.doClone(null);
                }, 0);
            } else {
                this.isLoading = false;
            }
        } else if (error) {
            this.isLoading    = false;
            this.errorMessage = this.extractErrorMessage(error);
        }
    }

    handleSearchInput(event) {
        this.searchTerm         = event.target.value;
        this.newOpportunityId   = null;
        this.newOpportunityName = '';
        this.oppError           = false;
        this.errorMessage       = null;

        clearTimeout(this.searchTimeout);

        if (this.searchTerm.length < 1) {
            this.searchResults = [];
            this.showDropdown  = false;
            this.searching     = false;  // reset spinner when input cleared
            return;
        }

        this.searching = true;
        this.searchTimeout = setTimeout(() => {
            searchOpportunities({ keyword: this.searchTerm, accountId: this.customerNameId })
                .then(results => {
                    this.searchResults = results;
                    this.showDropdown  = results.length > 0;
                    this.searching     = false;
                })
                .catch(err => {
                    this.searching    = false;
                    this.errorMessage = this.extractErrorMessage(err);
                });
        }, 300);
    }

    handleSelectOpportunity(event) {
        this.newOpportunityId   = event.currentTarget.dataset.id;
        this.newOpportunityName = event.currentTarget.dataset.name;
        this.searchTerm         = event.currentTarget.dataset.name;
        this.showDropdown       = false;
        this.oppError           = false;
        this.errorMessage       = null;
    }

    handleClearSelection() {
        clearTimeout(this.searchTimeout);  // cancel any pending search
        this.newOpportunityId   = null;
        this.newOpportunityName = '';
        this.searchTerm         = '';
        this.searchResults      = [];
        this.showDropdown       = false;
        this.searching          = false;   // reset spinner
        this.errorMessage       = null;
        this.oppError           = false;
    }

    handleClone() {
        this.errorMessage = null;
        if (!this.newOpportunityId) {
            this.oppError = true;
            return;
        }
        this.doClone(this.newOpportunityId);
    }

    doClone = async (newOppId) => {
        this.cloning      = true;
        this.errorMessage = null;
        try {
            const newId = await cloneRecord({
                sourceId        : this.recordId,
                newOpportunityId: newOppId
            });
            this.dispatchEvent(new ShowToastEvent({
                title   : 'Success',
                message : 'Proposal Form cloned successfully!',
                variant : 'success'
            }));
            this.dispatchEvent(new CloseActionScreenEvent());
            this[NavigationMixin.Navigate]({
                type       : 'standard__recordPage',
                attributes : { recordId: newId, actionName: 'view' }
            });
        } catch (e) {
            this.errorMessage = this.extractErrorMessage(e);
            this.cloning      = false;
            this.isLoading    = false;
        } finally {
            this.cloning = false;
        }
    }

    extractErrorMessage(error) {
        if (!error) return 'An unexpected error occurred.';
        if (error.body?.message) return error.body.message;
        if (Array.isArray(error.body?.output?.errors) && error.body.output.errors.length > 0)
            return error.body.output.errors.map(e => e.message).join('\n');
        if (error.body?.output?.fieldErrors) {
            const fe = error.body.output.fieldErrors;
            return Object.keys(fe).map(f => fe[f].map(e => `${f}: ${e.message}`).join('\n')).join('\n');
        }
        if (Array.isArray(error.body) && error.body.length > 0) return error.body.map(e => e.message).join('\n');
        if (typeof error.message === 'string') return error.message;
        if (typeof error.body === 'string') return error.body;
        return 'An unexpected error occurred. Please contact your administrator.';
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    get cloneLabel()    { return this.cloning ? 'Cloning...' : 'Clone'; }
    get cloneDisabled() { return this.cloning || !this.newOpportunityId; }
    get isSelected()    { return !!this.newOpportunityId; }
    get noResults() {
        return !this.searching 
            && this.searchTerm.length > 0 
            && this.searchResults.length === 0 
            && !this.showDropdown;
    }
}