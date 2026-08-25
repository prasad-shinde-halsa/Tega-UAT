public class CreateMonthlyBudgetDetailManual {
    @InvocableMethod (label = 'Create Monthly Budget Detail Single Year' description = 'returns nothing')
    public static void createMonthDetManualSingleYear(List<List<L2_Budget_Line_Item__c>> bliList){
        try{
        List<L2_Budget_Line_Item__c> bliListFlow =  bliList[0];
        L2_Budget_Line_Item__c budgetLineItem = bliListFlow[0];
        system.debug('budgetLineItem => '+budgetLineItem);
        
        Budget__c budget = [Select Id,Part_List__c,CurrencyISOCode,Budget_For_Financial_Year__c,Concurrent_Year__c,Inventory_Part_List_Relationship__c,Financial_Year__c 
                            from Budget__c where Id =: budgetLineItem.Budget__c];
        
        budgetLineItem.CurrencyISOCode = budget.CurrencyISOCode;
        insert budgetLineItem;
        
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
        
        Integer monthCounter = 1;
        String financialYear = budget.Financial_Year__c;
        String[] financialYearArray = financialYear.split('-');
        String currentYear = financialYearArray[0]; 
        String nextYear = financialYearArray[1]; 
        
        List<Monthly_Budget_Detail__c> monthBudDetList = new List<Monthly_Budget_Detail__c>();
        
        for(String str : monthsMap.keySet()){           
            Monthly_Budget_Detail__c monthlyBudDetRec = new Monthly_Budget_Detail__c();
             if(monthCounter <= 9){
                 monthlyBudDetRec.Name = str + '-' + currentYear;
             }else{
                 monthlyBudDetRec.Name = str + '-' + nextYear;
             }
            monthCounter++;
            monthlyBudDetRec.L2_Budget_Line_Item__c = budgetLineItem.Id;
            monthlyBudDetRec.CurrencyISOCode = budget.CurrencyISOCode;
            monthBudDetList.add(monthlyBudDetRec);
        }
        
        insert monthBudDetList;
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'CreateMonthlyBudgetDetailManual',  'createMonthDetManualSingleYear');
            
        }
    }
}