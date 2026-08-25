public with sharing class UpdateExchangeRateLWCController {
    
    @AuraEnabled(cacheable=true)
    public static List<DC_Budget__c> getBudgetRecords(String financialYear, List<String> currencyIsoCodes) {
        return [
            SELECT Id, Total_Order__c, Total_Sales__c, Total_Order_In_INR__c, 
            Total_Sales_In_INR__c, Exchange_Rate_Updated__c, CurrencyIsoCode, Financial_Year__c 
            FROM DC_Budget__c 
            WHERE Financial_Year__c = :financialYear 
            AND CurrencyIsoCode IN :currencyIsoCodes
        ];
    }
    

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAvailableFinancialYears() {
        List<Map<String, String>> financialYearOptions = new List<Map<String, String>>();

        Schema.DescribeFieldResult fieldResult = DC_Budget__c.Financial_Year__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry picklistValue : picklistValues) {
            financialYearOptions.add(new Map<String, String>{
                'label' => picklistValue.getLabel(),
                'value' => picklistValue.getValue()
            });
        }

        return financialYearOptions;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Date> getFinancialYearDates(String financialYear) {
        Map<String, Date> financialYearDates = new Map<String, Date>();

        Date startDate = Date.valueOf(financialYear.substring(0, 4) + '-04-01'); 
        Date endDate = startDate.addYears(1).addDays(-1); 

        financialYearDates.put('startDate', startDate);
        financialYearDates.put('endDate', endDate);

        return financialYearDates;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCurrenciesByFinancialYear(String financialYear) {
        Map<String, Date> financialYearDates = getFinancialYearDates(financialYear);

        Date startDate = financialYearDates.get('startDate');

        Set<String> isoCodes = new Set<String>();

        List<DatedConversionRate> rates = [
            SELECT IsoCode 
            FROM DatedConversionRate
            WHERE StartDate >= :startDate
            ORDER BY StartDate DESC
        ];

        for (DatedConversionRate rate : rates) {
            isoCodes.add(rate.IsoCode);
        }

        return new List<String>(isoCodes);
    }

    @AuraEnabled
    public static void runBatch(String financialYear, List<String> currencyIsoCodes, List<Id> budgetIdList) {
        if (String.isBlank(financialYear) || currencyIsoCodes.isEmpty()) {
            throw new AuraHandledException('Both financial year and currency ISO codes are required.');
        }
        Database.executeBatch(new UpdateExchangeRateBatch(financialYear, currencyIsoCodes, budgetIdList));
    }
}