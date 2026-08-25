public class ShowQuestionariesController {
 /*
 Method to create multiple records of PPR questions & Answer
 */ 
    @AuraEnabled
    public static void createMultipleRecord(List<String> qnaWrapper){
        try {
        Integer existingQnA;
        Integer lwcQnA;
        String RecId;
            System.debug('$qnaWrapper:'+qnaWrapper);
        for (String qna : qnaWrapper){
            RecId = qna.split(';')[0];
        }
      
        System.debug('RecId:'+RecId);
        //Creating PPRQna List
        List<PPR_Question_Answer__c> qnaList = [SELECT Id, Name, PPR_Line_Item__c,Question_Master__c,Answer__c FROM PPR_Question_Answer__c WHERE PPR_Line_Item__c =: RecId];
        System.debug('QnaList:'+qnaList);
        
        //Creating set of QnA(ID's) for PPRLineItem: [Existing set of QNA in Database]
            Set<ID> existingQnaSet = new Set<ID>();
            for(PPR_Question_Answer__c objPprQna: qnaList){
                existingQnaSet.add(objPprQna.Question_Master__c);
            }
            existingQnA = existingQnaSet.size();
            System.debug('$existingQnaSet:'+existingQnaSet);
            System.debug('$No_of_existingQnA:'+existingQnA);
        
        //Craeting Set of qxisting Updated.
            Set<ID> existingUpdated = existingQnaSet.clone();

        //Creating Set of QNA on the LWC Component
            Set<ID> lwcQnaSet = new Set<ID>();
            for (String objLwcQna: qnaWrapper){
                String qmID = objLwcQna.split(';')[1];
                lwcQnaSet.add(qmID);
            }
            lwcQnA = lwcQnaSet.size();
            System.debug('$lwcQnaSet:'+lwcQnaSet);
            System.debug('$No_of_lwcQnA:'+lwcQnA);

        // Creating Set of lwcQna Updated
            Set<ID> lwcQnaUpdated = lwcQnaSet.clone();
            Set<ID> lwcQnaUpdated2 = lwcQnaSet.clone();

        // getting Set pf ID's to be Inserted
            lwcQnaUpdated2.removeAll(existingQnaSet);
            System.debug('$et to Insert:'+lwcQnaUpdated2);
           
        // getting Set pf ID's to be Updated
            lwcQnaSet.retainAll(existingQnaSet);
            System.debug('$et to Update:'+lwcQnaSet);

        // getting Set pf ID's to be Deleted
            existingUpdated.removeAll(lwcQnaSet);
            System.debug('$et to Delete:' +existingUpdated);

        //Inserting Fresh Records if None QNA existed on PPR Line item. 
        System.debug('QnAWrapper:'+qnaWrapper);
        List<PPR_Question_Answer__c> pprQnAList = new List <PPR_Question_Answer__c>();
            System.debug('QNA List:'+qnaList);
                for(String qna: qnaWrapper){
                    if(lwcQnaUpdated2.contains((ID)qna.split(';')[1])){
                        PPR_Question_Answer__c objPPRQnA = new PPR_Question_Answer__c();
                        System.debug('qnaSplit=:-->'+qna.split(';')[0]);
                        objPPRQnA.PPR_Line_Item__c = qna.split(';')[0];
                        objPPRQnA.Question_Master__c = qna.split(';')[1];
                        system.debug('qna =>'+qna);
                        objPPRQnA.Answer__c = qna.split(';')[2];
                        // objPPRQnA.Answer__c = qna.split(';')[3];
                        // system.debug('cbVal =>'+qna.split(';')[3]);
                        pprQnAList.add(objPPRQnA);  
                    }
                    System.debug('pprQnAList:'+pprQnAList);
                }
                SObjectType schemaType = Schema.getGlobalDescribe().get('PPR_Question_Answer__c');
                if(schemaType.getDescribe().isCreateable()){
                    insert pprQnAList;
                }
        
        //Updating Records
        List<PPR_Question_Answer__c> qnaListTobeUpdated = new List <PPR_Question_Answer__c>();    
            for (PPR_Question_Answer__c objQna: [SELECT Id, Name, Question__c, Answer__c, PPR_Line_Item__r.Id, Question_Master__r.Id FROM PPR_Question_Answer__c WHERE Question_Master__r.Id IN: lwcQnaSet ]){
                System.debug('##ObjQna:'+lwcQnaSet);
                for (String qna : qnaWrapper){
                    Boolean isNewQuestion = false;
                    String pprId = qna.split(';')[0];
                    String qmId = qna.split(';')[1];
                    String ans = qna.split(';')[2];
                    // String cbVal = qna.split(';')[3];
                        System.debug('$pprID:'+pprId);
                        System.debug('$qmId:'+qmId);
                        System.debug('$ans:'+ans);
                        // System.debug('$cbVal:'+cbVal);
                        if (objQna.PPR_Line_Item__r.Id == pprId && objQna.Question_Master__r.Id == qmID){
                            objQna.Answer__c = ans;
                                System.debug('$objQna.Answer__c'+objQna.Answer__c);
                                qnaListTobeUpdated.add(objQna);
                                System.debug('$qnaListTobeUpdated:'+qnaListTobeUpdated);
                        }
                    }
                }
         //   if(schemaType.getDescribe().isUpdateable()){
                 update qnaListTobeUpdated;              
           //  }    
            
            System.debug('$UpdatedQnaList:'+qnaListTobeUpdated);

        //Deleting Records
        List<PPR_Question_Answer__c> qnaListTobeDeleted = new List <PPR_Question_Answer__c>();
            for(PPR_Question_Answer__c objQna : [SELECT Id, Name, Question__c, Answer__c, PPR_Line_Item__r.Id, Question_Master__r.Id FROM PPR_Question_Answer__c WHERE Question_Master__r.Id IN: existingUpdated ] ){
                qnaListTobeDeleted.add(objQna);
            }
           if(schemaType.getDescribe().isDeletable()){ 
            delete qnaListTobeDeleted;
           } 

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
/*
Creating Wrapper class for the PPRLine Items. Dynamic fields passing label to the UI from Question master object.
*/

    @AuraEnabled(cacheable=true)
    public static List<FailureQuestionsWrap> getQuestionaWrapperList(Id RecId) {
        List<FailureQuestionsWrap> wrapperListToReturn = new List<FailureQuestionsWrap>();
        try{
        Set<String> categorySet = new Set<String>();
        System.debug('$RecId:'+RecId);
        PPR_Line_Item__c pli = [select Id,Failure_Category__c,PMG__c from PPR_Line_Item__c where Id=: RecId limit 1];
        String pmg = pli.PMG__c ;
        String failurecat = pli.Failure_Category__c;
        String[] failureCatList = failurecat.split(';');
        system.debug('failureCatList===>'+failureCatList);


        List<PPR_Question_Answer__c> QnAList = [SELECT Id, Name, Question_Master__c, Answer__c, PPR_Line_Item__c, Question__c FROM PPR_Question_Answer__c WHERE PPR_Line_Item__c=: RecId];
        System.debug('QnAList:'+QnAList);

        Map<String,String> QnAMap = new Map<String, String>();
            for(PPR_Question_Answer__c objPPRQnA: QnAList){
                QnAMap.put(objPPRQnA.Question_Master__c,objPPRQnA.Answer__c);
                System.debug('QnAMap:'+QnAMap);
            }


        List<QuestionWrapper> wrapperList = new List<QuestionWrapper>();
        for(Question_Master__c qm: [select id, Failure_Category__c,PMG__c,Question_Label__c,Question_Type__c,Sequence__c,Drop_Down_Options__c,Mandatory__c
        from Question_Master__c where PMG__c=:pmg and Failure_Category__c in:failureCatList ORDER BY Sequence__c]){
            system.debug('qm===>'+qm);
            QuestionWrapper wc = new QuestionWrapper();
            wc.QuestionLabel = qm.Question_Label__c;
            wc.failureCategory = qm.Failure_Category__c;
            wc.dataType = qm.Question_Type__c;
            wc.QuestionMaster = qm.id;

            //Populate prefilled ans on the UI.
            if(QnAMap.containsKey(qm.id)){
                wc.Answer = QnAMap.get(qm.id);
            }

            wc.Sequence = qm.Sequence__c;
            if(qm.Question_Type__c == 'Text'){
                wc.isText = true;
                wc.isDate = false;
                wc.isDropDown = false;
                wc.isCheckBox =false;
                if(qm.Mandatory__c == true){
                    wc.isMandatory = true;
                }
                else{
                    wc.isMandatory = false;
                }
            }  
            else if(qm.Question_Type__c == 'Drop-Down'){
                wc.isText = false;
                wc.isDate = false;
                wc.isDropDown = true;
                wc.isCheckBox =false;
                
                List<String> optionsList = qm.Drop_Down_Options__c.split(';');
                List<OptionWrapper> optionWrapperList = new List<OptionWrapper>();
                for(String str : optionsList){
                    OptionWrapper opWrap = new OptionWrapper(str,str);
                    optionWrapperList.add(opWrap);
                }
                wc.options2 = optionWrapperList;
                
                wc.options = qm.Drop_Down_Options__c.split(';');
                if(qm.Mandatory__c == true){
                    wc.isMandatory = true;
                }
                else{
                    wc.isMandatory = false;
                }
            }    
           else if(qm.Question_Type__c == 'Date'){
                wc.isText = false;
                wc.isDate = true;
                wc.isDropDown = false;
                wc.isCheckBox =false;
                if(qm.Mandatory__c == true){
                    wc.isMandatory = true;
                }
                else{
                    wc.isMandatory = false;
                }
            }  

            // else if(qm.Question_Type__c == 'Checkbox'){
            //     wc.isText = false;
            //     wc.isDate = false;
            //     wc.isDropDown = false;
            //     wc.isCheckBox =true;
            //     if(qm.Mandatory__c == true){
            //         wc.isMandatory = true;
            //     }
            //     else{
            //         wc.isMandatory = false;
            //     }
            // }  
            wrapperList.add(wc);
        }
        system.debug('wrapperList =>'+wrapperList);

        Map<String,List<QuestionWrapper>> failureCateQuestionMap = new Map<String,List<QuestionWrapper>>();
        for(QuestionWrapper qw : wrapperList){
                if(!failureCateQuestionMap.containsKey(qw.failureCategory)){
                    List<QuestionWrapper> quesWrapList = new List<QuestionWrapper>();
                    quesWrapList.add(qw);
                    failureCateQuestionMap.put(qw.failureCategory, quesWrapList);
                }else if(failureCateQuestionMap.containsKey(qw.failureCategory)){
                    List<QuestionWrapper> quesWrapList = failureCateQuestionMap.get(qw.failureCategory);
                    quesWrapList.add(qw);
                    failureCateQuestionMap.put(qw.failureCategory, quesWrapList);
                }
        }

       

        for(String failCatKey : failureCateQuestionMap.keySet()){
            FailureQuestionsWrap failCatWrap = new FailureQuestionsWrap();
            failCatWrap.failureCategory = failCatKey;
            failCatWrap.questions = failureCateQuestionMap.get(failCatKey);
            wrapperListToReturn.add(failCatWrap);
        }
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'ShowQuestionariesController',  'getQuestionaWrapperList');
        }
        return wrapperListToReturn;
    }
    
    public class QuestionWrapper{
        @AuraEnabled public String QuestionLabel;
        @AuraEnabled public String dataType;
        @AuraEnabled public Decimal Sequence;
        @AuraEnabled public String QuestionMaster;
        @AuraEnabled public String Answer;
        @AuraEnabled public Boolean isText;
        @AuraEnabled public Boolean isDate;
        @AuraEnabled public Boolean isDropDown;
        @AuraEnabled public Boolean isCheckBox;
        @AuraEnabled public Boolean isMandatory;
        @AuraEnabled public string[] options;
        @AuraEnabled public OptionWrapper[] options2;
        @AuraEnabled public String failureCategory;
    }

    public class FailureQuestionsWrap{
        @AuraEnabled public list<QuestionWrapper> questions;
        @AuraEnabled public String failureCategory;
    }
    
    public class OptionWrapper{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}