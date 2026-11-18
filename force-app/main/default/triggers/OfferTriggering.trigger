trigger OfferTriggering on Quote (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {

        Budget_FY_year_Config__mdt budgetConfig = [SELECT MIS_Edit_Start_Date__c, MIS_Edit_End_Date__c FROM Budget_FY_year_Config__mdt LIMIT 1];

        List<MIS_Budget__c> newMISRecords = new List<MIS_Budget__c>();
        List<MIS_Budget__c> updateMisRecord = new List<MIS_Budget__c>();
        
        list<String> allRealtedBudgetLine = new List<String>();

        List<quote> allNewQuotes = new List<Quote>();


        for ( Integer i=0; Trigger.new.size() > i; i++ ) {
            // if(eachOffer.DC_Budget_Line_Items__c != null && ){
            //     allRealtedBudgetLine.add(eachOffer.DC_Budget_Line_Items__c)
            Quote newValueQuote = Trigger.New[i];
            Quote oldValueQuote = Trigger.isUpdate ? Trigger.Old[i] : new Quote();

            if(newValueQuote.Status == 'LS' && oldValueQuote.Status != 'LS' && newValueQuote.DC_Budget_Line_Items__c != null ){
                allRealtedBudgetLine.add(newValueQuote.DC_Budget_Line_Items__c);
                allNewQuotes.add(newValueQuote);
            }
            // else if(newValueQuote.Status == 'LS' && newValueQuote.DC_Budget_Line_Items__c != null ){
            //     allRealtedBudgetLine.add(newValueQuote.DC_Budget_Line_Items__c);
            //     allNewQuotes.add(newValueQuote);
            // }

        }

        if(allRealtedBudgetLine.size() > 0){



            system.debug('allRealtedBudgetLine:::: '+allRealtedBudgetLine);

         List<MIS_Budget__c> existingMISRecords = [SELECT Id, Order_Type__c,CreatedDate FROM MIS_Budget__c  WHERE Budget_Line_Items__c = :allRealtedBudgetLine[0]]; 
         List<DC_Budget_Line_Items__c> allBLI = [Select Id, Name, Order_Type__c from DC_Budget_Line_Items__c WHERE Id =:allRealtedBudgetLine[0]];

         MIS_Budget__c newMIS = new MIS_Budget__c();
         
         newMIS.Budget_Line_Items__c = allNewQuotes[0].DC_Budget_Line_Items__c;
         newMIS.Mis_Monthly_Report__c = budgetConfig.MIS_Edit_Start_Date__c; // Add this line


         Date lostDate = allNewQuotes[0].Lost_Date__c;
         Integer lostDateYear  = lostDate.year();
         Integer lostMonth = lostDate.month();
            
            String[] monthNames = new String[]{
                    'Jan','Feb','Mar','Apr','May','Jun',
                        'Jul','Aug','Sep','Oct','Nov','Dec'
                        };
                            
            String lostDatemonth = monthNames[lostMonth - 1];
            
            String lostDatemonthName = allNewQuotes[0].Budgeted_Order_Month__c;
            
            String formatedLostDatemonthName = lostDatemonth + ', ' + lostDateYear;
         if (lostDate != null) {
             switch on lostDatemonthName {
                 when 'Jan' { // January
                     newMIS.Order_Expected_Stage_Jan__c = 'Lost';
                     newMIS.Order_Expected_Month_Jan__c = formatedLostDatemonthName; 
                 }
                 when 'Feb' { // February
                     newMIS.Order_Expected_Stage_Feb__c = 'Lost';
                     newMIS.Order_Expected_Month_Feb__c = formatedLostDatemonthName; 
                 }
                 when 'Mar' { // March
                     newMIS.Order_Expected_Stage_Mar__c = 'Lost';
                     newMIS.Order_Expected_Month_Mar__c = formatedLostDatemonthName; 
                 }
                 when 'Apr' { // April
                     newMIS.Order_Expected_Stage_Apr__c = 'Lost';
                     newMIS.Order_Expected_Month_Apr__c = formatedLostDatemonthName; 
                 }
                 when 'May' { // May
                     newMIS.Order_Expected_Stage_May__c = 'Lost';
                     newMIS.Order_Expected_Month_May__c = formatedLostDatemonthName; 
                 }
                 when 'Jun' { // June
                     newMIS.Order_Expected_Stage_Jun__c = 'Lost';
                     newMIS.Order_Expected_Month_Jun__c = formatedLostDatemonthName; 
                 }
                 when 'Jul' { // July
                     newMIS.Order_Expected_Stage_Jul__c = 'Lost';
                     newMIS.Order_Expected_Month_Jul__c = formatedLostDatemonthName; 
                 }
                 when 'Aug' { // August
                     newMIS.Order_Expected_Stage_Aug__c = 'Lost';
                     newMIS.Order_Expected_Month_Aug__c = formatedLostDatemonthName; 
                 }
                 when 'Sep' { // September
                     newMIS.Order_Expected_Stage_Sep__c = 'Lost';
                     newMIS.Order_Expected_Month_Sep__c = formatedLostDatemonthName; 
                 }
                 when 'Oct' { // October
                     newMIS.Order_Expected_Stage_Oct__c = 'Lost';
                     newMIS.Order_Expected_Month_Oct__c = formatedLostDatemonthName; 
                 }
                 when 'Nov' { // November
                     newMIS.Order_Expected_Stage_Nov__c = 'Lost';
                     newMIS.Order_Expected_Month_Nov__c = formatedLostDatemonthName; 
                 }
                 when 'Dec' { // December
                     newMIS.Order_Expected_Stage_Dec__c = 'Lost';
                     newMIS.Order_Expected_Month_Dec__c = formatedLostDatemonthName; 
                 }
             }
         }



        if(existingMISRecords.size() > 0 && existingMISRecords[0].createdDate >= budgetConfig.MIS_Edit_Start_Date__c 
        && existingMISRecords[0].createdDate <= budgetConfig.MIS_Edit_End_Date__c){
            MIS_Budget__c existingMIS = existingMISRecords[0];
            newMIS.Id = existingMIS.Id;
            newMIS.Order_Type__c = existingMIS.Order_Type__c; 
            newMIS.Mis_Monthly_Report__c = budgetConfig.MIS_Edit_Start_Date__c; 
            
            updateMisRecord.add(newMIS); 
        }
        else{
            // newMIS.Id = existingMIS.Id;
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
        integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
       i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
       
    }
}