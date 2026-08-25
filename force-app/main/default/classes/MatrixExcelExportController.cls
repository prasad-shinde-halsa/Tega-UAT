/**
 * @name        MatrixExcelExportController
 * @description This Apex controller is used by the Visualforce page `MonthlyMatrixExport` 
 *              to export a monthly PMG matrix as an Excel file.
 *              It extracts parameters passed from the LWC component (including fiscal year, month, filters, 
 *              user currency, and matrix data in JSON format), deserializes the matrix data,
 *              and prepares it for display in an Excel-formatted Visualforce page.
 * @author      Reetabrata Mishra
 * @createdDate 2025-07-02
 * @version     1.0
 */

public class MatrixExcelExportController {
    public String fy { get; set; }
    public String orderType { get; set; }
    public String month { get; set; }
    public String level1 { get; set; }
    public String level2 { get; set; }
    public String userCurrency { get; set; }
    public List<MonthlyData> visibleMatrix { get; set; }
    
    /**
     * @description Constructor that initializes class properties from URL parameters.
     *              If JSON matrix data is passed, it attempts to decode and deserialize it into the matrix list.
     *              If decoding or deserialization fails, an empty matrix is used.
     */
    public MatrixExcelExportController() {
        fy = ApexPages.currentPage().getParameters().get('fy');
        orderType = ApexPages.currentPage().getParameters().get('orderType');
        month = ApexPages.currentPage().getParameters().get('month');
        level1 = ApexPages.currentPage().getParameters().get('level1');
        level2 = ApexPages.currentPage().getParameters().get('level2');
        userCurrency = ApexPages.currentPage().getParameters().get('currency');
        
        // Decode and parse matrix data from URL param
        String rawJson = ApexPages.currentPage().getParameters().get('jsonData');
        if (String.isNotBlank(rawJson)) {
            try {
                String decodedJson = EncodingUtil.urlDecode(rawJson, 'UTF-8');
                visibleMatrix = (List<MonthlyData>) JSON.deserialize(decodedJson, List<MonthlyData>.class);
            } catch (Exception e) {
                visibleMatrix = new List<MonthlyData>();
            }
        } else {
            visibleMatrix = new List<MonthlyData>();
        }
    }
    /**
     * @description Inner class representing a single PMG row in the matrix export.
     *              Holds monthly, YTD, and forecast data for a PMG.
     */
    public class MonthlyData {
        public String pmg { get; set; }
        public Decimal monthlyReceived { get; set; }
        public Decimal budgetedOrder { get; set; }
        public Decimal ytdActual { get; set; }
        public Decimal ytdBudget { get; set; }
        public Decimal forecastMIS { get; set; }
        public Decimal forecastBudget { get; set; }
    }
}