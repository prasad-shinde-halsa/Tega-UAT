/*
Name : OfferTriggerHelper 
Desc : This is a handler class of OfferTriggerHandler
US :
*/
public class OfferTriggerHelper {
    /*
Name : updateScopeWithOffer
Desc : this method use to update offer  in scope with selection.
*/
    public static void updateScopeWithOffer(Map<Id,SObject> newMap, Map<Id,SObject> oldMap){
        try{
        system.debug('---updateScopeWithOffer-->>');
        Map<String, Id> SAPOfferNumMap = new Map<String, Id>();
        Id recordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        for(SObject obj : newMap.values()){
            Quote offr = (Quote)obj;
            
            if(oldMap != null ){
                if(oldMap.get(offr.Id).get('SAP_Offer_Id__c') !=  offr.SAP_Offer_Id__c 
                   && String.isNotBlank(offr.SAP_Offer_Id__c) && offr.RecordTypeId == recordTypeId){
                       SAPOfferNumMap.put(offr.SAP_Offer_Id__c, offr.Id);
                   }                
            }else {
                if(String.isNotBlank(offr.SAP_Offer_Id__c) && offr.RecordTypeId == recordTypeId){
                    SAPOfferNumMap.put(offr.SAP_Offer_Id__c, offr.Id);
                }
            }
        }
        
        List<Scope_With_Selection__c> scopeSelList = [SELECT Id,Proposal_Form__r.SAP_Offer_Number__c,Offer__c  
                                                      FROM Scope_With_Selection__c 
                                                      WHERE Proposal_Form__r.SAP_Offer_Number__c IN : SAPOfferNumMap.keySet()];
        
        System.debug('scopeSelList-->>'+scopeSelList);
        if(scopeSelList != null && scopeSelList.size() > 0 ){
            for(Scope_With_Selection__c sc : scopeSelList){
                if(SAPOfferNumMap.containsKey(sc.Proposal_Form__r.SAP_Offer_Number__c)){
                    sc.Offer__c = SAPOfferNumMap.get(sc.Proposal_Form__r.SAP_Offer_Number__c);
                }
            }
            
            update scopeSelList;
        }
        
        } catch (Exception e) {TegaUtility.trackLogs( e,  'OfferTriggerHelper',  'updateScopeWithOffer');}
    }
    
    
    public static void validateOfferOnFinialze(Map<Id,SObject> newMap, Map<Id,SObject> oldMap){
    list<Id> quotelistToValidate = new list<Id>();
        for(SObject Obj : newMap.values()) {
            Quote offer = (Quote)obj;
            if(newMap.get(offer.Id).get('status') == 'Finalized' && (newMap.get(offer.Id).get('status') != oldMap.get(offer.Id).get('status') )){
                quotelistToValidate.add(offer.Id);
            }
            
         }    
         list<QuoteLineItem> quoteLineItemZeroBTP = new list<QuoteLineItem>([select Id,quoteId from quoteLineItem where quoteId in:quotelistToValidate and BTP_Price__c =0]);
         
         for(QuoteLineItem qli : quoteLineItemZeroBTP){
             newMap.get(qli.quoteId).addError(Label.BTPZeroOfferError);
         }
    
    }
    
    /*
Name : CreateOfferSpareMethod
Desc : this method use to update SapOfferId  in Offer.
*/
    public static void CreateSAPOfferId(Map<Id, SObject> newMap, Map<Id,SObject> oldMap) {
        try{
        Map <Id, Quote> offertoUpdate = new Map <Id, Quote>();
        Id recordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer').getRecordTypeId();
        Id recordTypeIdNonSpare = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        Integration_Transaction__c IT = new Integration_Transaction__c();
        for(SObject Obj : newMap.values()) {
            Quote offer = (Quote)obj;
            if(oldMap != null ){
                if((Offer.Status == 'LS' && oldMap.get(offer.Id).get('Status') !=  'LS' || 
                   Offer.Status == 'HO' && oldMap.get(offer.Id).get('Status') !=  'HO' ||
                   Offer.Status == 'DF' && oldMap.get(offer.Id).get('Status') !=  'DF' || 
                   Offer.Status == 'Closed and Lost' && oldMap.get(offer.Id).get('Status') !=  'Closed and Lost') &&
                   String.isNotBlank(Offer.Status) && Offer.RecordTypeId == recordTypeIdNonSpare){
                        
                       IT.Record_Id__c=offer.Id;
                       IT.Status__c='Draft';
                       IT.Operation__c = 'Send Acknowledgement to SAP';
                       IT.Request__c = offer.QuoteNumber;
                       insert IT;
                       NonSpareOfferAcknowledgementHelper.SendAcknowledgementToSAP(offer.Id,IT.Id);
                        
                }
                
                // status chnages subham
                if(Offer.Status == 'Finalized' && oldMap.get(offer.Id).get('Status') !=  Offer.Status 
                   && String.isNotBlank(Offer.Status) && Offer.RecordTypeId == recordTypeId && Offer.Approval_Status__c =='Submitted'
                   && Offer.Discount_Value__c != null && Offer.Discount_Value__c <= 1 && String.isBlank(Offer.SAP_Offer_Id__c)  ){// condtion modified by Ranjeet
                       offertoUpdate.put(Offer.id, offer);
                       IT.Record_Id__c=offer.Id;
                       IT.Status__c='Draft';
                       IT.Operation__c = 'Create Offer Spare';
                       IT.Request__c = offer.QuoteNumber;
                       insert IT;
                   }
                   
                
               else if(Offer.Status == 'Approved' && offer.Approval_Status__c == 'Price Accepted' && String.isBlank(Offer.SAP_Offer_Id__c) //is blanlk added by Ranjeet
                    && String.isNotBlank(Offer.Status) && Offer.RecordTypeId == recordTypeId && (oldMap.get(offer.Id).get('Approval_Status__c') !=  Offer.Approval_Status__c || oldMap.get(offer.Id).get('Status') !=  Offer.Status) ){
                       offertoUpdate.put(Offer.id, offer);
                       IT.Record_Id__c=offer.Id;
                       IT.Status__c='Draft';
                       IT.Operation__c = 'Create Offer Spare';
                       IT.Request__c = offer.QuoteNumber;
                       insert IT;
                   }
                 
                
            }  
            
            
        }
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'OfferTriggerHelper',  'CreateSAPOfferId');
            
        }
        
    }

    /*
    Name : populatePriceBook
    Desc : this method populate Price book in offer.
    */
    public static void populatePriceBook(List<Quote> newOfferList){
        try{
        Id offerSpareRecordTypeId = TegaUtilityWithoutSharing.getOfferRecordTypeId('Offer');
        Id priceBookId;
        if(Test.isrunningtest()){
            priceBookId = Test.getStandardPricebookId();
        }else { 
            Pricebook2 stdPriceBook = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];
            priceBookId = stdPriceBook.Id;
        }
        
        for(Quote offer : newOfferList){
            if(offer.recordTypeId == offerSpareRecordTypeId){
                offer.Pricebook2Id = priceBookId;
            }            
        }
        } catch (Exception e) {TegaUtility.trackLogs( e,  'OfferTriggerHelper',  'populatePriceBook');}
    }
    
         /*
    Name : populateHead
    Desc : this method use to populate RM Sales Head and PMG Head
    */
    public static void populateHead(List<Quote> newList, Map<Id,SObject> oldMap, boolean isUpdate){
        try{
        Set<Id> brachIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Map<Id,Id> branchMap = new Map<Id, Id>();
        Map<Id, String> oppIdsMap = new Map<Id, String>();
        for(Quote offr : newList){
            system.debug('Branch__c-->>'+offr.Branch__c);
            if(isUpdate){
                //if(oldMap.get(offr.Id).get('Branch__c') !=  offr.Branch__c){
                    brachIds.add(offr.Branch__c);
                    oppIds.add(offr.OpportunityId);                    
               // }                
            }else {
                if(String.isNotBlank(offr.Branch__c)){
                    brachIds.add(offr.Branch__c);
                    oppIds.add(offr.OpportunityId);
                }
            }
        }
                         
        system.debug('brachIds-->>'+brachIds);
        if(brachIds.size() > 0){ 
            List<Branch__c> branchList = [SELECT Id,Sales_Region__r.Manager__c FROM Branch__c 
                                          WHERE Id IN : brachIds AND Sales_Region__c !=null ];
            
            if(branchList !=null && branchList.size() > 0 ){
                for(Branch__c br : branchList){
                    branchMap.put(br.Id, br.Sales_Region__r.Manager__c);
                }
            }  
        }
        if(oppIds.size() > 0){
            List<opportunity> oppList = [SELECT Id, recordType.Name FROM opportunity 
                                        WHERE Id IN : oppIds];
            
            if(oppList != null && oppList.size() > 0 ){
                for(opportunity opp : oppList){
                    oppIdsMap.put(opp.Id, opp.recordType.Name);
                } 
            }            
        }
        
        List<User_Mappings__c> userMappingList = new List<User_Mappings__c>([Select Id,Object_Name__c,PMG__c,User__c,User_Type__c from User_Mappings__c WHERE 
                                                                            Object_Name__c = 'Quote' AND User_Type__c = 'PMG Head']);
        Map<String,Id> userMappingMap = new Map<String,Id>();
        
        for(User_Mappings__c userMap : userMappingList){
            userMappingMap.put(userMap.PMG__c,userMap.User__c);
        }
        
        Set<String> usernameSet = new Set<String>();
        for(Quote offr : newList){
            if(oppIdsMap.containsKey(offr.OpportunityId)){
                if(userMappingMap.containsKey(oppIdsMap.get(offr.OpportunityId))){
                    usernameSet.add(userMappingMap.get(oppIdsMap.get(offr.OpportunityId)));
                }                
            }
        }
        system.debug('usernameSet-->>'+usernameSet);
        
        Map<String, User> userNameMap = new Map<String, User>();
        List<User> userList = [SELECT Id, username FROM user WHERE username IN : usernameSet];
        if(userList != null && userList.size() > 0 ){
            for(user usr : userList){             
                userNameMap.put(usr.username, usr);
            }
        }
        system.debug('branchMap-->>'+branchMap);
        system.debug('userNameMap-->>'+userNameMap);
       for(Quote offr : newList){
            
            if(branchMap.containsKey(offr.Branch__c)){
                offr.Regional_Sales_Head__c = branchMap.get(offr.Branch__c);              
            }
             if(oppIdsMap.containsKey(offr.OpportunityId)){
                 if(userMappingMap.containsKey(oppIdsMap.get(offr.OpportunityId))){
                     String testuserId = userMappingMap.get(oppIdsMap.get(offr.OpportunityId));
                     system.debug('testuserId-->'+testuserId);
                     if(!userNameMap.isEmpty()){
                        offr.PMG_Head__c =  userNameMap.get(userMappingMap.get(oppIdsMap.get(offr.OpportunityId))).Id;
                     }
              }                
            }
        }
        } catch (Exception e) {TegaUtility.trackLogs( e,  'OfferTriggerHelper',  'populateHead');}
       
    }
    
    public static void afterIDcreation(List<Quote> newList){
        try{
        Id userId = userinfo.getUserId();
        User user = [Select Id,SalesGroupCode__c from User where Id =: userId];
        Id offerSpareRecordTypeId = TegaUtilityWithoutSharing.getOfferRecordTypeId('Offer');
        for(Quote offer : newList){
            //AK 01/06/2023 Fix
            if(offer.recordtypeid == offerSpareRecordTypeId){
                if(String.isBlank(user.SalesGroupCode__c)){
                    offer.addError('SalesGroupCode is Blank in User Details, Please go to User Record and fill SalesGroupCode first');
                }else{
                    offer.SalesGrp__c = user.SalesGroupCode__c;
                } 
            }
        }
        } catch (Exception e) {TegaUtility.trackLogs( e,  'OfferTriggerHelper',  'afterIDcreation');}
    }
}