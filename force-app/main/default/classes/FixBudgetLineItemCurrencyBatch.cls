public class FixBudgetLineItemCurrencyBatch implements Database.Batchable<SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, CurrencyIsoCode, Currency__c ' +
            'FROM DC_Budget_Line_Items__c ' +
            'WHERE Budget__r.Financial_Year__c = \'2026-27\' ' +
            'AND Currency_Same_As_Budget__c = false'
        );
        
    }
    
    public void execute(Database.BatchableContext bc, List<DC_Budget_Line_Items__c> scope) {
        List<DC_Budget_Line_Items__c> toUpdate = new List<DC_Budget_Line_Items__c>();
        
        System.debug('Records-->'+ scope[0]);
        
        for (DC_Budget_Line_Items__c li : scope) {
            if (li.CurrencyIsoCode != li.Currency__c) {
                li.CurrencyIsoCode = li.Currency__c;
                toUpdate.add(li);
            }
        }
        
        if (!toUpdate.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(toUpdate, false);
                
                for (Database.SaveResult sr : results) {
                    if (!sr.isSuccess()) {
                        for (Database.Error err : sr.getErrors()) {
                            System.debug('Error updating record ' + sr.getId() + ': ' + err.getMessage());
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Exception in batch execute: ' + e.getMessage());
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
                            FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        System.debug('Currency sync completed. Status: ' + job.Status + 
                     ', Records Processed: ' + job.JobItemsProcessed + 
                     ', Errors: ' + job.NumberOfErrors);
    }
}