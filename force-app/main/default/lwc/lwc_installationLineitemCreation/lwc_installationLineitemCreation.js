import { LightningElement, api, wire,track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import getInstallationData from '@salesforce/apex/lwc_installationController.getInstallationData';
import getPartDescriptions from '@salesforce/apex/lwc_installationController.getPartDescriptions';
import getL2L3ProductQuantity from '@salesforce/apex/lwc_installationController.getL2L3ProductQuantity';
import getSoDescriptions from '@salesforce/apex/lwc_installationController.getSoDescriptions';
import getSoNumber from '@salesforce/apex/lwc_installationController.getSoNumber';
import checkWheretoFetch from '@salesforce/apex/lwc_installationController.checkFilledData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveInstallationLineItems from '@salesforce/apex/lwc_installationController.saveInstallationLineItems';
import saveInstallationLineItemsSo from '@salesforce/apex/lwc_installationController.saveInstallationLineItemsSo';

export default class Lwc_installationLineitemCreation extends NavigationMixin(LightningElement) {
    @api installationId;  // This will be passed from the parent component or page
    htmlFlag;
     customer;
     partlist;
     myPartlistId;
     soNumber;
     salesOrder;
     recordId;
     modalContainer;    
     componentName='';
     isLoaded = false;
     displayManualtable = false;
     displaySOtable = false;
     displayPLMtable = false;
     @track tableData = []; // Stores table rows dynamically    
     @track partListOptions = []; // Options for the picklist field
     @track tableData2 = [
        {
            id: Date.now(),
            soDescription: '',       // Selected soDescription (Name)
            itemCode: '',   // Fetched ItemCode
            quantity: '',   // Fetched Quantity
            installationQuantity: '',
            problem: false,
            dimension: '',
            remarks: ''
        },
    ];
     @track soOptions = [];
     @track soOptionsMap = new Map(); // Map to store additional SO details
     partListItemCodeMap = new Map();// Map for Part List Id => Item Code
     componentOptions=[
        { label: 'None', value: 'None' },
        { label: 'FEH', value: 'FEH' },
        { label: 'DEH', value: 'DEH' },
        { label: 'SHELL', value: 'SHELL' }
    ];
    @track isSalesOrderDisabled = false; // Tracks whether the sales order field is disabled

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }
    connectedCallback() {
        // console.log('installationId '+this.recordId);
        // console.log('So Number'+this.soNumber);
         this.setHtmlFlag();
        if (this.recordId) {
            console.log('installationId:', this.recordId);
            this.fetchSoNumber(this.recordId);
        } else {
            console.error('Record ID is not available in connectedCallback.');
        }
        
    }
    fetchSoNumber(recordId) {
        getSoNumber({ 'installationId': this.recordId })
            .then((result) => {
                this.soId = result;
                console.log('So Number:', this.soId);
                this.fetchSoDescriptions(this.soId);
            })
            .catch((error) => {
                console.error('Error fetching SO number:', error);
            });
    }

    renderedCallback() {
        console.log('installationId rr cb'+this.recordId);
        if(this.isLoaded)return;
        const STYLE =document.createElement("style");
        STYLE.innerText=`.uiModal--horizontalForm .modal-container {
            width: 100% !important;
            max-width: 100%;
            min-width: 480px;
            max-height: 100%;
            min-height: 480px;
        }`;
        this.template.querySelector('lightning-card').appendChild(STYLE);
        this.isLoaded=true;
    }

    @wire(getInstallationData, { installationId: '$recordId' })
    wiredInstallation({ data,error}) {
        if (data) {
            console.log('Wire Data:', JSON.stringify(data));
            this.customer = data.Customer__r?.Name || 'N/A'; // Safe navigation operator
            this.partlist = data.Part_List__r?.Name || null;
            this.soNumber = data.SO_Number__r?.Name || null;

            // Update isSalesOrderDisabled
            this.isSalesOrderDisabled = this.partlist !== null || this.soNumber !== null;
    
            if (data.Part_List__c) {
                this.fetchPartDescriptions(data.Part_List__c);
                console.log('Partlist:', data.Part_List__c);
                this.myPartlistId = data.Part_List__c;
            }
        } else if (error) {
            console.error('Error fetching installation data:', error);
        }
    }   
    // Handles manual entry of the Sales Order field    
    handleSalesOrderChange(event) {
        this.salesOrder = event.target.value;
    }
    
    fetchSoDescriptions(soId) {
        getSoDescriptions({ solistId: soId })
            .then((result) => {
                console.log('SO Descriptions:', result);
                this.soOptions = result.map(item => ({ 
                    label: item.Name, 
                    value: item.Id  
                    // itemCode: item.ItemCode,  // Assuming ItemCode is returned in the Apex method
                    // quantity: item.Quantity  // Assuming Quantity is returned in the Apex method 
                }));

                console.log("sooptions" +this.soOptions);
                // Create a Map for efficient lookups
            this.soOptionsMap = new Map();
            result.forEach(item => {
                this.soOptionsMap.set(item.Id, item);
            });

            // Log the Map properly
            console.log('SO Options Map (entries):', this.soOptionsMap);
            })      
            .catch((error) => {
                console.error('Error fetching SO Descriptions:', error);
            });
    }

    handleSoChange(event) {
        const { field, id } = event.target.dataset;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    
        if (field === 'soDescription') {
            // Retrieve the selected SO details from the Map
            const selectedSo = this.soOptionsMap.get(value);
            console.log('const value:', value);
            console.log('selectedSo:', selectedSo);
            if (selectedSo) {
                console.log('Inside if selectedSo');
                this.tableData2 = this.tableData2.map(row => {
                    if (row.id == id) {
                        console.log('Inside if second');
                        return {
                            ...row,
                            soDescription: value,
                            item: selectedSo.ProductId,
                            itemName: selectedSo.Name,
                            itemCode: selectedSo.ItemCode,
                            quantity: selectedSo.Quantity
                        };
                    }
                    console.log('row:',row);
                    return row;
                });
            }
        } else {
           
        // Update the field dynamically
        this.tableData2 = this.tableData2.map(row => {
            if (row.id === parseInt(id, 0)) {
                const updatedRow = { ...row, [field]: value };

                // Validate installationQuantity
                if (field === 'installationQuantity') {
                    const maxQuantity = row.quantity || 0; // Default to 0 if quantity is undefined
                    const insQty = Number(value);
                    if (insQty > maxQuantity) {
                        updatedRow.installationQuantity = maxQuantity;
                        this.showErrorToast('Installation Quantity cannot exceed Total Quantity');
                    }
                }

                return updatedRow;
            }
            return row;
        });
    }

    console.log('Updated Table Data (handleSoChange):', JSON.stringify(this.tableData2));
}

      // Helper method to show error toast
      showErrorToast(message) {
        const event = new ShowToastEvent({
            title: 'Validation Error',
            message: message,
            variant: 'error',
        }); 
        this.dispatchEvent(event);
    }
 
    handleSaveSo() {

    console.log('Save button clicked');
    let isValid = true;
    let errorMessages = [];

    // Iterate through each row to validate
    this.tableData2.forEach((row, index) => {
        console.log(`Validating row ${index + 1}:`, row);

        if (!row.soDescription || row.soDescription.trim() === '') {
            isValid = false;
            errorMessages.push(`Row ${index + 1}: Item is required.`);
        }

        if (!row.installationQuantity || row.installationQuantity <= 0) {
            isValid = false;
            errorMessages.push(`Row ${index + 1}: Installation Quantity is required and must be greater than 0.`);
        }

        if (row.problem && (!row.remarks || row.remarks.trim() === '')) {
            isValid = false;
            errorMessages.push(`Row ${index + 1}: Remarks are required when Problem is checked.`);
        }
    });

    // If validation fails, show error messages
    if (!isValid) {
        console.log('Validation failed. Errors:', errorMessages);
        this.showErrorToast(errorMessages.join(' '));
        return; // Prevent further execution if validation fails
    }

    console.log('Validation passed. Proceeding to save...');

        
        const lineItems = this.tableData2.map(row => ({
         Installation__c: this.recordId,
         Item_Description__c: row.itemName,
         Item__c: row.item,
         //Total_Quantity__c: row.quantity,
         Component__c: 'None',
         Installed_Quantity__c: row.installationQuantity,
         Problem__c: row.problem,  
         Dimension_Received__c: row.dimension,
         Remarks__c: row.remarks
     }));
     console.log('line item So',lineItems); // Optional: For debugging purposes
         // Call Apex to save data
         saveInstallationLineItemsSo({ lineItems })
             .then(() => {
                 this.dispatchEvent(
                     new ShowToastEvent({
                         title: 'Success',
                         message: 'Installation Line Items saved successfully',
                         variant: 'success',
                     })
                 );
                 // Redirect to the Installation record
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Installation__c', // Replace with your object's API name
                        actionName: 'view'
                    }
                });
             })
             .catch((error) => {
                 this.dispatchEvent(
                     new ShowToastEvent({
                         title: 'Error',
                         message: 'Error saving Installation Line Items: ' + error.body.message,
                         variant: 'error',
                     })
                 );
             });
     }
    // Initialize with one default row
    @track tableData = [
        {
            id: Date.now(),
            partlist: '',
            itemCode: '',
            component: '',
            totalQuantity: '',
            installationQuantity: '',
            problem: false,
            dimension: '',
            remarks: ''
        }
    ];

    handleAddRow() {
        this.tableData = [
            ...this.tableData,
            {
                id: Date.now(),       // Unique row ID
                partlist: '',         // Partlist dropdown value
                itemCode: '',         // Item Code field value
                component: '',        // Component dropdown value
                totalQuantity: '',    // Numeric input
                installationQuantity: '', // Numeric input
                problem: false,       // Checkbox
                dimension: '',        // Text input
                remarks: ''           // Text input
            }
        ];
        console.log('Updated Table Data:', JSON.stringify(this.tableData));
    }

    handleRemoveRow(event) {
        const rowId = parseInt(event.target.dataset.id);

        if (this.tableData.length > 1) {
            this.tableData = this.tableData.filter(row => row.id !== rowId);
        } else {
            alert('At least one row must be present.');
        }
    }

    handleAddRowSo() {
        this.tableData2 = [
            ...this.tableData2,
            {
                id: Date.now(),       // Unique row ID
                soDescription: '',         // SO Description dropdown value
                itemCode: '',         // Item Code field value
                component: '',        // Component dropdown value
                totalQuantity: '',    // Numeric input
                installationQuantity: '', // Numeric input
                problem: false,       // Checkbox
                dimension: '',        // Text input
                remarks: ''           // Text input
            }
        ];
        console.log('Updated Table Data:', JSON.stringify(this.tableData2));
    }

    handleRemoveRowSo(event) {
        const rowId = parseInt(event.target.dataset.id);

        if (this.tableData2.length > 1) {
            this.tableData2 = this.tableData2.filter(row => row.id !== rowId);
        } else {
            alert('At least one row must be present.');
        }
    }

    fetchPartDescriptions(partListId) {
        getPartDescriptions({ partlistId: partListId })
            .then((result) => {
                console.log('Part descriptions:', result);
                this.partListOptions = result.map(item => ({ label: item.Name, value: item.Id }));
                console.log("partlistoptions" +this.partListOptions);
                // Populate mapping of Part List Id to ItemCode
                this.partListItemCodeMap = new Map();
                result.forEach(item => {
                    console.log("item.ItemCode" +item);
                    this.partListItemCodeMap.set(item.Id, item);
                });
                console.log('Part List to Item Code Map:', this.partListItemCodeMap);
            })  
            .catch((error) => {
                console.error('Error fetching part descriptions:', error);
            });
    }
    fetchL2L3ProductQuantity(partlistId, itemCode , componentName, row) {
        console.log('Inside fetchL2L3ProductQuantity');
        console.log('itemCode1',itemCode);
        console.log('Original itemCode:', JSON.stringify(itemCode));

    // Extract actual value from Proxy object
    const actualItemCode = itemCode.L3id; // Adjust based on structure
    console.log('Resolved Item Code:', actualItemCode);
        if (!partlistId || !actualItemCode|| !componentName) {
            console.error('Missing parameters for fetching quantity.');
            return;
        }
    getL2L3ProductQuantity({ plmId: this.myPartlistId, productL3: actualItemCode, compName: componentName })
            .then(quantity => {
                this.tableData = this.tableData.map(tableRow => {
                    if (tableRow.id === row.id) {
                        return { ...tableRow, totalQuantity: quantity };
                    }
                    return tableRow;
                });
                console.log('Updated Quantity:', quantity);
            })
            .catch(error => {
                console.error('Error fetching L2L3 Product Quantity:', error);
            });
    }
    handleFieldChange(event) {
        console.log('INSIDE HANDLE CHANGE');
        const { field, id } = event.target.dataset;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        console.log('Value:', value);
        console.log('Event Details:', event.target.Name);
    
        this.tableData = this.tableData.map(row => {
            if (row.id === parseInt(id)) {
                const updatedRow = { ...row, [field]: value };
    
                // Handle partlist selection
                if (field === 'partlist') {
                    console.log('Selected Part List:', value);
                    const itemCode = this.partListItemCodeMap.get(value) || '';
                    updatedRow.partlist = value;
                    updatedRow.itemCode = itemCode;
                    updatedRow.component = '';
                    updatedRow.totalQuantity = '';
                    updatedRow.installationQuantity='';
                }
    
                // Handle component selection
                if (field === 'component') {
                    this.componentName = value;
                    console.log('Selected Component:', this.componentName);
                    updatedRow.totalQuantity = '';
                    updatedRow.installationQuantity='';
                    if (value === 'None') {
                        updatedRow.totalQuantity = '1';
                        updatedRow.installationQuantity = '1';
                    } else {
                        this.fetchL2L3ProductQuantity(row.partlist, row.itemCode, value, row);
                    }
                }
    
                // Validate installationQuantity
                if (field === 'installationQuantity') {
                    const maxQuantity = row.totalQuantity || 0; // Default to 0 if totalQuantity is undefined
                    const insQty = Number(value);
                    if (insQty > maxQuantity) {
                        updatedRow.installationQuantity = maxQuantity;
                        this.showErrorToast('Installation Quantity cannot exceed Total Quantity');
                    }
                }
    
                return updatedRow;
            }
            return row;
        });
    
        console.log('Updated Table Data:', JSON.stringify(this.tableData));
    }
    
    // Helper method to show error toast
    showErrorToast(message) {
        const event = new ShowToastEvent({
            title: 'Validation Error',
            message: message,
            variant: 'error',
        });
        this.dispatchEvent(event);
    }
  /*  handleFieldChange(event) {
        console.log('INSIDE HANDLE CHANGE');
        const { field, id } = event.target.dataset;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        console.log('value:', value);   
        console.log('Event Details:', event.target.Name);
        this.tableData = this.tableData.map(row => {
            if (row.id === parseInt(id)) {
                // Auto-populate Item Code when Part List is selected
                if (field === 'partlist') {
                    console.log('selected plm', this.plmName);
                    const itemCode = this.partListItemCodeMap.get(value) || '';
                    //const itemCode = itemCode1.Name;
                    console.log('itemCode:'+itemCode);
                    return { ...row, 
                        partlist: value, 
                        itemCode: itemCode,
                        component: '', 
                        totalQuantity: '' };
                }
                else if (field === 'component') {
                    this.componentName = value;
                    console.log('selected component',this.componentName);
                    // Set totalQuantity and installationQuantity to 1 if componentName is 'None'
                        if (value === 'none') {
                            return {
                                ...row,
                                [field]: value,
                                totalQuantity: 1,
                                installationQuantity: 1,
                            };
                        }
                    this.fetchL2L3ProductQuantity(row.partlist, row.itemCode, value, row);
                }
                return { ...row, [field]: value };
            }
            return row;
        });
        console.log('Updated Table Data*:', JSON.stringify(this.tableData));
    }
*/
// Save the table data into the Installation_Line_Item__c object
handleSave() {
    
    console.log('Save button clicked');
    let isValid = true;
    let errorMessages = [];

    // Iterate through each row to validate
    this.tableData.forEach((row, index) => {
        console.log(`Validating row ${index + 1}:`, row);

        if (!row.partlist || row.partlist.trim() === '') {
            isValid = false;
            errorMessages.push(`Row ${index + 1}: Item is required.`);
        }

        if (!row.component || row.component.trim() === '') {
            isValid = false;
            errorMessages.push(`Row ${index + 1}: Component is required.`);
        }

        if (!row.installationQuantity || row.installationQuantity <= 0) {
            isValid = false;
            errorMessages.push(`Row ${index + 1}: Installation Quantity is required and must be greater than 0.`);
        }

        if (row.problem && (!row.remarks || row.remarks.trim() === '')) {
            isValid = false;
            errorMessages.push(`Row ${index + 1}: Remarks are required when Problem is checked.`);
        }
    });

    // If validation fails, show error messages
    if (!isValid) {
        console.log('Validation failed. Errors:', errorMessages);
        this.showErrorToast(errorMessages.join(' '));
        return; // Prevent further execution if validation fails
    }

    console.log('Validation passed. Proceeding to save...');
 
    const lineItems = this.tableData.map(row => {
        let itemFieldValue;

        // Check if itemCode.Name contains only 'PLM'
    if (row.itemCode.Name.includes('PLM') && !(
        row.itemCode.Name.includes('FEH') || 
        row.itemCode.Name.includes('DEH') || 
        row.itemCode.Name.includes('SHELL'))) {
        itemFieldValue = null;
    }
        
        // Check if itemCode.Name contains 'FEH', 'DEH', or 'SHELL' with PLM
        else if (row.itemCode.Name.includes('FEH') || row.itemCode.Name.includes('DEH') || row.itemCode.Name.includes('SHELL')) {
            itemFieldValue = row.itemCode.Id;
        } else {
            itemFieldValue = row.itemCode.L3id;
        }

        // Return the mapped object with conditional logic for Item__c
        return {
            Installation__c: this.recordId,
            Item_Description__c: row.itemCode.Name,
            Item__c: itemFieldValue,
            Component__c: row.component,
            Installed_Quantity__c: row.installationQuantity,
            Problem__c: row.problem,  
            Dimension_Received__c: row.dimension,
            Remarks__c: row.remarks
        };
    });

    console.log('line item partlist',lineItems); // Optional: For debugging purposes

    saveInstallationLineItems({ lineItems })
        .then(() => {
            console.log('Data saved successfully.');
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Installation Line Items saved successfully.',
                    variant: 'success'
                })
            );
            // Redirect to the Installation record
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Installation__c', // Replace with your object's API name
                    actionName: 'view'
                }
            });
        })
        .catch(error => {
            console.error('Error saving data:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to save Installation Line Items.',
                    variant: 'error'
                })
            );
        });
}

setHtmlFlag(){
    checkWheretoFetch({ installationId: this.recordId })
        .then((result) => {
            console.log('checkWheretoFetch:', result);
            this.htmlFlag = result;
            this.renderHtmlCondition();
        })
        .catch((error) => {
            console.error('Error checking empty fields:', error);
        });
}
renderHtmlCondition(){
    if(this.htmlFlag == 1 || this.htmlFlag == 2){
        console.log('Inside renderHtmlCondition',this.htmlFlag);
        this.displayPLMtable = true;
        //PLM
    }
    else if(this.htmlFlag == 3){
        console.log('Inside renderHtmlCondition, 2nd loop',this.htmlFlag);
        this.displaySOtable = true;
        //SO
    }
    else if(this.htmlFlag == 4){
        console.log('Inside renderHtmlCondition 3rd loop',this.htmlFlag);
        this.displayManualtable = true;
        //Manual
    }
}
refresher(){

}
}