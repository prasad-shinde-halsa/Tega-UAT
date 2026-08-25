import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import cloneBudget from'@salesforce/apex/DC_BudgetCloner.cloneBudget';
import { NavigationMixin } from 'lightning/navigation';

export default class DC_BudgetClonerLWC extends NavigationMixin(LightningElement) {


    @api recordId; // The record ID from the record page
    @track cloneSuccess = false
    @track newClonedBudgetId = '';

    @track errorMessagePara = false;
    @track errorMessage = '';



    handleFullDataClone() {
        this.cloneData();
         
    }

    handleRedirection(){
        console.log('clone budget:: ', this.newClonedBudgetId)
        this.openRecordInBackground(this.newClonedBudgetId)
    }

    cloneData() {

        let recordDetails = {};
        let errorDetails = '';

        if( true ){
            cloneBudget({ recordId: this.recordId })
            .then(result => {
                console.log('result:  ', result);
                recordDetails = result;
                errorDetails = undefined;
                //window.open('https://tegaindustrieslimited--uatdev.sandbox.lightning.force.com/lightning/r/DC_Budget__c/'+recordDetails+'/view', '_blank');
                console.log('recordDetails:: ',recordDetails);
                //this.showToastHandler(`The clone record is created with record ID ${recordDetails}`)
               
                if(recordDetails.status == 201){
                    this.cloneSuccess = true;
                    this.newClonedBudgetId = recordDetails.createdBudget;
                }
                if(recordDetails.status == 203){
                    this.errorMessagePara = true;
                    this.errorMessage = recordDetails.message;
                }
                if(recordDetails.status == 204){
                    this.errorMessagePara = true;
                    this.errorMessage = recordDetails.message;
                }
                if(recordDetails.status == 205){
                    this.errorMessagePara = true;
                    this.errorMessage = recordDetails.message;
                }
                if(recordDetails.status == 404){
                    this.errorMessagePara = true;
                    this.errorMessage = recordDetails.message;
                }

                //this.openRecordInBackground(recordDetails)
            })
            .catch(error => {
                errorDetails = error;
                recordDetails = undefined;
            })

        }

        /* this.dispatchEvent(
            new ShowToastEvent({
                title: 'Clone Started',
                message: `${type} has been initiated for record ID: ${this.recordId}`,
                variant: 'success',
            })
        ); */
    }

    showToastHandler(text){
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Clone Started',
                message: text,
                variant: 'success',
            })
        );
    }

    openRecordInBackground(recId) {
        // Generate the record page URL
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recId,
                objectApiName: 'DC_Budget__c', // Replace with your object's API name
                actionName: 'view'
            }
        }).then((url) => {
            // Open the record in a new background tab
            window.open(url, '_blank'); // _blank opens in a new tab
        }).catch((error) => {
            console.error('Error generating URL:', error);
        });
    }

}