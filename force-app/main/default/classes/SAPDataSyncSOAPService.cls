global class SAPDataSyncSOAPService {
    
    webservice static String insertSAPRecord(
        String materialName,
        Decimal materialCost,
        String currencyIsoCode,
        String lastUpdatedDate,
        String sapDataSyncName
    ) {
        try {
            // Validate required fields
            if (String.isBlank(sapDataSyncName)) {
                return 'ERROR: sapDataSyncName (Name) is required';
            }
            
            SAP_data_Sync__c newRecord = new SAP_data_Sync__c();
            
            newRecord.Name             = sapDataSyncName;
            newRecord.Material_Name__c = materialName;
            newRecord.Material_Cost__c = materialCost;
            newRecord.CurrencyIsoCode  = currencyIsoCode;
            
            if (String.isNotBlank(lastUpdatedDate)) {
                newRecord.Last_Updated_Date__c = Date.valueOf(lastUpdatedDate);
            }
            
            insert newRecord;
            
            return 'SUCCESS: Record Created with Id = ' + newRecord.Id;
            
        } catch (DmlException e) {
            return 'DML ERROR: ' + e.getMessage();
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }
}