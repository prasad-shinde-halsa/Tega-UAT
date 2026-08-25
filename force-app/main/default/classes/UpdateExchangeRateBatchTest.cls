@isTest
private class UpdateExchangeRateBatchTest {
    
    @TestSetup
    static void setupTestData() {
        Account testCustomer = new Account(Name = 'Test Customer');
        insert testCustomer;
        
        PMG_Master__c testPMGMaster = new PMG_Master__c(Name = 'Test PMG Master');
        insert testPMGMaster;
        
        Date startDate = Date.newInstance(2023, 4, 1);
        Date endDate = Date.newInstance(2024, 3, 31);
        
        DatedConversionRate[] rates = new List<DatedConversionRate>{
            new DatedConversionRate(
                IsoCode = 'USD',
                ConversionRate = 82.5,  
                StartDate = startDate
            ),
            new DatedConversionRate(
                IsoCode = 'EUR',
                ConversionRate = 90.2, 
                StartDate = startDate
            )
        };
        
        List<DC_Budget__c> budgets = new List<DC_Budget__c>{
            new DC_Budget__c(
                Financial_Year__c = '2023-24',
                CurrencyIsoCode = 'USD',
                Exchange_Rate_Updated__c = false
            ),
            new DC_Budget__c(
                Financial_Year__c = '2023-24',
                CurrencyIsoCode = 'EUR',
                Exchange_Rate_Updated__c = false
            )
        };
        insert budgets;
        
        // Create test budget line items
        List<DC_Budget_Line_Items__c> lineItems = new List<DC_Budget_Line_Items__c>{
            new DC_Budget_Line_Items__c(
                Budget__c = budgets[0].Id,
                Customer__c = testCustomer.Id,
                PMG_Master__c = testPMGMaster.Id,
                Apr_Order__c = 100, May_Order__c = 200, Jun_Order__c = 300,
                Apr_Sales__c = 90, May_Sales__c = 180, Jun_Sales__c = 270,
                Jul_Order__c = 400, Aug_Order__c = 500, Sep_Order__c = 600,
                Jul_Sales__c = 360, Aug_Sales__c = 450, Sep_Sales__c = 540
            ),
            new DC_Budget_Line_Items__c(
                Budget__c = budgets[1].Id,
                Customer__c = testCustomer.Id,
                PMG_Master__c = testPMGMaster.Id,
                Apr_Order__c = 150, May_Order__c = 250, Jun_Order__c = 350,
                Apr_Sales__c = 135, May_Sales__c = 225, Jun_Sales__c = 315,
                Jul_Order__c = 450, Aug_Order__c = 550, Sep_Order__c = 650,
                Jul_Sales__c = 405, Aug_Sales__c = 495, Sep_Sales__c = 585
            )
        };
        insert lineItems;
    }
    
    @isTest
static void testBatchWithValidFinancialYear() {
    String financialYear = '2023-24';
    List<String> currencyIsoCodes = new List<String>{'USD', 'EUR'};
    List<Id> budgetIdList = new List<Id>(); // Add this parameter
    
    Test.startTest();
    
    List<DC_Budget__c> initialBudgets = [
        SELECT Id, CurrencyIsoCode, Total_Order__c, Total_Sales__c, 
               Total_Order_In_INR__c, Total_Sales_In_INR__c, Exchange_Rate_Updated__c
        FROM DC_Budget__c
        WHERE Financial_Year__c = :financialYear
    ];
    
    UpdateExchangeRateBatch batchJob = new UpdateExchangeRateBatch(financialYear, currencyIsoCodes, budgetIdList);
    Database.executeBatch(batchJob);
    
    Test.stopTest();
    
    List<DC_Budget__c> updatedBudgets = [
        SELECT Id, CurrencyIsoCode, Total_Order__c, Total_Sales__c, 
               Total_Order_In_INR__c, Total_Sales_In_INR__c, Exchange_Rate_Updated__c
        FROM DC_Budget__c
        WHERE Financial_Year__c = :financialYear
    ];
    
    for (DC_Budget__c budget : updatedBudgets) {
        System.assertNotEquals(null, budget.Total_Order_In_INR__c, 'Total Order in INR should be calculated');
        System.assertNotEquals(null, budget.Total_Sales_In_INR__c, 'Total Sales in INR should be calculated');
       // System.assertEquals(true, budget.Exchange_Rate_Updated__c, 'Exchange Rate Updated should be marked as true');
        
        if (budget.CurrencyIsoCode == 'USD') {
            if (budget.Total_Order__c != null) {
                Decimal expectedOrderInINR = (budget.Total_Order__c * 1000) / 82.5;
                //System.assertEquals(expectedOrderInINR, budget.Total_Order_In_INR__c, 'USD Order conversion is incorrect');
            }
            if (budget.Total_Sales__c != null) {
                Decimal expectedSalesInINR = (budget.Total_Sales__c * 1000) / 82.5;
                //System.assertEquals(expectedSalesInINR, budget.Total_Sales_In_INR__c, 'USD Sales conversion is incorrect');
            }
        } else if (budget.CurrencyIsoCode == 'EUR') {
            if (budget.Total_Order__c != null) {
                Decimal expectedOrderInINR = (budget.Total_Order__c * 1000) / 90.2;
                //System.assertEquals(expectedOrderInINR, budget.Total_Order_In_INR__c, 'EUR Order conversion is incorrect');
            }
            if (budget.Total_Sales__c != null) {
                Decimal expectedSalesInINR = (budget.Total_Sales__c * 1000) / 90.2;
               // System.assertEquals(expectedSalesInINR, budget.Total_Sales_In_INR__c, 'EUR Sales conversion is incorrect');
            }
        }
    }
}
    
}