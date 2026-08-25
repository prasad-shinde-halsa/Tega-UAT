/////////////////////////////////////////////
//      Test Class for ProductDataRetrieverAPI2
//      Dev Name - Ranjeet Kumar          ///
/////////////////////////////////////////////

@isTest
private class ProductDataRetrieverAPI2Test {
    
    @testSetup
    static void setupTestData() {
        // Create Account (Customer)
        Account testCustomer = new Account(
            Name = 'Test Customer Account'
        );
        insert testCustomer;
        
        // Create Sales_Org__c
        Sales_Org__c testSalesOrg = new Sales_Org__c(
            Name = 'Test Sales Org'
        );
        insert testSalesOrg;
        
        // Create Product2 (Product_L3__c)
        Product2 testProduct = new Product2(
            Name = 'Test Product L3',
            IsActive = true
        );
        insert testProduct;
        
        // Create Part_List__c
        Part_List__c testPartList = new Part_List__c(
            Name = 'Test Part List',
            Customer__c = testCustomer.Id,
            Direct_Quoted_Exchange_Rate__c = 1.0,
            Version_Number_Component__c = 'REV-001'
        );
        insert testPartList;
        
        // Create L2_L3_Product__c junction record
        L2_L3_Product__c junctionRecord = new L2_L3_Product__c(
            Product_L3__c = testProduct.Id,
            Part_List__c = testPartList.Id
        );
        insert junctionRecord;
        
        // Create Item_Weight__c
        Item_Weight__c testItemWeight = new Item_Weight__c(
            Product_L3__c = testProduct.Id,
            Net_Weight__c = 25.5,
            Plant__c = 'Plant001',
            Description__c = 'Weight Description'
        );
        insert testItemWeight;
        
        // Create Sales_Organization_Product__c
        Sales_Organization_Product__c testSalesOrgProduct = new Sales_Organization_Product__c(
            Product__c = testProduct.Id,
            Price__c = 500.00,
            Sales_Org__c = testSalesOrg.Id
        );
        insert testSalesOrgProduct;
        
        // Create L1_L3_Product__c
        L1_L3_Product__c testL1L3Product = new L1_L3_Product__c(
            Product_del__c = testProduct.Id,
            Part_List__c = testPartList.Id,
            L1L3_Code__c = 'TEST-L1L3-001',
            Last_Sales_Date__c = Date.today().addDays(-30),
            Last_Sales_Price__c = 450.00,
            Offer_Number__c = 'OFFER001',
            Order_Number__c = 'ORDER001'
        );
        insert testL1L3Product;
    }
    
    // ─── Helper to build and fire the REST request ────────────────────────────
    private static Map<String, Object> fireRequest(String product2Name, String partListName, String salesOrgId, String partListRevisionNo) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/api/getProductData/';
        req.httpMethod = 'POST';
        
        ProductDataRetrieverAPI2.RequestWrapper requestData = new ProductDataRetrieverAPI2.RequestWrapper();
        requestData.product2Name       = product2Name;
        requestData.partListName       = partListName;
        requestData.salesOrgId         = salesOrgId;
        requestData.partListRevisionNo = partListRevisionNo;
        
        req.requestBody = Blob.valueOf(JSON.serialize(requestData));
        RestContext.request  = req;
        RestContext.response = res;
        
        Test.startTest();
        ProductDataRetrieverAPI2.getProductRelatedData();
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        response.put('__statusCode__', res.statusCode);
        return response;
    }
    
    // ─── Helper: returns true if the list contains a "No records found" message ─
    private static Boolean isNoRecords(List<Object> lst) {
        if (lst == null || lst.isEmpty()) return false;
        Map<String, Object> first = (Map<String, Object>) lst.get(0);
        return first.containsKey('message') && first.get('message') == 'No records found';
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO A : Both product2Name AND partListName provided
    // ─────────────────────────────────────────────────────────────────────────
    
    // A1 — Both provided + valid revisionNo → all arrays populated with real data
    /*@isTest
    static void testBothProvided_WithRevision_AllDataReturned() {
        Part_List__c partList = [SELECT Name, Version_Number_Component__c FROM Part_List__c LIMIT 1];
        Sales_Org__c salesOrg = [SELECT Id FROM Sales_Org__c LIMIT 1];
        
        Map<String, Object> response = fireRequest('Test Product L3', partList.Name, salesOrg.Id, partList.Version_Number_Component__c);
        
        System.assertEquals(true,  response.get('success'), 'Should be successful');
        System.assertEquals(200,   response.get('__statusCode__'));
        System.assertEquals('Data retrieved successfully', response.get('message'));
        
        List<Object> partListResp  = (List<Object>) response.get('partList');
        List<Object> itemWeights   = (List<Object>) response.get('itemWeights');
        List<Object> salesOrgProds = (List<Object>) response.get('salesOrganizationProducts');
        List<Object> l1l3Prods    = (List<Object>) response.get('L1L3product');
        
        // All arrays must have real records (not "No records found")
        System.assertEquals(false, isNoRecords(partListResp),  'partList should have real data');
        System.assertEquals(false, isNoRecords(itemWeights),   'itemWeights should have real data');
        System.assertEquals(false, isNoRecords(salesOrgProds), 'salesOrganizationProducts should have real data');
        System.assertEquals(false, isNoRecords(l1l3Prods),     'L1L3product should have real data');
        
        // Spot-check values
        Map<String, Object> plItem  = (Map<String, Object>) partListResp.get(0);
        System.assertEquals('REV-001', plItem.get('Part List Revision No'));
        System.assertEquals(1.0,       plItem.get('Direct_Quoted_Exchange_Rate__c'));
        
        Map<String, Object> iwItem  = (Map<String, Object>) itemWeights.get(0);
        System.assertEquals(25.5, iwItem.get('Net_Weight__c'));
        
        Map<String, Object> sopItem = (Map<String, Object>) salesOrgProds.get(0);
        System.assertEquals(500.00, sopItem.get('Price__c'));
        System.assertEquals((String) salesOrg.Id, (String) sopItem.get('Sales_Org__c'));
        
        Map<String, Object> l1l3Item = (Map<String, Object>) l1l3Prods.get(0);
        System.assertEquals('ORDER001', l1l3Item.get('Order_Number__c'));
    }*/
    
    // A2 — Both provided + NO revisionNo → partList and L1L3 = "No records found", itemWeights and salesOrg populated
    @isTest
    static void testBothProvided_NoRevision_PartListAndL1L3NoRecords() {
        Part_List__c partList = [SELECT Name FROM Part_List__c LIMIT 1];
        Sales_Org__c salesOrg = [SELECT Id FROM Sales_Org__c LIMIT 1];
        
        Map<String, Object> response = fireRequest('Test Product L3', partList.Name, salesOrg.Id, null);
        
        System.assertEquals(true, response.get('success'));
        System.assertEquals(200,  response.get('__statusCode__'));
        
        System.assertEquals(true, isNoRecords((List<Object>) response.get('partList')),    'partList should be No records found');
        System.assertEquals(true, isNoRecords((List<Object>) response.get('L1L3product')), 'L1L3product should be No records found');
        
        System.assertEquals(false, isNoRecords((List<Object>) response.get('itemWeights')),               'itemWeights should have real data');
        System.assertEquals(false, isNoRecords((List<Object>) response.get('salesOrganizationProducts')), 'salesOrgProducts should have real data');
    }
    
    // A3 — Both provided + WRONG revisionNo → partList and L1L3 = "No records found"
    @isTest
    static void testBothProvided_WrongRevision_PartListAndL1L3NoRecords() {
        Part_List__c partList = [SELECT Name FROM Part_List__c LIMIT 1];
        Sales_Org__c salesOrg = [SELECT Id FROM Sales_Org__c LIMIT 1];
        
        Map<String, Object> response = fireRequest('Test Product L3', partList.Name, salesOrg.Id, 'WRONG-REV-999');
        
        System.assertEquals(true, response.get('success'));
        System.assertEquals(200,  response.get('__statusCode__'));
        
        System.assertEquals(true, isNoRecords((List<Object>) response.get('partList')),    'partList should be No records found for wrong revision');
        System.assertEquals(true, isNoRecords((List<Object>) response.get('L1L3product')), 'L1L3product should be No records found for wrong revision');
    }
    
    // A4 — Both provided + non-existent names → all arrays = "No records found"
    @isTest
    static void testBothProvided_NonExistentNames_AllNoRecords() {
        Sales_Org__c salesOrg = [SELECT Id FROM Sales_Org__c LIMIT 1];
        
        Map<String, Object> response = fireRequest('Non-Existent Product', 'Non-Existent Part List', salesOrg.Id, 'REV-001');
        
        System.assertEquals(true, response.get('success'));
        System.assertEquals(200,  response.get('__statusCode__'));
        
        System.assertEquals(true, isNoRecords((List<Object>) response.get('partList')),                   'partList should be No records found');
        System.assertEquals(true, isNoRecords((List<Object>) response.get('itemWeights')),                'itemWeights should be No records found');
        System.assertEquals(true, isNoRecords((List<Object>) response.get('salesOrganizationProducts')), 'salesOrgProducts should be No records found');
        System.assertEquals(true, isNoRecords((List<Object>) response.get('L1L3product')),               'L1L3product should be No records found');
    }
    
    // A5 — Both provided + wrong salesOrgId → salesOrgProducts = "No records found", rest populated
    @isTest
    static void testBothProvided_WrongSalesOrg_SalesOrgProductsNoRecords() {
        Part_List__c partList = [SELECT Name, Version_Number_Component__c FROM Part_List__c LIMIT 1];
        
        Sales_Org__c differentSalesOrg = new Sales_Org__c(Name = 'Different Sales Org');
        insert differentSalesOrg;
        
        Map<String, Object> response = fireRequest('Test Product L3', partList.Name, differentSalesOrg.Id, partList.Version_Number_Component__c);
        
        System.assertEquals(true, response.get('success'));
        
        System.assertEquals(true,  isNoRecords((List<Object>) response.get('salesOrganizationProducts')), 'salesOrgProducts should be No records found for unlinked Sales Org');
        System.assertEquals(false, isNoRecords((List<Object>) response.get('partList')),                  'partList should have real data');
        System.assertEquals(false, isNoRecords((List<Object>) response.get('itemWeights')),               'itemWeights should have real data');
    }
    
    // A6 — Multiple L2_L3_Product__c records → still works correctly
    @isTest
    static void testBothProvided_MultipleL2L3Records_Success() {
        Product2 existingProduct   = [SELECT Id FROM Product2 WHERE Name = 'Test Product L3' LIMIT 1];
        Part_List__c existingPartList = [SELECT Id, Name, Version_Number_Component__c FROM Part_List__c LIMIT 1];
        Sales_Org__c salesOrg      = [SELECT Id FROM Sales_Org__c LIMIT 1];
        
        insert new L2_L3_Product__c(Product_L3__c = existingProduct.Id, Part_List__c = existingPartList.Id);
        
        Map<String, Object> response = fireRequest('Test Product L3', existingPartList.Name, salesOrg.Id, existingPartList.Version_Number_Component__c);
        
        System.assertEquals(true, response.get('success'));
        System.assertEquals(false, isNoRecords((List<Object>) response.get('partList')), 'partList should have real data');
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO B : Only partListName provided (product2Name blank)
    // ─────────────────────────────────────────────────────────────────────────
    
    // B1 — Only partListName (valid) → partList populated, all others = "No records found"
    @isTest
    static void testOnlyPartListName_ValidName_PartListPopulated() {
        Part_List__c partList = [SELECT Name FROM Part_List__c LIMIT 1];
        Sales_Org__c salesOrg = [SELECT Id FROM Sales_Org__c LIMIT 1];
        
        Map<String, Object> response = fireRequest(null, partList.Name, salesOrg.Id, null);
        
        System.assertEquals(true, response.get('success'));
        System.assertEquals(200,  response.get('__statusCode__'));
        
        System.assertEquals(false, isNoRecords((List<Object>) response.get('partList')),   'partList should have real data');
        System.assertEquals(true,  isNoRecords((List<Object>) response.get('itemWeights')),               'itemWeights should be No records found');
        System.assertEquals(true,  isNoRecords((List<Object>) response.get('salesOrganizationProducts')), 'salesOrgProducts should be No records found');
        System.assertEquals(true,  isNoRecords((List<Object>) response.get('L1L3product')),               'L1L3product should be No records found');
        
        // Spot-check partList data
        List<Object> partListResp = (List<Object>) response.get('partList');
        Map<String, Object> plItem = (Map<String, Object>) partListResp.get(0);
        System.assertNotEquals(null, plItem.get('Id'), 'partList Id should not be null');
        System.assertEquals(partList.Name, plItem.get('Name'));
    }
    
    // B2 — Only partListName (non-existent) → all arrays = "No records found"
    @isTest
    static void testOnlyPartListName_NonExistentName_AllNoRecords() {
        Sales_Org__c salesOrg = [SELECT Id FROM Sales_Org__c LIMIT 1];
        
        Map<String, Object> response = fireRequest(null, 'Non-Existent Part List', salesOrg.Id, null);
        
        System.assertEquals(true, response.get('success'));
        System.assertEquals(200,  response.get('__statusCode__'));
        
        System.assertEquals(true, isNoRecords((List<Object>) response.get('partList')),                   'partList should be No records found');
        System.assertEquals(true, isNoRecords((List<Object>) response.get('itemWeights')),                'itemWeights should be No records found');
        System.assertEquals(true, isNoRecords((List<Object>) response.get('salesOrganizationProducts')), 'salesOrgProducts should be No records found');
        System.assertEquals(true, isNoRecords((List<Object>) response.get('L1L3product')),               'L1L3product should be No records found');
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO C : Only product2Name provided (partListName blank)
    // ─────────────────────────────────────────────────────────────────────────
    
    // C1 — Only product2Name (valid) → itemWeights and salesOrgProducts populated, partList and L1L3 = "No records found"
    @isTest
    static void testOnlyProduct2Name_ValidName_ItemWeightsAndSalesOrgPopulated() {
        Sales_Org__c salesOrg = [SELECT Id FROM Sales_Org__c LIMIT 1];
        
        Map<String, Object> response = fireRequest('Test Product L3', null, salesOrg.Id, null);
        
        System.assertEquals(true, response.get('success'));
        System.assertEquals(200,  response.get('__statusCode__'));
        
        System.assertEquals(true,  isNoRecords((List<Object>) response.get('partList')),    'partList should be No records found');
        System.assertEquals(true,  isNoRecords((List<Object>) response.get('L1L3product')), 'L1L3product should be No records found');
        System.assertEquals(false, isNoRecords((List<Object>) response.get('itemWeights')),               'itemWeights should have real data');
        System.assertEquals(false, isNoRecords((List<Object>) response.get('salesOrganizationProducts')), 'salesOrgProducts should have real data');
        
        // Spot-check itemWeights
        List<Object> itemWeights = (List<Object>) response.get('itemWeights');
        Map<String, Object> iwItem = (Map<String, Object>) itemWeights.get(0);
        System.assertEquals(25.5, iwItem.get('Net_Weight__c'));
        
        // Spot-check salesOrgProducts
        List<Object> salesOrgProds = (List<Object>) response.get('salesOrganizationProducts');
        Map<String, Object> sopItem = (Map<String, Object>) salesOrgProds.get(0);
        System.assertEquals(500.00, sopItem.get('Price__c'));
    }
    
    // C2 — Only product2Name (non-existent) → all arrays = "No records found"
    @isTest
    static void testOnlyProduct2Name_NonExistentName_AllNoRecords() {
        Sales_Org__c salesOrg = [SELECT Id FROM Sales_Org__c LIMIT 1];
        
        Map<String, Object> response = fireRequest('Non-Existent Product', null, salesOrg.Id, null);
        
        System.assertEquals(true, response.get('success'));
        System.assertEquals(200,  response.get('__statusCode__'));
        
        System.assertEquals(true, isNoRecords((List<Object>) response.get('partList')),                   'partList should be No records found');
        System.assertEquals(true, isNoRecords((List<Object>) response.get('itemWeights')),                'itemWeights should be No records found');
        System.assertEquals(true, isNoRecords((List<Object>) response.get('salesOrganizationProducts')), 'salesOrgProducts should be No records found');
        System.assertEquals(true, isNoRecords((List<Object>) response.get('L1L3product')),               'L1L3product should be No records found');
    }
    
    // C3 — Only product2Name (valid) + wrong salesOrgId → salesOrgProducts = "No records found"
    @isTest
    static void testOnlyProduct2Name_WrongSalesOrg_SalesOrgProductsNoRecords() {
        Sales_Org__c differentSalesOrg = new Sales_Org__c(Name = 'Different Sales Org');
        insert differentSalesOrg;
        
        Map<String, Object> response = fireRequest('Test Product L3', null, differentSalesOrg.Id, null);
        
        System.assertEquals(true, response.get('success'));
        
        System.assertEquals(true,  isNoRecords((List<Object>) response.get('salesOrganizationProducts')), 'salesOrgProducts should be No records found for unlinked Sales Org');
        System.assertEquals(false, isNoRecords((List<Object>) response.get('itemWeights')),               'itemWeights should have real data');
        System.assertEquals(true,  isNoRecords((List<Object>) response.get('partList')),                  'partList should be No records found');
        System.assertEquals(true,  isNoRecords((List<Object>) response.get('L1L3product')),               'L1L3product should be No records found');
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATION TESTS
    // ─────────────────────────────────────────────────────────────────────────
    
    // V1 — Both blank → 400 validation error
    @isTest
    static void testBothNamesBlank_ValidationError() {
        Sales_Org__c salesOrg = [SELECT Id FROM Sales_Org__c LIMIT 1];
        
        Map<String, Object> response = fireRequest(null, null, salesOrg.Id, null);
        
        System.assertEquals(false, response.get('success'));
        System.assertEquals(400,   response.get('__statusCode__'));
        System.assertEquals('At least one of Product Name or Part List Name is required', response.get('message'));
    }
    
    // V2 — salesOrgId blank → 400 validation error
    @isTest
    static void testSalesOrgIdBlank_ValidationError() {
        Part_List__c partList = [SELECT Name FROM Part_List__c LIMIT 1];
        
        Map<String, Object> response = fireRequest('Test Product L3', partList.Name, null, null);
        
        System.assertEquals(false, response.get('success'));
        System.assertEquals(400,   response.get('__statusCode__'));
        System.assertEquals('Sales Org ID is required', response.get('message'));
    }
    
    // V3 — Malformed JSON → 400 error
    @isTest
    static void testMalformedJSON_ErrorReturned() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI  = '/services/apexrest/api/getProductData/';
        req.httpMethod  = 'POST';
        req.requestBody = Blob.valueOf('{ invalid json }');
        RestContext.request  = req;
        RestContext.response = res;
        
        Test.startTest();
        ProductDataRetrieverAPI2.getProductRelatedData();
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        
        System.assertEquals(false, response.get('success'));
        System.assertEquals(400,   res.statusCode);
        System.assert(((String) response.get('message')).startsWith('Error:'), 'Message should start with Error:');
    }
}