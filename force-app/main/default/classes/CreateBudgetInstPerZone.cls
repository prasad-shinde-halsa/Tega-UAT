global class CreateBudgetInstPerZone implements Comparable {
    
    public Id bliId;
    public Date instDate;
    
    public CreateBudgetInstPerZone(Id bliId, Date instDate) {
        this.instDate = instDate;
        this.bliId = bliId;
    }
    
    global Integer compareTo(Object compareTo) {
        CreateBudgetInstPerZone compareToEmp = (CreateBudgetInstPerZone)compareTo;
        if (instDate == compareToEmp.instDate) return 0;
        if (instDate > compareToEmp.instDate) return 1;
        return -1;
    }   
    
    @InvocableMethod (label = 'Create Budget Installation Per Zone' description = 'returns nothing')
    public static void createBudgetInstPerZoneMethod (List<ID> ids){
        try{
        List<Zone_Identification_For_Budget__c> zoneIdentBudList = [Select Id,Budget__c,Budget__r.CurrencyISOCode,Budget__r.Budget_for_Years__c,Budget__r.Inventory_Part_List_Relationship__c,
                                                                    Lead_Time_Months__c,Life__c,Negotitation_Time_Months__c,Product_L2__c,
                                                                    Transit_Time_Months__c,Inventory__c,Remaining_Inventory_After_Consumption__c
                                                                    from Zone_Identification_For_Budget__c 
                                                                    WHERE Id IN: ids];
        system.debug('zoneIdentBudList =>'+zoneIdentBudList);
        
        List<Zone_Priority_Selection__c> zps = new List<Zone_Priority_Selection__c>([Select Id,Inventory_Part_List_Relationship__c,Zone_L2__c from Zone_Priority_Selection__c 
                                         WHERE Inventory_Part_List_Relationship__c =: zoneIdentBudList[0].Budget__r.Inventory_Part_List_Relationship__c 
                                         AND Zone_L2__c =: zoneIdentBudList[0].Product_L2__c]);
        
        String budgetForYears = zoneIdentBudList[0].Budget__r.Budget_for_Years__c;
        Integer budgetForYearsInt = integer.valueof(budgetForYears);
        
        Decimal lifeMonths = zoneIdentBudList[0].Life__c;   //12
        Decimal transitimeMonths = zoneIdentBudList[0].Transit_Time_Months__c;  
        Decimal negotitationimeMonths = zoneIdentBudList[0].Negotitation_Time_Months__c;
        Decimal leadTimeMonths = zoneIdentBudList[0].Lead_Time_Months__c;
        
        Decimal orderMonth = lifeMonths - (transitimeMonths + negotitationimeMonths + leadTimeMonths);
        Integer orderMonthInt = (Integer)orderMonth;
        system.debug('orderMonth =>'+orderMonth);   //8
        
        List<L2_Budget_Line_Item__c> budgetLineItemList = [SELECT Id, Name,Installation_Score__c,Budget__c,L2_Projected_Budget__c,Product_L2__c,Product_L2__r.Name,Installation_Date__c,
                                                           Zone_Identification_For_Budget__c,Life_Months__c, Lead_Time_Months__c, Transit_Time_Months__c, Negotitation_Time_Months__c 
                                                           FROM L2_Budget_Line_Item__c WHERE Zone_Identification_For_Budget__c =: zoneIdentBudList[0].Id];
        system.debug('budgetLineItemList =>'+budgetLineItemList);
        
        Map<Id,L2_Budget_Line_Item__c> budgetLineItemMap = new Map<Id,L2_Budget_Line_Item__c>();
        
        Map<Id,List<Date>> wrpMap = new Map<Id,List<Date>>();
        
        for(L2_Budget_Line_Item__c bli : budgetLineItemList){
            budgetLineItemMap.put(bli.Id,bli);
            
            Date installationDate = bli.Installation_Date__c;
            DateTime lastOrdDateTime = installationDate.addYears(budgetForYearsInt);
            Date lastOrdDate = date.newinstance(lastOrdDateTime.year(), lastOrdDateTime.month(), lastOrdDateTime.day());
            //Date lastOrdDate = (Date)lastOrdDateTime;
            DateTime ordDateTime = installationDate.addMonths(orderMonthInt);
            system.debug('lastOrdDate==>'+lastOrdDate);
            system.debug('installationDate==>'+installationDate);
            
            
            while(lastOrdDate > installationDate){
            system.debug('installationDate2==>'+installationDate);
    
                if(!wrpMap.containsKey(bli.Id)){
                    List<Date> dateList = new List<Date>();
                    Date newOrdDate = date.newinstance(ordDateTime.year(), ordDateTime.month(), ordDateTime.day());
                    //Date newOrdDate = (Date)ordDateTime;
                    dateList.add(newOrdDate);
                    wrpMap.put(bli.Id,dateList);
                }else if(wrpMap.containsKey(bli.Id)){
                    List<Date> dateList = wrpMap.get(bli.Id);
                    Date newOrdDate = date.newinstance(ordDateTime.year(), ordDateTime.month(), ordDateTime.day());
                    dateList.add(newOrdDate);
                    wrpMap.put(bli.Id,dateList);
                }
                installationDate = installationDate.addMonths(orderMonthInt);
                ordDateTime = installationDate.addMonths(orderMonthInt);
            }
            system.debug('wrpMap =>'+wrpMap);
        }
        
        // Now we need to sort dates for all map values
        
        List<CreateBudgetInstPerZone> empList = new List<CreateBudgetInstPerZone>();
                
        for(Id bliId : wrpMap.keySet()){
            List<Date> dateList = wrpMap.get(bliId);
            for(Date dt : dateList){
                CreateBudgetInstPerZone dtGrp = new CreateBudgetInstPerZone(bliId,dt);
                empList.add(dtGrp);
            }
        }
        system.debug('empList Unsorted =>'+empList);
        empList.sort();
        system.debug('empList Sorted =>'+empList);
        
        // After this we will be creating BudgetInstallationPerZone Records for L2 Zone
        
        List<Budget_Installation_Per_Zone__c> bipzList = new List<Budget_Installation_Per_Zone__c>();
        
        Decimal inventory = 0;
        if(zoneIdentBudList.size() > 0 && zoneIdentBudList[0].Inventory__c != null)
        inventory = zoneIdentBudList[0].Inventory__c;
        
        // AK Changes 05/05/2023
        Custom_Exchange_Rate__c custExcRate = new Custom_Exchange_Rate__c();
        if(zoneIdentBudList[0].Budget__r.CurrencyISOCode != 'INR'){
            custExcRate = [Select Id,Name,Converted_to_INR__c from Custom_Exchange_Rate__c where Name =: zoneIdentBudList[0].Budget__r.CurrencyISOCode]; 
        }
        
        for(CreateBudgetInstPerZone cbi : empList){
            Budget_Installation_Per_Zone__c bipz = new Budget_Installation_Per_Zone__c();
            bipz.Zone_Identification_For_Budget__c = zoneIdentBudList[0].Id;
            bipz.Installation_Date__c = cbi.instDate;
            bipz.CurrencyIsoCode = zoneIdentBudList[0].Budget__r.CurrencyISOCode;
            L2_Budget_Line_Item__c bli = budgetLineItemMap.get(cbi.bliId);
            bipz.Budget_Line_Item_Name__c = cbi.bliId;
            Decimal installationScorePerL2 = bli.Installation_Score__c;
            Decimal projBudget = bli.L2_Projected_Budget__c;
            
            if(inventory >= installationScorePerL2 && inventory != 0){
                bipz.Installation__c = installationScorePerL2;
                bipz.Remaining_Inventory__c = inventory - installationScorePerL2;
                inventory = inventory - installationScorePerL2;
            }else if(inventory < installationScorePerL2 && installationScorePerL2 != 0){
                bipz.Remaining_Inventory__c = 0;
                bipz.Installation__c = installationScorePerL2 ;
                
                // Calculation of revenue for remaining inventories
                Decimal remainingInstallation = installationScorePerL2 - (installationScorePerL2 - inventory);
                Decimal scoreCal = 100 - ((remainingInstallation/installationScorePerL2) * 100);
                Decimal revenue = (scoreCal/100) * projBudget;
                bipz.Revenue__c = revenue;
                if(custExcRate.Id != null){
                    bipz.Revenue_INR__c = custExcRate.Converted_to_INR__c * bipz.Revenue__c;
                }
            }else if(inventory ==  0){
                bipz.Revenue__c = installationScorePerL2;
                if(custExcRate.Id != null){
                    bipz.Revenue_INR__c = custExcRate.Converted_to_INR__c * bipz.Revenue__c;
                }
            }        
            bipzList.add(bipz);
            
        }
        zoneIdentBudList[0].Remaining_Inventory_After_Consumption__c = inventory; 
        
        
        insert bipzList;
        update zoneIdentBudList[0];
        if(zps.size() < 0){
        zps[0].Score__c = inventory;
        update zps;
    }
        
        List<Budget_Installation_Per_Zone__c> bipzRecList = [Select Id,Zone_Identification_For_Budget__c,Revenue__c ,Budget_Line_Item_Name__c from Budget_Installation_Per_Zone__c 
                                                          WHERE Zone_Identification_For_Budget__c =: zoneIdentBudList[0].Id];
        
        List<Budget_Line_Item_Installation__c> bliInstList = new List<Budget_Line_Item_Installation__c>();
        
        for(Budget_Installation_Per_Zone__c bipz : bipzRecList){
            Budget_Line_Item_Installation__c bilInstRec = new Budget_Line_Item_Installation__c();
            bilInstRec.Budget_Installation_Per_Zone__c = bipz.Id;
            L2_Budget_Line_Item__c bli = budgetLineItemMap.get(bipz.Budget_Line_Item_Name__c);
            bilInstRec.Budget_Line_Item__c = bli.Id;
            bilInstRec.Total_Installation__c = bli.Installation_Score__c;
            bilInstRec.Value__c = bli.L2_Projected_Budget__c;
            system.debug('budget currency => '+zoneIdentBudList[0].Budget__r.CurrencyISOCode);
            bilInstRec.CurrencyIsoCode = zoneIdentBudList[0].Budget__r.CurrencyISOCode;
            bliInstList.add(bilInstRec);
        }
        
        insert bliInstList;
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'CreateBudgetInstPerZone',  'createBudgetInstPerZoneMethod ');
            
        }
    }
    
}