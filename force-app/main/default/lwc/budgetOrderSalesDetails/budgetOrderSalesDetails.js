import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME from '@salesforce/schema/User.Profile.Name';
import DC_BUDGET_OBJECT from '@salesforce/schema/DC_Budget__c';
import getPicklistValuesLwc from '@salesforce/apex/DcBudgetLWCController.getPicklistValuesLwc';
import getDCBudgetLineItems from '@salesforce/apex/DcBudgetLWCController.getDCBudgetLineItems';
import updateEditedBudgetLineItems from '@salesforce/apex/DcBudgetLWCController.updateEditedBudgetLineItems';
import getBudgetDetails from '@salesforce/apex/DcBudgetLWCController.getBudgetDetails';

const MONTHS = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'];

const LINE_TYPES = ['Order', 'Sales'];

const includesText = (text, term) => !term || (text || '').toLowerCase().includes(term.toLowerCase());

const sumOf = (records, field) => records.reduce((sum, record) => sum + (parseFloat(record[field]) || 0), 0);

export default class BudgetOrderSalesDetails extends LightningElement {
    @api recordId;

    records = [];
    // Pending changes by line item Id. A line edited in both Order and Sales is saved
    // once, because saving can create a new version of the line.
    edits = {};
    filter = { customer: '', pmg: '', orderType: '' };
    orderTypeOptions = [];
    profileName = '';
    advanceRecordTypeId;
    pmgRecordTypeId;
    currencyCode = '';
    isLoading = false;

    @wire(getRecord, { recordId: USER_ID, fields: [PROFILE_NAME] })
    wiredUser({ data, error }) {
        if (data) {
            this.profileName = data.fields.Profile.value?.fields.Name.value || '';
        } else if (error) {
            console.error('Error reading the user profile', error);
        }
    }

    @wire(getObjectInfo, { objectApiName: DC_BUDGET_OBJECT })
    wiredBudgetInfo({ data, error }) {
        if (data) {
            const recordTypes = Object.values(data.recordTypeInfos);
            this.advanceRecordTypeId = recordTypes.find((type) => type.name === 'Advance Budget')?.recordTypeId;
            this.pmgRecordTypeId = recordTypes.find((type) => type.name === 'PMG')?.recordTypeId;
        } else if (error) {
            console.error('Error reading the budget record types', error);
        }
    }

    @wire(getPicklistValuesLwc, { ObjectApi_name: 'DC_Budget_Line_Items__c', Field_name: 'Order_Type__c' })
    wiredOrderTypes({ data, error }) {
        if (data) {
            this.orderTypeOptions = [
                { label: 'None', value: '' },
                ...data.map(({ label, value }) => ({ label, value }))
            ];
        } else if (error) {
            console.error('Error reading the order types', error);
        }
    }

    @wire(getBudgetDetails, { recordId: '$recordId' })
    wiredCurrency({ data, error }) {
        if (data) {
            this.currencyCode = data;
        } else if (error) {
            console.error('Error reading the budget currency', error);
            this.currencyCode = '';
        }
    }

    connectedCallback() {
        this.loadRecords();
    }

    loadRecords() {
        this.isLoading = true;
        getDCBudgetLineItems({ DCBudgetId: this.recordId, UserId: USER_ID })
            .then((result) => {
                this.records = result || [];
            })
            .catch((error) => {
                console.error('Error fetching budget line items', error);
                this.records = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    get filteredRecords() {
        return this.records.filter((record) => this.matchesFilter(record));
    }

    // Each budget line gives two table rows: Order, then Sales. The line's details
    // appear only on the Order row and span both.
    get tableRows() {
        return this.filteredRecords.flatMap((record, index) =>
            LINE_TYPES.map((type) => this.toTableRow(record, index, type))
        );
    }

    get hasRows() {
        return this.filteredRecords.length > 0;
    }

    get totalOrderText() {
        return this.formatTotal('Total_Order__c');
    }

    get totalSalesText() {
        return this.formatTotal('Total_Sales__c');
    }

    get hasEdits() {
        return this.editedLineCount > 0;
    }

    get editedLineCount() {
        return Object.keys(this.edits).length;
    }

    get editSummary() {
        return `${this.editedLineCount} budget ${this.editedLineCount === 1 ? 'line has' : 'lines have'} unsaved changes`;
    }

    formatTotal(field) {
        return `${this.currencyCode} ${sumOf(this.filteredRecords, field).toLocaleString('en-IN')}`;
    }

    matchesFilter(record) {
        const { customer, pmg, orderType } = this.filter;
        return (
            includesText(record.Customer__r?.Name, customer) &&
            includesText(record.PMG_Master__r?.Name, pmg) &&
            (!orderType || (record.Order_Type__c || 'N/A') === orderType)
        );
    }

    toTableRow(record, index, type) {
        const isOrder = type === 'Order';
        const disabled = !this.isEditable(record);
        const pending = this.edits[record.Id] || {};
        const baseClass = isOrder ? 'line-order' : 'line-sales';
        return {
            key: `${record.Id}-${type}`,
            Id: record.Id,
            isFirstRow: isOrder,
            rowClass: record.Created_by_PMG__c ? `${baseClass} red-font` : baseClass,
            type,
            flagClass: isOrder ? 'type-flag type-flag-order' : 'type-flag type-flag-sales',
            serialNumber: index + 1,
            name: record.Name,
            pmg: record.PMG_Master__r?.Name || 'N/A',
            productGroup: record.PG_Master__r?.Name || 'N/A',
            applicationType: record.Application_Type_Master__r?.Name || 'N/A',
            orderType: record.Order_Type__c || 'N/A',
            customerName: record.Customer__r?.Name,
            customerLabel: record.Customer_Name__c,
            partList: record.Part_List__r?.Name || 'N/A',
            productName: record.Product__r?.Name || 'N/A',
            description: record.Description__c,
            total: record[`Total_${type}__c`] || 0,
            months: MONTHS.map((month) => {
                const field = `${month}_${type}__c`;
                const isEdited = field in pending;
                return {
                    field,
                    label: `${month.toUpperCase()} ${type}`,
                    value: isEdited ? pending[field] : record[field] || 0,
                    inputClass: isEdited ? 'slds-input month-input month-input-edited' : 'slds-input month-input',
                    disabled
                };
            })
        };
    }

    // Same rules as showOrderDetails and showSalesDetails.
    isEditable(record) {
        const profile = this.profileName;
        const status = record.Budget__r?.Status__c;
        const recordTypeId = record.Budget__r?.RecordTypeId;
        const isPmgApproved = record.Is_PMG_Label_Approved__c;

        return (
            ((profile === 'System Administrator' || profile === 'Sales') && recordTypeId === this.advanceRecordTypeId) ||
            (profile === 'Sales' && status === 'Draft' && !isPmgApproved) ||
            (profile === 'Regional Manager' && status === 'Submitted' && !isPmgApproved) ||
            (profile === 'Ex-Com Leadership' && status === '1st Level Approved' && !isPmgApproved) ||
            (profile === 'PMG' && status === '2nd Level Approved' && !isPmgApproved) ||
            (profile === 'Leadership' && status === '3rd Level Approved' && isPmgApproved) ||
            (profile === 'System Administrator' && status !== '4th Level Approved') ||
            (profile === 'PMG' && recordTypeId === this.pmgRecordTypeId)
        );
    }

    handleFilterChange(event) {
        this.filter = { ...this.filter, [event.target.dataset.filter]: event.target.value };
    }

    handleInlineEdit(event) {
        const { id, field } = event.target.dataset;
        let value = event.target.value;

        if (value < 0) {
            value = -value;
            event.target.value = value;
            this.showToast('Warning', 'Negative values are not allowed.', 'warning');
        }

        this.edits = { ...this.edits, [id]: { ...this.edits[id], [field]: value } };
    }

    handleSave() {
        this.isLoading = true;
        // Send the record as Apex returned it: it needs the whole line, including
        // Budget__r, because a line created by another user is cloned as a new version.
        const budgetLineItems = this.records
            .filter((record) => this.edits[record.Id])
            .map((record) => ({ ...record, ...this.edits[record.Id] }));

        updateEditedBudgetLineItems({ budgetLineItems })
            .then(() => {
                this.showToast('Success', 'Records updated successfully.', 'success');
                this.edits = {};
                window.location.reload();
            })
            .catch((error) => {
                console.error('Error saving records', error);
                this.showToast('Error', `Error saving records: ${error?.body?.message || error?.message}`, 'error');
                this.isLoading = false;
            });
    }

    handleCancel() {
        this.edits = {};
        this.showToast('Info', 'Changes have been discarded', 'info');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}