@isTest
private  class MatrixExcelExportControllerTest {
@isTest
    static void test_Controller_WithValidJson() {
        // Step 1: Prepare mock JSON input
        List<MatrixExcelExportController.MonthlyData> testData = new List<MatrixExcelExportController.MonthlyData>{
            new MatrixExcelExportController.MonthlyData()
        };
        testData[0].pmg = 'Test PMG';
        testData[0].monthlyReceived = 123.45;
        testData[0].budgetedOrder = 234.56;
        testData[0].ytdActual = 345.67;
        testData[0].ytdBudget = 456.78;
        testData[0].forecastMIS = 567.89;
        testData[0].forecastBudget = 678.90;

        String jsonData = JSON.serialize(testData);
        String encodedJson = EncodingUtil.urlEncode(jsonData, 'UTF-8');

        // Step 2: Set page parameters
        Test.setCurrentPage(Page.MonthlyMatrixExport); // replace with your actual VF page name
        ApexPages.currentPage().getParameters().put('fy', '2025');
        ApexPages.currentPage().getParameters().put('orderType', 'Retail');
        ApexPages.currentPage().getParameters().put('month', 'June');
        ApexPages.currentPage().getParameters().put('level1', 'Level A');
        ApexPages.currentPage().getParameters().put('level2', 'Level B');
        ApexPages.currentPage().getParameters().put('currency', 'USD');
        ApexPages.currentPage().getParameters().put('jsonData', encodedJson);

        // Step 3: Instantiate controller
        MatrixExcelExportController controller = new MatrixExcelExportController();

        // Step 4: Assertions
        System.assertEquals('2025', controller.fy);
        System.assertEquals('Retail', controller.orderType);
        System.assertEquals('June', controller.month);
        System.assertEquals('Level A', controller.level1);
        System.assertEquals('Level B', controller.level2);
        System.assertEquals('USD', controller.userCurrency);
        System.assertEquals(1, controller.visibleMatrix.size());
        System.assertEquals('Test PMG', controller.visibleMatrix[0].pmg);
    }

    @isTest
    static void test_Controller_WithInvalidJson() {
        // Set invalid JSON input
        Test.setCurrentPage(Page.MonthlyMatrixExport);
        ApexPages.currentPage().getParameters().put('jsonData', 'invalid-json-here');

        MatrixExcelExportController controller = new MatrixExcelExportController();

        System.assertNotEquals(null, controller.visibleMatrix);
        System.assertEquals(0, controller.visibleMatrix.size());
    }

    @isTest
    static void test_Controller_WithoutJson() {
        Test.setCurrentPage(Page.MonthlyMatrixExport);
        // No jsonData parameter set

        MatrixExcelExportController controller = new MatrixExcelExportController();

        System.assertNotEquals(null, controller.visibleMatrix);
        System.assertEquals(0, controller.visibleMatrix.size());
    }
    @isTest
static void test_Controller_WithMalformedJson_ShouldTriggerCatch() {
    // Step 1: Set malformed JSON
    String badJson = EncodingUtil.urlEncode('{"pmg":"Test PMG",', 'UTF-8');

    // Step 2: Set Page
    Test.setCurrentPage(Page.MonthlyMatrixExport);
    ApexPages.currentPage().getParameters().put('jsonData', badJson);

    // Step 3: Call controller
    MatrixExcelExportController controller = new MatrixExcelExportController();

    // Step 4: Assert fallback works
    System.assertNotEquals(null, controller.visibleMatrix, 'Fallback list should not be null');
    System.assertEquals(0, controller.visibleMatrix.size(), 'Fallback list should be empty');
}

}