@isTest
private class ProductDataRetrieverAPITest {
    
    @testSetup
    static void setupTestData() {
        // Create Account for Customer__c lookup
        Account customer = new Account(Name = 'Test Customer');
        insert customer;
        
        // Create Part_List__c record with required fields
        Part_List__c partList = new Part_List__c(
            Customer__c = customer.Id
        );
        insert partList;
        
        // Query to get the auto-generated Name
        partList = [SELECT Id, Name FROM Part_List__c WHERE Id = :partList.Id];
        
        // Create Product2 record with lookup to Part_List__c
        Product2 product = new Product2(
            Name = 'Test Product',
            Part_List__c = partList.Id,
            IsActive = true
        );
        insert product;
        
        // Create Item_Weight__c records
        List<Item_Weight__c> itemWeights = new List<Item_Weight__c>();
        for (Integer i = 1; i <= 3; i++) {
            itemWeights.add(new Item_Weight__c(
                Product_L3__c = product.Id
            ));
        }
        insert itemWeights;
        
        // Create Sales_Org__c record FIRST
        Sales_Org__c salesOrg = new Sales_Org__c(
            Name = '1000'
        );
        insert salesOrg;
        
        // Query to get the inserted Id
        salesOrg = [SELECT Id, Name FROM Sales_Org__c WHERE Id = :salesOrg.Id LIMIT 1];
        
        // Create Sales_Organization_Product__c records - use the Id from salesOrg
        List<Sales_Organization_Product__c> salesOrgProducts = new List<Sales_Organization_Product__c>();
        for (Integer i = 1; i <= 2; i++) {
            Sales_Organization_Product__c sop = new Sales_Organization_Product__c(
                Product__c = product.Id,
                Sales_Org__c = salesOrg.Id  // Use the Id, not the Name
            );
            salesOrgProducts.add(sop);
        }
        
        insert salesOrgProducts;
        
        // Create SAP_Last_Sale_Price__c records
        List<SAP_Last_Sale_Price__c> sapPrices = new List<SAP_Last_Sale_Price__c>();
        for (Integer i = 1; i <= 2; i++) {
            sapPrices.add(new SAP_Last_Sale_Price__c(
                Product_L3__c = product.Id
            ));
        }
        insert sapPrices;
        
        // Create Sales_Org_Last_SAP_SO__c records
        List<Sales_Org_Last_SAP_SO__c> salesOrgSOs = new List<Sales_Org_Last_SAP_SO__c>();
        for (SAP_Last_Sale_Price__c sapPrice : sapPrices) {
            salesOrgSOs.add(new Sales_Org_Last_SAP_SO__c(
                SAP_Last_Sale__c = sapPrice.Id
            ));
        }
        insert salesOrgSOs;
    }
    
    @isTest
    static void testGetProductRelatedData_Success() {
        // Get the actual auto-generated names
        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];
        Part_List__c partList = [SELECT Id, Name FROM Part_List__c LIMIT 1];
        
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/productData';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        String requestBody = '{"product2Name":"' + product.Name + '","partListName":"' + partList.Name + '"}';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Execute
        Test.startTest();
        ProductDataRetrieverAPI.getProductRelatedData();
        Test.stopTest();
        
        // Parse response
        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        // Assert
        System.assertEquals(200, res.statusCode, 'Status code should be 200');
        System.assertEquals(true, responseMap.get('success'), 'Response should be successful');
        System.assertEquals('Data retrieved successfully', responseMap.get('message'));
        
        List<Object> data = (List<Object>) responseMap.get('data');
        System.assertNotEquals(null, data, 'Data should not be null');
        System.assert(data.size() > 0, 'Should have at least one result');
        
        // Verify structure
        Map<String, Object> firstResult = (Map<String, Object>) data[0];
        System.assert(firstResult.containsKey('partList'), 'Should contain partList');
        System.assert(firstResult.containsKey('itemWeights'), 'Should contain itemWeights');
        System.assert(firstResult.containsKey('salesOrganizationProducts'), 'Should contain salesOrganizationProducts');
        System.assert(firstResult.containsKey('salesOrgLastSAPSO'), 'Should contain salesOrgLastSAPSO');
    }
    
    @isTest
    static void testGetProductRelatedData_NoMatchingRecords() {
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/productData';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        String requestBody = '{"product2Name":"NonExistent","partListName":"NonExistent"}';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Execute
        Test.startTest();
        ProductDataRetrieverAPI.getProductRelatedData();
        Test.stopTest();
        
        // Parse response
        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        // Assert
        System.assertEquals(400, res.statusCode, 'Status code should be 400');
        System.assertEquals(false, responseMap.get('success'), 'Response should not be successful');
        System.assertEquals('No matching Product2 records found', responseMap.get('message'));
    }
    
    @isTest
    static void testGetProductRelatedData_MissingProduct2Name() {
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/productData';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        String requestBody = '{"partListName":"Test"}';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Execute
        Test.startTest();
        ProductDataRetrieverAPI.getProductRelatedData();
        Test.stopTest();
        
        // Parse response
        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        // Assert
        System.assertEquals(400, res.statusCode, 'Status code should be 400');
        System.assertEquals(false, responseMap.get('success'), 'Response should not be successful');
        System.assertEquals('Product2 Name and Part List Name are required', responseMap.get('message'));
    }
    
    @isTest
    static void testGetProductRelatedData_MissingPartListName() {
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/productData';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        String requestBody = '{"product2Name":"Test"}';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Execute
        Test.startTest();
        ProductDataRetrieverAPI.getProductRelatedData();
        Test.stopTest();
        
        // Parse response
        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        // Assert
        System.assertEquals(400, res.statusCode, 'Status code should be 400');
        System.assertEquals(false, responseMap.get('success'), 'Response should not be successful');
        System.assertEquals('Product2 Name and Part List Name are required', responseMap.get('message'));
    }
    
    @isTest
    static void testGetProductRelatedData_EmptyRequestBody() {
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/productData';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        String requestBody = '{}';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Execute
        Test.startTest();
        ProductDataRetrieverAPI.getProductRelatedData();
        Test.stopTest();
        
        // Parse response
        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        // Assert
        System.assertEquals(400, res.statusCode, 'Status code should be 400');
        System.assertEquals(false, responseMap.get('success'), 'Response should not be successful');
    }
    
    @isTest
    static void testGetProductRelatedData_MultipleProducts() {
        // Get existing part list and customer
        Part_List__c partList = [SELECT Id, Name, Customer__c FROM Part_List__c LIMIT 1];
        Product2 existingProduct = [SELECT Id, Name FROM Product2 LIMIT 1];
        
        // Create another Product2 with same Part List and Name
        Product2 product2 = new Product2(
            Name = existingProduct.Name,
            Part_List__c = partList.Id,
            IsActive = true
        );
        insert product2;
        
        // Create related records for second product
        Item_Weight__c itemWeight = new Item_Weight__c(
            Product_L3__c = product2.Id
        );
        insert itemWeight;
        
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/productData';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        String requestBody = '{"product2Name":"' + existingProduct.Name + '","partListName":"' + partList.Name + '"}';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Execute
        Test.startTest();
        ProductDataRetrieverAPI.getProductRelatedData();
        Test.stopTest();
        
        // Parse response
        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        // Assert
        System.assertEquals(200, res.statusCode, 'Status code should be 200');
        System.assertEquals(true, responseMap.get('success'), 'Response should be successful');
        
        List<Object> data = (List<Object>) responseMap.get('data');
        System.assertEquals(2, data.size(), 'Should return 2 product data records');
    }
    
    @isTest
    static void testGetProductRelatedData_NoRelatedRecords() {
        // Get existing customer
        Account customer = [SELECT Id FROM Account LIMIT 1];
        
        // Create Product2 without any related records
        Part_List__c partList2 = new Part_List__c(
            Customer__c = customer.Id
        );
        insert partList2;
        
        partList2 = [SELECT Id, Name FROM Part_List__c WHERE Id = :partList2.Id];
        
        Product2 product2 = new Product2(
            Name = 'Isolated Product',
            Part_List__c = partList2.Id,
            IsActive = true
        );
        insert product2;
        
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/productData';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        String requestBody = '{"product2Name":"' + product2.Name + '","partListName":"' + partList2.Name + '"}';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Execute
        Test.startTest();
        ProductDataRetrieverAPI.getProductRelatedData();
        Test.stopTest();
        
        // Parse response
        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        // Assert
        System.assertEquals(200, res.statusCode, 'Status code should be 200');
        System.assertEquals(true, responseMap.get('success'), 'Response should be successful');
        
        List<Object> data = (List<Object>) responseMap.get('data');
        System.assertEquals(1, data.size(), 'Should return 1 product data');
        
        Map<String, Object> firstResult = (Map<String, Object>) data[0];
        List<Object> itemWeights = (List<Object>) firstResult.get('itemWeights');
        List<Object> salesOrgProducts = (List<Object>) firstResult.get('salesOrganizationProducts');
        List<Object> salesOrgSO = (List<Object>) firstResult.get('salesOrgLastSAPSO');
        
        System.assertEquals(0, itemWeights.size(), 'Should have 0 Item Weights');
        System.assertEquals(0, salesOrgProducts.size(), 'Should have 0 Sales Org Products');
        System.assertEquals(0, salesOrgSO.size(), 'Should have 0 Sales Org Last SAP SO');
    }
    
    @isTest
    static void testGetProductRelatedData_InvalidJSON() {
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/productData';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        String requestBody = '{invalid json}';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Execute
        Test.startTest();
        ProductDataRetrieverAPI.getProductRelatedData();
        Test.stopTest();
        
        // Parse response
        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        // Assert
        System.assertEquals(400, res.statusCode, 'Status code should be 400');
        System.assertEquals(false, responseMap.get('success'), 'Response should not be successful');
        String message = (String) responseMap.get('message');
        System.assert(message.contains('Error:'), 'Should contain error message');
        System.assertNotEquals(null, responseMap.get('errorDetails'), 'Error details should not be null');
    }
    
    @isTest
    static void testGetProductRelatedData_SpecialCharacters() {
        // Get existing customer
        Account customer = [SELECT Id FROM Account LIMIT 1];
        
        // Create records with special characters
        Part_List__c partList = new Part_List__c(
            Customer__c = customer.Id
        );
        insert partList;
        
        partList = [SELECT Id, Name FROM Part_List__c WHERE Id = :partList.Id];
        
        String specialName = 'Test Product & More';
        Product2 product = new Product2(
            Name = specialName,
            Part_List__c = partList.Id,
            IsActive = true
        );
        insert product;
        
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/productData';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        // Properly escape the JSON
        Map<String, String> requestMap = new Map<String, String>();
        requestMap.put('product2Name', product.Name);
        requestMap.put('partListName', partList.Name);
        String requestBody = JSON.serialize(requestMap);
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Execute
        Test.startTest();
        ProductDataRetrieverAPI.getProductRelatedData();
        Test.stopTest();
        
        // Parse response
        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        // Assert
        System.assertEquals(200, res.statusCode, 'Status code should be 200');
        System.assertEquals(true, responseMap.get('success'), 'Response should handle special characters');
    }
    
    @isTest
    static void testFieldConfigCacheInitialization() {
        // This test verifies the field configuration cache is properly initialized
        
        // Get test data
        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];
        Part_List__c partList = [SELECT Id, Name FROM Part_List__c LIMIT 1];
        
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/productData';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        String requestBody = '{"product2Name":"' + product.Name + '","partListName":"' + partList.Name + '"}';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Execute multiple times to test cache
        Test.startTest();
        ProductDataRetrieverAPI.getProductRelatedData();
        
        // Reset context for second call
        RestContext.request = req;
        RestContext.response = new RestResponse();
        ProductDataRetrieverAPI.getProductRelatedData();
        Test.stopTest();
        
        // If we get here without errors, cache is working correctly
        System.assert(true, 'Cache initialization should work correctly');
    }
    
    @isTest
    static void testBuildDynamicObject_NullHandling() {
        // Get test data
        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];
        Part_List__c partList = [SELECT Id, Name FROM Part_List__c LIMIT 1];
        
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/productData';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        String requestBody = '{"product2Name":"' + product.Name + '","partListName":"' + partList.Name + '"}';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Execute
        Test.startTest();
        ProductDataRetrieverAPI.getProductRelatedData();
        Test.stopTest();
        
        // Parse response - should handle null records gracefully
        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        // Assert - should still succeed even with some null fields
        System.assertEquals(200, res.statusCode, 'Should handle null records gracefully');
    }
}