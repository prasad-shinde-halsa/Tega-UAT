import { LightningElement, track, wire, api } from 'lwc';
import getPicklistValuesLwc from '@salesforce/apex/DcBudgetLWCController.getPicklistValuesLwc';
import getDCBudgetLineItems from '@salesforce/apex/DcBudgetLWCController.getDCBudgetLineItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateBudgetLineItems from '@salesforce/apex/DcBudgetLWCController.updateBudgetLineItems';
import Id from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import DCBUDGET_OBJECT from "@salesforce/schema/DC_Budget__c";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import DC_Budget_LineItem_OBJECT from '@salesforce/schema/DC_Budget_Line_Items__c';
import ORDEREXPECTEDSTAGE_FIELD from '@salesforce/schema/MIS_Budget__c.Order_Expected_Stage_Aug__c';
import getAllStageMetadata from '@salesforce/apex/DcBudgetLWCController.getAllStageMetadata';

import getMisDateRange from '@salesforce/apex/DcBudgetLWCController.getMisDateRange';
import fnYear from '@salesforce/schema/DC_Budget__c.Financial_Year__c';

export default class ShowMISDetails extends LightningElement {

    @api recordId
    @track showTable = false;
    @track selectedOrderType = '';
    @track OrderTypeOptions = [];
    @track AUGOrderStageOptions = [];
    @track OrderExpectedMonthOptions = [];
    @track budgetLineItems = [];
    allBudgetLineItems = [];
    @track searchTerm = '';
    @track selectedOrderType = '';
    @track editedRecords = {};
    @track showButtons = false;
    @track isLoading = false;
    @track userProfileName = '';
    @track status = ''
    @track isEditable = false
    @track AdvanceBudgetRecordTypeId;
    itemRecordtypeId
    PMGRecordTypeId
    @track searchTermPMG = '';
    budgetFY
    orderType
    AUGOrderStageData
    @track metadataMap = {};

    @track misDateRange = {}
    @track canEditMis = false;

    // Fetch User Profile Information
    @wire(getRecord, { recordId: Id, fields: [ProfileName, fnYear] })
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

    @wire(getRecord, { recordId: '$recordId', fields: [fnYear] })
    userDetails({ error, data }) {
        if (data) {
            console.log('dcBudget data', JSON.stringify(data));
            if(data.fields.Financial_Year__c.value != null){
                this.budgetFY = data.fields.Financial_Year__c.value;
            }
            
            console.log('User Profile:', this.userProfileName);

        } else if (error) {
            console.error('Error For Finding Budget:', error);
        }
    }

    @wire(getAllStageMetadata)
    wiredMetadata({ error, data }) {
        if (data) {
            this.metadataMap = data;
            console.log('Metadata Map:', data);
        } else if (error) {
            console.error('Error fetching metadata:', error);
        }
    }

    @wire(getObjectInfo, { objectApiName: DCBUDGET_OBJECT })
    Function({ error, data }) {
        if (data) {
            let objArray = data.recordTypeInfos;
            for (let i in objArray) {
                if (objArray[i].name == "Advance Budget") {
                    this.AdvanceBudgetRecordTypeId = objArray[i].recordTypeId
                }
                if (objArray[i].name == "PMG") {
                    this.PMGRecordTypeId = objArray[i].recordTypeId
                }
            }

            console.log('Advance Record Type Id ', this.AdvanceBudgetRecordTypeId)
            console.log('PMG Record Type Id ', this.PMGRecordTypeId)

        } else if (error) {
            console.log(JSON.stringify(error))
        }
    };

    @wire(getObjectInfo, { objectApiName: DC_Budget_LineItem_OBJECT }) productInfo;

    @wire(getPicklistValues, { recordTypeId: '$productInfo.data.defaultRecordTypeId', fieldApiName: ORDEREXPECTEDSTAGE_FIELD })
    wiredAUGOrderStageDataValues({ data, error }) {
        if (data) {
            console.log('📌 Picklist Data:', JSON.stringify(data));
            this.AUGOrderStageData = data;
        } else if (error) {
            console.error('❌ Error loading picklist values:', error);
        }
    }

    @wire(getPicklistValuesLwc, { ObjectApi_name: 'DC_Budget_Line_Items__c', Field_name: 'Order_Type__c' })
    handleOrderTypeOptions({ data, error }) {
        if (data) {
            console.log('Status Picklist Data:', JSON.stringify(data));
            this.OrderTypeOptions = [
                { label: 'None', value: '' },
                ...data.map(picklistValue => ({
                    label: picklistValue.label,
                    value: picklistValue.value
                }))
            ];
        } else if (error) {
            console.error(error);
        }
    }

     //subham deb
     @wire(getMisDateRange, {FNyear: '$budgetFY'})
     getData({error, data}){
         if(data){
             console.log('misRange::: ', JSON.stringify(data))
             let startDate = new Date(data[0].MIS_Edit_Start_Date__c);
             let endDate = new Date(data[0].MIS_Edit_End_Date__c)
             let todayDate = new Date();
             console.log('dates:::: ', startDate,' :: ', endDate, ' ::: ', todayDate);
             if((startDate < todayDate) && (todayDate <= endDate) ){
                 this.canEditMis = true;
                 console.log('if true mis edit')
             }
         }
         else{
             console.error(error)
         }
     }


    connectedCallback() {
        this.fetchBudgetLineItems();
    }

    fetchBudgetLineItems() {
        this.isLoading = true;
        getDCBudgetLineItems({ DCBudgetId: this.recordId, UserId: Id, ProfileName: this.userProfileName })
            .then((result) => {
                
                console.log('REcordId', this.recordId);
                console.log('Aug Data:', JSON.stringify(result));
                if (result && result.length > 0) {
                    this.status = result[0].Budget__r.Status__c;
                    this.orderType = result[0].Order_Type__c;
                    this.budgetFY = result[0].Budget__r.Financial_Year__c;
                    console.log('Budget FY', this.budgetFY);
                    this.setOrderExpectedMonthOptions();
                    this.itemRecordtypeId = result[0].Budget__r.RecordTypeId;
                    let indexingValue = 1;
                    this.allBudgetLineItems = result.map(item => (
                        
                        {
                        ...item,
                        Order_Type__c: item.Order_Type__c || '',
                        
                        Jan_Order__c: item.Jan_Order__c || 0,
                        Feb_Order__c: item.Feb_Order__c || 0,
                        Mar_Order__c: item.Mar_Order__c || 0,
                        Apr_Order__c: item.Apr_Order__c || 0,
                        May_Order__c: item.May_Order__c || 0,
                        Jun_Order__c: item.Jun_Order__c || 0,
                        Jul_Order__c: item.Jul_Order__c || 0,
                        Aug_Order__c: item.Aug_Order__c || 0,
                        Sep_Order__c: item.Sep_Order__c || 0,
                        Oct_Order__c: item.Oct_Order__c || 0,
                        Nov_Order__c: item.Nov_Order__c || 0,
                        Dec_Order__c: item.Dec_Order__c || 0,
                        // Aug_Sales__c: item.Aug_Sales__c || 0,
                        Total_Sales__c: item.Total_Sales__c || 0,
                        Total_Order__c: item.Total_Order__c || 0,
                        Part_List: item.Part_List__r?.Name || '',
                        Application_Type_Master: item.Application_Type_Master__r?.Name || '',
                        PG_Master: item.PG_Master__r?.Name || '',
                        PMG_Master: item.PMG_Master__r?.Name || '',
                        Product_Name: item.Product__r?.Name || '',
                        isPMGApproved: item.Is_PMG_Label_Approved__c,

                        Jan_Order_Actual__c: item.Jan_Order_Actual__c || 0,
                        Feb_Order_Actual__c: item.Feb_Order_Actual__c || 0,
                        Mar_Order_Actual__c: item.Mar_Order_Actual__c || 0,
                        Apr_Order_Actual__c: (item.Apr_Order_Actual__c / 52.99) || 0,
                        May_Order_Actual__c: item.May_Order_Actual__c || 0,
                        Jun_Order_Actual__c: item.Jun_Order_Actual__c || 0,
                        Jul_Order_Actual__c: item.Jul_Order_Actual__c || 0,
                        Aug_Order_Actual__c: item.Aug_Order_Actual__c || 0,
                        Sep_Order_Actual__c: item.Sep_Order_Actual__c || 0,
                        Oct_Order_Actual__c: item.Oct_Order_Actual__c || 0,
                        Nov_Order_Actual__c: item.Nov_Order_Actual__c || 0,
                        Dec_Order_Actual__c: item.Dec_Order_Actual__c || 0,

                        Expected_Order_Value_Jan__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Expected_Order_Value_Jan__c || 0) : 0,
                        Expected_Order_Value_Feb__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Expected_Order_Value_Feb__c || 0) : 0,
                        Expected_Order_Value_Mar__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Expected_Order_Value_Mar__c || 0) : 0,
                        Expected_Order_Value_April__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Expected_Order_Value_April__c || 0) : 0,
                        Expected_Order_Value_May__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Expected_Order_Value_May__c || 0) : 0,
                        Expected_Order_Value_June__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Expected_Order_Value_June__c || 0) : 0,
                        Expected_Order_Value_Jul__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Expected_Order_Value_Jul__c || 0) : 0,
                        Expected_Order_Value_Aug__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Expected_Order_Value_Aug__c || 0) : 0,
                        Expected_Order_Value_Sep__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Expected_Order_Value_Sep__c || 0) : 0,
                        Expected_Order_Value_Oct__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Expected_Order_Value_Oct__c || 0) : 0,
                        Expected_Order_Value_Nov__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Expected_Order_Value_Nov__c || 0) : 0,
                        Expected_Order_Value_Dec__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Expected_Order_Value_Dec__c || 0) : 0,


                        
                        misId : (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Id || null) : null,

                        

                        Order_Expected_Month_Jan__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Month_Jan__c || null) : null,
                        Order_Expected_Stage_Jan__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Stage_Jan__c || 'No work done') : null,

                        Order_Expected_Month_Feb__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Month_Feb__c || null) : null,
                        Order_Expected_Stage_Feb__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Stage_Feb__c || 'No work done') : null,

                        Order_Expected_Month_Mar__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Month_Mar__c || null) : null,
                        Order_Expected_Stage_Mar__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Stage_Mar__c || 'No work done') : null,

                        Order_Expected_Month_Apr__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Month_Apr__c || null) : null,
                        Order_Expected_Stage_Apr__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Stage_Apr__c || 'No work done') : null,

                        Order_Expected_Month_May__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Month_May__c || null) : null,
                        Order_Expected_Stage_May__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Stage_May__c || 'No work done') : null,

                        Order_Expected_Month_Jun__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Month_Jun__c || null) : null,
                        Order_Expected_Stage_Jun__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Stage_Jun__c || 'No work done') : null,

                        Order_Expected_Month_Jul__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Month_Jul__c || null) : null,
                        Order_Expected_Stage_Jul__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Stage_Jul__c || 'No work done') : null,

                        Order_Expected_Month_Aug__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Month_Aug__c || null) : null,
                        Order_Expected_Stage_Aug__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Stage_Aug__c || 'No work done') : null,

                        Order_Expected_Month_Sep__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Month_Sep__c || null) : null,
                        Order_Expected_Stage_Sep__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Stage_Sep__c || 'No work done') : null,

                        Order_Expected_Month_Oct__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Month_Oct__c || null) : null,
                        Order_Expected_Stage_Oct__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Stage_Oct__c || 'No work done') : null,

                        Order_Expected_Month_Nov__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Month_Nov__c || null) : null,
                        Order_Expected_Stage_Nov__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Stage_Nov__c || 'No work done') : null,

                        Order_Expected_Month_Dec__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Month_Dec__c || null) : null,
                        Order_Expected_Stage_Dec__c: (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Order_Expected_Stage_Dec__c || 'No work done') : null,

                        Remarks_Jan__c : (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Remarks_Jan__c || null) : null,
                        Remarks_Feb__c : (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Remarks_Feb__c || null) : null,
                        Remarks_Mar__c : (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Remarks_Mar__c || null) : null,
                        Remarks_Apr__c : (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Remarks_Apr__c || null) : null,
                        Remarks_May__c : (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Remarks_May__c || null) : null,
                        Remarks_Jun__c : (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Remarks_Jun__c || null) : null,
                        Remarks_Jul__c : (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Remarks_Jul__c || null) : null,
                        Remarks_Aug__c : (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Remarks_Aug__c || null) : null,
                        Remarks_Sep__c : (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Remarks_Sep__c || null) : null,
                        Remarks_Oct__c : (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Remarks_Oct__c || null) : null,
                        Remarks_Nov__c : (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Remarks_Nov__c || null) : null,
                        Remarks_Dec__c : (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].Remarks_Dec__c || null) : null,

                        jan_index: item.Jan_Order__c? indexingValue++ : 0,
                        feb_index: item.Feb_Order__c? indexingValue++ : 0,
                        mar_index: item.Mar_Order__c? indexingValue++ : 0,
                        apr_index: item.Apr_Order__c? indexingValue++ : 0,
                        may_index: item.May_Order__c? indexingValue++ : 0,
                        jun_index: item.Jun_Order__c? indexingValue++ : 0,
                        jul_index: item.Jul_Order__c? indexingValue++ : 0,
                        aug_index: item.Aug_Order__c? indexingValue++ : 0,
                        sep_index: item.Sep_Order__c? indexingValue++ : 0,
                        oct_index: item.Oct_Order__c? indexingValue++ : 0,
                        nov_index: item.Nov_Order__c? indexingValue++ : 0,
                        dec_index: item.Dec_Order__c? indexingValue++ : 0,

                        Order_Stage_Options: this.getOrderExpectedStageOptions(item.Order_Type__c),
                        Order_Month_Options: this.setOrderExpectedMonthOptions(item.Order_Type__c),

                        CreatedDate : (item.MIS_Budgets__r != null ) ? (item.MIS_Budgets__r[0].CreatedDate || null) : null,
                    }
                ));
                    this.budgetLineItems = this.allBudgetLineItems;
                    console.log('budgetLineItems : ', JSON.stringify(this.budgetLineItems));
                    this.showTable = true;
                    this.CheckisEditable();
                } else {
                    this.budgetLineItems = [];
                    this.showTable = false;
                }
            })
            .catch((error) => {
                this.isLoading = false;
                console.error('Error fetching budget line items:', error);
                this.budgetLineItems = [];
                this.showTable = false;
            })
            .finally(() => {
            this.isLoading = false;
        });
    }

    getOrderExpectedStageOptions(orderType) {
        if (!this.AUGOrderStageData) {
            console.warn('⚠️ Picklist data not yet loaded.');
            return [];
        }

        if (!this.AUGOrderStageData.controllerValues) {
            console.error('❌ Missing `controllerValues` in AUGOrderStageData.');
            return [];
        }

        if (!orderType) {
            console.warn('⚠️ No Order Type provided.');
            return [];
        }

        const orderTypeKey = this.AUGOrderStageData.controllerValues[orderType];
        console.log('✅ OrderTypeKey:', orderTypeKey);

        if (orderTypeKey === undefined) {
            console.warn(`⚠️ No matching key found in controllerValues for OrderType: ${orderType}`);
            return [];
        }

        // let vvvla = this.AUGOrderStageData.values
        // .filter(option => option.validFor.includes(orderTypeKey))
        // .map(option => ({ label: option.label, value: option.value }));
        // console.log('vvla::: ', vvvla)
        // vvvla.unshift({label: 'No work done', value:'No work done'})
        // return vvvla;
        

        return this.AUGOrderStageData.values
            .filter(option => option.validFor.includes(orderTypeKey))
            .map(option => ({ label: option.label, value: option.value }));
        
            //need to be chnages
           // return this.AUGOrderStageData.values.push({label: 'No work done', value:'No work done'})
    }

    setOrderExpectedMonthOptions(orderType) {
        if (!this.budgetFY) return [];
    
        let [startYear] = this.budgetFY.split('-').map(Number);
        let endYear = startYear + 1;
    
        let today = new Date();
        let currentYear = today.getFullYear();
        let currentMonthIndex = today.getMonth();
        let currentFY = currentMonthIndex >= 3 ? currentYear : currentYear - 1;
    
        // Define months starting from April
        const months = ["Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"];
    
        let currentMonthName = today.toLocaleString('en-US', { month: 'short' });
        
        // Always start from April (index 0) for the current financial year
        let startIndex = 0;
    
        console.log(`Budget FY: ${startYear}-${endYear}, Current FY: ${currentFY}`);
        console.log(`Current Month: ${currentMonthName} (Start Index: ${startIndex})`);
    
        return months.map((month, index) => {
            let year = startYear;
            // For months after December (Jan, Feb, Mar), use the next year
            if (month === "Jan" || month === "Feb" || month === "Mar") {
                year = endYear;
            }
            return { 
                label: `${month}, ${year}`, 
                value: `${month}, ${year}` 
            };
        });
    }

    CheckisEditable() {
        const profileName = this.userProfileName;
        const status = this.status;
        const recordTypeId = this.itemRecordtypeId;
        const orderType = this.orderType;

        console.log('this.canEditMis::: ', this.canEditMis);
        this.budgetLineItems = this.budgetLineItems.map((item) => {
            let isDisabled = true;
                        
            const disableJanFields = item.Jan_Order__c === 0 || 
            item.Order_Expected_Stage_Jan__c === 'Order' || 
            item.Order_Expected_Stage_Jan__c === 'Lost' ||
            !this.canEditMis;

            const disableFebFields = item.Feb_Order__c === 0 || 
            item.Order_Expected_Stage_Feb__c === 'Order' || 
            item.Order_Expected_Stage_Feb__c === 'Lost' ||
            !this.canEditMis;

            const disableMarFields = item.Mar_Order__c === 0 || 
            item.Order_Expected_Stage_Mar__c === 'Order' || 
            item.Order_Expected_Stage_Mar__c === 'Lost' ||
            !this.canEditMis;

            const disableAprFields = item.Apr_Order__c === 0 || 
            item.Order_Expected_Stage_Apr__c === 'Order' || 
            item.Order_Expected_Stage_Apr__c === 'Lost' ||
            !this.canEditMis;

            const disableMayFields = item.May_Order__c === 0 || 
            item.Order_Expected_Stage_May__c === 'Order' || 
            item.Order_Expected_Stage_May__c === 'Lost' ||
            !this.canEditMis;

            const disableJunFields = item.Jun_Order__c === 0 || 
            item.Order_Expected_Stage_Jun__c === 'Order' || 
            item.Order_Expected_Stage_Jun__c === 'Lost' ||
            !this.canEditMis;

            const disableJulFields = item.Jul_Order__c === 0 || 
            item.Order_Expected_Stage_Jul__c === 'Order' || 
            item.Order_Expected_Stage_Jul__c === 'Lost' ||
            !this.canEditMis;

            const disableAugFields = item.Aug_Order__c === 0 || 
            item.Order_Expected_Stage_Aug__c === 'Order' || 
            item.Order_Expected_Stage_Aug__c === 'Lost' ||
            !this.canEditMis;

            const disableSepFields = item.Sep_Order__c === 0 || 
            item.Order_Expected_Stage_Sep__c === 'Order' || 
            item.Order_Expected_Stage_Sep__c === 'Lost' ||
            !this.canEditMis;

            const disableOctFields = item.Oct_Order__c === 0 || 
            item.Order_Expected_Stage_Oct__c === 'Order' || 
            item.Order_Expected_Stage_Oct__c === 'Lost' ||
            !this.canEditMis;

            const disableNovFields = item.Nov_Order__c === 0 || 
            item.Order_Expected_Stage_Nov__c === 'Order' || 
            item.Order_Expected_Stage_Nov__c === 'Lost' ||
            !this.canEditMis;

            const disableDecFields = item.Dec_Order__c === 0 || 
            item.Order_Expected_Stage_Dec__c === 'Order' || 
            item.Order_Expected_Stage_Dec__c === 'Lost' ||
            !this.canEditMis;

            const disableRemarkField = !this.canEditMis;

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
            isDisabled = true;
        } else {
            isDisabled = true;
            
            console.log('Not Editable:', item.Name);
        }

        return {
            ...item,
            isDisabled, // Add the computed isDisabled property to each record
            disableJanFields,
            disableFebFields,
            disableMarFields,
            disableAprFields,
            disableMayFields,
            disableJunFields,
            disableJulFields,
            disableAugFields,
            disableSepFields,
            disableOctFields,
            disableNovFields,
            disableDecFields,
            disableRemarkField
        };
    });

    this.allBudgetLineItems = this.budgetLineItems;
}

    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.filterResults();
    }

    handleOrderTypeChange(event) {
        this.selectedOrderType = event.target.value;
        this.filterResults();
    }

    handleSearchPMG(event) {
        this.searchTermPMG = event.target.value;
        this.filterResults();
    }

    filterResults() {
        if (!this.searchTerm && !this.selectedOrderType && !this.searchTermPMG) {
            this.budgetLineItems = this.allBudgetLineItems;
        } else {
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
        this.showTable = this.budgetLineItems.length > 0;
    }


    get budgetLineItemsWithIndex() {
        return this.budgetLineItems.map((item, index) => ({
            ...item,
            serialNumber: index+1,
            isPMG: item.Created_by_PMG__c == true ? true : false,
            rowClass: this.getRowClass(item)
        }));
    }

    getRowClass(record) {
        return record.Created_by_PMG__c ? 'red-font' : '';
    }

    handleInlineEdit(event) {
        const { id, field } = event.target.dataset;
        let value = event.target.value;
    
        console.log('value and field----> ', value, '   ', field)

        if (value < 0) {
            value = -(value);
            event.target.value = value;
            alert('Negative values are not allowed.');
        }
    
        const editedItemIndex = this.budgetLineItems.findIndex(item => item.Id === id);
        const previousValue = this.budgetLineItems[editedItemIndex][field];
    
        // Validation for Order Expected Month - Jan
        if (field === 'Order_Expected_Month_Jan__c' && previousValue) {
            const getMonthDate = (monthStr) => {
                const [month, year] = monthStr.split(', ');
                return new Date(`${month} 1, ${year}`);
            };
    
            const previousDate = getMonthDate(previousValue);
            const newDate = getMonthDate(value);
    
            // if (newDate < previousDate) {
            //     event.target.value = previousValue;
            //     alert('Cannot select a month earlier than the previously selected month.');
            //     return;
            // }
        }

        // Validation for Order Expected Month - Feb
        if (field === 'Order_Expected_Month_Feb__c' && previousValue) {
            const getMonthDate = (monthStr) => {
                const [month, year] = monthStr.split(', ');
                return new Date(`${month} 1, ${year}`);
            };
    
            const previousDate = getMonthDate(previousValue);
            const newDate = getMonthDate(value);
    
            // if (newDate < previousDate) {
            //     event.target.value = previousValue;
            //     alert('Cannot select a month earlier than the previously selected month.');
            //     return;
            // }
        }

        // Validation for Order Expected Month - Mar
        if (field === 'Order_Expected_Month_Mar__c' && previousValue) {
            const getMonthDate = (monthStr) => {
                const [month, year] = monthStr.split(', ');
                return new Date(`${month} 1, ${year}`);
            };
    
            const previousDate = getMonthDate(previousValue);
            const newDate = getMonthDate(value);
    
            // if (newDate < previousDate) {
            //     event.target.value = previousValue;
            //     alert('Cannot select a month earlier than the previously selected month.');
            //     return;
            // }
        }

        // Validation for Order Expected Month - Apr
        if (field === 'Order_Expected_Month_Apr__c' && previousValue) {
            const getMonthDate = (monthStr) => {
                const [month, year] = monthStr.split(', ');
                return new Date(`${month} 1, ${year}`);
            };
    
            const previousDate = getMonthDate(previousValue);
            const newDate = getMonthDate(value);
    
            // if (newDate < previousDate) {
            //     event.target.value = previousValue;
            //     alert('Cannot select a month earlier than the previously selected month.');
            //     return;
            // }
        }

        // Validation for Order Expected Month - May
        if (field === 'Order_Expected_Month_May__c' && previousValue) {
            const getMonthDate = (monthStr) => {
                const [month, year] = monthStr.split(', ');
                return new Date(`${month} 1, ${year}`);
            };
    
            const previousDate = getMonthDate(previousValue);
            const newDate = getMonthDate(value);
    
            // if (newDate < previousDate) {
            //     event.target.value = previousValue;
            //     alert('Cannot select a month earlier than the previously selected month.');
            //     return;
            // }
        }

        // Validation for Order Expected Month - Jun
        if (field === 'Order_Expected_Month_Jun__c' && previousValue) {
            const getMonthDate = (monthStr) => {
                const [month, year] = monthStr.split(', ');
                return new Date(`${month} 1, ${year}`);
            };
    
            const previousDate = getMonthDate(previousValue);
            const newDate = getMonthDate(value);
    
            // if (newDate < previousDate) {
            //     event.target.value = previousValue;
            //     alert('Cannot select a month earlier than the previously selected month.');
            //     return;
            // }
        }

        // Validation for Order Expected Month - Jul
        if (field === 'Order_Expected_Month_Jul__c' && previousValue) {
            const getMonthDate = (monthStr) => {
                const [month, year] = monthStr.split(', ');
                return new Date(`${month} 1, ${year}`);
            };
    
            const previousDate = getMonthDate(previousValue);
            const newDate = getMonthDate(value);
    
            // if (newDate < previousDate) {
            //     event.target.value = previousValue;
            //     alert('Cannot select a month earlier than the previously selected month.');
            //     return;
            // }
        }

        // Validation for Order Expected Month - Aug
        if (field === 'Order_Expected_Month_Aug__c' && previousValue) {
            const getMonthDate = (monthStr) => {
                const [month, year] = monthStr.split(', ');
                return new Date(`${month} 1, ${year}`);
            };
    
            const previousDate = getMonthDate(previousValue);
            const newDate = getMonthDate(value);
    
            // if (newDate < previousDate) {
            //     event.target.value = previousValue;
            //     alert('Cannot select a month earlier than the previously selected month.');
            //     return;
            // }
        }

        // Validation for Order Expected Month - Sep
        if (field === 'Order_Expected_Month_Sep__c' && previousValue) {
            const getMonthDate = (monthStr) => {
                const [month, year] = monthStr.split(', ');
                return new Date(`${month} 1, ${year}`);
            };
    
            const previousDate = getMonthDate(previousValue);
            const newDate = getMonthDate(value);
    
            // if (newDate < previousDate) {
            //     event.target.value = previousValue;
            //     alert('Cannot select a month earlier than the previously selected month.');
            //     return;
            // }
        }

        // Validation for Order Expected Month - Oct
        if (field === 'Order_Expected_Month_Oct__c' && previousValue) {
            const getMonthDate = (monthStr) => {
                const [month, year] = monthStr.split(', ');
                return new Date(`${month} 1, ${year}`);
            };
    
            const previousDate = getMonthDate(previousValue);
            const newDate = getMonthDate(value);
    
            // if (newDate < previousDate) {
            //     event.target.value = previousValue;
            //     alert('Cannot select a month earlier than the previously selected month.');
            //     return;
            // }
        }

        // Validation for Order Expected Month - Nov
        if (field === 'Order_Expected_Month_Nov__c' && previousValue) {
            const getMonthDate = (monthStr) => {
                const [month, year] = monthStr.split(', ');
                return new Date(`${month} 1, ${year}`);
            };
    
            const previousDate = getMonthDate(previousValue);
            const newDate = getMonthDate(value);
    
            // if (newDate < previousDate) {
            //     event.target.value = previousValue;
            //     alert('Cannot select a month earlier than the previously selected month.');
            //     return;
            // }
        }

        // Validation for Order Expected Month - Dec
        if (field === 'Order_Expected_Month_Dec__c' && previousValue) {
            const getMonthDate = (monthStr) => {
                const [month, year] = monthStr.split(', ');
                return new Date(`${month} 1, ${year}`);
            };
    
            const previousDate = getMonthDate(previousValue);
            const newDate = getMonthDate(value);
    
            // if (newDate < previousDate) {
            //     event.target.value = previousValue;
            //     alert('Cannot select a month earlier than the previously selected month.');
            //     return;
            // }
        }
    
        // Validation for Order Expected Stage - Jan
        if (field === 'Order_Expected_Stage_Jan__c' && previousValue) {
            const orderType = this.budgetLineItems[editedItemIndex].Order_Type__c;
            const metadataList = this.metadataMap[orderType] || [];
    
            const prevMetadata = metadataList.find(meta => meta.Name__c === previousValue);
            const newMetadata = metadataList.find(meta => meta.Name__c === value);
            
            if (prevMetadata && newMetadata) {
                const prevSequence = prevMetadata.Stage_Sequence__c;
                const newSequence = newMetadata.Stage_Sequence__c;
                console.log('new sequence --> ',newSequence)
                if (newSequence < prevSequence) {
                    alert('Invalid stage selection: You cannot move to a lower stage.');
                    event.target.value = previousValue;
                    return;
                }
                
            }
            if(value == 'Offer' || value == 'Order' || value == 'Lost'){
                alert('You cant select Offer, Order and Lost stages, This will automatically set from PRF Status.');
                event.target.value = previousValue;
                return;
            }
        }

        // Validation for Order Expected Stage - Feb
        if (field === 'Order_Expected_Stage_Feb__c' && previousValue) {
            const orderType = this.budgetLineItems[editedItemIndex].Order_Type__c;
            const metadataList = this.metadataMap[orderType] || [];
    
            const prevMetadata = metadataList.find(meta => meta.Name__c === previousValue);
            const newMetadata = metadataList.find(meta => meta.Name__c === value);
            
            if (prevMetadata && newMetadata) {
                const prevSequence = prevMetadata.Stage_Sequence__c;
                const newSequence = newMetadata.Stage_Sequence__c;
                
                if (newSequence < prevSequence) {
                    alert('Invalid stage selection: You cannot move to a lower stage.');
                    event.target.value = previousValue;
                    return;
                }
            }
            if(value == 'Offer' || value == 'Order' || value == 'Lost'){
                alert('You cant select Offer, Order and Lost stages, This will automatically set from PRF Status.');
                event.target.value = previousValue;
                return;
            }
        }

        // Validation for Order Expected Stage - Mar
        if (field === 'Order_Expected_Stage_Mar__c' && previousValue) {
            const orderType = this.budgetLineItems[editedItemIndex].Order_Type__c;
            const metadataList = this.metadataMap[orderType] || [];
    
            const prevMetadata = metadataList.find(meta => meta.Name__c === previousValue);
            const newMetadata = metadataList.find(meta => meta.Name__c === value);
            
            if (prevMetadata && newMetadata) {
                const prevSequence = prevMetadata.Stage_Sequence__c;
                const newSequence = newMetadata.Stage_Sequence__c;
                
                if (newSequence < prevSequence) {
                    alert('Invalid stage selection: You cannot move to a lower stage.');
                    event.target.value = previousValue;
                    return;
                }
            }
            if(value == 'Offer' || value == 'Order' || value == 'Lost'){
                alert('You cant select Offer, Order and Lost stages, This will automatically set from PRF Status.');
                event.target.value = previousValue;
                return;
            }
        }

        // Validation for Order Expected Stage - Apr
        if (field === 'Order_Expected_Stage_Apr__c' && previousValue) {
            const orderType = this.budgetLineItems[editedItemIndex].Order_Type__c;
            const metadataList = this.metadataMap[orderType] || [];
    
            const prevMetadata = metadataList.find(meta => meta.Name__c === previousValue);
            const newMetadata = metadataList.find(meta => meta.Name__c === value);
            
            if (prevMetadata && newMetadata) {
                const prevSequence = prevMetadata.Stage_Sequence__c;
                const newSequence = newMetadata.Stage_Sequence__c;
                
                if (newSequence < prevSequence) {
                    alert('Invalid stage selection: You cannot move to a lower stage.');
                    event.target.value = previousValue;
                    return;
                }
            }
            if(value == 'Offer' || value == 'Order' || value == 'Lost'){
                alert('You cant select Offer, Order and Lost stages, This will automatically set from PRF Status.');
                event.target.value = previousValue;
                return;
            }
        }

        // Validation for Order Expected Stage - May
        if (field === 'Order_Expected_Stage_May__c' && previousValue) {
            const orderType = this.budgetLineItems[editedItemIndex].Order_Type__c;
            const metadataList = this.metadataMap[orderType] || [];
    
            const prevMetadata = metadataList.find(meta => meta.Name__c === previousValue);
            const newMetadata = metadataList.find(meta => meta.Name__c === value);
            
            if (prevMetadata && newMetadata) {
                const prevSequence = prevMetadata.Stage_Sequence__c;
                const newSequence = newMetadata.Stage_Sequence__c;
                
                if (newSequence < prevSequence) {
                    alert('Invalid stage selection: You cannot move to a lower stage.');
                    event.target.value = previousValue;
                    return;
                }
            }
            console.log('vvvvv--> ', value)
            if(value == 'Offer' || value == 'Order' || value == 'Lost'){
                alert('You cant select Offer, Order and Lost stages, This will automatically set from PRF Status.');
                event.target.value = previousValue;
                return;
            }
        }

        // Validation for Order Expected Stage - Jun
        if (field === 'Order_Expected_Stage_Jun__c' && previousValue) {
            const orderType = this.budgetLineItems[editedItemIndex].Order_Type__c;
            const metadataList = this.metadataMap[orderType] || [];
    
            const prevMetadata = metadataList.find(meta => meta.Name__c === previousValue);
            const newMetadata = metadataList.find(meta => meta.Name__c === value);
            
            if (prevMetadata && newMetadata) {
                const prevSequence = prevMetadata.Stage_Sequence__c;
                const newSequence = newMetadata.Stage_Sequence__c;
                
                if (newSequence < prevSequence) {
                    alert('Invalid stage selection: You cannot move to a lower stage.');
                    event.target.value = previousValue;
                    return;
                }
            }
            if(value == 'Offer' || value == 'Order' || value == 'Lost'){
                alert('You cant select Offer, Order and Lost stages, This will automatically set from PRF Status.');
                event.target.value = previousValue;
                return;
            }
        }

        // Validation for Order Expected Stage - Jul
        if (field === 'Order_Expected_Stage_Jul__c' && previousValue) {
            const orderType = this.budgetLineItems[editedItemIndex].Order_Type__c;
            const metadataList = this.metadataMap[orderType] || [];
    
            const prevMetadata = metadataList.find(meta => meta.Name__c === previousValue);
            const newMetadata = metadataList.find(meta => meta.Name__c === value);
            
            if (prevMetadata && newMetadata) {
                const prevSequence = prevMetadata.Stage_Sequence__c;
                const newSequence = newMetadata.Stage_Sequence__c;
                
                if (newSequence < prevSequence) {
                    alert('Invalid stage selection: You cannot move to a lower stage.');
                    event.target.value = previousValue;
                    return;
                }
            }
            if(value == 'Offer' || value == 'Order' || value == 'Lost'){
                alert('You cant select Offer, Order and Lost stages, This will automatically set from PRF Status.');
                event.target.value = previousValue;
                return;
            }
        }

        // Validation for Order Expected Stage - Aug
        if (field === 'Order_Expected_Stage_Aug__c' && previousValue) {
            const orderType = this.budgetLineItems[editedItemIndex].Order_Type__c;
            const metadataList = this.metadataMap[orderType] || [];
    
            const prevMetadata = metadataList.find(meta => meta.Name__c === previousValue);
            const newMetadata = metadataList.find(meta => meta.Name__c === value);
            
            if (prevMetadata && newMetadata) {
                const prevSequence = prevMetadata.Stage_Sequence__c;
                const newSequence = newMetadata.Stage_Sequence__c;
                
                if (newSequence < prevSequence) {
                    alert('Invalid stage selection: You cannot move to a lower stage.');
                    event.target.value = previousValue;
                    return;
                }
            }
            if(value == 'Offer' || value == 'Order' || value == 'Lost'){
                alert('You cant select Offer, Order and Lost stages, This will automatically set from PRF Status.');
                event.target.value = previousValue;
                return;
            }
        }

        // Validation for Order Expected Stage - Sep
        if (field === 'Order_Expected_Stage_Sep__c' && previousValue) {
            const orderType = this.budgetLineItems[editedItemIndex].Order_Type__c;
            const metadataList = this.metadataMap[orderType] || [];
    
            const prevMetadata = metadataList.find(meta => meta.Name__c === previousValue);
            const newMetadata = metadataList.find(meta => meta.Name__c === value);
            
            if (prevMetadata && newMetadata) {
                const prevSequence = prevMetadata.Stage_Sequence__c;
                const newSequence = newMetadata.Stage_Sequence__c;
                
                if (newSequence < prevSequence) {
                    alert('Invalid stage selection: You cannot move to a lower stage.');
                    event.target.value = previousValue;
                    return;
                }
            }
            if(value == 'Offer' || value == 'Order' || value == 'Lost'){
                alert('You cant select Offer, Order and Lost stages, This will automatically set from PRF Status.');
                event.target.value = previousValue;
                return;
            }
        }

        // Validation for Order Expected Stage - Oct
        if (field === 'Order_Expected_Stage_Oct__c' && previousValue) {
            const orderType = this.budgetLineItems[editedItemIndex].Order_Type__c;
            const metadataList = this.metadataMap[orderType] || [];
    
            const prevMetadata = metadataList.find(meta => meta.Name__c === previousValue);
            const newMetadata = metadataList.find(meta => meta.Name__c === value);
            
            if (prevMetadata && newMetadata) {
                const prevSequence = prevMetadata.Stage_Sequence__c;
                const newSequence = newMetadata.Stage_Sequence__c;
                
                if (newSequence < prevSequence) {
                    alert('Invalid stage selection: You cannot move to a lower stage.');
                    event.target.value = previousValue;
                    return;
                }
            }
            if(value == 'Offer' || value == 'Order' || value == 'Lost'){
                alert('You cant select Offer, Order and Lost stages, This will automatically set from PRF Status.');
                event.target.value = previousValue;
                return;
            }
        }

        // Validation for Order Expected Stage - Nov
        if (field === 'Order_Expected_Stage_Nov__c' && previousValue) {
            const orderType = this.budgetLineItems[editedItemIndex].Order_Type__c;
            const metadataList = this.metadataMap[orderType] || [];
    
            const prevMetadata = metadataList.find(meta => meta.Name__c === previousValue);
            const newMetadata = metadataList.find(meta => meta.Name__c === value);
            
            if (prevMetadata && newMetadata) {
                const prevSequence = prevMetadata.Stage_Sequence__c;
                const newSequence = newMetadata.Stage_Sequence__c;
                
                if (newSequence < prevSequence) {
                    alert('Invalid stage selection: You cannot move to a lower stage.');
                    event.target.value = previousValue;
                    return;
                }
            }
            if(value == 'Offer' || value == 'Order' || value == 'Lost'){
                alert('You cant select Offer, Order and Lost stages, This will automatically set from PRF Status.');
                event.target.value = previousValue;
                return;
            }
        }

        // Validation for Order Expected Stage - Dec
        if (field === 'Order_Expected_Stage_Dec__c' && previousValue) {
            const orderType = this.budgetLineItems[editedItemIndex].Order_Type__c;
            const metadataList = this.metadataMap[orderType] || [];
    
            const prevMetadata = metadataList.find(meta => meta.Name__c === previousValue);
            const newMetadata = metadataList.find(meta => meta.Name__c === value);
            
            if (prevMetadata && newMetadata) {
                const prevSequence = prevMetadata.Stage_Sequence__c;
                const newSequence = newMetadata.Stage_Sequence__c;
                
                if (newSequence < prevSequence) {
                    alert('Invalid stage selection: You cannot move to a lower stage.');
                    event.target.value = previousValue;
                    return;
                }
            }
            if(value == 'Offer' || value == 'Order' || value == 'Lost'){
                alert('You cant select Offer, Order and Lost stages, This will automatically set from PRF Status.');
                event.target.value = previousValue;
                return;
            }
        }

        if(value == 'Offer' || value == 'Order' || value == 'Lost' || value == 'Generation of RFQ'){
            alert('You cant select Offer, Order and Lost stages, This will automatically set from PRF Status.');
            event.target.value = previousValue;
            return;
        }

        // Additional logic would go here

        if (editedItemIndex !== -1) {
            this.budgetLineItems[editedItemIndex] = {
                ...this.budgetLineItems[editedItemIndex],
                [field]: value
            };
        }
    
        if (!this.editedRecords[id]) {
            this.editedRecords[id] = { Id: id };
        }
        this.editedRecords[id][field] = value;
    
        this.showButtons = Object.keys(this.editedRecords).length > 0;

        console.log('this.editedRecords:: ', JSON.stringify(this.editedRecords));
    }

    handleSave() {
        this.updateRecords();
    }

    updateRecords() {
        this.isLoading = true;
        const updatedRecords = Object.values(this.editedRecords);
        console.log('updatedRecords', JSON.stringify(updatedRecords));

        if (updatedRecords.length === 0) {
            this.showToast('Info', 'No changes to save.', 'info');
            this.isLoading = false;
            return;
        }

        const completeRecords = updatedRecords.map(record => {
            const originalRecord = this.budgetLineItems.find(item => item.Id === record.Id);
            if (originalRecord) {
                console.log('original record::: ', JSON.stringify(originalRecord))
                return {
                    // ...originalRecord,
                    // ...record,

                    // id: record.Id,
                    // Order_Type__c: record.Order_Type__c,
                    // MIS_Budgets__r:[
                        // {
                            Id: originalRecord.misId,
                            Mis_Date__c: originalRecord.CreatedDate != null? originalRecord.CreatedDate : null,
                            Budget_Line_Items__c: originalRecord.Id,
                            Order_Type__c: originalRecord.Order_Type__c,

                            Order_Expected_Month_Jan__c: record.Order_Expected_Month_Jan__c ? record.Order_Expected_Month_Jan__c : originalRecord.Order_Expected_Month_Jan__c,
                            Order_Expected_Stage_Jan__c: record.Order_Expected_Stage_Jan__c ? record.Order_Expected_Stage_Jan__c : originalRecord.Order_Expected_Stage_Jan__c,
                            Expected_Order_Value_Jan__c: record.Expected_Order_Value_Jan__c ? record.Expected_Order_Value_Jan__c : originalRecord.Expected_Order_Value_Jan__c,
                            Remarks_Jan__c: record.Remarks_Jan__c ? record.Remarks_Jan__c : originalRecord.Remarks_Jan__c,
                            
                            Order_Expected_Month_Feb__c: record.Order_Expected_Month_Feb__c ? record.Order_Expected_Month_Feb__c : originalRecord.Order_Expected_Month_Feb__c,
                            Order_Expected_Stage_Feb__c: record.Order_Expected_Stage_Feb__c ? record.Order_Expected_Stage_Feb__c : originalRecord.Order_Expected_Stage_Feb__c,
                            Expected_Order_Value_Feb__c: record.Expected_Order_Value_Feb__c ? record.Expected_Order_Value_Feb__c : originalRecord.Expected_Order_Value_Feb__c,
                            Remarks_Feb__c: record.Remarks_Feb__c ? record.Remarks_Feb__c : originalRecord.Remarks_Feb__c,
                            
                            Order_Expected_Month_Mar__c: record.Order_Expected_Month_Mar__c ? record.Order_Expected_Month_Mar__c : originalRecord.Order_Expected_Month_Mar__c,
                            Order_Expected_Stage_Mar__c: record.Order_Expected_Stage_Mar__c ? record.Order_Expected_Stage_Mar__c : originalRecord.Order_Expected_Stage_Mar__c,
                            Expected_Order_Value_Mar__c: record.Expected_Order_Value_Mar__c ? record.Expected_Order_Value_Mar__c : originalRecord.Expected_Order_Value_Mar__c,
                            Remarks_Mar__c: record.Remarks_Mar__c ? record.Remarks_Mar__c : originalRecord.Remarks_Mar__c,
                            
                            Order_Expected_Month_Apr__c: record.Order_Expected_Month_Apr__c ? record.Order_Expected_Month_Apr__c : originalRecord.Order_Expected_Month_Apr__c,
                            Order_Expected_Stage_Apr__c: record.Order_Expected_Stage_Apr__c ? record.Order_Expected_Stage_Apr__c : originalRecord.Order_Expected_Stage_Apr__c,
                            Expected_Order_Value_April__c: record.Expected_Order_Value_April__c ? record.Expected_Order_Value_April__c : originalRecord.Expected_Order_Value_April__c,
                            Remarks_Apr__c: record.Remarks_Apr__c ? record.Remarks_Apr__c : originalRecord.Remarks_Apr__c,
                            
                            Order_Expected_Month_May__c: record.Order_Expected_Month_May__c ? record.Order_Expected_Month_May__c : originalRecord.Order_Expected_Month_May__c,
                            Order_Expected_Stage_May__c: record.Order_Expected_Stage_May__c ? record.Order_Expected_Stage_May__c : originalRecord.Order_Expected_Stage_May__c,
                            Expected_Order_Value_May__c: record.Expected_Order_Value_May__c ? record.Expected_Order_Value_May__c : originalRecord.Expected_Order_Value_May__c,
                            Remarks_May__c: record.Remarks_May__c ? record.Remarks_May__c : originalRecord.Remarks_May__c,
                            
                            Order_Expected_Month_Jun__c: record.Order_Expected_Month_Jun__c ? record.Order_Expected_Month_Jun__c : originalRecord.Order_Expected_Month_Jun__c,
                            Order_Expected_Stage_Jun__c: record.Order_Expected_Stage_Jun__c ? record.Order_Expected_Stage_Jun__c : originalRecord.Order_Expected_Stage_Jun__c,
                            Expected_Order_Value_June__c: record.Expected_Order_Value_June__c ? record.Expected_Order_Value_June__c : originalRecord.Expected_Order_Value_June__c,
                            Remarks_Jun__c: record.Remarks_Jun__c ? record.Remarks_Jun__c : originalRecord.Remarks_Jun__c,
                            
                            Order_Expected_Month_Jul__c: record.Order_Expected_Month_Jul__c ? record.Order_Expected_Month_Jul__c : originalRecord.Order_Expected_Month_Jul__c,
                            Order_Expected_Stage_Jul__c: record.Order_Expected_Stage_Jul__c ? record.Order_Expected_Stage_Jul__c : originalRecord.Order_Expected_Stage_Jul__c,
                            Expected_Order_Value_Jul__c: record.Expected_Order_Value_Jul__c ? record.Expected_Order_Value_Jul__c : originalRecord.Expected_Order_Value_Jul__c,
                            Remarks_Jul__c: record.Remarks_Jul__c ? record.Remarks_Jul__c : originalRecord.Remarks_Jul__c,
                            
                            Order_Expected_Month_Aug__c: record.Order_Expected_Month_Aug__c ? record.Order_Expected_Month_Aug__c : originalRecord.Order_Expected_Month_Aug__c,
                            Order_Expected_Stage_Aug__c: record.Order_Expected_Stage_Aug__c ? record.Order_Expected_Stage_Aug__c : originalRecord.Order_Expected_Stage_Aug__c,
                            Expected_Order_Value_Aug__c: record.Expected_Order_Value_Aug__c ? record.Expected_Order_Value_Aug__c : originalRecord.Expected_Order_Value_Aug__c,
                            Remarks_Aug__c: record.Remarks_Aug__c ? record.Remarks_Aug__c : originalRecord.Remarks_Aug__c,
                            
                            Order_Expected_Month_Sep__c: record.Order_Expected_Month_Sep__c ? record.Order_Expected_Month_Sep__c : originalRecord.Order_Expected_Month_Sep__c,
                            Order_Expected_Stage_Sep__c: record.Order_Expected_Stage_Sep__c ? record.Order_Expected_Stage_Sep__c : originalRecord.Order_Expected_Stage_Sep__c,
                            Expected_Order_Value_Sep__c: record.Expected_Order_Value_Sep__c ? record.Expected_Order_Value_Sep__c : originalRecord.Expected_Order_Value_Sep__c,
                            Remarks_Sep__c: record.Remarks_Sep__c ? record.Remarks_Sep__c : originalRecord.Remarks_Sep__c,
                            
                            Order_Expected_Month_Oct__c: record.Order_Expected_Month_Oct__c ? record.Order_Expected_Month_Oct__c : originalRecord.Order_Expected_Month_Oct__c,
                            Order_Expected_Stage_Oct__c: record.Order_Expected_Stage_Oct__c ? record.Order_Expected_Stage_Oct__c : originalRecord.Order_Expected_Stage_Oct__c,
                            Expected_Order_Value_Oct__c: record.Expected_Order_Value_Oct__c ? record.Expected_Order_Value_Oct__c : originalRecord.Expected_Order_Value_Oct__c,
                            Remarks_Oct__c: record.Remarks_Oct__c ? record.Remarks_Oct__c : originalRecord.Remarks_Oct__c,
                            
                            Order_Expected_Month_Nov__c: record.Order_Expected_Month_Nov__c ? record.Order_Expected_Month_Nov__c : originalRecord.Order_Expected_Month_Nov__c,
                            Order_Expected_Stage_Nov__c: record.Order_Expected_Stage_Nov__c ? record.Order_Expected_Stage_Nov__c : originalRecord.Order_Expected_Stage_Nov__c,
                            Expected_Order_Value_Nov__c: record.Expected_Order_Value_Nov__c ? record.Expected_Order_Value_Nov__c : originalRecord.Expected_Order_Value_Nov__c,
                            Remarks_Nov__c: record.Remarks_Nov__c ? record.Remarks_Nov__c : originalRecord.Remarks_Nov__c,
                            
                            Order_Expected_Month_Dec__c: record.Order_Expected_Month_Dec__c ? record.Order_Expected_Month_Dec__c : originalRecord.Order_Expected_Month_Dec__c,
                            Order_Expected_Stage_Dec__c: record.Order_Expected_Stage_Dec__c ? record.Order_Expected_Stage_Dec__c : originalRecord.Order_Expected_Stage_Dec__c,
                            Expected_Order_Value_Dec__c: record.Expected_Order_Value_Dec__c ? record.Expected_Order_Value_Dec__c : originalRecord.Expected_Order_Value_Dec__c,
                            Remarks_Dec__c: record.Remarks_Dec__c ? record.Remarks_Dec__c : originalRecord.Remarks_Dec__c


                        // }
                    // ]
                };
            }
            // return record;
        });

        console.log('completeRecords', JSON.stringify(completeRecords));

        updateBudgetLineItems({ updateMis: completeRecords })
            .then(() => {
                this.showToast('Success', 'Records updated successfully.', 'success');
                this.editedRecords = {};
                this.showButtons = false;
                // window.location.reload();
                this.fetchBudgetLineItems();

            })
            .catch(error => {
                console.error('Error saving records:', error);
                this.showToast('Error', 'Error saving records: ' + error.body.message, 'error');
                this.isLoading = false;
            });
    }

    handleCancel() {
        this.editedRecords = {};
        this.connectedCallback();
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