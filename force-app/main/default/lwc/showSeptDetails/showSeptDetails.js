import { LightningElement,track,wire,api } from 'lwc';
import getPicklistValuesLwc from '@salesforce/apex/DcBudgetLWCController.getPicklistValuesLwc';
import getDCBudgetLineItems from '@salesforce/apex/DcBudgetLWCController.getDCBudgetLineItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateBudgetLineItems from '@salesforce/apex/DcBudgetLWCController.updateBudgetLineItems';
import Id from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import DCBUDGET_OBJECT from "@salesforce/schema/DC_Budget__c";

export default class ShowSeptDetails extends LightningElement {
    @api recordId
    @track showTable = false;
    @track selectedOrderType = '';
    @track OrderTypeOptions = [];
    @track budgetLineItems = [];
    allBudgetLineItems = [];
    @track searchTerm = '';
    @track selectedOrderType = '';
    @track editedRecords = {};
    @track showButtons = false;
    @track isLoading = false;
    @track userProfileName = '';
    @track status =''
    @track isEditable = false
    @track AdvanceBudgetRecordTypeId;
    itemRecordtypeId
    PMGRecordTypeId
    @track searchTermPMG = '';

    // Fetch User Profile Information
    @wire(getRecord, { recordId: Id, fields: [ProfileName] })
    userDetails({ error, data }) {
        if (data) {
            console.log('profile data', JSON.stringify(data));
            if (data.fields.Profile.value != null) {
                this.userProfileName = data.fields.Profile.value.fields.Name.value;
            }
            console.log('User Profile:', this.userProfileName);

        } else if (error) {
            console.error('Error For Finding Profile Name:', error);
        }
    }

    @wire(getObjectInfo, { objectApiName: DCBUDGET_OBJECT })
    Function({ error, data }) {
        if (data) {
            let objArray = data.recordTypeInfos;
            for (let i in objArray) {
                if (objArray[i].name == "Advance Budget"){
                    this.AdvanceBudgetRecordTypeId = objArray[i].recordTypeId
                }
                if (objArray[i].name == "PMG"){
                    this.PMGRecordTypeId = objArray[i].recordTypeId
                }
            }
            
            console.log('Advance Record Type Id ', this.AdvanceBudgetRecordTypeId)
            console.log('PMG Record Type Id ', this.PMGRecordTypeId)

        } else if (error) {
            console.log(JSON.stringify(error))
            // perform your logic related to error 
        }
    };

    @wire(getPicklistValuesLwc, { ObjectApi_name: 'DC_Budget_Line_Items__c', Field_name: 'Order_Type__c' })
    handleOrderTypeOptions({ data, error }) {
        if (data) {
            console.log('Status Picklist Data:', JSON.stringify(data)); // Log to check structure
            // Map picklist values and prepend "None" option
            this.OrderTypeOptions = [
                { label: 'None', value: '' }, // Add "None" as the default option
                ...data.map(picklistValue => ({
                    label: picklistValue.label, // Use the label for display
                    value: picklistValue.value  // Use the API value for comparison
                }))
            ];
        } else if (error) {
            console.error(error);
        }
    }
    connectedCallback() {
        this.fetchBudgetLineItems();
    }

    fetchBudgetLineItems() {
        this.isLoading = true;
        getDCBudgetLineItems({ DCBudgetId: this.recordId , UserId: Id, ProfileName: this.userProfileName })
            .then((result) => {
                this.isLoading = false;
                if (result && result.length > 0) {
                    this.status = result[0].Budget__r.Status__c;
                    this.itemRecordtypeId = result[0].Budget__r.RecordTypeId;
                    this.allBudgetLineItems = result.map(item => ({
                        ...item,
                        Order_Type__c: item.Order_Type__c || 'N/A',
                        Sep_Order__c: item.Sep_Order__c || 0,
                        Sep_Sales__c: item.Sep_Sales__c || 0,
                        Total_Sales__c: item.Total_Sales__c || 0,
                        Total_Order__c: item.Total_Order__c || 0,
                        Part_List: item.Part_List__r?.Name || 'N/A',  // Use optional chaining
                        Application_Type_Master: item.Application_Type_Master__r?.Name || 'N/A', // Use optional chaining
                        PG_Master: item.PG_Master__r?.Name || 'N/A', // Use optional chaining
                       PMG_Master: item.PMG_Master__r?.Name || 'N/A', // Use optional chaining
                        Product_Name: item.Product__r?.Name || 'N/A',
                        isPMGApproved: item.Is_PMG_Label_Approved__c,
                    }));
                   
                    this.budgetLineItems = this.allBudgetLineItems;
                    this.CheckisEditable();
                    this.showTable = true; // Show the table when data exists
                } else {
                    this.budgetLineItems = [];
                    this.showTable = false; // Hide the table when there's no data
                }
            })
            .catch((error) => {
                this.isLoading = false;
                console.error('Error fetching budget line items:', error);
                this.budgetLineItems = [];
                this.showTable = false; // Hide the table when an error occurs
            });
    }
    CheckisEditable() {
        const profileName = this.userProfileName;
        const status = this.status;
        const recordTypeId = this.itemRecordtypeId;

        this.budgetLineItems = this.budgetLineItems.map((item) => {
            // Determine isDisabled based on profileName, recordTypeId, status, and isPMGApproved
            let isDisabled = true;
            // Profiles with unrestricted access based on record type
            const hasUnrestrictedAccess =
                (profileName === 'System Administrator' && recordTypeId === this.AdvanceBudgetRecordTypeId) ||
                (profileName === 'Sales' && recordTypeId === this.AdvanceBudgetRecordTypeId);

            // Profiles with conditional access based on status and PMG approval
            const hasConditionalAccess =
                (profileName === 'Sales' && status === 'Draft' && !item.isPMGApproved) ||
                (profileName === 'Regional Manager' && status === 'Submitted' && !item.isPMGApproved) ||
                (profileName === 'Leadership' && status === '1st Level Approved' && !item.isPMGApproved) ||
                (profileName === 'PMG' && status === '2nd Level Approved' && !item.isPMGApproved) ||
                (profileName === 'Ex-Com Leadership' && status === '3rd Level Approved' && item.isPMGApproved) ||
                (profileName === 'System Administrator' && status !== '4th Level Approved') ||
                (profileName === 'PMG' && recordTypeId === this.PMGRecordTypeId);

            if (hasUnrestrictedAccess == true || hasConditionalAccess == true) {
                console.log('Editable:', item.Name);
                isDisabled = false;
            } else {
                isDisabled = true;
                console.log('Not Editable:', item.Name);
            }

            return {
                ...item,
                isDisabled, // Add the computed isDisabled property to each record
            };
        });
    }
    
    handleSearch(event) {
        this.searchTerm = event.target.value
        this.filterResults();

    }
    handleOrderTypeChange(event) {
        this.selectedOrderType = event.target.value
        this.filterResults();
    }

    handleSearchPMG(event) {
        this.searchTermPMG = event.target.value
        this.filterResults();
    }

    filterResults() {
        if (!this.searchTerm && !this.selectedOrderType && !this.searchTermPMG) {
            // No filters applied, show all items
            this.budgetLineItems = this.allBudgetLineItems;
        } else {
            // Apply filters
            this.budgetLineItems = this.allBudgetLineItems.filter(item => {
                const matchesSearchTerm =
                    !this.searchTerm ||
                    (item.Customer__r.Name && item.Customer__r.Name.toLowerCase().includes(this.searchTerm.toLowerCase()));
                const matchesOrderType =
                    !this.selectedOrderType || item.Order_Type__c === this.selectedOrderType;
                const matchesSearchTermPMG =
                    !this.searchTermPMG ||
                    (item.PMG_Master && item.PMG_Master.toLowerCase().includes(this.searchTermPMG.toLowerCase()));
    
                return matchesSearchTerm && matchesOrderType && matchesSearchTermPMG;
            });
        }
    
        // Show the table only if there is data
        this.showTable = this.budgetLineItems.length > 0;
    }
    
    get budgetLineItemsWithIndex() {
        return this.budgetLineItems.map((item, index) => ({
            ...item,
            serialNumber: index + 1,
            isPMG: item.Created_by_PMG__c == true ? true : false,
            rowClass: this.getRowClass(item) // Add row class conditionally
        }));
    }
    
    getRowClass(record) {
        return record.Created_by_PMG__c ? 'red-font' : ''; // Add 'red-font' class if Created_by_PMG__c is true
    }
    handleInlineEdit(event) {
        const { id, field } = event.target.dataset;
        let value = event.target.value;
    
        // Prevent negative values
        if (value < 0) {
            value = -(value); // Reset to 0 or any default value
            event.target.value = value; // Update the input field visually
            alert('Negative values are not allowed.'); // Display an error message
            //return;
        }
    
        // Update the specific field in the local budgetLineItems
        const editedItemIndex = this.budgetLineItems.findIndex(item => item.Id === id);
        if (editedItemIndex !== -1) {
            this.budgetLineItems[editedItemIndex] = {
                ...this.budgetLineItems[editedItemIndex],
                [field]: value
            };
        }
    
        // Update the editedRecords with the new value
        if (!this.editedRecords[id]) {
            this.editedRecords[id] = { Id: id };
        }
        this.editedRecords[id][field] = value;
    
        // Show buttons if any record is edited
        this.showButtons = Object.keys(this.editedRecords).length > 0;
    }
    handleSave() {
        this.updateRecords();
        /*getDCBudgetLineItems({ DCBudgetId: this.recordId, UserId: Id })
            .then(result => {
                this.status = result[0].Budget__r.Status__c;
                const profileName = this.userProfileName;
                const recordTypeId = this.itemRecordtypeId;
                const status = this.status; // Assume `status` is a property set from the record or parent.
                this.budgetLineItems = this.budgetLineItems.map((item) => {
                    // Default disabled logic based on profile and status
                    let isDisabled = false;
                    // Profiles with unrestricted access based on record type
                    const hasUnrestrictedAccess =
                        (profileName === 'System Administrator' && recordTypeId === this.AdvanceBudgetRecordTypeId) ||
                        (profileName === 'Sales' && recordTypeId === this.BudgetLineItemRecordTypeId);

                    // Profiles with conditional access based on status and PMG approval
                    const hasConditionalAccess =
                        (profileName === 'Sales' && status === 'Draft' && !item.isPMGApproved) ||
                        (profileName === 'Regional Manager' && status === 'Submitted' && !item.isPMGApproved) ||
                        (profileName === 'PMG' && status === '1st Level Approved' && !item.isPMGApproved) ||
                        (profileName === 'Leadership' && status === '2nd Level Approved' && !item.isPMGApproved) ||
                        (profileName === 'Ex-Com Leadership' && status === '3rd Level Approved' && !item.isPMGApproved) ||
                        (profileName === 'System Administrator' && status !== '4th Level Approved');

                    if (hasUnrestrictedAccess == true || hasConditionalAccess == true) {
                        console.log('Editable:', item.Name);
                        isDisabled = false;
                        this.updateRecords()
                    } else {
                        this.showToast('Warning', 'Records Are Not Editable', 'warning');
                        isDisabled = true;
                        console.log('Not Editable:', item.Name);
                    }

                    return {
                        ...item,
                        isDisabled, // Add the computed isDisabled property to each record
                    };
                });
            })*/

    }

    updateRecords() {
        this.isLoading = true;
        const updatedRecords = Object.values(this.editedRecords); // Convert map to array
        console.log('updatedRecords', JSON.stringify(updatedRecords));

        if (updatedRecords.length === 0) {
            this.showToast('Info', 'No changes to save.', 'info');
            this.isLoading = false;
            return;
        }

        // Merge edited fields into full original records
        const completeRecords = updatedRecords.map(record => {
            const originalRecord = this.budgetLineItems.find(item => item.Id === record.Id);
            if (originalRecord) {
                // Merge edited values into the original record
                return {
                    ...originalRecord,
                    ...record // Overwrite with the edited fields
                };
            }
            return record; // Fallback (shouldn't happen if Ids match correctly)
        });

        console.log('completeRecords', JSON.stringify(completeRecords));

        // Call Apex to update records
        updateBudgetLineItems({ budgetLineItems: completeRecords })
            .then(() => {
                this.showToast('Success', 'Records updated successfully.', 'success');
                this.editedRecords = {}; // Clear edited records
                this.showButtons = false;
                window.location.reload();
            })
            .catch(error => {
                console.error('Error saving records:', error);
                this.showToast('Error', 'Error saving records: ' + error.body.message, 'error');
                this.isLoading = false;
            });
    }

    handleCancel() {
        // Clear all changes and reload initial data
        this.editedRecords = {};
        this.connectedCallback(); // Reload initial data (you can optimize this as needed)
        this.showToast('Info', 'Changes have been discarded', 'info');
        this.showButtons = false;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
}