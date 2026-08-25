/**
 * @name        RunRateCalculationController
 * @description Apex controller for the Run Rate Calculation Lightning Web Component (LWC).
 *              This class provides budget data and currency exchange rates for custom financial 
 *              reporting, specifically tailored for YTD and forecast-based calculations.
 *              
 *              - Retrieves approved DC_Budget__c records for the selected financial year.
 *              - Includes associated active Budget_Line_Items__r with monthly budget and actual fields.
 *              - Supports currency conversion via exchange rate metadata (fetched separately).
 *              
 *              This controller enables dynamic LWC reporting with run rate calculations based on
 *              current fiscal performance and budget targets.
 * 
 * @author      Reetabrata Mishra
 * @date        24th July 2025
 * @version     1.0
 */


public class RunRateCalculationController {
    //Get All Budget 
    @AuraEnabled
    public static List<DC_Budget__c> getDCBudgetAndChildItems(String selectedFY) {
        Id rtId = Schema.SObjectType.DC_Budget__c.getRecordTypeInfosByDeveloperName().get('Development_Budget').getRecordTypeId();

        List<DC_Budget__c> DCBudgetList = new List<DC_Budget__c>();
        
        try {
            DCBudgetList = [
                SELECT Id, Name,RecordTypeId, Status__c, Financial_Year__c,CurrencyIsoCode,Branch__r.Branch_Code__c ,
                (
                    SELECT Id, Name, Budget_FN_Year__c,CurrencyIsoCode,PMG_Master__r.Name,Order_Type__c,PMG_Name__c,
                    Apr_Order_Actual__c, Aug_Order_Actual__c, Dec_Order_Actual__c, Mar_Order_Actual__c,
                    Feb_Order_Actual__c, Jan_Order_Actual__c, Jul_Order_Actual__c, Jun_Order_Actual__c,
                    May_Order_Actual__c, Nov_Order_Actual__c, Oct_Order_Actual__c, Sep_Order_Actual__c,
                    Apr_Order__c, May_Order__c, Jun_Order__c, Jul_Order__c, Aug_Order__c, Sep_Order__c,
                    Dec_Order__c, Jan_Order__c, Feb_Order__c, Mar_Order__c, Nov_Order__c, Oct_Order__c

                    FROM Budget_Line_Items__r
                    WHERE Active_Status__c = true
                )
                FROM DC_Budget__c
                WHERE Status__c = '4th Level Approved'
                AND Financial_Year__c = :selectedFY 
                
            ];
           // AND Id IN ('a1iC3000000dq1xIAA')
        } catch (Exception ex) {
            System.debug('⚠️ Error in getDCBudgetAndChildItems: ' + ex.getMessage());
        }
        
        return DCBudgetList;
    }

    // NEW METHOD: Get all Form 4E/4D records for the financial year
    @AuraEnabled
    public static List<X4E_4D__c> getAllForm4E4DRecords(String selectedFY) {
        List<X4E_4D__c> formRecords = new List<X4E_4D__c>();
        
        try {
            // Extract year from selectedFY (format: "2024-25")
            Integer startYear = Integer.valueOf(selectedFY.split('-')[0]);
            Date fiscalStart = Date.newInstance(startYear, 4, 1); // April 1
            Date fiscalEnd = Date.newInstance(startYear + 1, 3, 31); // March 31
            
            formRecords = [
                SELECT Id, Name, CreatedDate, Total_Value__c, CurrencyIsoCode, SF_Offer__r.Branch__r.Branch_Code__c,
                       PMG__c, End_Customer_PO_Value__c, Status_SO__c,Order_Category__c,
                       DC_Budget_Line_Items__c, DC_Budget_Line_Items__r.Budget__c
                FROM X4E_4D__c 
                WHERE Status_SO__c = 'Closed'
                AND CreatedDate >= :fiscalStart
            AND CreatedDate <= :fiscalEnd
                ORDER BY CreatedDate
            ];
        } catch (Exception ex) {
            System.debug('⚠️ Error in getAllForm4E4DRecords: ' + ex.getMessage());
        }
        
        return formRecords;
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
    
    @AuraEnabled
    public static List<String> getFinancialYears() {
         List<String> fyList = new List<String>();

        // Query the metadata
        List<Financial_Year_Option_For_Custom_Reports__mdt> mdList = [
            SELECT Financial_Year_Values_For_RunRate_Report__c 
            FROM Financial_Year_Option_For_Custom_Reports__mdt
        ];

        for (Financial_Year_Option_For_Custom_Reports__mdt md : mdList) {
            String values = md.Financial_Year_Values_For_RunRate_Report__c ;

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