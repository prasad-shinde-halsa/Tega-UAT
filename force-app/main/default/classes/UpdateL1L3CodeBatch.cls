// Batch Apex Class for handling large volumes of data
// Use this if you have more than 10,000 records

public class UpdateL1L3CodeBatch implements Database.Batchable<SObject> {
    
    // Start method - Query records
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, code_formula__c, L1L3_Code__c 
            FROM L1_L3_Product__c 
            WHERE code_formula__c != null
        ]);
    }
    
    // Execute method - Process each batch
    public void execute(Database.BatchableContext bc, List<L1_L3_Product__c> scope) {
        List<L1_L3_Product__c> productsToUpdate = new List<L1_L3_Product__c>();
        
        for(L1_L3_Product__c product : scope) {
            product.L1L3_Code__c = product.code_formula__c;
            productsToUpdate.add(product);
        }
        
        if(!productsToUpdate.isEmpty()) {
            try {
                update productsToUpdate;
            } catch(DmlException e) {
                System.debug('Error updating batch: ' + e.getMessage());
            }
        }
    }
    
    // Finish method
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch job completed');
        
        // Optional: Send email notification
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
            FROM AsyncApexJob 
            WHERE Id = :bc.getJobId()
        ];
        
        System.debug('Job Status: ' + job.Status);
        System.debug('Records Processed: ' + job.TotalJobItems);
        System.debug('Errors: ' + job.NumberOfErrors);
    }
}

// To execute this batch class, run in Anonymous Apex:
// UpdateL1L3CodeBatch batch = new UpdateL1L3CodeBatch();
// Database.executeBatch(batch, 200);