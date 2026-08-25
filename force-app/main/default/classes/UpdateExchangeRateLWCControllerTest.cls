@isTest
private class UpdateExchangeRateLWCControllerTest {
    
    @isTest
    static void testGetAvailableFinancialYears() {
        Test.startTest();
        List<Map<String, String>> financialYears = UpdateExchangeRateLWCController.getAvailableFinancialYears();
        Test.stopTest();
        
        System.assertNotEquals(0, financialYears.size(), 'Financial years list should not be empty');
        System.assert(financialYears[0].containsKey('label'), 'Each entry should contain a label');
        System.assert(financialYears[0].containsKey('value'), 'Each entry should contain a value');
    }
    
    @isTest
    static void testGetFinancialYearDates() {
        String financialYear = '2023-24';
        
        Test.startTest();
        Map<String, Date> dates = UpdateExchangeRateLWCController.getFinancialYearDates(financialYear);
        Test.stopTest();
        
        System.assertEquals(Date.valueOf('2023-04-01'), dates.get('startDate'), 'Start date should be April 1st');
        System.assertEquals(Date.valueOf('2024-03-31'), dates.get('endDate'), 'End date should be March 31st');
    }
    
    @isTest
    static void testGetCurrenciesByFinancialYear() {
        String financialYear = '2023-24';
        
        List<DatedConversionRate> mockRates = new List<DatedConversionRate>();
        Test.setFixedSearchResults(new List<Id>());
        
        Test.startTest();
        List<String> currencies = UpdateExchangeRateLWCController.getCurrenciesByFinancialYear(financialYear);
        Test.stopTest();
        
        System.assertNotEquals(null, currencies, 'Currencies list should not be null');
    }
    
    @isTest
    static void testRunBatchSuccess() {
        String financialYear = '2023-24';
        List<String> currencyIsoCodes = new List<String>{'USD', 'EUR'};
            List<Id> budgetIdList = new List<Id>(); 
        
        Test.startTest();
        try {
            UpdateExchangeRateLWCController.runBatch(financialYear, currencyIsoCodes, budgetIdList);
            System.assert(true, 'Batch should execute successfully');
        } catch (Exception e) {
            System.assert(false, 'No exception should be thrown: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
   }