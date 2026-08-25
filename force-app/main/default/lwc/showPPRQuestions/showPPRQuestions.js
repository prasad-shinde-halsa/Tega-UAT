import { LightningElement,api, wire,track } from 'lwc';
import getQuestionaWrapperList from '@salesforce/apex/ShowQuestionariesController.getQuestionaWrapperList';
import createMultipleRecord from '@salesforce/apex/ShowQuestionariesController.createMultipleRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

let i=0;
let j=0;

export default class WrapperInLwc extends NavigationMixin(LightningElement) {
    @track results;
    @api recordId;
    isError = false;   

    @wire(getQuestionaWrapperList, {RecId: '$recordId'})
    wrapperList({ data, error }) {
        if(data){
            console.log('Data'+JSON.stringify(data));
            this.results = data
            console.log(data);
        }else{
            console.log('Error'+error);
        }
    }

    //Cancel Button --> onClick --> NavigateTo PPRLIneItem Recordpage
    navigateToRecordPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'PPR_Line_Item__c',
                actionName: 'view'
            }
        });
    }

    //Save Button --> onClick --> saveButtonHandler
    saveButtonHandler(){
        //this.updateRecordView();
        console.log('Inside Save Button handler');
        var wrapList= [];
        let count = 0;
        console.log('Results:', this.results);
        for(let res of this.results){
            console.log('res =>'+res);
            for(let ques of res.questions){
                console.log('ques =>'+ques);
                let pprId = this.recordId;
                let qmId = ques.QuestionMaster;
                let ans = this.template.querySelector('[data-id="' +qmId+ '"]').value;
                let cbVal = this.template.querySelector('[data-id="' +qmId+ '"]').value; 
                console.log('PprId:',pprId);
                console.log('QMid:',qmId);
                console.log('Ans:',ans);
                console.log('cbVal:',cbVal );
               
                if(ques.isMandatory == true && ans == ''){
                    this.isError = true;
                    wrapList[count] = pprId+';'+qmId + ';' + ans ;
                    count = count+1;
                }else if(ques.isMandatory == true && ans != ''){
                    wrapList[count] = pprId+';'+qmId + ';' + ans ;
                    count = count+1;
                }else if(ques.isMandatory == false && ans != ''){
                    wrapList[count] = pprId+';'+qmId + ';' + ans ;
                    count = count+1;
                }
            }
        }

        /*this.results.questions.forEach(element => {
            let pprId = this.recordId;
            let qmId = element.QuestionMaster;
            let ans = this.template.querySelector('[data-id="' +qmId+ '"]').value;
            let cbVal = this.template.querySelector('[data-id="' +qmId+ '"]').value; 
            console.log('PprId:',pprId);
            console.log('QMid:',qmId);
            console.log('Ans:',ans);
            console.log('cbVal:',cbVal );
            wrapList[count] = pprId+';'+qmId + ';' + ans ;
            count = count+1;
        });*/
        console.log('Error exist',this.isError);
       console.log('WrapList:',wrapList);
       console.log('WrapList JSON:',JSON.stringify(wrapList));

        if(this.isError == false){
            createMultipleRecord({ qnaWrapper : wrapList})
        .then((result) => {
            console.log('result =>',result);
            //if(result != null){
                this.error= undefined;
                const event = new ShowToastEvent({
                    title: 'Success!',
                    message: 'Record created, Successfully!',
                    variant: 'Success',
                });
                this.dispatchEvent(event);
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'PPR_Question_Answer__c',
                        actionName: 'view'
                    }
                });
            /*}else{
                const event = new ShowToastEvent({
                title: 'Error!',
                message: 'Please contact your system admin..!',
                variant: 'Error',
                });
                this.dispatchEvent(event);
            }*/
        })
        .catch((error)=> {
            console.log('Errpr 110 =>'+JSON.stringify(error));
            this.error = error;
            this.result = undefined;
            const event = new ShowToastEvent({
                title: 'Error!',
                message: 'Please contact your system admin..!',
                variant: 'Error',
            });
            this.dispatchEvent(event);
        });
        }else if(this.isError == true){
            const event = new ShowToastEvent({
                title: 'Error!',
                message: 'Please fill all mandatory answers',
                variant: 'Error',
            });
            this.dispatchEvent(event);
        }
        
    }
}