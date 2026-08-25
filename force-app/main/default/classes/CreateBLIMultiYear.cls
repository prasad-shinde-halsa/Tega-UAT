public class CreateBLIMultiYear {
    @InvocableMethod (label = 'Create BLI Multi Year' description = 'returns nothing')
    public static void createMultiBLIMultiYear (List<List<L2_Budget_Line_Item__c>> bliList){
        try{
        List<L2_Budget_Line_Item__c> bliListFlow =  bliList[0];
        L2_Budget_Line_Item__c budgetLineItem = bliListFlow[0];
        system.debug('budgetLineItem => '+budgetLineItem);
        
        Budget__c bud = [Select Id,CurrencyIsoCode from Budget__c where Id =: budgetLineItem.Budget__c];
        
        Decimal occurence = budgetLineItem.Order_Occurence__c;
        Integer intOccurence = (Integer)occurence;
        Decimal monthIntervals = budgetLineItem.Recurring_Order_Time_Interval_Months__c;
        Integer intMonthsToAdded = (Integer)monthIntervals;
        
        List<L2_Budget_Line_Item__c> bliListToInsert = new List<L2_Budget_Line_Item__c>();
        budgetLineItem.Order_Type__c = 'Spares';
        budgetLineItem.CurrencyIsoCode = bud.CurrencyIsoCode;
        bliListToInsert.add(budgetLineItem);
        
        Date installationDate = budgetLineItem.Installation_Date__c;
        
        while(intOccurence > 0){
            installationDate = installationDate.addMonths(intMonthsToAdded);    
            L2_Budget_Line_Item__c clonedBLI = budgetLineItem.clone(false, true, false, false);
            clonedBLI.Installation_Date__c = installationDate;
            clonedBLI.Order_Type__c = 'Spares';
            clonedBLI.CurrencyIsoCode = bud.CurrencyIsoCode;
            bliListToInsert.add(clonedBLI);
            system.debug('clonedBLI =>'+clonedBLI);
            intOccurence--;
        }
        
        insert bliListToInsert;
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'CalculateScoreController',  'execute');
            
        }
    }
}