import { LightningElement ,track,wire} from 'lwc';
import getMisAndParentItems from '@salesforce/apex/MISDataDumpController.getMisAndParentItems';

export default class MISDataDump extends LightningElement {
    
    @track selectedFY;
    @track isLoading = false;
    @track financialYearOptions = [];
    @track showTable = true
    @track MISData = [];
    @track tableData = [];
    
    connectedCallback() {
        this.generateFinancialYears();
        this.getMisAndParentItems();
    }

    generateFinancialYears() {
        this.isLoading = true;
        const today = new Date();
        const currentMonth = today.getMonth() + 1;
        const currentYear = today.getFullYear();
        const fyStartYear = currentMonth >= 4 ? currentYear : currentYear - 1;

        const firstFyStartYear = 2025;
        let options = [];

        for (let year = firstFyStartYear; year <= fyStartYear; year++) {
            const endYear = (year + 1).toString().slice(-2);
            options.push({ label: `${year}-${endYear}`, value: `${year}-${endYear}` });
        }

        this.financialYearOptions = options;
        this.selectedFY = `${fyStartYear}-${(fyStartYear + 1).toString().slice(-2)}`;
        this.isLoading = false;
    }

    getMisAndParentItems() {
        this.isLoading = true;
        getMisAndParentItems({ selectedFY: this.selectedFY })
            .then(result => {
                this.MISData = result;
                this.ProcessData(result);
            })
            .catch(error => {
                console.error('❌ Error fetching data:', error);
                this.showTable = false;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    ProcessData(misData){

        if (!misData || misData.length === 0) {
            this.showTable = false;
            return;
        }
        this.isLoading = true;

        // Process each MIS record into table rows
        this.tableData = misData.map((item, index) => {
            // Collect the Order Expected Stage values
            const orderExpectedStages = [
                item.Order_Expected_Stage_Apr__c,
                item.Order_Expected_Stage_May__c,
                item.Order_Expected_Stage_Jun__c,
                item.Order_Expected_Stage_Jul__c,
                item.Order_Expected_Stage_Aug__c,
                item.Order_Expected_Stage_Sep__c,
                item.Order_Expected_Stage_Oct__c,
                item.Order_Expected_Stage_Nov__c,
                item.Order_Expected_Stage_Dec__c,
                item.Order_Expected_Stage_Jan__c,
                item.Order_Expected_Stage_Feb__c,
                item.Order_Expected_Stage_Mar__c
            ].filter(val => val && val.trim() !== '').join(', '); // Filter empty & join with comma


                        // ✅ Collect remarks dynamically
                const combinedRemarks = [
                    item.Remarks_Apr__c,
                    item.Remarks_Jun__c,
                    item.Remarks_Aug__c,
                    item.Remarks_Oct__c,
                    item.Remarks_Dec__c,
                    item.Remarks_Mar__c,
                    item.Remarks_Feb__c,
                    item.Remarks_Jan__c,
                    item.Remarks_Nov__c,
                    item.Remarks_Sep__c,
                    item.Remarks_Jul__c,
                    item.Remarks_May__c
                ].filter(val => val && val.trim() !== '').join(', ');


                const orderExpectedMonths = [
                item.Order_Expected_Month_Apr__c,
                item.Order_Expected_Month_May__c,
                item.Order_Expected_Month_Jun__c,
                item.Order_Expected_Month_Jul__c,
                item.Order_Expected_Month_Aug__c,
                item.Order_Expected_Month_Sep__c,
                item.Order_Expected_Month_Oct__c,
                item.Order_Expected_Month_Nov__c,
                item.Order_Expected_Month_Dec__c,
                item.Order_Expected_Month_Jan__c,
                item.Order_Expected_Month_Feb__c,
                item.Order_Expected_Month_Mar__c
            ].filter(val => val && val.trim() !== '').join(', ');


                const expectedOrderValues = [
                item.Expected_Order_Value_April__c,
                item.Expected_Order_Value_May__c,
                item.Expected_Order_Value_June__c,
                item.Expected_Order_Value_Jul__c,
                item.Expected_Order_Value_Aug__c,
                item.Expected_Order_Value_Sep__c,
                item.Expected_Order_Value_Oct__c,
                item.Expected_Order_Value_Nov__c,
                item.Expected_Order_Value_Dec__c,
                item.Expected_Order_Value_Jan__c,
                item.Expected_Order_Value_Feb__c
            ]
            .filter(val => val !== null && val !== undefined && val !== '' && val !== 0) // remove blanks & zero values
            .join(', ');




            return {
                id: item.Id,
                slNo: index + 1,
                budgetId: item.Budget_Line_Items__r?.Budget__r?.Name || '',
                budgetStatus: item.Budget_Line_Items__r?.Budget__r?.Status__c || '',
                misMonth: item.Mis_Monthly_Report__c ? new Date(item.Mis_Monthly_Report__c).toLocaleDateString() : '',
                //misMonth: 
                //misrencyCode: item.Budget_Line_Items__r?.Budget__r?.CurrencyIsoCode || '',
                currencyCode: item.Budget_Line_Items__r?.Budget__r?.CurrencyIsoCode || '',
                pmgName:item.Budget_Line_Items__r?.PMG_Name__c || '',
                pmgMonth: item.Mis_Monthly_Report__c ? new Date(item.Mis_Monthly_Report__c).toLocaleDateString() : '',
                curName: item.Budget_Line_Items__r?.PMG_Name__c || '',
                productGroup: item.Budget_Line_Items__r?.Product_Group_Name__c || '',
                description: item.Budget_Line_Items__r?.Description__c || '-',
                customerCode: item.Budget_Line_Items__r?.Customer_Code__c || '',
                customerName: item.Budget_Line_Items__r?.Customer_Name__c || '',
                annualPotential: item.Budget_Line_Items__r?.Annual_Potential__c || 0,
                orderExpectedStage:orderExpectedStages|| '-',
                remarks: combinedRemarks || '-',
                orderExpectedValue: expectedOrderValues || '-',
                orderType: item.Order_Type__c || '',
                budgetType: item.Budget_Line_Items__r?.Budget__r?.RecordType.Name || '',
                budgetMonth: item.Budget_Line_Items__r?.Budget_FN_Year__c || '',
                orderExpectedMonth: orderExpectedMonths || '-',
                branch: item.Budget_Line_Items__r?.Budget__r?.Branch_Name__c || '',
                misCreatedBy: item.CreatedBy?.Name || '',
                
                // // Get the current month's expected stage and month
                // orderExpectedStage: this.getCurrentMonthField(item, 'Order_Expected_Stage_'),
                // orderExpectedMonth: this.getCurrentMonthField(item, 'Order_Expected_Month_'),
                // budgetedOrder: this.getCurrentMonthField(item, 'Budget_Line_Items__r.', '_Order__c', true),
                // remarks: this.getCurrentMonthField(item, 'Remarks_')
            };
        });
        
        this.showTable = this.tableData.length > 0;

    }
   

 


    handleFYChange(event) {
        this.selectedFY = event.detail.value;
       this.getMisAndParentItems();

    }
}