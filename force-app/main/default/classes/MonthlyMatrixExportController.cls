public class MonthlyMatrixExportController {
    public String fy { get; set; }
    public String orderType { get; set; }
    public String monthName { get; set; }
    public String quarter { get; set; }
    public String level1 { get; set; }
    public String level2 { get; set; }
    public String currencyCode { get; set; }
    public String periodLabel { get; set; }
    public List<ExportRow> exportData { get; set; }
    public TotalRow totals { get; set; }
    public String exportFileName { get; set; }
    
    public MonthlyMatrixExportController() {
        // Get parameters from URL
        fy = ApexPages.currentPage().getParameters().get('fy');
        orderType = ApexPages.currentPage().getParameters().get('orderType');
        monthName = ApexPages.currentPage().getParameters().get('month');
        quarter = ApexPages.currentPage().getParameters().get('quarter');
        level1 = ApexPages.currentPage().getParameters().get('level1');
        level2 = ApexPages.currentPage().getParameters().get('level2');
        currencyCode = ApexPages.currentPage().getParameters().get('currency');
        
        // Set default values
        if (String.isBlank(fy)) fy = 'All';
        if (String.isBlank(orderType)) orderType = 'All';
        if (String.isBlank(monthName)) monthName = 'All';
        if (String.isBlank(quarter)) quarter = 'All';
        if (String.isBlank(level1)) level1 = 'All';
        if (String.isBlank(level2)) level2 = 'All';
        if (String.isBlank(currencyCode)) currencyCode = 'USD';
        
        // Set period label
        if (String.isNotBlank(quarter) && quarter != 'All') {
            Map<String, String> quarterLabels = new Map<String, String>{
                'Q1' => 'Q1 (April - June)',
                'Q2' => 'Q2 (July - September)',
                'Q3' => 'Q3 (October - December)',
                'Q4' => 'Q4 (January - March)'
            };
            periodLabel = quarterLabels.get(quarter);
        } else {
            periodLabel = monthName != 'All' ? monthName : 'APRIL';
        }
        
        // Generate filename with proper naming
        String timestamp = System.now().format('yyyyMMdd_HHmmss');
        String periodPart = String.isNotBlank(quarter) && quarter != 'All' ? quarter : monthName;
        exportFileName = 'MIS_Report_' + fy + '_' + periodPart + '_' + timestamp;
        
        // Parse JSON data
        String jsonData = ApexPages.currentPage().getParameters().get('jsonData');
        String totalsJson = ApexPages.currentPage().getParameters().get('totalsData');
        parseExportData(jsonData, totalsJson);
    }
    
    private void parseExportData(String jsonData, String totalsJson) {
        exportData = new List<ExportRow>();
        totals = new TotalRow();
        
        if (String.isBlank(jsonData)) {
            return;
        }
        
        try {
            String decodedData = EncodingUtil.urlDecode(jsonData, 'UTF-8');
            List<Object> dataList = (List<Object>) JSON.deserializeUntyped(decodedData);
            
            for (Object obj : dataList) {
                Map<String, Object> rowMap = (Map<String, Object>) obj;
                
                ExportRow row = new ExportRow();
                row.pmg = (String) rowMap.get('pmg');
                row.budgetedOrder = (String) rowMap.get('budgetedOrder');
                row.monthlyReceived = (String) rowMap.get('monthlyReceived');
                row.achievement = (String) rowMap.get('achievement');
                row.ytdBudget = (String) rowMap.get('ytdBudget');
                row.ytdActual = (String) rowMap.get('ytdActual');
                row.ytdAchievement = (String) rowMap.get('ytdAchievement');
                row.forecastBudget = (String) rowMap.get('forecastBudget');
                row.forecastMIS = (String) rowMap.get('forecastMIS');
                row.fullYearForecast = (String) rowMap.get('fullYearForecast');
                
                exportData.add(row);
            }
            
            // Parse totals
            if (String.isNotBlank(totalsJson)) {
                String decodedTotals = EncodingUtil.urlDecode(totalsJson, 'UTF-8');
                Map<String, Object> totalsMap = (Map<String, Object>) JSON.deserializeUntyped(decodedTotals);
                
                totals.budgetedOrder = (String) totalsMap.get('budgetedOrder');
                totals.monthlyReceived = (String) totalsMap.get('monthlyReceived');
                totals.achievement = (String) totalsMap.get('achievement'); 
                totals.ytdBudget = (String) totalsMap.get('ytdBudget');
                totals.ytdActual = (String) totalsMap.get('ytdActual');
                totals.ytdAchievement = (String) totalsMap.get('ytdAchievement'); 
                totals.forecastBudget = (String) totalsMap.get('forecastBudget');
                totals.forecastMIS = (String) totalsMap.get('forecastMIS');
                totals.fullYearForecast = (String) totalsMap.get('fullYearForecast');
            }
            
        } catch (Exception e) {
            System.debug('Error parsing export data: ' + e.getMessage());
        }
    }
    
    public class ExportRow {
        public String pmg { get; set; }
        public String budgetedOrder { get; set; }
        public String monthlyReceived { get; set; }
        public String achievement { get; set; }
        public String ytdBudget { get; set; }
        public String ytdActual { get; set; }
        public String ytdAchievement { get; set; }
        public String forecastBudget { get; set; }
        public String forecastMIS { get; set; }
        public String fullYearForecast { get; set; }
    }
    
    public class TotalRow {
        public String budgetedOrder { get; set; }
        public String monthlyReceived { get; set; }
        public String achievement { get; set; }   
        public String ytdBudget { get; set; }
        public String ytdActual { get; set; }
        public String ytdAchievement { get; set; }  
        public String forecastBudget { get; set; }
        public String forecastMIS { get; set; }
        public String fullYearForecast { get; set; }
    }
}