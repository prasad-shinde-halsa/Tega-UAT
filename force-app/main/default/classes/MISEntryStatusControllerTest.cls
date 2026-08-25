@isTest
private class MISEntryStatusControllerTest {

    @testSetup
    static void setupData() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        // Create test branch
        Branch__c branch = new Branch__c(
            Name = 'Test Branch',
            Branch_Code__c = 'TB001',
            CIF_Factor__c = 1.04,
            CurrencyIsoCode = 'USD',
            Is_WOS__c = true,
            Branch_Head__c = currentUser.Id
        );
        insert branch;
        
        // Create test company
        Company__c company = new Company__c(
            Name = 'Test Company',
            Company_Code__c = 'LS06',
            CurrencyIsoCode = 'USD'
        );
        insert company;

        // Create junction record between company and branch
        Sales_Org_Branch_Relationship__c rel = new Sales_Org_Branch_Relationship__c(
            Company__c = company.Id,
            Branch__c = branch.Id
        );
        insert rel;

        // Create test pmg
        PMG_Master__c pmgMaster = new PMG_Master__c(
            Name = 'Test PMG Master'
        );
        insert pmgMaster;
        
        // Create test customer
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
        
        // Create Budget Line Item
        DC_Budget_Line_Items__c lineItem = new DC_Budget_Line_Items__c(
            PMG_Master__c = pmgMaster.Id,
            Customer__c = customer.Id,
            Budget__c = budget.Id,
            Order_Type__c = 'E-Spares',
            Active_Status__c = true,
            Jul_Order__c = 5000,
            Jul_Order_Actual__c = 2000
        );
        insert lineItem;
        
        // Create MIS record
        MIS_Budget__c mis = new MIS_Budget__c(
            Budget_Line_Items__c = lineItem.Id,
            CurrencyIsoCode = 'USD',
            Expected_Order_Value_Jul__c = 1000,
            Order_Expected_Month_Jul__c = 'Jul, 2025'
        );
        insert mis;
    }

    @isTest
    static void testGetAllCompany() {
        Test.startTest();
        List<Company__c> companies = MISEntryStatusController.getAllCompany();
        Test.stopTest();

        System.assert(!companies.isEmpty(), 'Company list should not be empty');
        System.assertEquals('Test Company', companies[0].Name, 'Company name should match');
    }

    @isTest
    static void testGetBranchesForCompany() {
        Company__c company = [SELECT Id FROM Company__c LIMIT 1];
        
        Test.startTest();
        List<Sales_Org_Branch_Relationship__c> branches = MISEntryStatusController.getBranchesForCompany(company.Id);
        List<Sales_Org_Branch_Relationship__c> emptyList = MISEntryStatusController.getBranchesForCompany(null);
        Test.stopTest();

        System.assert(!branches.isEmpty(), 'Branches should not be empty for valid company');
        System.assertEquals(true, emptyList.isEmpty(), 'Empty list expected when companyId is null');
    }

    @isTest
    static void testGetDCBudgetAndChildItems() {
        Test.startTest();
        List<DC_Budget__c> budgets = MISEntryStatusController.getDCBudgetAndChildItems('2025-26');
        Test.stopTest();

        System.assert(!budgets.isEmpty(), 'Budgets should not be empty');
        System.assertEquals('4th Level Approved', budgets[0].Status__c, 'Budget status should match');
        System.assertEquals('2025-26', budgets[0].Financial_Year__c, 'Budget year should match');
        System.assert(!budgets[0].Budget_Line_Items__r.isEmpty(), 'Budget line items should not be empty');
        System.assert(!budgets[0].Budget_Line_Items__r[0].MIS_Budgets__r.isEmpty(), 'MIS budgets should not be empty');
    }
}