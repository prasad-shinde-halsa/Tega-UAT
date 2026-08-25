import { LightningElement ,api,track,wire} from 'lwc';
import getDCBudget from '@salesforce/apex/SelectBudgetMonthForFlowController.getDCBudget';

export default class SelectBudgetMonthForFlow extends LightningElement {

    @api inputId;
    @api selectedMonth;
    selectedMonth
    @track monthOptions = []
    @track totalOrderValue = 0.00
    selectedMonthValue = 0.00;
    currency = ''
    budgetRecord = {};
    formattedSelectedMonthValue

    connectedCallback(){

        this.getRecordDetails()
    }

    getRecordDetails(){

        getDCBudget({ BLIid: this.inputId })
        .then( result =>{
            this.budgetRecord = result;
            this.totalOrderValue = result.Total_Order__c
            this.currency = result.Budget__r.CurrencyIsoCode
            console.log(
                'currency: ' + this.currency)
            this.buildMonthOptions(result);
        })
        .catch(error => {
                console.error('❌ Error fetching data:', error);
            })
            .finally(() => {
               
            });
    }
    buildMonthOptions(record) {
        const monthMap = [
            { label: 'April', value: 'Apr', field: 'Apr_Order__c' },
            { label: 'May', value: 'May', field: 'May_Order__c' },
            { label: 'June', value: 'Jun', field: 'Jun_Order__c' },
            { label: 'July', value: 'Jul', field: 'Jul_Order__c' },
            { label: 'August', value: 'Aug', field: 'Aug_Order__c' },
            { label: 'September', value: 'Sep', field: 'Sep_Order__c' },
            { label: 'October', value: 'Oct', field: 'Oct_Order__c' },
            { label: 'November', value: 'Nov', field: 'Nov_Order__c' },
            { label: 'December', value: 'Dec', field: 'Dec_Order__c' },
            { label: 'January', value: 'Jan', field: 'Jan_Order__c' },
            { label: 'February', value: 'Feb', field: 'Feb_Order__c' },
            { label: 'March', value: 'Mar', field: 'Mar_Order__c' }
        ];

        this.monthOptions = monthMap
            .filter(m => record[m.field] != null && record[m.field] > 0)
            .map(m => ({ label: m.label, value: m.value }));
    }
    handleMonthChange(event) {
        this.selectedMonth = event.detail.value; // Output to Flow
        console.log('Selected Month: ' + this.selectedMonth )
         this.updateSelectedMonthValue();
    }

    updateSelectedMonthValue() {
        console.log('Entering Selected Month: ' + this.selectedMonth )
        if (!this.selectedMonth) return;
        
        const monthFieldMap = {
            'Apr': 'Apr_Order__c',
            'May': 'May_Order__c',
            'Jun': 'Jun_Order__c',
            'Jul': 'Jul_Order__c',
            'Aug': 'Aug_Order__c',
            'Sep': 'Sep_Order__c',
            'Oct': 'Oct_Order__c',
            'Nov': 'Nov_Order__c',
            'Dec': 'Dec_Order__c',
            'Jan': 'Jan_Order__c',
            'Feb': 'Feb_Order__c',
            'Mar': 'Mar_Order__c'
        };

        const fieldName = monthFieldMap[this.selectedMonth];
        console.log('fieldName: ' + fieldName )
        this.selectedMonthValue = this.budgetRecord[fieldName] || 0.00;
        console.log('Selected Month Value: ' + this.selectedMonthValue);
        this.setFormattedValue(this.selectedMonthValue)
    }
    // Computed property for display
    setFormattedValue(value) {

         this.formattedSelectedMonthValue = `${this.currency} ${value.toLocaleString()}`;
         console.log('formattedSelectedMonthValue: ' + this.formattedSelectedMonthValue )
    }
}