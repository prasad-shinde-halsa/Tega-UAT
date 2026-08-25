public class BudgetLineItemTriggerHelper {
    public void updateMonthlyChildFromParentBLI(Map<id, L2_Budget_Line_Item__c> newMap, Map<id, L2_Budget_Line_Item__c> oldMap){
    /*    
        L2_Budget_Line_Item__c bliObj = new L2_Budget_Line_Item__c();
        
        // This map contains BLI Field's API Name as Key and Monthly Field's API Name as Value
        Map<String,String> bliMonthlyBudgetMap = new Map<String,String>();
        bliMonthlyBudgetMap.put('budget_against_po__c','Payment_Against_PO__c');
        bliMonthlyBudgetMap.put('payment_against_dispatch__c','Payment_Against_Dispatch__c');
        bliMonthlyBudgetMap.put('budget_against_delivery_at_port_of_desti__c','Payment_Against_Delivery_Port_of_Dest__c');
        bliMonthlyBudgetMap.put('budget_against_bl__c','Payment_Against_BL__c');
        bliMonthlyBudgetMap.put('payment_after_x_month__c','Payment_After_X_Month__c');
        bliMonthlyBudgetMap.put('last_payment__c','Last_Payment__c');
        bliMonthlyBudgetMap.put('dispatch_date__c','Dispatch_Date__c');
        bliMonthlyBudgetMap.put('delivery_date_port_of_destination__c','Delivery_Date_Port_Of_Destination__c');
        bliMonthlyBudgetMap.put('bill_of_landing_date__c','Bill_Of_Landing_Date__c');
        bliMonthlyBudgetMap.put('date_after_x_month__c','Date_After_X_Month__c');
        bliMonthlyBudgetMap.put('last_date_of_payment__c','Last_Date_of_Payment__c');
        bliMonthlyBudgetMap.put('x_no_of_month__c','X_No_of_Month__c');
        bliMonthlyBudgetMap.put('y_no_of_month__c','Y_No_of_Month__c');
        
        Map<Id,List<String>> changedValuesInBLIMap = new Map<Id,List<String>>();
        
        // This takes all available fields from the required object. 
        Schema.SObjectType objType = bliObj.getSObjectType(); 
        Map<String, Schema.SObjectField> mapFields = Schema.SObjectType.L2_Budget_Line_Item__c.fields.getMap(); 
        
        for(L2_Budget_Line_Item__c bli : newMap.values()){
            L2_Budget_Line_Item__c oldBli = oldMap.get(bli.Id);
            for (String str : mapFields.keyset()){ 
                try{ 
                    if(bli.get(str) != oldBli.get(str)){ 
                        //System.Debug('Field changed: ' + str + '. The value has changed from: ' + oldBli.get(str) + ' to: ' + bli.get(str));
                        if(!changedValuesInBLIMap.containsKey(bli.Id)){
                            List<String> changedFieldsList = new List<String>();
                            changedFieldsList.add(str);
                            changedValuesInBLIMap.put(bli.Id,changedFieldsList);
                        }else if(changedValuesInBLIMap.containsKey(bli.Id)){
                            List<String> changedFieldsList = changedValuesInBLIMap.get(bli.Id);
                            changedFieldsList.add(str);
                            changedValuesInBLIMap.put(bli.Id,changedFieldsList);
                            
                        }
                        
                    } 
                } 
                catch (Exception e) { 
                    System.Debug('Error: ' + e); 
                } 
            }
        }
        system.debug('changedValuesInBLIMap ===>'+ changedValuesInBLIMap);
        List<Monthly_Budget_Detail__c> mbdList = [Select Id,Payment_Against_PO__c,Payment_Against_Dispatch__c,Payment_Against_Delivery_Port_of_Dest__c,Payment_Against_BL__c,
                                                  Payment_After_X_Month__c,Last_Payment__c,Dispatch_Date__c,Delivery_Date_Port_Of_Destination__c,Bill_Of_Landing_Date__c,
                                                  Date_After_X_Month__c,Last_Date_of_Payment__c,X_No_of_Month__c,Y_No_of_Month__c,L2_Budget_Line_Item__c 
                                                  FROM Monthly_Budget_Detail__c 
                                                  WHERE L2_Budget_Line_Item__c IN : changedValuesInBLIMap.keySet()];
        system.debug('mbdList =>'+mbdList);
        
        Map<Id,List<Monthly_Budget_Detail__c>> mbdMap = new Map<Id,List<Monthly_Budget_Detail__c>>();
        for(Monthly_Budget_Detail__c mbd : mbdList){
            if(!mbdMap.containsKey(mbd.L2_Budget_Line_Item__c)){
                List<Monthly_Budget_Detail__c> mbdListTemp = new List<Monthly_Budget_Detail__c>();
                mbdListTemp.add(mbd);
                mbdMap.put(mbd.L2_Budget_Line_Item__c,mbdListTemp);
            }else if(mbdMap.containsKey(mbd.L2_Budget_Line_Item__c)){
                List<Monthly_Budget_Detail__c> mbdListTemp = mbdMap.get(mbd.L2_Budget_Line_Item__c);
                mbdListTemp.add(mbd);
                mbdMap.put(mbd.L2_Budget_Line_Item__c,mbdListTemp);
            }
        }
        
        Map<Id,Monthly_Budget_Detail__c> mbdUpdateMap = new Map<Id,Monthly_Budget_Detail__c>();
        
        if(mbdMap.size() > 0){
            for(L2_Budget_Line_Item__c bli : newMap.values()){
                List<String> changedValuesInBLI = changedValuesInBLIMap.get(bli.Id);
                for(String str : changedValuesInBLI){
                    if(str != 'lastmodifieddate' && str != 'systemmodstamp'){
                        List<Monthly_Budget_Detail__c> mbdListTemp = mbdMap.get(bli.Id);
                        for(Monthly_Budget_Detail__c mbd : mbdListTemp){
                            system.debug('mbd ===>'+mbd);
                            String mbdAPIName = bliMonthlyBudgetMap.get(str);
                            system.debug('mbdAPIName===>'+mbdAPIName);
                            mbd.put(mbdAPIName,bli.get(str));
                            mbdUpdateMap.put(mbd.Id,mbd);
                        }
                    }
                }
            }
            
            update mbdUpdateMap.values();
        }
        
        */
    }
}