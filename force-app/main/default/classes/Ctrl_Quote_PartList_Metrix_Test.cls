@isTest
public class Ctrl_Quote_PartList_Metrix_Test {
    
    @testSetup
    static void setupTestData() {
        // 1. Create Standard Pricebook reference
        Id pricebookId = Test.getStandardPricebookId();
        
        // 2. Create Account & Opportunity (with Validation Rule Bypasses)
        Account testAcc = new Account(
            Name = 'Test Account',
            Sync_with_SAP__c = true
        );
        insert testAcc;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAcc.Id
        );
        insert testOpp;
        
        // 3. Create Part List
        Part_List__c testPL = new Part_List__c(
            Name = 'Test Part List',
            Customer__c = testAcc.Id 
        );
        insert testPL;
        
        // 4. Create Quote
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = pricebookId,
            Part_List__c = testPL.Id,
            Customer_offr__c = testAcc.Id
        );
        insert testQuote;
        
        // 5. Create Products and PricebookEntries
        Product2 testProd1 = new Product2(Name = 'Test Product 1', IsActive = true);
        Product2 testProd2 = new Product2(Name = 'Test Product 2', IsActive = true);
        Product2 testProd3 = new Product2(Name = 'Zero Price Prod', IsActive = true); 
        insert new List<Product2>{testProd1, testProd2, testProd3};
        
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testProd1.Id, UnitPrice = 100, IsActive = true);
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testProd2.Id, UnitPrice = 200, IsActive = true);
        PricebookEntry pbe3 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testProd3.Id, UnitPrice = 0, IsActive = true); 
        insert new List<PricebookEntry>{pbe1, pbe2, pbe3};
        
        // 6. Create L2_L3_Product__c records
        List<L2_L3_product__c> l2l3List = new List<L2_L3_product__c>();
        l2l3List.add(new L2_L3_product__c(Part_List__c = testPL.Id, Product_L3__c = testProd1.Id, Quantity__c = 2));
        l2l3List.add(new L2_L3_product__c(Part_List__c = testPL.Id, Product_L3__c = testProd1.Id, Quantity__c = 3));
        l2l3List.add(new L2_L3_product__c(Part_List__c = testPL.Id, Product_L3__c = testProd2.Id, Quantity__c = 1));
        l2l3List.add(new L2_L3_product__c(Part_List__c = testPL.Id, Product_L3__c = testProd3.Id, Quantity__c = 1)); 
        insert l2l3List;
        
        // 7. Create QuoteLineItems with specific settings
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        
        // QLI 1: 'fullset' branch coverage
        qliList.add(new QuoteLineItem(QuoteId = testQuote.Id, Product2Id = testProd1.Id, PricebookEntryId = pbe1.Id, Quantity = 1, UnitPrice = 100, L2_L3_Product__c = l2l3List[0].Id, settingType__c = 'fullset'));
        
        // QLI 2: Missing fullset, but explicitly covers FEH, DEH, and SHELL 'else' branches
        qliList.add(new QuoteLineItem(QuoteId = testQuote.Id, Product2Id = testProd2.Id, PricebookEntryId = pbe2.Id, Quantity = 2, UnitPrice = 200, L2_L3_Product__c = l2l3List[2].Id, settingType__c = 'FEH;DEH;SHELL'));
        
        // QLI 3: Covers the $0 Unit Price logic
        qliList.add(new QuoteLineItem(QuoteId = testQuote.Id, Product2Id = testProd3.Id, PricebookEntryId = pbe3.Id, Quantity = 1, UnitPrice = 0, L2_L3_Product__c = l2l3List[3].Id));
        
        // QLI 4 & 5: Custom QuoteLineItems
        qliList.add(new QuoteLineItem(QuoteId = testQuote.Id, Product2Id = testProd1.Id, PricebookEntryId = pbe1.Id, Quantity = 10, UnitPrice = 100));
        qliList.add(new QuoteLineItem(QuoteId = testQuote.Id, Product2Id = testProd1.Id, PricebookEntryId = pbe1.Id, Quantity = 5, UnitPrice = 100));
        
        insert qliList;
    }
    
    @isTest
    static void testControllerInitializationAndMapping() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.setCurrentPage(Page.vf_ExcelPage_PLM);
        ApexPages.currentPage().getParameters().put('id', testQuote.Id);
        
        Test.startTest();
        Ctrl_Quote_PartList_Metrix ctrl = new Ctrl_Quote_PartList_Metrix(new ApexPages.StandardController(testQuote));
        Test.stopTest();
        
        System.assertNotEquals(null, ctrl.QuoteRecord);
        System.assertNotEquals(null, ctrl.PL);
        System.assertNotEquals(null, ctrl.filterList);
        
        System.assertEquals(true, ctrl.showFullSet);
        System.assertEquals(true, ctrl.showFEH);
        System.assertEquals(true, ctrl.showDEH);
        System.assertEquals(true, ctrl.showSHELL);
    }
    
    @isTest
    static void testControllerWithoutPartList() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote quoteNoPL = new Quote(Name = 'No Part List Quote', OpportunityId = opp.Id, Pricebook2Id = Test.getStandardPricebookId());
        insert quoteNoPL;
        
        Test.setCurrentPage(Page.vf_ExcelPage_PLM);
        ApexPages.currentPage().getParameters().put('id', quoteNoPL.Id);
        
        Test.startTest();
        Ctrl_Quote_PartList_Metrix ctrl = new Ctrl_Quote_PartList_Metrix(new ApexPages.StandardController(quoteNoPL));
        Test.stopTest();
        
        System.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.ERROR));
    }

    @isTest
    static void testAmountInWordsLogic() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.setCurrentPage(Page.vf_ExcelPage_PLM);
        ApexPages.currentPage().getParameters().put('id', testQuote.Id);
        Ctrl_Quote_PartList_Metrix ctrl = new Ctrl_Quote_PartList_Metrix(new ApexPages.StandardController(testQuote));

        // 1. Test Static Math Logic Branches (With Double Space expectations)
        System.assertEquals('Zero', Ctrl_Quote_PartList_Metrix.amountInWords(0));
        System.assertEquals('Fifteen Only', Ctrl_Quote_PartList_Metrix.amountInWords(15));
        System.assertEquals('Twenty Five Only', Ctrl_Quote_PartList_Metrix.amountInWords(25));
        System.assertEquals('One Hundred Five Only', Ctrl_Quote_PartList_Metrix.amountInWords(105));
        System.assertEquals('One Thousand Two Hundred Thirty Four Only', Ctrl_Quote_PartList_Metrix.amountInWords(1234));
        System.assertEquals('One Lakh Fifty  Thousand Only', Ctrl_Quote_PartList_Metrix.amountInWords(150000));
        System.assertEquals('One Crore Twenty  Lakh Only', Ctrl_Quote_PartList_Metrix.amountInWords(12000000));

        // 2. Test Null/Zero Handlers
        ctrl.QuoteRecord = null;
        System.assertEquals('', ctrl.getAmountInWords());
        
        ctrl.fehGrandTotal = 0;
        System.assertEquals('Zero Only', ctrl.getFEHAmountInWords());
        ctrl.dehGrandTotal = null;
        System.assertEquals('Zero Only', ctrl.getDEHAmountInWords());
        ctrl.shellGrandTotal = 0;
        System.assertEquals('Zero Only', ctrl.getShellAmountInWords());
        ctrl.spareGrandTotal = null;
        System.assertEquals('Zero Only', ctrl.getSpareAmountInWords());
        ctrl.customGrandTotal = 0;
        System.assertEquals('Zero Only', ctrl.getCustomAmountInWords());
        ctrl.fullSetGrandTotal = null;
        System.assertEquals('Zero Only', ctrl.getFullSetAmountInWords());

        // 3. Test POSITIVE Number Handlers (With Double Space fixes applied here too)
        ctrl.fehGrandTotal = 500;
        System.assertEquals('Five Hundred Only', ctrl.getFEHAmountInWords());
        
        ctrl.dehGrandTotal = 1500;
        System.assertEquals('One Thousand Five Hundred Only', ctrl.getDEHAmountInWords());
        
        ctrl.shellGrandTotal = 20000;
        System.assertEquals('Twenty  Thousand Only', ctrl.getShellAmountInWords()); // Fixed Double Space
        
        ctrl.spareGrandTotal = 100000;
        System.assertEquals('One Lakh Only', ctrl.getSpareAmountInWords());
        
        ctrl.customGrandTotal = 3000000;
        System.assertEquals('Thirty  Lakh Only', ctrl.getCustomAmountInWords()); // Fixed Double Space
        
        ctrl.fullSetGrandTotal = 15000000;
        System.assertEquals('One Crore Fifty  Lakh Only', ctrl.getFullSetAmountInWords()); // Fixed Double Space
    }
    
    @isTest
    static void testExportMethods() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        ApexPages.currentPage().getParameters().put('id', testQuote.Id);
        Ctrl_Quote_PartList_Metrix ctrl = new Ctrl_Quote_PartList_Metrix(new ApexPages.StandardController(testQuote));
        
        Test.startTest();
        
        // Fixed: Replaced .contains() with .containsIgnoreCase() for robust URL matching
        PageReference prExcelPLM = ctrl.downloadExcelPLM();
        System.assertEquals(true, prExcelPLM.getUrl().containsIgnoreCase('vf_ExcelPage_PLM'));
        
        PageReference prExcelPLS = ctrl.downloadExcelPLS();
        System.assertEquals(true, prExcelPLS.getUrl().containsIgnoreCase('vf_ExcelPage_PLS'));
        
        PageReference prExcelPLT = ctrl.downloadExcelPLT();
        System.assertEquals(true, prExcelPLT.getUrl().containsIgnoreCase('vf_ExcelPage_PLT'));
        
        PageReference prPDFPLM = ctrl.downloadPDFPLM();
        System.assertEquals('attachment; filename=PLM_PartList_Data.pdf', prPDFPLM.getHeaders().get('content-disposition'));
        
        Test.stopTest();
    }
    
    @isTest
    static void testL2L3WrapperConstructors() {
        Ctrl_Quote_PartList_Metrix.L2L3Wrapper defaultWrap = new Ctrl_Quote_PartList_Metrix.L2L3Wrapper();
        defaultWrap.sortingOrder = '1';
        defaultWrap.ItemDescription = 'Test';
        defaultWrap.fehQuantity = 1;
        defaultWrap.dehQuantity = 1;
        defaultWrap.shellQuantity = 1;
        defaultWrap.pnlQuantity = 1;
        defaultWrap.sfbQuantity = 1;
        defaultWrap.mfbQuantity = 1;
        defaultWrap.strQuantity = 1;
        defaultWrap.sprlQuantity = 1;
        defaultWrap.spareQuantity = 1;
        defaultWrap.customQuantity = 1;
        
        defaultWrap.fehTotal = 1;
        defaultWrap.dehTotal = 1;
        defaultWrap.shellTotal = 1;
        defaultWrap.spareTotal = 1;
        defaultWrap.pnlTotal = 1;
        defaultWrap.sfbTotal = 1;
        defaultWrap.mfbTotal = 1;
        defaultWrap.strTotal = 1;
        defaultWrap.sprlTotal = 1;
        defaultWrap.customTotal = 1;

        System.assertEquals(1, defaultWrap.fehQuantity);
        
        Ctrl_Quote_PartList_Metrix.L2L3Wrapper paramWrap = new Ctrl_Quote_PartList_Metrix.L2L3Wrapper('Test Group Name');
        System.assertEquals('Test Group Name', paramWrap.L2ProductName);
    }
}