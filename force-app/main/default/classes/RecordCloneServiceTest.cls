@isTest
private class RecordCloneServiceTest {

    @testSetup
    static void setupData() {
        // Create a Branch
        Branch__c branch = new Branch__c(
            Name = 'Test Branch',
            Branch_Code__c = 'TB001',
            CIF_Factor__c = 1.04,
            CurrencyIsoCode = 'USD',
            Is_WOS__c = true
        );
        insert branch;

        // Create a Company
        Company__c company = new Company__c(
            Name = 'Test Company',
            Company_Code__c = 'LS06',
            CurrencyIsoCode = 'USD'
        );
        insert company;

        // Create a PMG Master
        PMG_Master__c pmgMaster = new PMG_Master__c(Name = 'Test PMG Master');
        insert pmgMaster;

        // Create a Customer
        Account customer = new Account(Name = 'Test Customer');
        insert customer;

        // Create DC Budget
        DC_Budget__c budget = new DC_Budget__c(
            Name = 'FY26 Budget',
            Status__c = '4th Level Approved',
            Financial_Year__c = '2025-26',
            CurrencyIsoCode = 'USD',
            Branch__c = branch.Id,
            Company__c = company.Id
        );
        insert budget;

        // Create Budget Line Item (Source record for cloning)
        DC_Budget_Line_Items__c lineItem = new DC_Budget_Line_Items__c(
            PMG_Master__c = pmgMaster.Id,
            Customer__c = customer.Id,
            Budget__c = budget.Id,
            Order_Type__c = 'E-Spares',
            Active_Status__c = true,
            Jul_Order__c = 5000,
            Aug_Order__c = 3000
        );
        insert lineItem;
    }

    @isTest
    static void testCloneRecordService_JulyMonth() {
        // Fetch source budget + line item
        DC_Budget__c targetBudget = [SELECT Id FROM DC_Budget__c LIMIT 1];
        DC_Budget_Line_Items__c source = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];

        // Prepare request (Clone July with value 9999)
        RecordCloneService.CloneRequest req = new RecordCloneService.CloneRequest();
        req.recordId = source.Id;
        req.budgetId = targetBudget.Id;
        req.budgetMonth = 'Jul';
        req.budgetValue = 9999;

        Test.startTest();
        List<RecordCloneService.CloneResponse> responses =
            RecordCloneService.cloneRecords(new List<RecordCloneService.CloneRequest>{req});
        Test.stopTest();

        // Assert clone created
        System.assertEquals(1, responses.size(), 'One clone should be created');
        DC_Budget_Line_Items__c cloned = [
            SELECT Id, Budget__c, Jul_Order__c, Aug_Order__c, Sep_Order__c
            FROM DC_Budget_Line_Items__c
            WHERE Id = :responses[0].clonedRecordId
        ];

        // Assert budget is overridden
        System.assertEquals(targetBudget.Id, cloned.Budget__c, 'Budget should be overridden');
        
        // Assert July is set correctly
        System.assertEquals(9999, cloned.Jul_Order__c, 'July should have new budget value');

        // Assert other months reset to 0
        System.assertEquals(0, cloned.Aug_Order__c, 'August should be reset to 0');
        System.assertEquals(0, cloned.Sep_Order__c, 'September should be reset to 0');

    }

    @isTest
    static void testCloneRecordService_NovemberMonth() {
        // Fetch source budget + line item
        DC_Budget__c targetBudget = [SELECT Id FROM DC_Budget__c LIMIT 1];
        DC_Budget_Line_Items__c source = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];

        // Prepare request (Clone November with value 1111)
        RecordCloneService.CloneRequest req = new RecordCloneService.CloneRequest();
        req.recordId = source.Id;
        req.budgetId = targetBudget.Id;
        req.budgetMonth = 'Nov';
        req.budgetValue = 1111;

        Test.startTest();
        List<RecordCloneService.CloneResponse> responses =
            RecordCloneService.cloneRecords(new List<RecordCloneService.CloneRequest>{req});
        Test.stopTest();

        // Assert clone created
        System.assertEquals(1, responses.size(), 'One clone should be created');
        DC_Budget_Line_Items__c cloned = [
            SELECT Id, Budget__c, Nov_Order__c, Dec_Order__c, Jul_Order__c
            FROM DC_Budget_Line_Items__c
            WHERE Id = :responses[0].clonedRecordId
        ];

        // Assert budget is overridden
        System.assertEquals(targetBudget.Id, cloned.Budget__c, 'Budget should be overridden');
        // Assert November is set correctly
        System.assertEquals(1111, cloned.Nov_Order__c, 'November should have new budget value');

        // Assert other months reset to 0
        System.assertEquals(0, cloned.Dec_Order__c, 'December should be reset to 0');
        System.assertEquals(0, cloned.Jul_Order__c, 'July should be reset to 0');
    }
    @isTest
    static void testCloneRecordService_NullValue() {
         RecordCloneService.CloneRequest req = new RecordCloneService.CloneRequest();
        Test.startTest();
        List<RecordCloneService.CloneResponse> responses =
            RecordCloneService.cloneRecords(new List<RecordCloneService.CloneRequest>{req});
        Test.stopTest();
    }
}