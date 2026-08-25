@isTest
public class updateAccountManagerBatchTestClass {
    
    @testSetup
    static void setupData() {
        //**Create Users (Managers)
        User u1 = new User(
            FirstName = 'Test1',
            LastName = 'Manager',
            Alias = 'tman',
            Email = 'tman@test.com',
            Username = 'tman' + DateTime.now().getTime() + '@test.com',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );
        insert u1;
        User u2 = new User(
            FirstName = 'Test2',
            LastName = 'Manager',
            Alias = 'tman',
            Email = 'tman@test.com',
            Username = 'tman' + DateTime.now().getTime() + '@test.com',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );
        insert u2;

        //**Create Sales Regions
        Sales_Region__c region1 = new Sales_Region__c(Name = 'Region 1', Manager__c = u1.Id);
        insert region1;
        Sales_Region__c region2 = new Sales_Region__c(Name = 'Region 2', Manager__c = u2.Id);
        insert region2;
        //**Create Accounts - Case 1: No Manager, but Region has Manager
        Account acc1 = new Account(Name = 'Account 1', Sales_Region__c = region1.Id,billingCity='Test',BillingPostalCode='23478',Customer_Code__c = 'CUST-89' );
        insert acc1;
        //**Case 2: Has Manager but different from Region Manager
        Account acc2 = new Account(Name = 'Account 24', Sales_Region__c = region2.Id, Regional_Manager__c = u1.Id, Customer_Code__c = 'CUST-22' , billingCity='Kolkata', BillingPostalCode='12345');
        insert acc2;
        //**Case 3: No Region/Manager, but fallback through Customer_Sales_Organization__c
        Sales_Region__c branchRegion = new Sales_Region__c(Name = 'Branch Region', Manager__c = u1.Id);
        insert branchRegion;
        Account acc3 = new Account(Name = 'Account 34', Description='Test',billingCity='Test City',BillingPostalCode='23456',Customer_Code__c = 'CUST-09' );

        insert acc3;
        Branch__c branch = new Branch__c(Name = 'Branch A', Sales_Region__c = branchRegion.Id,Branch_Code__c='0987654');
        insert branch;
        Customer_Sales_Organization__c cso = new Customer_Sales_Organization__c(
            Name = 'CSO 1',
            Customer__c = acc3.Id,
            Branch__c = branch.Id,
            CreatedFromAccount__c = true
        );
        insert cso;
    }
    @isTest
    static void testTriggerUpdate() {
        //**Fetch the region to change manager
        Sales_Region__c regionToUpdate = [SELECT Id, Manager__c FROM Sales_Region__c LIMIT 1];
        //**Create a new manager to simulate change
        User newManager = new User(
            FirstName = 'Test',
            LastName = 'Manager',
            Alias = 'tman',
            Email = 'tman@test.com',
            Username = 'tman' + DateTime.now().getTime() + '@test.com',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );
        insert newManager;
        regionToUpdate.Manager__c = newManager.Id;
        update regionToUpdate;
        Test.startTest();
        //**The trigger should automatically run the batch
        Test.stopTest();
        //**Validate Accounts are updated
        List<Account> updatedAccounts = [SELECT Id, Regional_Manager__c FROM Account WHERE Sales_Region__c = :regionToUpdate.Id];
        for (Account acc : updatedAccounts) {
            System.assertEquals(newManager.Id, acc.Regional_Manager__c, 'Regional Manager should be updated');
        }
    }
    @isTest
    static void testAnonymousFallbackRun() {
        Test.startTest();
        //**Run batch manually to cover the fallback logic
        Database.executeBatch(new UpdateAccountManagerBatch(), 1);
        Test.stopTest();
        //**Validate the fallback updated Account 34
        Account fallbackAcc = [SELECT Regional_Manager__c, Sales_Region__c FROM Account WHERE Name = 'Account 34'];
        System.assertNotEquals(null, fallbackAcc.Regional_Manager__c, 'Fallback should assign manager');
        System.assertNotEquals(null, fallbackAcc.Sales_Region__c, 'Fallback should assign region');
    }
    @isTest
static void testErrorHandling() {
    //**First create a valid account
    Account acc = new Account(
        Name = 'Test Account',
        Customer_Code__c = 'TEST-123',
        BillingCity = 'Test City',
        BillingPostalCode = '12345'
    );
    insert acc;
    
    //**Now query it back and modify to make it invalid
    Account accToUpdate = [SELECT Id FROM Account WHERE Id = :acc.Id];
    accToUpdate.Name = null; //**This will make the update fail
    
    Test.startTest();
    UpdateAccountManagerBatch batch = new UpdateAccountManagerBatch(new Set<Id>{acc.Id});
    batch.execute(null, new List<Account>{accToUpdate});
    Test.stopTest();
    
    //**Verify error logs were created
    List<Error_Log__c> logs = [SELECT Id, Error_Message__c FROM Error_Log__c];
    System.assert(!logs.isEmpty(), 'Error logs should be created for failed updates');
    
}

}