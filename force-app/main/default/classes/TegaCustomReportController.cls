/**
* @name        TegaCustomReportController
* @description This Apex controller is used to retrieve budget and exchange rate data 
*              for the custom Tega Budget YTD and Forecast LWC report.
*              It fetches DC_Budget__c records with related Budget Line Items and MIS Budgets,
*              and provides the current exchange rates from DatedConversionRate for currency conversion.
* 
* @author      Reetabrata Mishra
* @date        2025-07-02
* @version     1.0
*/

public with sharing class TegaCustomReportController {
    //Get All Budget 
    @AuraEnabled
    public static List<DC_Budget__c> getDCBudgetAndChildItems(String selectedFY , List<String> budgetIds) {
         Id rtId = Schema.SObjectType.DC_Budget__c.getRecordTypeInfosByDeveloperName().get('Development_Budget').getRecordTypeId();
        try {
            List<String> fiscalYears = new List<String>();
            List<DC_Budget__c> DCBudgetList;
            fiscalYears.add(selectedFY);
            // Add next FY
            if (selectedFY != null && selectedFY.contains('-')) {
                List<String> parts = selectedFY.split('-');
                Integer nextStart = Integer.valueOf(parts[0]) + 1;
                Integer nextEnd = nextStart + 1;
                fiscalYears.add(nextStart + '-' + nextEnd);
            }
            system.debug('Budgetids From LWC'+budgetIds);
            
            if (budgetIds != null && !budgetIds.isEmpty()) {
                DCBudgetList = [
                    SELECT Id, Name,RecordTypeId, Status__c, Financial_Year__c,CurrencyIsoCode,Branch__r.Branch_Code__c ,
                    (
                        SELECT Id, Name, Active_Status__c, Order_Type__c, PMG_Master__c, Budget_FN_Year__c, PMG_Name__c,CurrencyIsoCode,
                        
                        Apr_Order_Actual__c, Aug_Order_Actual__c, Dec_Order_Actual__c, Mar_Order_Actual__c,
                        Feb_Order_Actual__c, Jan_Order_Actual__c, Jul_Order_Actual__c, Jun_Order_Actual__c,
                        May_Order_Actual__c, Nov_Order_Actual__c, Oct_Order_Actual__c, Sep_Order_Actual__c,
                        
                        Apr_Order__c, May_Order__c, Jun_Order__c, Jul_Order__c, Aug_Order__c, Sep_Order__c,
                        Dec_Order__c, Jan_Order__c, Feb_Order__c, Mar_Order__c, Nov_Order__c, Oct_Order__c,
                        (
                            SELECT Id, Name,CurrencyIsoCode,
                            Expected_Order_Value_April__c, Expected_Order_Value_Aug__c, Expected_Order_Value_Dec__c,Expected_Order_Value_Sep__c,
                            Expected_Order_Value_Feb__c, Expected_Order_Value_Jan__c, Expected_Order_Value_Jul__c, Expected_Order_Value_June__c,
                            Expected_Order_Value_Mar__c, Expected_Order_Value_May__c, Expected_Order_Value_Nov__c, Expected_Order_Value_Oct__c,
                            
                            Order_Expected_Month_Apr__c,Order_Expected_Month_Aug__c,Order_Expected_Month_Dec__c,Order_Expected_Month_Feb__c,Order_Expected_Month_Jan__c,
                            Order_Expected_Month_Jul__c,Order_Expected_Month_Jun__c,Order_Expected_Month_Mar__c,Order_Expected_Month_May__c,Order_Expected_Month_Nov__c,
                            Order_Expected_Month_Oct__c,Order_Expected_Month_Sep__c
                            
                            FROM MIS_Budgets__r
                        )
                        FROM Budget_Line_Items__r
                        WHERE Active_Status__c = true
                    )
                    FROM DC_Budget__c
                    WHERE Status__c = '4th Level Approved'
                    AND Id IN :budgetIds
                    
                ];
            } else{
                DCBudgetList = [
                    SELECT Id, Name, RecordTypeId,Status__c, Financial_Year__c,CurrencyIsoCode,Branch__r.Branch_Code__c ,
                    (
                        SELECT Id, Name, Active_Status__c, Order_Type__c, PMG_Master__c, Budget_FN_Year__c, PMG_Name__c,CurrencyIsoCode,
                        
                        Apr_Order_Actual__c, Aug_Order_Actual__c, Dec_Order_Actual__c, Mar_Order_Actual__c,
                        Feb_Order_Actual__c, Jan_Order_Actual__c, Jul_Order_Actual__c, Jun_Order_Actual__c,
                        May_Order_Actual__c, Nov_Order_Actual__c, Oct_Order_Actual__c, Sep_Order_Actual__c,
                        
                        Apr_Order__c, May_Order__c, Jun_Order__c, Jul_Order__c, Aug_Order__c, Sep_Order__c,
                        Dec_Order__c, Jan_Order__c, Feb_Order__c, Mar_Order__c, Nov_Order__c, Oct_Order__c,
                        (
                            SELECT Id, Name,CurrencyIsoCode,
                            Expected_Order_Value_April__c, Expected_Order_Value_Aug__c, Expected_Order_Value_Dec__c,Expected_Order_Value_Sep__c,
                            Expected_Order_Value_Feb__c, Expected_Order_Value_Jan__c, Expected_Order_Value_Jul__c, Expected_Order_Value_June__c,
                            Expected_Order_Value_Mar__c, Expected_Order_Value_May__c, Expected_Order_Value_Nov__c, Expected_Order_Value_Oct__c,
                            
                            Order_Expected_Month_Apr__c,Order_Expected_Month_Aug__c,Order_Expected_Month_Dec__c,Order_Expected_Month_Feb__c,Order_Expected_Month_Jan__c,
                            Order_Expected_Month_Jul__c,Order_Expected_Month_Jun__c,Order_Expected_Month_Mar__c,Order_Expected_Month_May__c,Order_Expected_Month_Nov__c,
                            Order_Expected_Month_Oct__c,Order_Expected_Month_Sep__c
                            
                            FROM MIS_Budgets__r
                        )
                        FROM Budget_Line_Items__r
                        WHERE Active_Status__c = true
                    )
                    FROM DC_Budget__c
                    WHERE Status__c = '4th Level Approved'
                    AND Financial_Year__c IN :fiscalYears 
                ];
            }
            
            
            //AND Id IN  ('a1hS20000027YbhIAE','a1hS20000027XSjIAM')
            
            return DCBudgetList;
            
        } catch (Exception ex) {
            // Log error if needed: System.debug('Error: ' + ex.getMessage());
            throw new AuraHandledException('An unexpected error occurred while retrieving budget data: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<DatedConversionRate> getDatedConversionRate ( String SelectedFy) {
        
      List<DatedConversionRate> result = new List<DatedConversionRate>();

    List<String> parts = selectedFY.split('-');
    Integer startYear = Integer.valueOf(parts[0]);
    Integer endYear = startYear + 1;

    Date fyStart = Date.newInstance(startYear, 4, 1);
    Date fyEnd   = Date.newInstance(endYear, 3, 31);

    result = [
        SELECT Id, IsoCode, ConversionRate, StartDate, NextStartDate
        FROM DatedConversionRate
        WHERE StartDate < :fyEnd
        AND NextStartDate > :fyStart
        AND StartDate >= :Date.newInstance(1900, 1, 1)   // removes dummy rows
        ORDER BY StartDate DESC
    ];

    // fallback to latest if FY has no rates
    if (result.isEmpty()) {
        result = [
            SELECT Id, IsoCode, ConversionRate, StartDate, NextStartDate
            FROM DatedConversionRate
            WHERE StartDate >= :Date.newInstance(1900, 1, 1)
            ORDER BY StartDate DESC
        ];
    }

    return result;

     
    }
    // Add this method to TegaCustomReportController
@AuraEnabled
public static List<X4E_4D__c> getAllForm4E4DRecords(String selectedFY) {
    try {
        // Extract year from selectedFY (format: "2024-25")
        Integer startYear = Integer.valueOf(selectedFY.split('-')[0]);
        Date fiscalStart = Date.newInstance(startYear, 4, 1); // April 1
        Date fiscalEnd = Date.newInstance(startYear + 1, 3, 31); // March 31
        
        return [
            SELECT Id, Name, CreatedDate, Total_Value__c, CurrencyIsoCode, SF_Offer__c,SF_Offer__r.Branch__r.Branch_Code__c,
                   PMG__c, End_Customer_PO_Value__c, Status_SO__c, Order_Category__c,
                   DC_Budget_Line_Items__c, DC_Budget_Line_Items__r.Budget__c
            FROM X4E_4D__c 
            WHERE Status_SO__c = 'Closed'
            AND CreatedDate >= :fiscalStart
            AND CreatedDate <= :fiscalEnd
            ORDER BY CreatedDate
        ];
    } catch (Exception ex) {
        System.debug('⚠️ Error in getAllForm4E4DRecords: ' + ex.getMessage() + ' Stack: ' + ex.getStackTraceString());
        throw new AuraHandledException('Error fetching Form 4E/4D records: ' + ex.getMessage());
    }
}
@AuraEnabled
    public static Map<String, String> getDCBudgetRecordTypes() {
        Map<String, String> recordTypeMap = new Map<String, String>();
        
        List<RecordType> recordTypes = [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'DC_Budget__c'
        ];
        
        for (RecordType rt : recordTypes) {
            recordTypeMap.put(rt.DeveloperName, rt.Id);
        }
        
        return recordTypeMap;
    }
      @AuraEnabled(cacheable=true)
public static String getVisitReportUrl() {

    try {
        List<SObject> records = Database.query(
            'SELECT DeveloperName, MasterLabel, Report_URL__c FROM Visit_Report_URL__mdt'
        );

        System.debug('Total Records = ' + records.size());
        System.debug('Records Data = ' + records);

        if (!records.isEmpty()) {
            String url = (String)records[0].get('Report_URL__c');
            System.debug('URL Found = ' + url);
            return url;
        }

        System.debug('No Metadata Records Found');
        return '';

    } catch (Exception e) {
        System.debug('Error = ' + e.getMessage());
        return '';
    }
}
    
    @AuraEnabled
    public static List<String> getFinancialYears() {
         List<String> fyList = new List<String>();

        // Query the metadata
        List<Financial_Year_Option_For_Custom_Reports__mdt> mdList = [
            SELECT Financial_Year_Values_For_MIS_Report__c
            FROM Financial_Year_Option_For_Custom_Reports__mdt
        ];

        for (Financial_Year_Option_For_Custom_Reports__mdt md : mdList) {
            String values = md.Financial_Year_Values_For_MIS_Report__c;

            if (String.isNotBlank(values)) {

                // Split values like 2025-26,2026-27
                for (String fy : values.split(',')) {
                    fy = fy.trim();   // remove spaces

                    if (String.isNotBlank(fy) && !fyList.contains(fy)) {
                        fyList.add(fy);
                    }
                }
            }
        }

        return fyList;
    
    }
}