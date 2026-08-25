@isTest
private class SelectBudgetMonthForFlowController_Test {

    @TestSetup
    static void setupTestData() {
        PMG_Master__c pmgMaster = new PMG_Master__c(
            Name = 'Test PMG Master'
        );
        insert pmgMaster;
        
        Account customer = new Account(
            Name = 'Test Customer'
        );
        insert customer;
        
        DC_Budget__c dcBudget = new DC_Budget__c(
            Name = 'Test Budget',
            Status__c = 'Draft',
            Financial_Year__c = '2025-26'
        );
        insert dcBudget;
        
        List<DC_Budget_Line_Items__c> budgetLineItems = new List<DC_Budget_Line_Items__c>();
        
        DC_Budget_Line_Items__c budgetLineItem1 = new DC_Budget_Line_Items__c(
            PMG_Master__c = pmgMaster.Id,
            Customer__c = customer.Id,
            Budget__c = dcBudget.Id,
            Order_Type__c = 'E-Spares',
            Active_Status__c = true,
            Apr_Order__c = 100,
            May_Order__c = 200,
            Order_Expected_Stage__c = 'Enquiry',
            Order_Expected_Month__c = 'April'
        );
        budgetLineItems.add(budgetLineItem1);

        DC_Budget_Line_Items__c budgetLineItem2 = new DC_Budget_Line_Items__c(
            PMG_Master__c = pmgMaster.Id,
            Customer__c = customer.Id,
            Budget__c = dcBudget.Id,
            Order_Type__c = 'C-Conversion',
            Active_Status__c = true,
            Apr_Order__c = 300,
            May_Order__c = 400
        );
        budgetLineItems.add(budgetLineItem2);
        
        insert budgetLineItems;
    }
    @isTest
    static void testGetDCBudgetAndChildItems() {
        
        DC_Budget_Line_Items__c budgetLineItem = [SELECT Id FROM DC_Budget_Line_Items__c WHERE Order_Type__c = 'E-Spares' LIMIT 1];
        Test.startTest();
        // Passing blank Id should return null
        DC_Budget_Line_Items__c result = SelectBudgetMonthForFlowController.getDCBudget(budgetLineItem.Id);
        Test.stopTest();

       
    }
    @isTest
    static void testGetDCBudgetAndChildItems_NoId() {
        Test.startTest();
        // Passing blank Id should return null
        DC_Budget_Line_Items__c result = SelectBudgetMonthForFlowController.getDCBudget('');
        Test.stopTest();

        System.assertEquals(null, result, 'Method should return null for blank Id');
    }
}