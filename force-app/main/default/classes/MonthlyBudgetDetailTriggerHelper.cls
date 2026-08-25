public without sharing class MonthlyBudgetDetailTriggerHelper {
    
    public void rangeValidation(List<Monthly_Budget_Detail__c> newList, Map<id, Monthly_Budget_Detail__c> newMap, Map<id, Monthly_Budget_Detail__c> oldMap){
        try{
        Set<String> mbdNameSet = new Set<String>();
        Set<Id> bliIdSet = new Set<Id>();
        for(Monthly_Budget_Detail__c mbd : newList){
            mbdNameSet.add(mbd.Name);
            bliIdSet.add(mbd.L2_Budget_Line_Item__c);
        }
        
        List<L2_Budget_Line_Item__c> bliList = new List<L2_Budget_Line_Item__c>([Select Id,Budget__c,Budget__r.Customer_Branch_Assignment__r.Company__r.Company_Code__c from L2_Budget_Line_Item__c 
                                                where Id IN: bliIdSet]);
        system.debug('bliList =>'+bliList);
        
        Map<Id,L2_Budget_Line_Item__c> bliMap = new Map<Id,L2_Budget_Line_Item__c>();
        Set<String> companyCodeSet = new Set<String>();
        for(L2_Budget_Line_Item__c bli : bliList){
            bliMap.put(bli.Id,bli);
            companyCodeSet.add(bli.Budget__r.Customer_Branch_Assignment__r.Company__r.Company_Code__c);
        }
        
        List<Monthly_Budget_Detail_Range__mdt> custMetaList = new List<Monthly_Budget_Detail_Range__mdt>([Select MasterLabel,Month__c,Company_Code__c,Start_Date__c,End_Date__c from Monthly_Budget_Detail_Range__mdt 
                                                         where Month__c IN: mbdNameSet AND 
                                                         Company_Code__c IN: companyCodeSet]);
        system.debug('custMetaList =>'+custMetaList);
        
        Map<String,Monthly_Budget_Detail_Range__mdt> custMetaMap = new Map<String,Monthly_Budget_Detail_Range__mdt>();
        for(Monthly_Budget_Detail_Range__mdt custMeta : custMetaList){
            custMetaMap.put(custMeta.Month__c,custMeta);
        }
        
        Date todaysDate = System.today();
        
        for(Monthly_Budget_Detail__c mbd : newList){
            Monthly_Budget_Detail_Range__mdt custMeta = custMetaMap.get(mbd.Name);
            if(todaysDate < custMeta.Start_Date__c || todaysDate > custMeta.End_Date__c){
                mbd.addError('Updation of Monthly Budget Detail Record is only allowed in certain date range, Contact your admin to know more !');
            }
        }
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'MonthlyBudgetDetailTriggerHelper',  'rangeValidation');
            
        }
    }
}