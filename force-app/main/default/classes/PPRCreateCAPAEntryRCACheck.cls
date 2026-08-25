public class PPRCreateCAPAEntryRCACheck {
    @InvocableMethod
    public static List<String> userCCMApproval(List<List<String>> ubList){
        List<String> retToFlow = new List<String>();
        try{
        List<String> ubIdList =  ubList[0];
        System.debug('#ubIdList:'+ubIdList);
        String pprID = ubIdList[0];
        System.debug('#pprID:'+pprID);
        
        //Get PPR Record
        List<PPR_Line_Item__c> pprList =[SELECT Id, Name, Drafting_Dept__c, Drawing_Change__c, Logistics__c, Manufacturing__c, 
                                         Offer_Team__c, Others__c, Purchase__c, Quality_QA__c, Quality_QC__c, Sales__c, 
                                         Sales_Back_Office__c, TSS__c 
                                         FROM PPR_Line_Item__c
                                         WHERE Id =: pprID];
        //Make RCACheckedList
        List<String> rcaCheckedList = new List<String>();
        
        //Check for checked Checkboxes
        for (PPR_Line_Item__c objPPR: pprList){
            if (objPPR.Drafting_Dept__c == true ){
                rcaCheckedList.add('CCDI');
            }
            if (objPPr.Quality_QC__c == true){
                rcaCheckedList.add('CCQL');
            }
            if(objPPr.Quality_QA__c == true){
                rcaCheckedList.add('CCQA');
            }
            if(objPPr.Sales__c == true){
                rcaCheckedList.add('CCSL');
            }
            if(objPPr.Drawing_Change__c == true){
                rcaCheckedList.add('CCDR');
            }
            if(objPPr.Purchase__c == true){
                rcaCheckedList.add('CCPR');
            }
            if(objPPr.Logistics__c == true){
                rcaCheckedList.add('CCLG');
            }
            if(objPPr.Sales_Back_Office__c == true){
                rcaCheckedList.add('CCSB');
            }
            if(objPPr.TSS__c == true){
                rcaCheckedList.add('CCTS');
            }
            if(objPPr.Offer_Team__c == true){
                rcaCheckedList.add('CCOF');
            }
            if(objPPr.Manufacturing__c == true){
                rcaCheckedList.add('CCMF');
            }
            if(objPPr.Others__c == true){
                rcaCheckedList.add('CCOT');
            }
            
        }
        
        System.debug('CheckedList'+rcaCheckedList);
        String returnString = String.join(rcaCheckedList,',');
        System.debug('returnString'+returnString);
        
        retToFlow.add(returnString);
        
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'PPRCreateCAPAEntryRCACheck',  'userCCMApproval');
        }
        return retToFlow;
    }
}