@isTest
private class TOPFieldstaggingTest {

    // =========================================================
    // TEST DATA FACTORY
    // =========================================================

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
            Name                           = name,
            Version_Number_Component__c    = revNo,
            CurrencyIsoCode                = currencyCode,
            Direct_Quoted_Exchange_Rate__c = exchangeRate,
            Customer__c                    = customerId
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

    private static Sales_Organization_Product__c createSalesOrgProduct(
        Id productId, String salesOrgId, Decimal price, String currencyCode
    ) {
        Sales_Organization_Product__c sop = new Sales_Organization_Product__c(
            Product__c      = productId,
            Sales_Org__c    = salesOrgId,
            Price__c        = price,
            CurrencyIsoCode = currencyCode
        );
        insert sop;
        return sop;
    }

    private static L1_L3_Product__c createL1L3Product(Id productId, Id partListId, String currencyCode) {
        L1_L3_Product__c l1l3 = new L1_L3_Product__c(
            Product_del__c  = productId,
            Part_List__c    = partListId,
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
    // TEST 1: Schedulable
    // =========================================================

    @isTest
    static void testSchedulable() {
        Test.startTest();
        System.schedule('TOPFieldstagging_Test_Job', '0 0 12 * * ?', new TOPFieldstagging());
        Test.stopTest();
        // No exception = schedulable interface wired correctly
    }

    // =========================================================
    // TEST 2: Empty staging record — all fields null → Completed
    // =========================================================

    @isTest
    static void testEmptyStagingRecord_Completes() {
        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>());

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Completed', res.Status__c, 'Empty staging record should complete with no errors');
        System.assertEquals(null, res.Error_Log__c, 'Error log should be null for empty record');
    }

    // =========================================================
    // TEST 3: No records in progress — batch executes with empty scope
    // =========================================================

    @isTest
    static void testNoRecordsInProgress() {
        insert new TOP_Field_Staging__c(Status__c = 'Completed', partListName__c = 'PL-SKIP');

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();
        // Should finish without any exception
    }

    // =========================================================
    // BLOCK 1: PART LIST UPDATES
    // =========================================================

    @isTest
    static void testBlock1_PartList_ExchangeRateAndCurrency_Updated() {
        Account acc     = createAccount();
        Part_List__c pl = createPartList('PL-001', 'R01', 'USD', 1.0, acc.Id);

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'partListName__c'               => 'PL-001',
            'partListRevisionNo__c'         => 'R01',
            'Direct_Quoted_Exchange_Rate__c' => 1.25,
            'partList_CurrencyIsoCode__c'   => 'EUR'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Completed', res.Status__c, 'Should complete for valid Part List update');
        System.assertEquals(null, res.Error_Log__c);

        Part_List__c updated = [SELECT Direct_Quoted_Exchange_Rate__c, CurrencyIsoCode FROM Part_List__c WHERE Id = :pl.Id];
        System.assertEquals(1.25, updated.Direct_Quoted_Exchange_Rate__c, 'Exchange rate should be updated');
        System.assertEquals('EUR', updated.CurrencyIsoCode, 'Currency should be updated');
    }

    @isTest
    static void testBlock1_PartList_OnlyExchangeRate_Updated() {
        Account acc     = createAccount();
        Part_List__c pl = createPartList('PL-EXCH', 'R01', 'USD', 1.0, acc.Id);

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'partListName__c'               => 'PL-EXCH',
            'partListRevisionNo__c'         => 'R01',
            'Direct_Quoted_Exchange_Rate__c' => 3.5
            // partList_CurrencyIsoCode__c intentionally omitted
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Completed', res.Status__c);

        Part_List__c updated = [SELECT Direct_Quoted_Exchange_Rate__c, CurrencyIsoCode FROM Part_List__c WHERE Id = :pl.Id];
        System.assertEquals(3.5, updated.Direct_Quoted_Exchange_Rate__c, 'Exchange rate should be updated');
        System.assertEquals('USD', updated.CurrencyIsoCode, 'Currency should remain unchanged');
    }

    @isTest
    static void testBlock1_PartList_OnlyCurrency_Updated() {
        Account acc     = createAccount();
        Part_List__c pl = createPartList('PL-CURR', 'R01', 'USD', 1.0, acc.Id);

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'partListName__c'             => 'PL-CURR',
            'partListRevisionNo__c'       => 'R01',
            'partList_CurrencyIsoCode__c' => 'GBP'
            // Direct_Quoted_Exchange_Rate__c intentionally omitted
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Completed', res.Status__c);

        Part_List__c updated = [SELECT CurrencyIsoCode FROM Part_List__c WHERE Id = :pl.Id];
        System.assertEquals('GBP', updated.CurrencyIsoCode, 'Currency should be updated to GBP');
    }

    @isTest
    static void testBlock1_PartList_RevisionBlank_MatchesAllRevisions() {
        Account acc  = createAccount();
        Part_List__c pl1 = createPartList('PL-BLANK-REV', 'R01', 'USD', 1.0, acc.Id);
        Part_List__c pl2 = createPartList('PL-BLANK-REV', 'R02', 'USD', 1.0, acc.Id);

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'partListName__c'               => 'PL-BLANK-REV',
            // partListRevisionNo__c blank = match all revisions
            'Direct_Quoted_Exchange_Rate__c' => 9.9
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Completed', res.Status__c, 'Should complete when revision is blank');

        for (Part_List__c pl : [SELECT Direct_Quoted_Exchange_Rate__c FROM Part_List__c WHERE Id IN (:pl1.Id, :pl2.Id)]) {
            System.assertEquals(9.9, pl.Direct_Quoted_Exchange_Rate__c, 'Both revisions should be updated');
        }
    }

    @isTest
    static void testBlock1_PartList_RevisionMatch_UpdatesOnlyMatchedRevision() {
        Account acc  = createAccount();
        Part_List__c pl1 = createPartList('PL-TWO-REV', 'R01', 'USD', 1.0, acc.Id);
        Part_List__c pl2 = createPartList('PL-TWO-REV', 'R02', 'USD', 1.0, acc.Id);

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'partListName__c'               => 'PL-TWO-REV',
            'partListRevisionNo__c'         => 'R01',
            'Direct_Quoted_Exchange_Rate__c' => 7.7
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        Part_List__c updated1 = [SELECT Direct_Quoted_Exchange_Rate__c FROM Part_List__c WHERE Id = :pl1.Id];
        Part_List__c updated2 = [SELECT Direct_Quoted_Exchange_Rate__c FROM Part_List__c WHERE Id = :pl2.Id];
        System.assertEquals(7.7, updated1.Direct_Quoted_Exchange_Rate__c, 'R01 should be updated');
        System.assertEquals(1.0, updated2.Direct_Quoted_Exchange_Rate__c, 'R02 should NOT be updated');
    }

    @isTest
    static void testBlock1_PartList_RevisionMismatch_Error() {
        Account acc = createAccount();
        createPartList('PL-REV-ERR', 'R01', 'USD', 1.0, acc.Id);

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'partListName__c'               => 'PL-REV-ERR',
            'partListRevisionNo__c'         => 'R99',
            'Direct_Quoted_Exchange_Rate__c' => 5.0,
            'partList_CurrencyIsoCode__c'   => 'EUR'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Revision mismatch should produce Error status');
        System.assert(res.Error_Log__c.contains('Part list revision not matched'), 'Error log should mention revision mismatch');
    }

    @isTest
    static void testValidation_PartListNotFound() {
        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'partListName__c'               => 'GHOST-PL',
            'Direct_Quoted_Exchange_Rate__c' => 2.0
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 1);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Non-existent Part List should produce Error');
        System.assert(res.Error_Log__c.contains('Part List not found'), 'Error log should mention Part List not found');
    }

    // =========================================================
    // BLOCK 2A: ITEM WEIGHT UPDATE
    // =========================================================

    @isTest
    static void testBlock2_ItemWeight_Updated() {
        Product2 prod       = createProduct('PROD-IW-001');
        Item_Weight__c iw   = createItemWeight(prod.Id, 10.0);

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c' => 'PROD-IW-001',
            'Net_Weight__c'   => 25.5
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Completed', res.Status__c, 'Should complete for valid item weight update');

        Item_Weight__c updated = [SELECT Net_Weight__c FROM Item_Weight__c WHERE Id = :iw.Id];
        System.assertEquals(25.5, updated.Net_Weight__c, 'Net weight should be updated');
    }

    @isTest
    static void testBlock2_ItemWeight_ProductNotFound_Error() {
        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c' => 'NON-EXISTENT-PROD',
            'Net_Weight__c'   => 15.0
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Non-existent product should produce Error');
        System.assert(res.Error_Log__c.contains('Product not found'), 'Error log should mention product not found');
    }

    // =========================================================
    // BLOCK 2B: SALES ORGANIZATION PRODUCT UPDATE
    // =========================================================

    /*
    @isTest
    static void testBlock2_SalesOrgProduct_Updated() {
        Product2 prod = createProduct('PROD-SOP-001');
        Sales_Organization_Product__c sop = createSalesOrgProduct(prod.Id, 'SO-100', 100.0, 'USD');

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c'        => 'PROD-SOP-001',
            'salesOrgId__c'          => 'SO-100',
            'Price__c'               => 250.0,
            'SOP_CurrencyIsoCode__c' => 'EUR'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Completed', res.Status__c, 'Should complete for valid SOP update');

        Sales_Organization_Product__c updated = [SELECT Price__c, CurrencyIsoCode FROM Sales_Organization_Product__c WHERE Id = :sop.Id];
        System.assertEquals(250.0, updated.Price__c, 'Price should be updated');
        System.assertEquals('EUR', updated.CurrencyIsoCode, 'Currency should be updated');
    }  */

    @isTest
    static void testBlock2_SalesOrgProduct_ProductNotFound_Error() {
        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c'        => 'GHOST-PROD',
            'salesOrgId__c'          => 'SO-100',
            'Price__c'               => 999.0,
            'SOP_CurrencyIsoCode__c' => 'EUR'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Non-existent product should produce Error');
        System.assert(res.Error_Log__c.contains('Product not found'), 'Error log should mention product not found');
    }

    // =========================================================
    // BLOCK 3: L1_L3_PRODUCT UPDATE
    // =========================================================
    /*
    @isTest
    static void testBlock3_L1L3_Updated() {
        Account acc           = createAccount();
        Product2 prod         = createProduct('PROD-L1L3-001');
        Part_List__c pl       = createPartList('PL-L1L3-001', 'R01', 'USD', 1.0, acc.Id);
        L1_L3_Product__c l1l3 = createL1L3Product(prod.Id, pl.Id, 'USD');

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c'         => 'PROD-L1L3-001',
            'partListName__c'         => 'PL-L1L3-001',
            'partListRevisionNo__c'   => 'R01',
            'Last_Sales_Date__c'      => Date.today(),
            'Last_Sales_Price__c'     => 500.0,
            'Order_Number__c'         => 'ORD-123',
            'L1L3_CurrencyIsoCode__c' => 'EUR'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Completed', res.Status__c, 'Should complete for valid L1L3 update');
        System.assertEquals(null, res.Error_Log__c);

        L1_L3_Product__c updated = [SELECT Last_Sales_Price__c, Order_Number__c, CurrencyIsoCode, Last_Sales_Date__c
                                    FROM L1_L3_Product__c WHERE Id = :l1l3.Id];
        System.assertEquals(500.0, updated.Last_Sales_Price__c, 'Last Sales Price should be updated');
        System.assertEquals('ORD-123', updated.Order_Number__c, 'Order Number should be updated');
        System.assertEquals('EUR', updated.CurrencyIsoCode, 'Currency should be updated');
        System.assertEquals(Date.today(), updated.Last_Sales_Date__c, 'Last Sales Date should be updated');
    }   */
	/*
    @isTest
    static void testBlock3_L1L3_RevisionBlank_MatchesAll() {
        Account acc      = createAccount();
        Product2 prod    = createProduct('PROD-L1L3-BLANK-REV');
        Part_List__c pl1 = createPartList('PL-L1L3-BLANK', 'R01', 'USD', 1.0, acc.Id);
        Part_List__c pl2 = createPartList('PL-L1L3-BLANK', 'R02', 'USD', 1.0, acc.Id);
        L1_L3_Product__c l1 = createL1L3Product(prod.Id, pl1.Id, 'USD');
        L1_L3_Product__c l2 = createL1L3Product(prod.Id, pl2.Id, 'USD');

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c'         => 'PROD-L1L3-BLANK-REV',
            'partListName__c'         => 'PL-L1L3-BLANK',
            // partListRevisionNo__c blank = match all
            'Last_Sales_Date__c'      => Date.today(),
            'Last_Sales_Price__c'     => 777.0,
            'Order_Number__c'         => 'ORD-BLANK',
            'L1L3_CurrencyIsoCode__c' => 'AUD'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Completed', res.Status__c, 'Should complete when L1L3 revision is blank');

        for (L1_L3_Product__c updated : [SELECT Last_Sales_Price__c FROM L1_L3_Product__c WHERE Id IN (:l1.Id, :l2.Id)]) {
            System.assertEquals(777.0, updated.Last_Sales_Price__c, 'Both L1L3 records should be updated');
        }
    }    */
	
    /*
    @isTest
    static void testBlock3_L1L3_RevisionMismatch_Error() {
        Account acc     = createAccount();
        Product2 prod   = createProduct('PROD-REV-ERR');
        Part_List__c pl = createPartList('PL-L1L3-REV-ERR', 'R01', 'USD', 1.0, acc.Id);
        createL1L3Product(prod.Id, pl.Id, 'USD');

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c'         => 'PROD-REV-ERR',
            'partListName__c'         => 'PL-L1L3-REV-ERR',
            'partListRevisionNo__c'   => 'R99',
            'Last_Sales_Date__c'      => Date.today(),
            'Last_Sales_Price__c'     => 1000.0,
            'Order_Number__c'         => 'ORD-ERR',
            'L1L3_CurrencyIsoCode__c' => 'EUR'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Revision mismatch should produce Error');
        System.assert(res.Error_Log__c.contains('Part list revision not matched'), 'Error log should mention revision mismatch');
    }   */

    @isTest
    static void testBlock3_L1L3_ProductNotFound_Error() {
        Account acc = createAccount();
        createPartList('PL-L1L3-NO-PROD', 'R01', 'USD', 1.0, acc.Id);

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c'         => 'NON-EXISTENT',
            'partListName__c'         => 'PL-L1L3-NO-PROD',
            'partListRevisionNo__c'   => 'R01',
            'Last_Sales_Date__c'      => Date.today(),
            'Last_Sales_Price__c'     => 100.0,
            'Order_Number__c'         => 'ORD-001',
            'L1L3_CurrencyIsoCode__c' => 'USD'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Non-existent product should produce Error');
        System.assert(res.Error_Log__c.contains('Product not found'), 'Error log should mention product not found');
    }

    @isTest
    static void testBlock3_L1L3_PartListNotFound_Error() {
        createProduct('PROD-L1L3-NO-PL');

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c'         => 'PROD-L1L3-NO-PL',
            'partListName__c'         => 'NON-EXISTENT-PL',
            'Last_Sales_Date__c'      => Date.today(),
            'Last_Sales_Price__c'     => 100.0,
            'Order_Number__c'         => 'ORD-002',
            'L1L3_CurrencyIsoCode__c' => 'USD'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Non-existent part list should produce Error');
        System.assert(res.Error_Log__c.contains('Part List not found'), 'Error log should mention Part List not found');
    }

    // =========================================================
    // VALIDATION TESTS
    // =========================================================

    @isTest
    static void testValidation_NetWeightMissingProduct() {
        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'Net_Weight__c' => 10.0
            // product2Name__c intentionally omitted
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 1);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Net_Weight__c without product should be Error');
        System.assert(res.Error_Log__c.contains('product2Name__c is required for updating Net_Weight__c'), 'Correct validation message expected');
    }

    @isTest
    static void testValidation_ExchangeRateMissingPartList() {
        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'Direct_Quoted_Exchange_Rate__c' => 1.5
            // partListName__c intentionally omitted
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 1);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Exchange rate without Part List should be Error');
        System.assert(res.Error_Log__c.contains('partListName__c is required'), 'Correct validation message expected');
    }

    @isTest
    static void testValidation_CurrencyIsoCodeMissingPartList() {
        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'partList_CurrencyIsoCode__c' => 'EUR'
            // partListName__c intentionally omitted
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 1);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'CurrencyIsoCode without Part List should be Error');
        System.assert(res.Error_Log__c.contains('partListName__c is required'), 'Correct validation message expected');
    }

    @isTest
    static void testValidation_SOP_PricePresentButCurrencyMissing() {
        Product2 prod = createProduct('PROD-SOP-VAL-1');

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c' => 'PROD-SOP-VAL-1',
            'salesOrgId__c'   => 'SO-999',
            'Price__c'        => 300.0
            // SOP_CurrencyIsoCode__c intentionally omitted
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 1);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Price without currency should fail validation');
        System.assert(res.Error_Log__c.contains('SOP_CurrencyIsoCode__c'), 'Error log should mention missing SOP currency');
    }

    @isTest
    static void testValidation_SOP_CurrencyPresentButPriceMissing() {
        Product2 prod = createProduct('PROD-SOP-VAL-2');

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c'        => 'PROD-SOP-VAL-2',
            'salesOrgId__c'          => 'SO-999',
            'SOP_CurrencyIsoCode__c' => 'EUR'
            // Price__c intentionally omitted
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 1);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Currency without price should fail validation');
        System.assert(res.Error_Log__c.contains('Price__c'), 'Error log should mention missing Price__c');
    }

    @isTest
    static void testValidation_SOP_MissingProductAndSalesOrg() {
        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            // product2Name__c and salesOrgId__c intentionally omitted
            'Price__c'               => 100.0,
            'SOP_CurrencyIsoCode__c' => 'USD'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 1);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'SOP without product/salesOrg should fail');
        System.assert(
            res.Error_Log__c.contains('product2Name__c') || res.Error_Log__c.contains('salesOrgId__c'),
            'Error log should mention missing SOP fields'
        );
    }

    @isTest
    static void testValidation_L1L3_PartialFields_MissingDate() {
        Account acc   = createAccount();
        createProduct('PROD-L1L3-VAL-1');
        createPartList('PL-L1L3-VAL-1', 'R01', 'USD', 1.0, acc.Id);

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c'         => 'PROD-L1L3-VAL-1',
            'partListName__c'         => 'PL-L1L3-VAL-1',
            'Last_Sales_Price__c'     => 500.0,
            'Order_Number__c'         => 'ORD-VAL',
            'L1L3_CurrencyIsoCode__c' => 'USD'
            // Last_Sales_Date__c intentionally omitted
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 1);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Missing Last_Sales_Date__c should fail L1L3 validation');
        System.assert(res.Error_Log__c.contains('Last_Sales_Date__c'), 'Error log should mention missing date');
    }

    @isTest
    static void testValidation_L1L3_PartialFields_MissingOrderNumber() {
        Account acc = createAccount();
        createProduct('PROD-L1L3-VAL-2');
        createPartList('PL-L1L3-VAL-2', 'R01', 'USD', 1.0, acc.Id);

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c'         => 'PROD-L1L3-VAL-2',
            'partListName__c'         => 'PL-L1L3-VAL-2',
            'Last_Sales_Date__c'      => Date.today(),
            'Last_Sales_Price__c'     => 500.0,
            'L1L3_CurrencyIsoCode__c' => 'USD'
            // Order_Number__c intentionally omitted
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 1);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Missing Order_Number__c should fail L1L3 validation');
        System.assert(res.Error_Log__c.contains('Order_Number__c'), 'Error log should mention missing Order_Number__c');
    }

    @isTest
    static void testValidation_L1L3_MissingPartListName() {
        createProduct('PROD-L1L3-VAL-3');

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c'         => 'PROD-L1L3-VAL-3',
            // partListName__c intentionally omitted
            'Last_Sales_Date__c'      => Date.today(),
            'Last_Sales_Price__c'     => 500.0,
            'Order_Number__c'         => 'ORD-VAL3',
            'L1L3_CurrencyIsoCode__c' => 'USD'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 1);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Missing partListName__c should fail L1L3 validation');
        System.assert(res.Error_Log__c.contains('partListName__c'), 'Error log should mention missing Part List name');
    }

    @isTest
    static void testValidation_L1L3_OnlyCurrencyProvided() {
        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'L1L3_CurrencyIsoCode__c' => 'EUR'
            // All other L1L3 and product/partList fields omitted
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 1);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Error', res.Status__c, 'Partial L1L3 fields should fail validation');
        System.assert(res.Error_Log__c.contains('Missing required fields for L1L3'), 'Error log should describe missing L1L3 fields');
    }

    // =========================================================
    // ALL FOUR OBJECTS IN ONE STAGING RECORD
    // =========================================================
	/*
    @isTest
    static void testAllFourObjects_UpdatedTogether() {
        Account acc     = createAccount();
        Product2 prod   = createProduct('PROD-ALL-001');
        Part_List__c pl = createPartList('PL-ALL-001', 'R01', 'USD', 1.0, acc.Id);
        Item_Weight__c iw             = createItemWeight(prod.Id, 5.0);
        Sales_Organization_Product__c sop = createSalesOrgProduct(prod.Id, 'SO-ALL', 50.0, 'USD');
        L1_L3_Product__c l1l3         = createL1L3Product(prod.Id, pl.Id, 'USD');

        TOP_Field_Staging__c stg = createStagingRecord(new Map<String, Object>{
            'product2Name__c'               => 'PROD-ALL-001',
            'partListName__c'               => 'PL-ALL-001',
            'partListRevisionNo__c'         => 'R01',
            'salesOrgId__c'                 => 'SO-ALL',
            // Block 1 — Part List
            'Direct_Quoted_Exchange_Rate__c' => 4.5,
            'partList_CurrencyIsoCode__c'   => 'AUD',
            // Block 2A — Item Weight
            'Net_Weight__c'                 => 88.0,
            // Block 2B — Sales Org Product
            'Price__c'                      => 600.0,
            'SOP_CurrencyIsoCode__c'        => 'AUD',
            // Block 3 — L1L3
            'Last_Sales_Date__c'            => Date.today(),
            'Last_Sales_Price__c'           => 750.0,
            'Order_Number__c'               => 'ORD-ALL-001',
            'L1L3_CurrencyIsoCode__c'       => 'AUD'
        });

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Completed', res.Status__c, 'All-in-one staging record should complete');
        System.assertEquals(null, res.Error_Log__c, 'No errors should be logged');

        pl   = [SELECT Direct_Quoted_Exchange_Rate__c, CurrencyIsoCode FROM Part_List__c WHERE Id = :pl.Id];
        iw   = [SELECT Net_Weight__c FROM Item_Weight__c WHERE Id = :iw.Id];
        sop  = [SELECT Price__c, CurrencyIsoCode FROM Sales_Organization_Product__c WHERE Id = :sop.Id];
        l1l3 = [SELECT Last_Sales_Price__c, Order_Number__c, CurrencyIsoCode FROM L1_L3_Product__c WHERE Id = :l1l3.Id];

        System.assertEquals(4.5,          pl.Direct_Quoted_Exchange_Rate__c, 'Part List exchange rate updated');
        System.assertEquals('AUD',         pl.CurrencyIsoCode,               'Part List currency updated');
        System.assertEquals(88.0,          iw.Net_Weight__c,                 'Item weight updated');
        System.assertEquals(600.0,         sop.Price__c,                     'SOP price updated');
        System.assertEquals('AUD',         sop.CurrencyIsoCode,              'SOP currency updated');
        System.assertEquals(750.0,         l1l3.Last_Sales_Price__c,         'L1L3 last sales price updated');
        System.assertEquals('ORD-ALL-001', l1l3.Order_Number__c,             'L1L3 order number updated');
        System.assertEquals('AUD',         l1l3.CurrencyIsoCode,             'L1L3 currency updated');
    }  */

    // =========================================================
    // MULTIPLE STAGING RECORDS IN ONE CHUNK
    // =========================================================

    @isTest
    static void testMultipleStagingRecords_ProcessedTogether() {
        Product2 prod1 = createProduct('PROD-MULTI-001');
        Product2 prod2 = createProduct('PROD-MULTI-002');
        createItemWeight(prod1.Id, 5.0);
        createItemWeight(prod2.Id, 8.0);

        List<TOP_Field_Staging__c> records = new List<TOP_Field_Staging__c>{
            new TOP_Field_Staging__c(product2Name__c = 'PROD-MULTI-001', Net_Weight__c = 12.0, Status__c = 'In Progress'),
            new TOP_Field_Staging__c(product2Name__c = 'PROD-MULTI-002', Net_Weight__c = 18.0, Status__c = 'In Progress'),
            new TOP_Field_Staging__c(product2Name__c = 'GHOST-MULTI',    Net_Weight__c = 5.0,  Status__c = 'In Progress')
        };
        insert records;

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        Map<Id, TOP_Field_Staging__c> resultMap = new Map<Id, TOP_Field_Staging__c>(
            [SELECT Status__c FROM TOP_Field_Staging__c WHERE Id IN :records]
        );

        System.assertEquals('Completed', resultMap.get(records[0].Id).Status__c, 'PROD-MULTI-001 should complete');
        System.assertEquals('Completed', resultMap.get(records[1].Id).Status__c, 'PROD-MULTI-002 should complete');
        System.assertEquals('Error',     resultMap.get(records[2].Id).Status__c, 'Ghost product should error');
    }

    // =========================================================
    // ERROR LOG CLEARED ON SUCCESSFUL RE-RUN
    // =========================================================

    @isTest
    static void testErrorLog_ClearedOnSuccess() {
        Account acc     = createAccount();
        Part_List__c pl = createPartList('PL-RETRY', 'R01', 'USD', 1.0, acc.Id);

        // Simulate a record that previously errored but is now re-submitted with valid data
        TOP_Field_Staging__c stg = new TOP_Field_Staging__c(
            partListName__c               = 'PL-RETRY',
            partListRevisionNo__c         = 'R01',
            Direct_Quoted_Exchange_Rate__c = 2.5,
            Status__c                     = 'In Progress',
            Error_Log__c                  = 'Previous error message from earlier run'
        );
        insert stg;

        Test.startTest();
        Database.executeBatch(new TOPFieldstagging(), 50);
        Test.stopTest();

        TOP_Field_Staging__c res = [SELECT Status__c, Error_Log__c FROM TOP_Field_Staging__c WHERE Id = :stg.Id];
        System.assertEquals('Completed', res.Status__c, 'Re-run with valid data should complete');
        System.assertEquals(null, res.Error_Log__c, 'Error log should be cleared (null) on success');
    }
}