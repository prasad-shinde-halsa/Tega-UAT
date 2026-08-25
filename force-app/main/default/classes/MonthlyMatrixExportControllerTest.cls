@isTest
private class MonthlyMatrixExportControllerTest {
    
    @isTest
    static void testConstructorWithAllParameters() {
        // Setup test data
        List<Map<String, String>> testData = new List<Map<String, String>>{
            new Map<String, String>{
                'pmg' => 'Product Group 1',
                'budgetedOrder' => '1000000',
                'monthlyReceived' => '850000',
                'achievement' => '85.00',
                'ytdBudget' => '5000000',
                'ytdActual' => '4200000',
                'ytdAchievement' => '84.00',
                'forecastBudget' => '12000000',
                'forecastMIS' => '11500000',
                'fullYearForecast' => '11800000'
            }
        };
        
        Map<String, String> totalsData = new Map<String, String>{
            'budgetedOrder' => '1000000',
            'monthlyReceived' => '850000',
            'ytdBudget' => '5000000',
            'ytdActual' => '4200000',
            'forecastBudget' => '12000000',
            'forecastMIS' => '11500000',
            'fullYearForecast' => '11800000'
        };
        
        String jsonData = EncodingUtil.urlEncode(JSON.serialize(testData), 'UTF-8');
        String totalsJson = EncodingUtil.urlEncode(JSON.serialize(totalsData), 'UTF-8');
        
        // Setup page parameters
        PageReference pageRef = Page.MonthlyMatrixExport; // Replace with actual VF page name
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('fy', 'FY2024');
        ApexPages.currentPage().getParameters().put('orderType', 'New');
        ApexPages.currentPage().getParameters().put('month', 'January');
        ApexPages.currentPage().getParameters().put('quarter', 'Q4');
        ApexPages.currentPage().getParameters().put('level1', 'Region A');
        ApexPages.currentPage().getParameters().put('level2', 'SubRegion 1');
        ApexPages.currentPage().getParameters().put('currency', 'EUR');
        ApexPages.currentPage().getParameters().put('jsonData', jsonData);
        ApexPages.currentPage().getParameters().put('totalsData', totalsJson);
        
        Test.startTest();
        MonthlyMatrixExportController controller = new MonthlyMatrixExportController();
        Test.stopTest();
        
        // Assertions
        System.assertEquals('FY2024', controller.fy, 'FY should match');
        System.assertEquals('New', controller.orderType, 'Order type should match');
        System.assertEquals('January', controller.monthName, 'Month should match');
        System.assertEquals('Q4', controller.quarter, 'Quarter should match');
        System.assertEquals('Region A', controller.level1, 'Level1 should match');
        System.assertEquals('SubRegion 1', controller.level2, 'Level2 should match');
        System.assertEquals('EUR', controller.currencyCode, 'Currency should match');
        System.assertEquals('Q4 (January - March)', controller.periodLabel, 'Period label should match Q4');
        System.assertNotEquals(null, controller.exportData, 'Export data should not be null');
        System.assertEquals(1, controller.exportData.size(), 'Should have 1 export row');
        System.assertNotEquals(null, controller.totals, 'Totals should not be null');
        System.assert(controller.exportFileName.contains('MIS_Report_FY2024_Q4'), 'Filename should contain correct parts');
    }
    
    @isTest
    static void testConstructorWithDefaultValues() {
        // Setup page with minimal parameters
        PageReference pageRef = Page.MonthlyMatrixExport;
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        MonthlyMatrixExportController controller = new MonthlyMatrixExportController();
        Test.stopTest();
        
        // Assertions for default values
        System.assertEquals('All', controller.fy, 'FY should default to All');
        System.assertEquals('All', controller.orderType, 'Order type should default to All');
        System.assertEquals('All', controller.monthName, 'Month should default to All');
        System.assertEquals('All', controller.quarter, 'Quarter should default to All');
        System.assertEquals('All', controller.level1, 'Level1 should default to All');
        System.assertEquals('All', controller.level2, 'Level2 should default to All');
        System.assertEquals('USD', controller.currencyCode, 'Currency should default to USD');
        System.assertEquals('APRIL', controller.periodLabel, 'Period label should default to APRIL');
    }
    
    @isTest
    static void testQuarterLabels() {
        PageReference pageRef = Page.MonthlyMatrixExport;
        Test.setCurrentPage(pageRef);
        
        // Test Q1
        ApexPages.currentPage().getParameters().put('quarter', 'Q1');
        MonthlyMatrixExportController controllerQ1 = new MonthlyMatrixExportController();
        System.assertEquals('Q1 (April - June)', controllerQ1.periodLabel, 'Q1 label should be correct');
        
        // Test Q2
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('quarter', 'Q2');
        MonthlyMatrixExportController controllerQ2 = new MonthlyMatrixExportController();
        System.assertEquals('Q2 (July - September)', controllerQ2.periodLabel, 'Q2 label should be correct');
        
        // Test Q3
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('quarter', 'Q3');
        MonthlyMatrixExportController controllerQ3 = new MonthlyMatrixExportController();
        System.assertEquals('Q3 (October - December)', controllerQ3.periodLabel, 'Q3 label should be correct');
    }
    
    @isTest
    static void testMonthPeriodLabel() {
        PageReference pageRef = Page.MonthlyMatrixExport;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('month', 'December');
        
        Test.startTest();
        MonthlyMatrixExportController controller = new MonthlyMatrixExportController();
        Test.stopTest();
        
        System.assertEquals('December', controller.periodLabel, 'Period label should be month name');
    }
    
    @isTest
    static void testExportDataParsing() {
        List<Map<String, String>> testData = new List<Map<String, String>>{
            new Map<String, String>{
                'pmg' => 'PMG A',
                'budgetedOrder' => '500000',
                'monthlyReceived' => '450000',
                'achievement' => '90.00',
                'ytdBudget' => '2500000',
                'ytdActual' => '2300000',
                'ytdAchievement' => '92.00',
                'forecastBudget' => '6000000',
                'forecastMIS' => '5800000',
                'fullYearForecast' => '5900000'
            },
            new Map<String, String>{
                'pmg' => 'PMG B',
                'budgetedOrder' => '750000',
                'monthlyReceived' => '700000',
                'achievement' => '93.33',
                'ytdBudget' => '3750000',
                'ytdActual' => '3500000',
                'ytdAchievement' => '93.33',
                'forecastBudget' => '9000000',
                'forecastMIS' => '8700000',
                'fullYearForecast' => '8850000'
            }
        };
        
        String jsonData = EncodingUtil.urlEncode(JSON.serialize(testData), 'UTF-8');
        
        PageReference pageRef = Page.MonthlyMatrixExport;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('jsonData', jsonData);
        
        Test.startTest();
        MonthlyMatrixExportController controller = new MonthlyMatrixExportController();
        Test.stopTest();
        
        System.assertEquals(2, controller.exportData.size(), 'Should have 2 export rows');
        System.assertEquals('PMG A', controller.exportData[0].pmg, 'First PMG should match');
        System.assertEquals('500000', controller.exportData[0].budgetedOrder, 'First budgeted order should match');
        System.assertEquals('PMG B', controller.exportData[1].pmg, 'Second PMG should match');
        System.assertEquals('750000', controller.exportData[1].budgetedOrder, 'Second budgeted order should match');
    }
    
    /*
    @isTest
    static void testTotalsParsing() {
        Map<String, String> totalsData = new Map<String, String>{
            'budgetedOrder' => '2500000',
            'monthlyReceived' => '2300000',
            'ytdBudget' => '12500000',
            'ytdActual' => '11800000',
            'forecastBudget' => '30000000',
            'forecastMIS' => '29500000',
            'fullYearForecast' => '29750000'
        };
        
        String totalsJson = EncodingUtil.urlEncode(JSON.serialize(totalsData), 'UTF-8');
        
        PageReference pageRef = Page.MonthlyMatrixExport;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('totalsData', totalsJson);
        
        Test.startTest();
        MonthlyMatrixExportController controller = new MonthlyMatrixExportController();
        Test.stopTest();
        
        System.assertNotEquals(null, controller.totals, 'Totals should not be null');
        System.assertEquals('2500000', controller.totals.budgetedOrder, 'Total budgeted order should match');
        System.assertEquals('2300000', controller.totals.monthlyReceived, 'Total monthly received should match');
        System.assertEquals('12500000', controller.totals.ytdBudget, 'Total YTD budget should match');
        System.assertEquals('11800000', controller.totals.ytdActual, 'Total YTD actual should match');
    }   */
    
    @isTest
    static void testEmptyJsonData() {
        PageReference pageRef = Page.MonthlyMatrixExport;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('jsonData', '');
        
        Test.startTest();
        MonthlyMatrixExportController controller = new MonthlyMatrixExportController();
        Test.stopTest();
        
        System.assertNotEquals(null, controller.exportData, 'Export data should be initialized');
        System.assertEquals(0, controller.exportData.size(), 'Export data should be empty');
    }
    
    @isTest
    static void testNullJsonData() {
        PageReference pageRef = Page.MonthlyMatrixExport;
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        MonthlyMatrixExportController controller = new MonthlyMatrixExportController();
        Test.stopTest();
        
        System.assertNotEquals(null, controller.exportData, 'Export data should be initialized');
        System.assertEquals(0, controller.exportData.size(), 'Export data should be empty');
    }
    
    @isTest
    static void testInvalidJsonData() {
        PageReference pageRef = Page.MonthlyMatrixExport;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('jsonData', 'invalid-json-data');
        
        Test.startTest();
        MonthlyMatrixExportController controller = new MonthlyMatrixExportController();
        Test.stopTest();
        
        // Should handle gracefully without throwing exception
        System.assertNotEquals(null, controller.exportData, 'Export data should be initialized');
    }
    
    @isTest
    static void testExportFileName() {
        PageReference pageRef = Page.MonthlyMatrixExport;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('fy', 'FY2024');
        ApexPages.currentPage().getParameters().put('month', 'March');
        
        Test.startTest();
        MonthlyMatrixExportController controller = new MonthlyMatrixExportController();
        Test.stopTest();
        
        System.assert(controller.exportFileName.startsWith('MIS_Report_FY2024_March_'), 
                     'Filename should start with correct prefix');
        System.assert(controller.exportFileName.length() > 'MIS_Report_FY2024_March_'.length(), 
                     'Filename should include timestamp');
    }
    
    @isTest
    static void testExportFileNameWithQuarter() {
        PageReference pageRef = Page.MonthlyMatrixExport;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('fy', 'FY2025');
        ApexPages.currentPage().getParameters().put('quarter', 'Q2');
        ApexPages.currentPage().getParameters().put('month', 'August');
        
        Test.startTest();
        MonthlyMatrixExportController controller = new MonthlyMatrixExportController();
        Test.stopTest();
        
        // When quarter is present, it should take precedence over month
        System.assert(controller.exportFileName.contains('Q2'), 
                     'Filename should contain quarter when specified');
        System.assert(!controller.exportFileName.contains('August'), 
                     'Filename should not contain month when quarter is specified');
    }
}