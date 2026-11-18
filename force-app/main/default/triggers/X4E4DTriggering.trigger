/**
 * Trigger: X4E4DTriggering
 * Object: X4E_4D__c
 * Events: After Insert, After Update
 *
 * Description:
 * This trigger creates or updates related MIS_Budget__c records when an X4E_4D__c
 * record is moved to "Closed" status.
 * Test class - X4E4DTriggeringTest
 * Key Logic:
 *  - Runs only on after insert and after update.
 *  - Collects Budget Line Item IDs from newly closed X4E_4D__c records.
 *  - For each related Budget Line Item:
 *      • Checks if an MIS_Budget__c already exists in the current MIS edit window
 *        (between MIS_Edit_Start_Date__c and MIS_Edit_End_Date__c from
 *         Budget_FY_year_Config__mdt).
 *      • If an existing MIS record is found → update it.
 *      • Otherwise → insert a new MIS_Budget__c record.
 *  - Populates monthly fields (Order_Expected_Stage_*__c and
 *    Order_Expected_Month_*__c) based on Budgeted_Order_Month__c value.
 *
 * Author - 
 * Last Modified By - Reetabrata
 * Last Modified Date = 1st sep 2025
 */

trigger X4E4DTriggering on X4E_4D__c (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {

        Budget_FY_year_Config__mdt budgetConfig = [SELECT MIS_Edit_Start_Date__c, MIS_Edit_End_Date__c FROM Budget_FY_year_Config__mdt LIMIT 1];

        List<MIS_Budget__c> newMISRecords = new List<MIS_Budget__c>();
        List<MIS_Budget__c> updateMisRecord = new List<MIS_Budget__c>();
        
        list<String> allRealtedBudgetLine = new List<String>();

        List<X4E_4D__c> allNewX4ERecords = new List<X4E_4D__c>();

        for ( Integer i=0; Trigger.new.size() > i; i++ ) {
            X4E_4D__c newValueX4E = Trigger.New[i];
            X4E_4D__c oldValueX4E = Trigger.isUpdate ? Trigger.Old[i] : new X4E_4D__c();

            if(newValueX4E.Status_SO__c == 'Closed' && oldValueX4E.Status_SO__c!= 'Closed' && newValueX4E.DC_Budget_Line_Items__c != null ){
                allRealtedBudgetLine.add(newValueX4E.DC_Budget_Line_Items__c);
                allNewX4ERecords.add(newValueX4E);
            }
            // else if(newValueX4E.Status_SO__c == 'Closed' && newValueX4E.DC_Budget_Line_Items__c != null ){
            //     allRealtedBudgetLine.add(newValueX4E.DC_Budget_Line_Items__c);
            //     allNewX4ERecords.add(newValueX4E);
            // }
        }

        if(allRealtedBudgetLine.size() > 0){
            system.debug('allRealtedBudgetLine:::: '+allRealtedBudgetLine);

            List<MIS_Budget__c> existingMISRecords = [SELECT Id, Order_Type__c, CreatedDate FROM MIS_Budget__c WHERE Budget_Line_Items__c = :allRealtedBudgetLine[0]]; 
            List<DC_Budget_Line_Items__c> allBLI = [SELECT Id, Name, Order_Type__c FROM DC_Budget_Line_Items__c WHERE Id = :allRealtedBudgetLine[0]];

            MIS_Budget__c newMIS = new MIS_Budget__c();
            newMIS.Budget_Line_Items__c = allNewX4ERecords[0].DC_Budget_Line_Items__c;
            newMIS.Mis_Monthly_Report__c = budgetConfig.MIS_Edit_Start_Date__c; 

            
            Date closedDate = allNewX4ERecords[0].Closed_Date__c;
            Integer closeDateMonth = closedDate.month(); // Returns 1–12
            
            String[] monthNames = new String[]{
                'Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'
                    };
                        
            String closeDatemonthName = monthNames[closeDateMonth - 1];
            
            Integer closeDateYear  = closedDate.year();
            
            String formatedcloseDatemonthName = closeDatemonthName + ', ' + closeDateYear;
            
            String budgetedOrderMonth = allNewX4ERecords[0].Budgeted_Order_Month__c;
            
            if (String.isNotBlank(budgetedOrderMonth)) {
                String monthValue = budgetedOrderMonth.trim();
                switch on monthValue {
                    when 'Jan' { 
                        newMIS.Order_Expected_Stage_Jan__c = 'Order'; 
                        newMIS.Order_Expected_Month_Jan__c = formatedcloseDatemonthName; 
                    }
                    when 'Feb' { 
                        newMIS.Order_Expected_Stage_Feb__c = 'Order'; 
                        newMIS.Order_Expected_Month_Feb__c = formatedcloseDatemonthName; 
                    }
                    when 'Mar' { 
                        newMIS.Order_Expected_Stage_Mar__c = 'Order'; 
                        newMIS.Order_Expected_Month_Mar__c = formatedcloseDatemonthName; 
                    }
                    when 'Apr' { 
                        newMIS.Order_Expected_Stage_Apr__c = 'Order'; 
                        newMIS.Order_Expected_Month_Apr__c = formatedcloseDatemonthName; 
                    }
                    when 'May' { 
                        newMIS.Order_Expected_Stage_May__c = 'Order'; 
                        newMIS.Order_Expected_Month_May__c = formatedcloseDatemonthName; 
                    }
                    when 'Jun' { 
                        newMIS.Order_Expected_Stage_Jun__c = 'Order'; 
                        newMIS.Order_Expected_Month_Jun__c = formatedcloseDatemonthName; 
                    }
                    when 'Jul' { 
                        newMIS.Order_Expected_Stage_Jul__c = 'Order'; 
                        newMIS.Order_Expected_Month_Jul__c = formatedcloseDatemonthName; 
                    }
                    when 'Aug' { 
                        newMIS.Order_Expected_Stage_Aug__c = 'Order'; 
                        newMIS.Order_Expected_Month_Aug__c = formatedcloseDatemonthName; 
                    }
                    when 'Sep' { 
                        newMIS.Order_Expected_Stage_Sep__c = 'Order'; 
                        newMIS.Order_Expected_Month_Sep__c = formatedcloseDatemonthName; 
                    }
                    when 'Oct' { 
                        newMIS.Order_Expected_Stage_Oct__c = 'Order'; 
                        newMIS.Order_Expected_Month_Oct__c = formatedcloseDatemonthName; 
                    }
                    when 'Nov' { 
                        newMIS.Order_Expected_Stage_Nov__c = 'Order'; 
                        newMIS.Order_Expected_Month_Nov__c = formatedcloseDatemonthName; 
                    }
                    when 'Dec' { 
                        newMIS.Order_Expected_Stage_Dec__c = 'Order'; 
                        newMIS.Order_Expected_Month_Dec__c = formatedcloseDatemonthName; 
                    }
                }
            }

            if(existingMISRecords.size() > 0 && existingMISRecords[0].CreatedDate >= budgetConfig.MIS_Edit_Start_Date__c 
            && existingMISRecords[0].CreatedDate <= budgetConfig.MIS_Edit_End_Date__c){
                MIS_Budget__c existingMIS = existingMISRecords[0];
                newMIS.Id = existingMIS.Id;
                newMIS.Order_Type__c = existingMIS.Order_Type__c; 
                newMIS.Mis_Monthly_Report__c = budgetConfig.MIS_Edit_Start_Date__c; 
                
                updateMisRecord.add(newMIS); 
            }
            else {
                newMIS.Order_Type__c = allBLI[0].Order_Type__c; 
                newMIS.Mis_Monthly_Report__c = budgetConfig.MIS_Edit_Start_Date__c; 
                newMISRecords.add(newMIS);
            }

            if (!updateMisRecord.isEmpty()) {
                update updateMisRecord; 
            }
            if(!newMISRecords.isEmpty()){
                insert newMISRecords;
            }
        }
         
    }
}