global class CreateMonthlyDetPerZone implements Comparable {
    
    public Id bliId;
    public Date instDate;
    
    public CreateMonthlyDetPerZone(Id bliId, Date instDate) {
        this.instDate = instDate;
        this.bliId = bliId;
    }
    
    global Integer compareTo(Object compareTo) {
        CreateMonthlyDetPerZone compareToEmp = (CreateMonthlyDetPerZone)compareTo;
        if (instDate == compareToEmp.instDate) return 0;
        if (instDate > compareToEmp.instDate) return 1;
        return -1;
    }   
    
    @InvocableMethod (label = 'Create Monthly Detail Records' description = 'returns nothing')
    public static void createMonthlyDetPerZoneMethod (List<ID> ids){
        try{
        List<Zone_Identification_For_Budget__c> zoneIdentBudList = [Select Id,Budget__c,Budget__r.Budget_for_Years__c,Budget__r.Inventory_Part_List_Relationship__c,
                                                                    Lead_Time_Months__c,Life__c,Negotitation_Time_Months__c,Product_L2__c,
                                                                    Transit_Time_Months__c,Inventory__c,Remaining_Inventory_After_Consumption__c
                                                                    from Zone_Identification_For_Budget__c 
                                                                    WHERE Id IN: ids];
        system.debug('zoneIdentBudList =>'+zoneIdentBudList);
        
        Budget__c budget = [Select Id,CurrencyISOCode,Part_List__c,Budget_For_Financial_Year__c,Concurrent_Year__c,Inventory_Part_List_Relationship__c,Financial_Year__c 
                            from Budget__c where Id =: zoneIdentBudList[0].Budget__c];
        system.debug('budget==>'+budget);
        Zone_Priority_Selection__c zps = new Zone_Priority_Selection__c();
        if(zoneIdentBudList[0].Budget__r.Inventory_Part_List_Relationship__c != null){
            zps = [Select Id,Inventory_Part_List_Relationship__c,Zone_L2__c from Zone_Priority_Selection__c 
                                             WHERE Inventory_Part_List_Relationship__c =: zoneIdentBudList[0].Budget__r.Inventory_Part_List_Relationship__c 
                                             AND Zone_L2__c =: zoneIdentBudList[0].Product_L2__c];
            system.debug('zps==>'+zps);
        }
        

        
        //String budgetForYears = zoneIdentBudList[0].Budget__r.Budget_for_Years__c;
        Integer budgetForYearsInt = 1;
        Decimal orderMonth;
        Decimal lifeMonths = zoneIdentBudList[0].Life__c;   //6
        system.debug('lifeMonths===>'+lifeMonths);
        Decimal transitimeMonths = zoneIdentBudList[0].Transit_Time_Months__c;
        system.debug('transitimeMonths===>'+transitimeMonths);
        Decimal negotitationimeMonths = zoneIdentBudList[0].Negotitation_Time_Months__c;
         system.debug('negotitationimeMonths===>'+negotitationimeMonths);
        Decimal leadTimeMonths = zoneIdentBudList[0].Lead_Time_Months__c;
         system.debug('leadTimeMonths===>'+leadTimeMonths);
        if (lifeMonths != NULL && transitimeMonths != NULL && negotitationimeMonths != NULL && leadTimeMonths!= NULL){

        orderMonth = lifeMonths - (transitimeMonths + negotitationimeMonths + leadTimeMonths);
        }
        Integer orderMonthInt = (Integer)orderMonth;
        system.debug('orderMonth =>'+orderMonth);   //3
        
        Map<String,Decimal> monthsMap = new Map<String,Decimal>();
        monthsMap.put('April',1);
        monthsMap.put('May',2);
        monthsMap.put('June',3);
        monthsMap.put('July',4);
        monthsMap.put('August',5);
        monthsMap.put('September',6);
        monthsMap.put('October',7);
        monthsMap.put('November',8);
        monthsMap.put('December',9);
        monthsMap.put('January',10);
        monthsMap.put('February',11);
        monthsMap.put('March',12);
        system.debug('monthsMap'+monthsMap);
        
        Integer monthCounter = 1;
        String financialYear = budget.Financial_Year__c;
        String[] financialYearArray = financialYear.split('-');
        String currentYear = financialYearArray[0]; 
        String nextYear = financialYearArray[1]; 
        
        Integer monthMultiplier = 0;
        
        List<L2_Budget_Line_Item__c> budgetLineItemList = [SELECT Id, Name,Installation_Score__c,Budget__c,L2_Projected_Budget__c,Product_L2__c,Product_L2__r.Name,Installation_Date__c,
                                                           Zone_Identification_For_Budget__c,Life_Months__c, Lead_Time_Months__c, Transit_Time_Months__c, Negotitation_Time_Months__c 
                                                           FROM L2_Budget_Line_Item__c WHERE Zone_Identification_For_Budget__c =: zoneIdentBudList[0].Id];
        system.debug('budgetLineItemList =>'+budgetLineItemList);
        
        Map<Id,L2_Budget_Line_Item__c> budgetLineItemMap = new Map<Id,L2_Budget_Line_Item__c>();
        
        Map<Id,List<Date>> wrpMap = new Map<Id,List<Date>>();
        
        for(L2_Budget_Line_Item__c bli : budgetLineItemList){
            budgetLineItemMap.put(bli.Id,bli);
            
            DateTime ordDateTime;
            Date installationDate = bli.Installation_Date__c;
            DateTime lastOrdDateTime = installationDate.addYears(budgetForYearsInt);
            Date lastOrdDate = date.newinstance(lastOrdDateTime.year(), 3, lastOrdDateTime.day());
            //Date lastOrdDate = (Date)lastOrdDateTime;
            ordDateTime = installationDate.addMonths(orderMonthInt);
            
            system.debug('lastOrdDate =>'+lastOrdDate);   
            
            while(lastOrdDate > installationDate && ordDateTime <= lastOrdDate){
                
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
                system.debug('installationDate =>'+installationDate);
                ordDateTime = installationDate.addMonths(orderMonthInt);
            }
            system.debug('wrpMap =>'+wrpMap);
        }
        
        // Now we need to sort dates for all map values
        
        List<CreateMonthlyDetPerZone> empList = new List<CreateMonthlyDetPerZone>();
                
        for(Id bliId : wrpMap.keySet()){
            List<Date> dateList = wrpMap.get(bliId);
            for(Date dt : dateList){
                CreateMonthlyDetPerZone dtGrp = new CreateMonthlyDetPerZone(bliId,dt);
                empList.add(dtGrp);
            }
        }
        system.debug('empList Unsorted =>'+empList);
        empList.sort();
        system.debug('empList Sorted =>'+empList);
        
        // After this we will be creating Monthly Budget Records
        
        Map<Id,Map<Decimal,List<Monthly_Budget_Detail__c>>> monthRecMap = new Map<Id,Map<Decimal,List<Monthly_Budget_Detail__c>>>();
        
        Decimal inventory = zoneIdentBudList[0].Inventory__c;
        
        Map<Id,Set<String>> everyMonthsMap = new Map<Id,Set<String>>();
        
        for(CreateMonthlyDetPerZone cbi : empList){
            Monthly_Budget_Detail__c monthRec = new Monthly_Budget_Detail__c();
            monthRec.Installation_Date__c = cbi.instDate;
            L2_Budget_Line_Item__c bli = budgetLineItemMap.get(cbi.bliId);
            monthRec.L2_Budget_Line_Item__c = cbi.bliId;
            Decimal installationScorePerL2 = bli.Installation_Score__c;
            Decimal projBudget = bli.L2_Projected_Budget__c;
            
            Date installationDate = cbi.instDate;
            DateTime currentDT = installationDate;
            String currentMonth = currentDT.format('MMMM');
            system.debug('currentMonth =>'+currentMonth);
            Decimal currentMonthVal = monthsMap.get(currentMonth);
            system.debug('currentMonthVal =>'+currentMonthVal);
            
            if(inventory >= installationScorePerL2 && inventory != 0){
                monthRec.Installation__c = installationScorePerL2;
                monthRec.Remaining_Inventory__c = inventory - installationScorePerL2;
                inventory = inventory - installationScorePerL2;
            }else if(inventory < installationScorePerL2 && installationScorePerL2 != 0){
                monthRec.Remaining_Inventory__c = 0;
                monthRec.Installation__c = installationScorePerL2 ;
                
                // Calculation of revenue for remaining inventories
                Decimal remainingInstallation = installationScorePerL2 - (installationScorePerL2 - inventory);
                Decimal scoreCal = 100 - ((remainingInstallation/installationScorePerL2) * 100);
                Decimal revenue = (scoreCal/100) * projBudget;
                //monthRec.Revenue__c = revenue;
                monthRec.Value__c = revenue;
                inventory = 0;
                
                
            }else if(inventory ==  0){
                //monthRec.Revenue__c = installationScorePerL2;
                monthRec.Value__c = projBudget;
            }
            
            if(currentMonthVal != 10 && currentMonthVal != 11 && currentMonthVal != 12){
                monthRec.Name = currentMonth + '-' + currentYear;
            }else{
                monthRec.Name = currentMonth + '-' + nextYear;
            }
            
            if(!monthRecMap.containsKey(bli.Id)){
                Map<Decimal,List<Monthly_Budget_Detail__c>> monthChildMap = new Map<Decimal,List<Monthly_Budget_Detail__c>>();
                List<Monthly_Budget_Detail__c> monthRecList = new List<Monthly_Budget_Detail__c>();
                monthRecList.add(monthRec);
                monthChildMap.put(currentMonthVal,monthRecList);
                monthRecMap.put(bli.Id,monthChildMap);
            }else if(monthRecMap.containsKey(bli.Id)){
                Map<Decimal,List<Monthly_Budget_Detail__c>> monthChildMap = monthRecMap.get(bli.Id);
                if(!monthChildMap.containsKey(currentMonthVal)){
                    List<Monthly_Budget_Detail__c> monthRecList = new List<Monthly_Budget_Detail__c>();
                    monthRecList.add(monthRec);
                    monthChildMap.put(currentMonthVal,monthRecList);
                    monthRecMap.put(bli.Id,monthChildMap);
                }else if(monthChildMap.containsKey(currentMonthVal)){
                    List<Monthly_Budget_Detail__c> monthRecList = monthChildMap.get(currentMonthVal);
                    monthRecList.add(monthRec);
                    monthChildMap.put(currentMonthVal,monthRecList);
                    monthRecMap.put(bli.Id,monthChildMap);
                }
            }
           
            if(!everyMonthsMap.containsKey(bli.Id)){
                system.debug('entered');
                Set<String> monthSet = new Set<String>();
                monthSet.add(currentMonth);
                everyMonthsMap.put(bli.Id,monthSet);
            }else if(everyMonthsMap.containsKey(bli.Id)){
                Set<String> monthSet = everyMonthsMap.get(bli.Id);
                monthSet.add(currentMonth);
                everyMonthsMap.put(bli.Id,monthSet);
            }

            
        }
        zoneIdentBudList[0].Remaining_Inventory_After_Consumption__c = inventory;
        if(zps.id != null){
            zps.Score__c = inventory;
        }
        
        system.debug('everyMonthsMap =>'+everyMonthsMap);
        
        for(Integer i=0;i<budgetLineItemList.size();i++){
            for(String str : monthsMap.keySet()){
                Set<String> monthsSet = everyMonthsMap.get(budgetLineItemList[i].Id);
                if(!monthsSet.contains(str)){                    
                    Map<Decimal,List<Monthly_Budget_Detail__c>> monthChildMap = monthRecMap.get(budgetLineItemList[i].Id);
                    Decimal currentMonthVal = monthsMap.get(str);
                    List<Monthly_Budget_Detail__c> monthRecList;
                    if(monthChildMap.get(currentMonthVal) != null){
                        monthRecList = monthChildMap.get(currentMonthVal);
                    }else{
                        monthRecList = new List<Monthly_Budget_Detail__c>();
                    }
                    Monthly_Budget_Detail__c monthRec = new Monthly_Budget_Detail__c();
                    if(currentMonthVal != 10 && currentMonthVal != 11 && currentMonthVal != 12){
                        monthRec.Name = str + '-' + currentYear;
                    }else{
                        monthRec.Name = str + '-' + nextYear;
                    }
                    monthRec.L2_Budget_Line_Item__c = budgetLineItemList[i].Id;
                    monthRecList.add(monthRec);
                    monthChildMap.put(currentMonthVal,monthRecList);
                    monthRecMap.put(budgetLineItemList[i].Id,monthChildMap);
                }
            }
        }
        
        // AK Changes 05/05/2023
        Custom_Exchange_Rate__c custExcRate = new Custom_Exchange_Rate__c();
        if(budget.CurrencyIsoCode != 'INR'){
            custExcRate = [Select Id,Name,Converted_to_INR__c from Custom_Exchange_Rate__c where Name =: budget.CurrencyIsoCode]; 
        }
                
        List<Monthly_Budget_Detail__c> monthRecFinalList = new List<Monthly_Budget_Detail__c>();
        
        //Sort Map based on month values
        for(Integer i=0;i<budgetLineItemList.size();i++){
            for(Integer j=1;j<=12;j++){
                Map<Decimal,List<Monthly_Budget_Detail__c>> monthChildMap = monthRecMap.get(budgetLineItemList[i].Id);
                List<Monthly_Budget_Detail__c> monthRecList;
                if(monthChildMap.get(j) != null){
                    monthRecList = monthChildMap.get(j);
                }else{
                    monthRecList = new List<Monthly_Budget_Detail__c>();
                }
                
                for(Monthly_Budget_Detail__c monthBudDet : monthRecList){
                    //monthBudDet.Name = j + '-' + monthBudDet.Name;
                    monthBudDet.Financial_Month__c = j;
                    monthBudDet.CurrencyIsoCode = budget.CurrencyIsoCode;
                    if(custExcRate.Id != null){
                        if(monthBudDet.Value__c != null){
                            monthBudDet.Budget_Value_INR__c = (monthBudDet.Value__c) * custExcRate.Converted_to_INR__c;
                        }else{
                            monthBudDet.Budget_Value_INR__c = monthBudDet.Value__c;
                        }
                    }
                    monthRecFinalList.add(monthBudDet);
                }
            }
        }
        
        
        insert monthRecFinalList;
        update zoneIdentBudList[0];
        if(zps.id != null){
            update zps;
        }
        
        /*List<Budget_Installation_Per_Zone__c> bipzRecList = [Select Id,Zone_Identification_For_Budget__c,Budget_Line_Item_Name__c from Budget_Installation_Per_Zone__c 
                                                          WHERE Zone_Identification_For_Budget__c =: zoneIdentBudList[0].Id];
        
        List<Budget_Line_Item_Installation__c> bliInstList = new List<Budget_Line_Item_Installation__c>();
        
        for(Budget_Installation_Per_Zone__c bipz : bipzRecList){
            Budget_Line_Item_Installation__c bilInstRec = new Budget_Line_Item_Installation__c();
            bilInstRec.Budget_Installation_Per_Zone__c = bipz.Id;
            L2_Budget_Line_Item__c bli = budgetLineItemMap.get(bipz.Budget_Line_Item_Name__c);
            bilInstRec.Budget_Line_Item__c = bli.Id;
            bilInstRec.Total_Installation__c = bli.Installation_Score__c;
            bilInstRec.Value__c = bli.L2_Projected_Budget__c;
            bliInstList.add(bilInstRec);
        }
        
        insert bliInstList;*/
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'CreateMonthlyDetPerZone',  'createMonthlyDetPerZoneMethod ');
            
        }
    }
}