public class UpdateAccountManagerBatch implements Database.Batchable<SObject> {
    
    private Set<Id> salesRegionId;
    
    // Constructor for trigger
    public UpdateAccountManagerBatch(Set<Id> salesRegionId) {
        this.salesRegionId = salesRegionId;
    }
    
    // Default constructor for anonymous run
    public UpdateAccountManagerBatch() {}
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query;
        
        if (salesRegionId != null && !salesRegionId.isEmpty()) {
            //**Trigger context — only process provided Account records
            query = 'SELECT Id, Name, Sales_Region__c, Regional_Manager__c, ' +
                'Sales_Region__r.Manager__c, ' +
                '(SELECT Branch__r.Sales_Region__r.Manager__c, Branch__r.Sales_Region__c' +
                ' FROM Customer_Sales_Organizations__r) ' +
                'FROM Account ' +
                'WHERE Sales_Region__c IN :salesRegionId';
        } else {
            //**Anonymous context — missing Sales Region or Regional Manager
            query = 'SELECT Id, Name, Sales_Region__c, Regional_Manager__c, ' +
                'Sales_Region__r.Manager__c, ' +
                '(SELECT Branch__r.Sales_Region__r.Manager__c, Branch__r.Sales_Region__c ' +
                ' FROM Customer_Sales_Organizations__r LIMIT 1) ' +
                'FROM Account ' +
                'WHERE Sales_Region__c = NULL OR Regional_Manager__c = NULL';
        }
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        List<Account> accountsToUpdate = new List<Account>();
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        
        try {
            for (Account acc : scope) {
                Boolean updated = false;
                
                //**CASE 1: Regional_Manager__c is null — assign from Sales_Region__r.Manager__c
                if (acc.Regional_Manager__c == null &&
                    acc.Sales_Region__r != null &&
                    acc.Sales_Region__r.Manager__c != null) {
                        
                        acc.Regional_Manager__c = acc.Sales_Region__r.Manager__c;
                        updated = true;
                    }
                
                //**CASE 2: Already has manager, but it's outdated — update it
                else if (acc.Regional_Manager__c != null &&
                         acc.Sales_Region__r != null &&
                         acc.Sales_Region__r.Manager__c != null &&
                         acc.Regional_Manager__c != acc.Sales_Region__r.Manager__c) {
                             
                             acc.Regional_Manager__c = acc.Sales_Region__r.Manager__c;
                             updated = true;
                         }
                
                //**CASE 3: Fallback to child relationship (only 1 record due to LIMIT 1)
                if (acc.Regional_Manager__c == null &&
                    acc.Sales_Region__c == null &&
                    acc.Customer_Sales_Organizations__r != null &&
                    !acc.Customer_Sales_Organizations__r.isEmpty()) {
                        
                        Customer_Sales_Organization__c cso = acc.Customer_Sales_Organizations__r[0];
                        
                        if (cso.Branch__r != null &&
                            cso.Branch__r.Sales_Region__r != null &&
                            cso.Branch__r.Sales_Region__r.Manager__c != null) {
                                
                                acc.Regional_Manager__c = cso.Branch__r.Sales_Region__r.Manager__c;
                                acc.Sales_Region__c = cso.Branch__r.Sales_Region__c;
                                updated = true;
                            }
                    }
                
                if (updated) {
                    accountsToUpdate.add(acc);
                }
            }
            
            //**Perform the update
            if (!accountsToUpdate.isEmpty()) {
                Database.SaveResult[] results = Database.update(accountsToUpdate, false);
                
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        for (Database.Error err : results[i].getErrors()) {
                            errorLogs.add(new Error_Log__c(
                                Class_Name__c = 'UpdateAccountManagerBatch',
                            	Method_Name__c = 'Execute',
                            	Error_Message__c = err.getMessage(),
                            	Error_Type__c = String.valueOf(err.getStatusCode())
                            ));
                        }
                    }
                }
            }
        } catch (Exception ex) {
            //**Catch any unhandled error and log it
            for (Account acc : scope) {
                errorLogs.add(new Error_Log__c(
                    Class_Name__c = 'UpdateAccountManagerBatch',
                	Method_Name__c = 'Execute',
                	Error_Message__c = ex.getMessage(),
                	Error_Type__c = ex.getTypeName(),
                	Line_Number__c = ex.getLineNumber()
                ));
            }
        }
        
        //**Insert all error logs if any
        if (!errorLogs.isEmpty()) {
            try {
                Database.insert(errorLogs, false);
            } catch (Exception insertEx) {
                System.debug('Failed to log errors: ' + insertEx.getMessage());
            }
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        System.debug('Account manager update batch finished.');
    }
}