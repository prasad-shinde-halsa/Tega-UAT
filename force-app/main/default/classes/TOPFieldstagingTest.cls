@isTest
private class TOPFieldstagingTest {

    // =========================================================
    // TEST DATA FACTORY
    // =========================================================

    // Added this to fix the REQUIRED_FIELD_MISSING: [Customer__c] error
    private static Account createAccount() {
        Account acc = new Account(Name = 'Test Customer');
        insert acc;
        return acc;
    }

    private static Product2 createProduct(String name) {
        Product2 prod = new Product2(Name = name, IsActive = true);
        insert prod;
        return prod;
    }

    private static Part_List__c createPartList(String name, String revNo, String currencyCode, Decimal exchangeRate, Id customerId) {
        Part_List__c pl = new Part_List__c(
            Name = name,
            Version_Number_Component__c = revNo,
            CurrencyIsoCode = currencyCode,
            Direct_Quoted_Exchange_Rate__c = exchangeRate,
            Customer__c = customerId // Populating the missing required field
        );
        insert pl;
        return pl;
    }

    private static Item_Weight__c createItemWeight(Id productId, Decimal netWeight) {
        Item_Weight__c iw = new Item_Weight__c(
            Product_L3__c = productId,
            Net_Weight__c = netWeight
        );
        insert iw;
        return iw;
    }

    private static Sales_Organization_Product__c createSalesOrgProduct(Id productId, String salesOrgId, Decimal price, String currencyCode) {
        Sales_Organization_Product__c sop = new Sales_Organization_Product__c(
            Product__c = productId,
            Sales_Org__c = salesOrgId, // Note: This must be a valid ID if it's a lookup
            Price__c = price,
            CurrencyIsoCode = currencyCode
        );
        insert sop;
        return sop;
    }

    private static L1_L3_Product__c createL1L3Product(Id productId, Id partListId, String currencyCode) {
        L1_L3_Product__c l1l3 = new L1_L3_Product__c(
            Product_del__c = productId,
            Part_List__c = partListId,
            CurrencyIsoCode = currencyCode
        );
        insert l1l3;
        return l1l3;
    }

    private static TOP_Field_Staging__c createStagingRecord(Map<String, Object> fields) {
        TOP_Field_Staging__c stg = new TOP_Field_Staging__c(Status__c = 'In Progress');
        for (String field : fields.keySet()) {
            stg.put(field, fields.get(field));
        }
        insert stg;
        return stg;
    }

    // =========================================================
    // TEST: Schedulable
    // =========================================================

    @isTest
    static void testSchedulable() {
        Test.startTest();
        String cronExp = '0 0 12 * * ?';
        System.schedule('TOPFieldstagging_Job_Test', cronExp, new TOPFieldstagging());
        Test.stopTest();
    }

    // =========================================================
    // TEST: Block 1 - Part List
    // =========================================================

    @isTest
    static void testBlock1_PartListUpdate_Success() {
        Account acc = createAccount();
        Part_List__c pl = createPartList('PL-001', 'R01', 'USD', 1.0, acc.Id);

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'partListName__c' => 'PL-001',
            'partListRevisionNo__c' => 'R01',
            'Direct_Quoted_Exchange_Rate__c' => 1.25,
            'partList_CurrencyIsoCode__c' => 'EUR'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c result = [SELECT Status__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Completed', result.Status__c);
    }

    @isTest
    static void testBlock1_PartListUpdate_RevisionMatch() {
        Account acc = createAccount();
        Part_List__c pl1 = createPartList('PL-002', 'R01', 'USD', 1.0, acc.Id);
        Part_List__c pl2 = createPartList('PL-002', 'R02', 'USD', 1.0, acc.Id);

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'partListName__c' => 'PL-002',
            'partListRevisionNo__c' => 'R01',
            'Direct_Quoted_Exchange_Rate__c' => 2.0
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        Part_List__c updated1 = [SELECT Direct_Quoted_Exchange_Rate__c FROM Part_List__c WHERE Id = :pl1.Id];
        System.assertEquals(2.0, updated1.Direct_Quoted_Exchange_Rate__c);
    }

    // =========================================================
    // TEST: Block 2 - SOP Update
    // =========================================================
    /*
    @isTest
    static void testBlock2_SOPUpdate_Success() {
        Product2 prod = createProduct('PROD-SOP-001');
        // If Sales_Org__c is a lookup to an object (e.g., Sales_Org__c custom object), 
        // you must insert that object first to get a valid ID.
        // Assuming it's a string for now, but if the error "Invalid ID" persists, 
        // replace 'SO-101' with a real record ID.
        
        // Use a 15-character string that looks like an ID if it's a lookup, or create a record:
        // Sales_Org_Record__c soRec = new Sales_Org_Record__c(Name='SO-101'); insert soRec;
        
        // Temporary fix: Using a hardcoded valid-format dummy ID string for the test
        String fakeId = 'a00000000000001AAA'; 

        Sales_Organization_Product__c sop = createSalesOrgProduct(prod.Id, fakeId, 100.0, 'USD');

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c' => 'PROD-SOP-001',
            'salesOrgId__c' => fakeId,
            'Price__c' => 150.0,
            'SOP_CurrencyIsoCode__c' => 'EUR'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        Sales_Organization_Product__c res = [SELECT Price__c FROM Sales_Organization_Product__c WHERE Id = :sop.Id];
        System.assertEquals(150.0, res.Price__c);
    }  */

    // =========================================================
    // TEST: Block 3 - L1L3
    // =========================================================
    
    @isTest
    static void testBlock3_L1L3Update_Success() {
        Account acc = createAccount();
        Product2 prod = createProduct('PROD-L1L3-001');
        Part_List__c pl = createPartList('PL-L1L3-001', 'R01', 'USD', 1.0, acc.Id);
        L1_L3_Product__c l1l3 = createL1L3Product(prod.Id, pl.Id, 'USD');

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c' => 'PROD-L1L3-001',
            'partListName__c' => 'PL-L1L3-001',
            'partListRevisionNo__c' => 'R01',
            'Last_Sales_Date__c' => Date.today(),
            'Last_Sales_Price__c' => 500.0,
            'Order_Number__c' => 'ORD-123',
            'L1L3_CurrencyIsoCode__c' => 'EUR'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        L1_L3_Product__c res = [SELECT Last_Sales_Price__c FROM L1_L3_Product__c WHERE Id = :l1l3.Id];
        System.assertEquals(500.0, res.Last_Sales_Price__c);
    }

    // =========================================================
    // TEST: Validations
    // =========================================================

    @isTest
    static void testValidation_NetWeightMissingProduct() {
        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'Net_Weight__c' => 10.0
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 1);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c);
    }

    @isTest
    static void testValidation_ExchangeRateMissingPart() {
        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'Direct_Quoted_Exchange_Rate__c' => 1.5
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 1);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c);
    }

    @isTest
    static void testEmptyStagingRecord() {
        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>());

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 1);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Completed', res.Status__c);
    }
	/*
    @isTest
    static void testMultiBlock_AllUpdates_Success() {
        Account acc = createAccount();
        Product2 prod = createProduct('PROD-MULTI');
        Part_List__c pl = createPartList('PL-MULTI', 'R01', 'USD', 1.0, acc.Id);
        Item_Weight__c iw = createItemWeight(prod.Id, 5.0);
        
        String fakeId = 'a00000000000001AAA';
        createSalesOrgProduct(prod.Id, fakeId, 50.0, 'USD');
        createL1L3Product(prod.Id, pl.Id, 'USD');

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c' => 'PROD-MULTI',
            'partListName__c' => 'PL-MULTI',
            'partListRevisionNo__c' => 'R01',
            'Direct_Quoted_Exchange_Rate__c' => 1.8,
            'partList_CurrencyIsoCode__c' => 'EUR',
            'Net_Weight__c' => 12.5,
            'salesOrgId__c' => fakeId,
            'Price__c' => 200.0,
            'SOP_CurrencyIsoCode__c' => 'EUR',
            'Last_Sales_Date__c' => Date.today(),
            'Last_Sales_Price__c' => 195.0,
            'Order_Number__c' => 'ORD-999',
            'L1L3_CurrencyIsoCode__c' => 'EUR'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Completed', res.Status__c);
    }    */
}