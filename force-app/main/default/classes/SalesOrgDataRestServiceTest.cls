@isTest
private class SalesOrgDataRestServiceTest {
    
    @testSetup
    static void setup() {
        // Create test data for different objects
        // Note: Name field is auto-generated, we don't set it manually
        Sales_Org_Last_SAP_SO__c salesOrg = new Sales_Org_Last_SAP_SO__c();
        insert salesOrg;
        
        Part_List__c partList = new Part_List__c();
        insert partList;
        
        Sales_Organization_Product__c salesOrgProduct = new Sales_Organization_Product__c();
        insert salesOrgProduct;
        
        Item_Weight__c itemWeight = new Item_Weight__c();
        insert itemWeight;
    }
    
    @isTest
    static void testGetSalesOrgData_MultipleObjects_Success() {
        // Get the created records to get their auto-generated Names
        Sales_Org_Last_SAP_SO__c salesOrg = [SELECT Id, Name FROM Sales_Org_Last_SAP_SO__c LIMIT 1];
        Part_List__c partList = [SELECT Id, Name FROM Part_List__c LIMIT 1];
        
        // Setup
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/getSalesOrgData/';
        req.httpMethod = 'POST';
        
        String requestBody = '{' +
            '"records": [' +
                '{' +
                    '"attributes": {' +
                        '"type": "Sales_Org_Last_SAP_SO__c"' +
                    '},' +
                    '"Name": "' + salesOrg.Name + '"' +
                '},' +
                '{' +
                    '"attributes": {' +
                        '"type": "Part_List__c"' +
                    '},' +
                    '"Name": "' + partList.Name + '"' +
                '}' +
            ']' +
        '}';
        
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Execute
        Test.startTest();
        SalesOrgDataRestService.getSalesOrgData();
        Test.stopTest();
        
        // Assert
        System.assertEquals(200, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('success'));
    }
    
    @isTest
    static void testGetSalesOrgData_NotFound() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/getSalesOrgData/';
        req.httpMethod = 'POST';
        
        String requestBody = '{' +
            '"records": [' +
                '{' +
                    '"attributes": {' +
                        '"type": "Sales_Org_Last_SAP_SO__c"' +
                    '},' +
                    '"Name": "Non Existent Name XYZ123"' +
                '}' +
            ']' +
        '}';
        
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        SalesOrgDataRestService.getSalesOrgData();
        Test.stopTest();
        
        System.assertEquals(200, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('No record found'));
    }
    
    @isTest
    static void testGetSalesOrgData_EmptyRequest() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/getSalesOrgData/';
        req.httpMethod = 'POST';
        
        String requestBody = '{"records": []}';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        SalesOrgDataRestService.getSalesOrgData();
        Test.stopTest();
        
        System.assertEquals(400, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('Request data is required'));
    }
    
    @isTest
    static void testGetSalesOrgData_AllObjectTypes() {
        // Get all created records
        Sales_Org_Last_SAP_SO__c salesOrg = [SELECT Id, Name FROM Sales_Org_Last_SAP_SO__c LIMIT 1];
        Part_List__c partList = [SELECT Id, Name FROM Part_List__c LIMIT 1];
        Sales_Organization_Product__c salesOrgProduct = [SELECT Id, Name FROM Sales_Organization_Product__c LIMIT 1];
        Item_Weight__c itemWeight = [SELECT Id, Name FROM Item_Weight__c LIMIT 1];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/getSalesOrgData/';
        req.httpMethod = 'POST';
        
        String requestBody = '{' +
            '"records": [' +
                '{' +
                    '"attributes": {"type": "Sales_Org_Last_SAP_SO__c"},' +
                    '"Name": "' + salesOrg.Name + '"' +
                '},' +
                '{' +
                    '"attributes": {"type": "Part_List__c"},' +
                    '"Name": "' + partList.Name + '"' +
                '},' +
                '{' +
                    '"attributes": {"type": "Sales_Organization_Product__c"},' +
                    '"Name": "' + salesOrgProduct.Name + '"' +
                '},' +
                '{' +
                    '"attributes": {"type": "Item_Weight__c"},' +
                    '"Name": "' + itemWeight.Name + '"' +
                '}' +
            ']' +
        '}';
        
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        SalesOrgDataRestService.getSalesOrgData();
        Test.stopTest();
        
        System.assertEquals(200, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains(salesOrg.Id));
        System.assert(responseBody.contains(partList.Id));
        System.assert(responseBody.contains(salesOrgProduct.Id));
        System.assert(responseBody.contains(itemWeight.Id));
    }
    
    @isTest
    static void testGetSalesOrgData_MixedResults() {
        // Get one existing record
        Sales_Organization_Product__c salesOrgProduct = [SELECT Id, Name FROM Sales_Organization_Product__c LIMIT 1];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/getSalesOrgData/';
        req.httpMethod = 'POST';
        
        String requestBody = '{' +
            '"records": [' +
                '{' +
                    '"attributes": {"type": "Sales_Organization_Product__c"},' +
                    '"Name": "' + salesOrgProduct.Name + '"' +
                '},' +
                '{' +
                    '"attributes": {"type": "Item_Weight__c"},' +
                    '"Name": "Non Existent Weight"' +
                '}' +
            ']' +
        '}';
        
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        SalesOrgDataRestService.getSalesOrgData();
        Test.stopTest();
        
        System.assertEquals(200, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains(salesOrgProduct.Id));
        System.assert(responseBody.contains('No record found'));
    }
    
    @isTest
    static void testGetSalesOrgData_ErrorHandling() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/getSalesOrgData/';
        req.httpMethod = 'POST';
        
        // Invalid JSON
        String requestBody = '{invalid json}';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        SalesOrgDataRestService.getSalesOrgData();
        Test.stopTest();
        
        System.assertEquals(500, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('Error'));
    }
}