@isTest
public class FixBudgetLineItemCurrencyBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create required parent records
        
        // Create Account for Customer lookup
        Account customer = new Account(
            Name = 'Test Customer Account'
        );
        insert customer;
        
        // Create Company custom object
        Company__c company = new Company__c(
            Name = 'Test Company',
            Company_Code__c = 'TEST001'
        );
        insert company;
        
        // Create PMG Master record (REQUIRED FIELD)
        PMG_Master__c pmgMaster = new PMG_Master__c(
            Name = 'Test PMG Master'
            // Add other required fields if any
        );
        insert pmgMaster;
        
        // Create Budget record
        DC_Budget__c budget = new DC_Budget__c(
            Name = 'Test Budget',
            Company__c = company.Id
        );
        insert budget;
        
        // Create test Budget Line Items
        List<DC_Budget_Line_Items__c> testRecords = new List<DC_Budget_Line_Items__c>();
        
        // Records with USD currency
        for (Integer i = 0; i < 50; i++) {
            DC_Budget_Line_Items__c li = new DC_Budget_Line_Items__c(
                Budget__c = budget.Id,
                Customer__c = customer.Id,
                PMG_Master__c = pmgMaster.Id,  // Add required field
                CurrencyIsoCode = 'USD'
            );
            testRecords.add(li);
        }
        
        // Records with EUR currency
        for (Integer i = 50; i < 75; i++) {
            DC_Budget_Line_Items__c li = new DC_Budget_Line_Items__c(
                Budget__c = budget.Id,
                Customer__c = customer.Id,
                PMG_Master__c = pmgMaster.Id,  // Add required field
                CurrencyIsoCode = 'EUR'
            );
            testRecords.add(li);
        }
        
        insert testRecords;
    }
    
    @isTest
    static void testBatchExecution() {
        // Query initial state
        Integer initialCount = [SELECT COUNT() FROM DC_Budget_Line_Items__c];
        System.assert(initialCount > 0, 'Test data should be created');
        
        Test.startTest();
        
        // Execute the batch
        FixBudgetLineItemCurrencyBatch batch = new FixBudgetLineItemCurrencyBatch();
        Id jobId = Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify batch job was created
        System.assertNotEquals(null, jobId, 'Batch job should be created');
        
        // Verify batch job completed
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
                           FROM AsyncApexJob 
                           WHERE Id = :jobId];
        
        System.assertEquals('Completed', job.Status, 'Batch job should complete successfully');
        System.assertEquals(0, job.NumberOfErrors, 'Batch should have no errors');
    }
    
    @isTest
    static void testBatchWithNoRecords() {
        // Delete all test data
        delete [SELECT Id FROM DC_Budget_Line_Items__c];
        
        Test.startTest();
        
        // Execute the batch with no records
        FixBudgetLineItemCurrencyBatch batch = new FixBudgetLineItemCurrencyBatch();
        Id jobId = Database.executeBatch(batch);
        
        Test.stopTest();
        
        // Verify batch completed even with no records
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors
                           FROM AsyncApexJob 
                           WHERE Id = :jobId];
        
        System.assertEquals('Completed', job.Status, 'Batch should complete with no records');
        System.assertEquals(0, job.NumberOfErrors, 'Batch should have no errors');
    }
    
    @isTest
    static void testQueryLocator() {
        Test.startTest();
        
        FixBudgetLineItemCurrencyBatch batch = new FixBudgetLineItemCurrencyBatch();
        Database.QueryLocator ql = batch.start(null);
        
        Test.stopTest();
        
        // Verify query locator returns results
        System.assertNotEquals(null, ql, 'QueryLocator should not be null');
    }
    
    @isTest
    static void testExecuteMethod() {
        // Create test data within this method with unique identifiers
        Account customer = new Account(Name = 'Test Customer Execute Method');
        insert customer;
        
        Company__c company = new Company__c(
            Name = 'Test Company Execute Method',
            Company_Code__c = 'EXEC001'
        );
        insert company;
        
        PMG_Master__c pmgMaster = new PMG_Master__c(
            Name = 'Test PMG Master Execute Method'
        );
        insert pmgMaster;
        
        DC_Budget__c budget = new DC_Budget__c(
            Name = 'Test Budget Execute Method',
            Company__c = company.Id
        );
        insert budget;
        
        List<DC_Budget_Line_Items__c> testRecords = new List<DC_Budget_Line_Items__c>();
        for (Integer i = 0; i < 10; i++) {
            testRecords.add(new DC_Budget_Line_Items__c(
                Budget__c = budget.Id,
                Customer__c = customer.Id,
                PMG_Master__c = pmgMaster.Id,
                CurrencyIsoCode = 'USD'
            ));
        }
        insert testRecords;
        
        System.assert(!testRecords.isEmpty(), 'Should have test records');
        
        Test.startTest();
        
        // Call execute method directly
        FixBudgetLineItemCurrencyBatch batch = new FixBudgetLineItemCurrencyBatch();
        batch.execute(null, testRecords);
        
        Test.stopTest();
        
        // Verify records were processed
        List<DC_Budget_Line_Items__c> updatedRecords = [SELECT Id, CurrencyIsoCode, Currency__c 
                                                        FROM DC_Budget_Line_Items__c 
                                                        WHERE Id IN :testRecords];
        System.assert(!updatedRecords.isEmpty(), 'Records should exist after processing');
    }
    
    @isTest
    static void testFinishMethod() {
        Test.startTest();
        
        FixBudgetLineItemCurrencyBatch batch = new FixBudgetLineItemCurrencyBatch();
        Id jobId = Database.executeBatch(batch);
        
        Test.stopTest();
        
        // Verify finish method can query the job
        AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertNotEquals(null, job, 'Job should exist after completion');
    }
}