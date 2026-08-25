@RestResource(urlMapping='/getSalesOrgData/*')
global with sharing class SalesOrgDataRestService {
    
    @HttpPost
    global static void getSalesOrgData() {
        Map<String, Object> response = new Map<String, Object>();
        List<Map<String, Object>> resultRecords = new List<Map<String, Object>>();
        
        RestResponse res = RestContext.response;
        
        try {
            // Get the request body as string and parse it
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            
            // Parse JSON manually
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            List<Object> records = (List<Object>) requestMap.get('records');
            
            if (records == null || records.isEmpty()) {
                response.put('success', false);
                response.put('message', 'Request data is required');
                response.put('records', new List<Object>());
                res.statusCode = 400;
                res.addHeader('Content-Type', 'application/json; charset=UTF-8');
                res.responseBody = Blob.valueOf(JSON.serializePretty(response));
                return;
            }
            
            // Process each record
            for (Object recordObj : records) {
                Map<String, Object> record = (Map<String, Object>) recordObj;
                Map<String, Object> attributes = (Map<String, Object>) record.get('attributes');
                String objectType = (String) attributes.get('type');
                String recordName = (String) record.get('Name');
                
                Map<String, Object> resultRecord = new Map<String, Object>();
                Map<String, Object> resultAttributes = new Map<String, Object>();
                resultAttributes.put('type', objectType);
                resultRecord.put('attributes', resultAttributes);
                
                try {
                    // Query based on object type and name
                    String recordId = queryRecordId(objectType, recordName);
                    
                    if (String.isNotBlank(recordId)) {
                        resultRecord.put('id', recordId);
                        resultRecord.put('Name', recordName);
                        resultRecord.put('success', true);
                        resultRecord.put('message', 'Record found');
                    } else {
                        resultRecord.put('id', null);
                        resultRecord.put('Name', recordName);
                        resultRecord.put('success', false);
                        resultRecord.put('message', 'No record found with name: ' + recordName);
                    }
                    
                } catch (Exception e) {
                    resultRecord.put('id', null);
                    resultRecord.put('Name', recordName);
                    resultRecord.put('success', false);
                    resultRecord.put('message', 'Error: ' + e.getMessage());
                }
                
                resultRecords.add(resultRecord);
            }
            
            response.put('success', true);
            response.put('message', 'Processing completed');
            response.put('records', resultRecords);
            res.statusCode = 200;
            
        } catch (Exception e) {
            response.put('success', false);
            response.put('message', 'Error: ' + e.getMessage());
            response.put('records', new List<Object>());
            res.statusCode = 500;
        }
        
        // Set proper headers and response body
        res.addHeader('Content-Type', 'application/json; charset=UTF-8');
        res.responseBody = Blob.valueOf(JSON.serializePretty(response));
    }
    
    // Method to query record ID based on object type
    private static String queryRecordId(String objectType, String recordName) {
        String recordId = null;
        
        if (String.isBlank(objectType) || String.isBlank(recordName)) {
            return null;
        }
        
        try {
            List<SObject> records;
            
            // Query based on object type
            switch on objectType.toLowerCase() {
                when 'sales_org_last_sap_so__c' {
                    records = Database.query(
                        'SELECT Id FROM Sales_Org_Last_SAP_SO__c WHERE Name = :recordName LIMIT 1'
                    );
                }
                when 'part_list__c' {
                    records = Database.query(
                        'SELECT Id FROM Part_List__c WHERE Name = :recordName LIMIT 1'
                    );
                }
                when 'sales_organization_product__c' {
                    records = Database.query(
                        'SELECT Id FROM Sales_Organization_Product__c WHERE Name = :recordName LIMIT 1'
                    );
                }
                when 'item_weight__c' {
                    records = Database.query(
                        'SELECT Id FROM Item_Weight__c WHERE Name = :recordName LIMIT 1'
                    );
                }
                when else {
                    // Dynamic SOQL for any other custom object
                    String query = 'SELECT Id FROM ' + String.escapeSingleQuotes(objectType) + 
                                   ' WHERE Name = :recordName LIMIT 1';
                    records = Database.query(query);
                }
            }
            
            if (records != null && !records.isEmpty()) {
                recordId = records[0].Id;
            }
            
        } catch (Exception e) {
            System.debug('Error querying ' + objectType + ': ' + e.getMessage());
            throw e;
        }
        
        return recordId;
    }
}