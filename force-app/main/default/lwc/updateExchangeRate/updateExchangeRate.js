import { LightningElement, track, wire } from 'lwc';
import getAvailableFinancialYears from '@salesforce/apex/UpdateExchangeRateLWCController.getAvailableFinancialYears';
import getCurrenciesByFinancialYear from '@salesforce/apex/UpdateExchangeRateLWCController.getCurrenciesByFinancialYear';
import getBudgetRecords from '@salesforce/apex/UpdateExchangeRateLWCController.getBudgetRecords';
import runBatch from '@salesforce/apex/UpdateExchangeRateLWCController.runBatch';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';  

export default class UpdateExchangeRateLWC extends LightningElement {
    @track financialYearOptions = [];  
    @track selectedFinancialYear;  
    @track currencyOptions = [];  
    @track selectedCurrencies = [];  
    @track budgetRecords = [];

    @wire(getAvailableFinancialYears)
    wiredFinancialYears({ error, data }) {
        if (data) {
            this.financialYearOptions = data;
        } else if (error) {
            console.error(error);
        }
    }

    handleFinancialYearChange(event) {
        this.selectedFinancialYear = event.detail.value;  

        if (this.selectedFinancialYear) {
            getCurrenciesByFinancialYear({ financialYear: this.selectedFinancialYear })
                .then((result) => {
                    this.currencyOptions = result.map((isoCode) => {
                        return { label: isoCode, value: isoCode };  
                    });
                })
                .catch((error) => {
                    console.error(error);
                });
        }
    }

    handleCurrencySelection(event) {
        this.selectedCurrencies = event.detail.value; 
        this.fetchBudgetRecords(); 
    }

    fetchBudgetRecords() {
        if (this.selectedFinancialYear && this.selectedCurrencies && this.selectedCurrencies.length > 0) {
            getBudgetRecords({ 
                financialYear: this.selectedFinancialYear, 
                currencyIsoCodes: this.selectedCurrencies 
            })
            .then(result => {
                this.budgetRecords = result;
            })
            .catch(error => {
                console.error('Error fetching budget records:', error);
            });
        }
    }

    runBatch() {
        if (!this.selectedFinancialYear || !this.selectedCurrencies.length) {
            this.showToast('Error', 'Please select a financial year and currencies.', 'error');
            return;
        }

        const budgetIdList = this.budgetRecords.map(record => record.Id);

        runBatch({ 
            financialYear: this.selectedFinancialYear, 
            currencyIsoCodes: this.selectedCurrencies,
            budgetIdList: budgetIdList
        })
            .then(() => {
                this.showToast('Success', 'Exchange Rate Updated.', 'success');
                window.location.reload(); 
            })
            .catch((error) => {
                console.error('Error running batch job', error);
                this.showToast('Error', 'Exchange Rate not Updated.', 'error');
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant, 
        });
        this.dispatchEvent(event);
    }
}