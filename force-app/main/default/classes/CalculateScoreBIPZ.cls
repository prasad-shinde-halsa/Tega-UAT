global class CalculateScoreBIPZ implements Comparable {
    
    public Wrapper wrap;
    public Date instDate;
    
    public CalculateScoreBIPZ(Wrapper wrap, Date instDate) {
        this.instDate = instDate;
        this.wrap = wrap;
    }
    
    global Integer compareTo(Object compareTo) {
        CalculateScoreBIPZ compareToEmp = (CalculateScoreBIPZ)compareTo;
        if (instDate == compareToEmp.instDate) return 0;
        if (instDate > compareToEmp.instDate) return 1;
        return -1;
    }   
    
    @InvocableMethod (label = 'Calculate Score BIPZ' description = 'returns nothing')
    public static void calculateScoreForBIPZ (List<ID> ids){
        
        List<Budget_Line_Item_Installation__c> bliInstList = [Select Id,Name,Budget_Installation_Per_Zone__c,Budget_Line_Item__c,Total_Installation__c, Value__c, 
                                                              Budget_Line_Item__r.Installation_Score__c , Budget_Line_Item__r.L2_Projected_Budget__c 
                                                              from Budget_Line_Item_Installation__c 
                                                              WHERE Budget_Installation_Per_Zone__c IN: ids Order By CreatedDate];
        system.debug('bliInstList => '+bliInstList);
        
        for(Budget_Line_Item_Installation__c bliInst : bliInstList){
            bliInst.Total_Installation__c = bliInst.Budget_Line_Item__r.Installation_Score__c;
            bliInst.Value__c = bliInst.Budget_Line_Item__r.L2_Projected_Budget__c;
        }
        
        update bliInstList;
        
        // Even though we are receiving list of id, we will always receive only one id from flow
        List<Budget_Installation_Per_Zone__c> bipzList = [SELECT Id,Revenue__c,Zone_Identification_For_Budget__c,Installation_Date__c,Total_Installation__c,Total_Value__c,Remaining_Inventory__c 
                                                          FROM Budget_Installation_Per_Zone__c 
                                                          WHERE Id IN: ids];
        system.debug('bipzList => '+bipzList); 
        
        List<Budget_Installation_Per_Zone__c> allBipzList = [SELECT Id, Zone_Identification_For_Budget__c ,Revenue__c,Installation_Date__c,Total_Installation__c,Total_Value__c,
                                                             Remaining_Inventory__c, 
                                                             (Select Id,Budget_Installation_Per_Zone__c,Budget_Line_Item__c,Total_Installation__c,Value__c 
                                                              from Budget_Line_Item_Installations__r ) 
                                                             FROM Budget_Installation_Per_Zone__c 
                                                             WHERE Zone_Identification_For_Budget__c =: bipzList[0].Zone_Identification_For_Budget__c 
                                                             ORDER BY Installation_Date__c];
        system.debug('allBipzList => '+allBipzList);
        
        // AK 30 Mar Fixes Start
        Integer bliInstListSize = bliInstList.size() - 1;
        Integer bipzAboveCurrentBipzSize = allBipzList.size() - 2;
		
        system.debug('bliInstList[bliInstListSize].Total_Installation__c =>'+bliInstList[bliInstListSize].Total_Installation__c);
        system.debug('bipzList[0].Remaining_Inventory__c =>'+bipzList[0].Remaining_Inventory__c);
        	
        if(bliInstList[bliInstListSize].Total_Installation__c <= bipzList[0].Remaining_Inventory__c){
            bipzList[0].Remaining_Inventory__c = allBipzList[bipzAboveCurrentBipzSize].Remaining_Inventory__c - bipzList[0].Total_Installation__c;
            
            if(bipzList[0].Remaining_Inventory__c <= 0){
                bipzList[0].Remaining_Inventory__c = 0;
            }
        }else if(bliInstList[bliInstListSize].Total_Installation__c > bipzList[0].Remaining_Inventory__c){
            
            bipzList[0].Remaining_Inventory__c = allBipzList[bipzAboveCurrentBipzSize].Remaining_Inventory__c - bipzList[0].Total_Installation__c;
            if(bipzList[0].Remaining_Inventory__c <= 0){
                bipzList[0].Remaining_Inventory__c = 0;
            }
            
            if(bipzList[0].Remaining_Inventory__c <= 0 || bipzList[0].Remaining_Inventory__c == null){
                bipzList[0].Installation__c =  bliInstList[bliInstListSize].Total_Installation__c - bipzList[0].Remaining_Inventory__c;
                // Calculation of revenue for remaining inventories
                Decimal scoreCal = 100 - ((bipzList[0].Remaining_Inventory__c/bliInstList[bliInstListSize].Total_Installation__c) * 100);
                Decimal revenue = (scoreCal/100) * bliInstList[bliInstListSize].Value__c;
                bipzList[0].Revenue__c = revenue;
                bipzList[0].Remaining_Inventory__c = 0;
            }
            
        }
        
        update bipzList[0];
        // AK 30 Mar Fixes End
         
        // 03/04/2023 : Code is fine till here, Below this issue is if we add another BLII in that BIPZ and run from there it will work fine
        // But if there is already a BIPZ for which there are let say 2 BLII and we are not running code from there then that will give error
        
        /******************************************************************/
        // This is a list of Budget Line Items which are tagged to Zone
        List<L2_Budget_Line_Item__c> bliRelatedToZoneList = [Select Id,Zone_Identification_For_Budget__c,Installation_Score__c,L2_Projected_Budget__c from L2_Budget_Line_Item__c 
                                                             WHERE Zone_Identification_For_Budget__c =: bipzList[0].Zone_Identification_For_Budget__c];
        system.debug('bliRelatedToZoneList => '+bliRelatedToZoneList);
        
        Map<Id,L2_Budget_Line_Item__c> bliRelatedToZoneMap = new Map<Id,L2_Budget_Line_Item__c>();
        
        for(L2_Budget_Line_Item__c bli : bliRelatedToZoneList){
            bliRelatedToZoneMap.put(bli.Id,bli);
        }
        
        /******************************************************************/
        // This is a list of Budget Line Items which are tagged to BIPZ => Related BLI Inst Records
        Set<Id> bliIdFromBipz = new Set<Id>();
        for(Budget_Line_Item_Installation__c bliInst : bliInstList){
            bliIdFromBipz.add(bliInst.Budget_Line_Item__c);
        }
        
        List<L2_Budget_Line_Item__c> bliRelatedToBIPZ = [Select Id,Zone_Identification_For_Budget__c,Installation_Score__c,L2_Projected_Budget__c from L2_Budget_Line_Item__c 
                                                             WHERE Id IN: bliIdFromBipz];
        
        Map<Id,L2_Budget_Line_Item__c> bliRelatedToBIPZMap = new Map<Id,L2_Budget_Line_Item__c>();
        
        for(L2_Budget_Line_Item__c bli : bliRelatedToBIPZ){
            bli.Installation_Date__c = bipzList[0].Installation_Date__c;
            bliRelatedToBIPZMap.put(bli.Id,bli);
        }
        
        // Updating Installation Dates of all related BLI linked to BIPZ which triggered the class
        update bliRelatedToBIPZMap.values();
        
        /******************************************************************/
        // Now we will compare map of both Budget Line Items to see which are Standalone BLI's which are not tagged to BIPZ from which class is triggered
        Map<Id,L2_Budget_Line_Item__c> leftoverBLIMap = new Map<Id,L2_Budget_Line_Item__c>();
        
        for(L2_Budget_Line_Item__c bli : bliRelatedToZoneList){
            // Checking those BLI which are there in Zone Map but not in BIPZ Map
            if(bliRelatedToZoneMap.containsKey(bli.Id) && !bliRelatedToBIPZMap.containsKey(bli.Id)){
                leftoverBLIMap.put(bli.Id,bli);
            }
        }
        
        system.debug('leftoverBLIMap => '+leftoverBLIMap);
        
        /******************************************************************/
        //Now we will fetch all BIPZ which are related to that PNL and try to find the latest entry which are related to Standalone BLI which we fetched in previous step
        
        
        Integer sizeAllBipzList = allBipzList.size() - 1;
        Date firstInstaDate = allBipzList[0].Installation_Date__c;
        
        // This map has Bli Id as key and Bipz Id as Value
        Map<Id,Budget_Installation_Per_Zone__c> latestBipzMap = new Map<Id,Budget_Installation_Per_Zone__c>();
        
        for(Budget_Installation_Per_Zone__c bipz : allBipzList){
            for(Budget_Line_Item_Installation__c bliInst : bipz.Budget_Line_Item_Installations__r){
                if(leftoverBLIMap.containsKey(bliInst.Budget_Line_Item__c)){
                    latestBipzMap.put(bliInst.Budget_Line_Item__c,bipz);
                    //break;
                }
            }
        }
		
		system.debug('latestBipzMap => '+latestBipzMap);
		        
        /******************************************************************/
        
        Zone_Identification_For_Budget__c zoneIdentBudget = [Select Id,Budget__c,Budget__r.Budget_for_Years__c,Budget__r.Inventory_Part_List_Relationship__c,
                                                                    Lead_Time_Months__c,Life__c,Negotitation_Time_Months__c,Product_L2__c,
                                                                    Transit_Time_Months__c,Inventory__c,Remaining_Inventory_After_Consumption__c
                                                                    from Zone_Identification_For_Budget__c 
                                                                    WHERE Id =: bipzList[0].Zone_Identification_For_Budget__c];
        
        
        List<Zone_Priority_Selection__c> zps = new List<Zone_Priority_Selection__c>([Select Id,Inventory_Part_List_Relationship__c,Zone_L2__c from Zone_Priority_Selection__c 
                                         WHERE Inventory_Part_List_Relationship__c =: zoneIdentBudget.Budget__r.Inventory_Part_List_Relationship__c 
                                         AND Zone_L2__c =: zoneIdentBudget.Product_L2__c]);
        
        String budgetForYears = zoneIdentBudget.Budget__r.Budget_for_Years__c;
        Integer budgetForYearsInt = integer.valueof(budgetForYears);
        
        Decimal lifeMonths = zoneIdentBudget.Life__c;   //12
        Decimal transitimeMonths = zoneIdentBudget.Transit_Time_Months__c;  
        Decimal negotitationimeMonths = zoneIdentBudget.Negotitation_Time_Months__c;
        Decimal leadTimeMonths = zoneIdentBudget.Lead_Time_Months__c;
        
        Decimal orderMonth = lifeMonths - (transitimeMonths + negotitationimeMonths + leadTimeMonths);
        Integer orderMonthInt = (Integer)orderMonth;
        system.debug('orderMonth =>'+orderMonth);   //8

        List<Wrapper> wrpList = new List<Wrapper>();
        
        for(L2_Budget_Line_Item__c bli : bliRelatedToZoneList){
            Wrapper wrp = new Wrapper();
            system.debug('bli 129 => '+bli);
            // Creating wrapper for Standalone BLI's
            if(leftoverBLIMap.containsKey(bli.Id)){
                Budget_Installation_Per_Zone__c bipz = latestBipzMap.get(bli.Id);
                system.debug('bipz => '+bipz);
                Set<Id> bliSet = new Set<Id>();
                for(Budget_Line_Item_Installation__c bliInst : bipz.Budget_Line_Item_Installations__r){
                    bliSet.add(bliInst.Budget_Line_Item__c);
                }
                if(bliSet.size() > 1){
                    wrp.totalInstallation = bipz.Total_Installation__c;
                    wrp.value = bipz.Total_Value__c;
                }else{
                    wrp.totalInstallation = bli.Installation_Score__c;
                    wrp.value = bli.L2_Projected_Budget__c;
                }
                wrp.bliIDSet = bliSet;
                wrp.installationDate = bipz.Installation_Date__c;
                wrpList.add(wrp);
            }
        }
       
        // Creating wrapper for BIPS => BLI's which triggered the apex
        Wrapper wrp = new Wrapper();
        wrp.bliIDSet = bliIdFromBipz;
        wrp.installationDate = bipzList[0].Installation_Date__c;
        wrp.totalInstallation = bipzList[0].Total_Installation__c;
        wrp.value = bipzList[0].Total_Value__c;

        wrpList.add(wrp);
        
        Map<Date,Wrapper> dateMap = new Map<Date,Wrapper>();
                
        for(Wrapper wrap : wrpList){
            system.debug('wrap => '+wrap);
            Date installationDate = wrap.installationDate;
            
            // 26 May Changes
            dateMap.put(installationDate,wrap);
            
            DateTime lastOrdDateTime = firstInstaDate.addYears(budgetForYearsInt);
            Date lastOrdDate = date.newinstance(lastOrdDateTime.year(), lastOrdDateTime.month(), lastOrdDateTime.day());
            DateTime ordDateTime = installationDate.addMonths(orderMonthInt);
            
            while(lastOrdDate > installationDate){
                Date newOrdDate = date.newinstance(ordDateTime.year(), ordDateTime.month(), ordDateTime.day());
                dateMap.put(newOrdDate,wrap);
                installationDate = installationDate.addMonths(orderMonthInt);
                ordDateTime = installationDate.addMonths(orderMonthInt);
            }
            system.debug('dateMap =>'+dateMap);
        }
        
        /******************************************************************/
        // Now we need to sort dates for all map values
        
        List<CalculateScoreBIPZ> dateWrapList = new List<CalculateScoreBIPZ>();
        for(Date dt : dateMap.keySet()){
            Wrapper wrap = dateMap.get(dt);
            CalculateScoreBIPZ dtGrp = new CalculateScoreBIPZ(wrap,dt);
            dateWrapList.add(dtGrp);
        }
        system.debug('dateWrapList Unsorted =>'+dateWrapList);
        dateWrapList.sort();
        system.debug('dateWrapList Sorted =>'+dateWrapList);
        
        /******************************************************************/
        // After this we will be creating BudgetInstallationPerZone Records for L2 Zone
        
        List<Budget_Installation_Per_Zone__c> bipzList2 = new List<Budget_Installation_Per_Zone__c>();
        
        Decimal inventory = 0;
        /*if(allBipzList[sizeAllBipzList].Remaining_Inventory__c != null ){
            inventory = allBipzList[sizeAllBipzList].Remaining_Inventory__c;
        }*/
        inventory = bipzList[0].Remaining_Inventory__c;
        system.debug('inventory => '+inventory);
        
        for(CalculateScoreBIPZ cbi : dateWrapList){
            Wrapper wrap = dateMap.get(cbi.instDate);
            Budget_Installation_Per_Zone__c bipz = new Budget_Installation_Per_Zone__c();
            bipz.Zone_Identification_For_Budget__c = bipzList[0].Zone_Identification_For_Budget__c;
            bipz.Installation_Date__c = cbi.instDate;
            //L2_Budget_Line_Item__c bli = budgetLineItemMap.get(cbi.bliId);
            //bipz.Budget_Line_Item_Name__c = cbi.bliId;
            Decimal installationScorePerL2 = wrap.totalInstallation;
            Decimal projBudget = wrap.value;
            
            if(inventory >= installationScorePerL2 && inventory != 0){
                bipz.Installation__c = installationScorePerL2;
                bipz.Remaining_Inventory__c = inventory - installationScorePerL2;
                inventory = inventory - installationScorePerL2;
            }else if(inventory < installationScorePerL2 && installationScorePerL2 != 0 && inventory !=  0){
                bipz.Remaining_Inventory__c = 0;
                bipz.Installation__c = installationScorePerL2 ;
                
                // Calculation of revenue for remaining inventories
                Decimal remainingInstallation = installationScorePerL2 - (installationScorePerL2 - inventory);
                Decimal scoreCal = 100 - ((remainingInstallation/installationScorePerL2) * 100);
                Decimal revenue = (scoreCal/100) * projBudget;
                bipz.Revenue__c = Math.round(revenue);
                inventory  = 0;
            }else if(inventory ==  0){
                bipz.Revenue__c = installationScorePerL2;
            }        
            bipzList2.add(bipz);
			           
        }
        zoneIdentBudget.Remaining_Inventory_After_Consumption__c = inventory; 
        
        
        
        system.debug('bipzList2 =>'+bipzList2);
        insert bipzList2;
        update zoneIdentBudget;
        if(zps.size() > 0){
            zps[0].Score__c = inventory;
            update zps;
        }
        
        /******************************************************************/

        List<Budget_Line_Item_Installation__c> bliInstNewList = new List<Budget_Line_Item_Installation__c>();
        
        for(Budget_Installation_Per_Zone__c bipz : bipzList2){
            Wrapper wrap = dateMap.get(bipz.Installation_Date__c);
            Set<Id> bliIDSet = wrap.bliIDSet;
            system.debug('bliIDSet =>'+bliIDSet);
            for(Id id : bliIDSet){
                Budget_Line_Item_Installation__c bilInstRec = new Budget_Line_Item_Installation__c();
            	bilInstRec.Budget_Installation_Per_Zone__c = bipz.Id;
                L2_Budget_Line_Item__c bli = bliRelatedToZoneMap.get(id);
                system.debug('bli =>'+bli);
                bilInstRec.Budget_Line_Item__c = bli.Id;
                bilInstRec.Total_Installation__c = bli.Installation_Score__c;
                bilInstRec.Value__c = bli.L2_Projected_Budget__c;
                //bilInstRec.Revenue__c = bipz.Revenue__c;
                system.debug(bilInstRec);
                bliInstNewList.add(bilInstRec);                
            }            
        }
        
        insert bliInstNewList;
        
        delete bipzList;
        
    }
    
    public class Wrapper{
        Date installationDate;
        Decimal totalInstallation;
        Set<Id> bliIDSet;
        Decimal value;
    }
 
}