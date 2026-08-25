public class UpdateExchangeRateBatch implements Database.Batchable<SObject> {
    private String financialYear;
    private List<String> currencyIsoCodes;
    private List<Id> budgetIdList;
    
    public UpdateExchangeRateBatch(String financialYear, List<String> currencyIsoCodes, List<Id> budgetIdList) {
        this.financialYear = financialYear;
        this.currencyIsoCodes = currencyIsoCodes;
        this.budgetIdList = budgetIdList;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Total_Order__c, Total_Sales__c, Total_Order_In_INR__c, Total_Sales_In_INR__c, ' +
            'Exchange_Rate_Updated__c, CurrencyIsoCode, Financial_Year__c ' +
            'FROM DC_Budget__c';
        
        if(budgetIdList.size() > 0){
            query += ' WHERE Id in :budgetIdList';
        }

        if (String.isNotEmpty(financialYear)) {
            query +=  ( query.contains('WHERE') ? ' AND ' : ' WHERE ') + ' Financial_Year__c = :financialYear';
        }
        
        if (currencyIsoCodes != null && !currencyIsoCodes.isEmpty()) {
            query += ( query.contains('WHERE') ? ' AND ' : ' WHERE ') + 'CurrencyIsoCode IN :currencyIsoCodes';
        }
        
        if (String.isEmpty(financialYear) && (currencyIsoCodes == null || currencyIsoCodes.isEmpty())) {
            query += ( query.contains('WHERE') ? ' AND ' : ' WHERE ') + 'Exchange_Rate_Updated__c = false';
        }
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<DC_Budget__c> scope) {
        Date fiscalYearStartDate;
        Date fiscalYearEndDate;
        
        if (String.isNotEmpty(financialYear)) {
            Integer year = Integer.valueOf(financialYear.split('-')[0]);
            
            fiscalYearStartDate = Date.newInstance(year, 4, 1); 
            fiscalYearEndDate = Date.newInstance(year + 1, 3, 31); 
        }
        List<DatedConversionRate> currenciesRate = [
            SELECT IsoCode, ConversionRate
            FROM DatedConversionRate
            WHERE IsoCode IN :currencyIsoCodes
            AND StartDate >= :fiscalYearStartDate
            AND StartDate <= :fiscalYearEndDate
            ORDER BY StartDate DESC
        ];
        
        Map<String, Decimal> exchangeRateMap = new Map<String, Decimal>();
        for (DatedConversionRate rate : currenciesRate) {
            if (rate.ConversionRate != null) {
                exchangeRateMap.put(rate.IsoCode, rate.ConversionRate);
            }
        }
        
        List<DC_Budget__c> budgetsToUpdate = new List<DC_Budget__c>();
        
        for (DC_Budget__c budget : scope) {
            if (budget.Total_Order__c != null && budget.Total_Sales__c != null) {
                Decimal exchangeRate = exchangeRateMap.get(budget.CurrencyIsoCode);
                
                if (exchangeRate != null) {
                    Decimal orderWithThousand = budget.Total_Order__c * 1000;
                    Decimal salesWithThousand = budget.Total_Sales__c * 1000;
                    
                    budget.Total_Order_In_INR__c = orderWithThousand / exchangeRate;
                    budget.Total_Sales_In_INR__c = salesWithThousand / exchangeRate;
                    budget.Exchange_Rate_Updated__c = true;
                    
                    budgetsToUpdate.add(budget);
                }
            }
        }
        
        if (!budgetsToUpdate.isEmpty()) {
            update budgetsToUpdate;
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        System.debug('UpdateExchangeRateBatch completed successfully.');
    }
}