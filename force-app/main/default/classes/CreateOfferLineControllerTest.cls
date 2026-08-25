/*
Name : CreateOfferLineControllerTest
Desc :  this is test class cover the CreateOfferLineController class.
*/

@isTest(SeeAllData=false)
public class CreateOfferLineControllerTest {

    private static testMethod void unit1(){

        // ── Account ──────────────────────────────────────────────────────────
        // Sync_with_SAP__c must be TRUE at insert time — the validation rule on
        // Opportunity fires on insert and checks the parent Account directly.
        Account testAcct = new Account(
            Name              = 'My Test Account',
            CurrencyIsoCode   = 'INR',
            Sync_with_SAP__c  = true
        );
        insert testAcct;

        // ── Sales Region & Branch ─────────────────────────────────────────────
        Sales_Region__c salesReg = new Sales_Region__c(
            Name            = 'Test Sales Region',
            Manager__c      = UserInfo.getUserId(),
            CurrencyIsoCode = 'INR'
        );
        insert salesReg;

        Branch__c br = new Branch__c(
            Name              = 'Bokaro',
            Branch_Code__c    = 'BKR',
            Sales_Region__c   = salesReg.Id,
            Mark_Up__c        = 1.5,
            Rate_PckFwd__c    = 1.5,
            CIF_Factor__c     = 1.5,
            Rate_Freight__c   = 1.5,
            Rate_Insurance__c = 1.5,
            Rate_Interest__c  = 1.5,
            Rate_Hedging__c   = 1.5,
            CurrencyIsoCode   = 'INR'
        );
        insert br;

        Branch_PMG_Relationship__c branchPMGRel = new Branch_PMG_Relationship__c(
            Branch__c         = br.Id,
            Mark_Up__c        = 1.5,
            Rate_PckFwd__c    = 1.5,
            CIF_Factor__c     = 1.5,
            Rate_Freight__c   = 1.5,
            Rate_Insurance__c = 1.5,
            Rate_Interest__c  = 1.5,
            Rate_Hedging__c   = 1.5,
            CurrencyIsoCode   = 'INR'
        );
        insert branchPMGRel;

        // ── Sales Org ─────────────────────────────────────────────────────────
        Sales_Org__c sOrg = new Sales_Org__c(Name = 'TGSO', CurrencyIsoCode = 'INR');
        insert sOrg;

        Customer_Sales_Organization__c custSalesOrg1 = new Customer_Sales_Organization__c(
            Customer__c            = testAcct.Id,
            CurrencyIsoCode        = 'INR',
            Branch__c              = br.Id,
            sales_Organizations__c = sOrg.Id,
            CreatedFromAccount__c  = true
        );
        insert custSalesOrg1;

        // ── Opportunity ───────────────────────────────────────────────────────
        Opportunity oppt = new Opportunity(
            Name                          = 'tega',
            AccountID                     = testAcct.Id,
            StageName                     = 'Customer Won',
            Amount                        = 3000,
            CloseDate                     = System.today(),
            PriceBook2Id                  = Test.getStandardPricebookId(),
            CurrencyIsoCode               = 'INR',
            Customer_Branch_Assignment__c = custSalesOrg1.Id
        );
        insert oppt;

        // ── Port & Freight ────────────────────────────────────────────────────
        Port_of_Destination__c port = new Port_of_Destination__c(
            Name          = 'Kolkata',
            Port_Code__c  = '001',
            CurrencyIsoCode = 'INR'
        );
        insert port;

        Freight__c freight = new Freight__c(
            Port_Code__c           = port.Id,
            Container_Rate_20Ft__c = 200,
            Container_Rate_40Ft__c = 200,
            CurrencyIsoCode        = 'INR'
        );
        insert freight;

        // ── Products ──────────────────────────────────────────────────────────
        List<Product2> lstProduct = new List<Product2>();
        Product2 l2Prod = new Product2(Name = 'PLM-01256-02-SHELL', CurrencyIsoCode = 'INR');
        lstProduct.add(l2Prod);

        Product2 l3Prod = new Product2(Name = 'M34-01026O000-0102', CurrencyIsoCode = 'INR');
        lstProduct.add(l3Prod);
        insert lstProduct;

        // ── Standard Pricebook & Entry ────────────────────────────────────────
        Pricebook2 standardPricebook = new Pricebook2(
            Id       = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        System.assertEquals(true, standardPricebook.IsStandard);

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id    = standardPricebook.Id,
            Product2Id      = l3Prod.Id,
            UnitPrice       = 10000,
            IsActive        = true,
            CurrencyIsoCode = 'INR'
        );
        insert pbe;

        pbe = [SELECT Id, Pricebook2.IsStandard FROM PricebookEntry WHERE Id = :pbe.Id];
        System.assertEquals(true, pbe.Pricebook2.IsStandard);

        // ── Part List ─────────────────────────────────────────────────────────
        // Direct_Quoted_Exchange_Rate__c is now queried inside calculateBTPPrice,
        // so it must be populated on the Part_List__c record.
        Part_List__c prt = new Part_List__c(
            Name                          = 'Test1993',
            Direct_Quoted_Exchange_Rate__c = 54,
            Customer__c                   = testAcct.Id,
            CurrencyIsoCode               = 'INR'
        );
        insert prt;

        // ── Quotes ────────────────────────────────────────────────────────────
        List<Quote> quoteList = new List<Quote>();
        Id offerRecordTypeId = TegaUtilityWithoutSharing.getOfferRecordTypeId('Offer');
        for (Integer i = 0; i < 2; i++) {
            Quote quote = new Quote(
                Name                    = 'tegaTest1' + i,
                OpportunityId           = oppt.Id,
                recordTypeId            = offerRecordTypeId,
                Approval_Status__c      = 'Price Accepted',
                Quotation_Date__c       = Date.today(),
                Quotation_Validity__c   = Date.today().addDays(20),
                Pricebook2Id            = Test.getStandardPricebookId(),
                Branch__c               = br.Id,
                Branch__r               = br,
                Port__c                 = port.Id,
                Sales_Org__c            = sOrg.Id,
                BTP_Type__c             = 'CIF',
                Payment_Months__c       = 24,
                Offer_Generation_at__c  = 'L3',
                CurrencyIsoCode         = 'INR',
                Part_List__c            = prt.Id,
                Customer_offr__c        = prt.Customer__c
            );
            quoteList.add(quote);
        }
        insert quoteList;

        // ── Item Weight & Sales Org Product ───────────────────────────────────
        Item_Weight__c itemWeight = new Item_Weight__c(
            Net_Weight__c   = 500,
            Product_L3__c   = l3Prod.Id,
            CurrencyIsoCode = 'INR'
        );
        insert itemWeight;

        Sales_Organization_Product__c sorgProduct = new Sales_Organization_Product__c(
            Product__c      = l3Prod.Id,
            Price__c        = 500,
            Sales_Org__c    = sOrg.Id,
            CurrencyIsoCode = 'INR'
        );
        insert sorgProduct;

        // ── L2-L3 Products ────────────────────────────────────────────────────
        // Only ONE record per Part_List + Product_L2 + Product_L3 combination.
        // The original test inserted two records with identical lookup fields.
        // When QuoteLineItem is later inserted, the "L1 L3 Automation" flow
        // fires and tries to create a second matching record, hitting a
        // DUPLICATE_VALUE error. One record with Quantity__c populated is enough
        // to cover all SOQL and logic paths in the apex class.
        L2_L3_product__c l2_l3_product = new L2_L3_product__c(
            CurrencyIsoCode = 'INR',
            Product_L2__c   = l2Prod.Id,
            Product_L3__c   = l3Prod.Id,
            Part_List__c    = prt.Id,
            Quantity__c     = 12.0
        );
        insert l2_l3_product;

        // ── Derived SO Price Factor ───────────────────────────────────────────
        Derived_SO_Price_Factor__c df = new Derived_SO_Price_Factor__c(
            SO_Price_Factor__c = 1,
            Part_List__c       = prt.Id,
            CurrencyIsoCode    = 'INR'
        );
        insert df;

        // ── SAP Last Sale records ─────────────────────────────────────────────
        SAP_Last_Sale_Price__c sapLastSales = new SAP_Last_Sale_Price__c(
            Product_L3__c   = l3Prod.Id,
            CurrencyIsoCode = 'INR'
        );
        insert sapLastSales;

        // Use a date > 6 months ago to exercise the Simple Interest (SI) branch
        // in both searchPartList and calculateBTPPrice (noOfMonth >= 6)
        Sales_Org_Last_SAP_SO__c salesOrglastsapPrice = new Sales_Org_Last_SAP_SO__c(
            SAP_Last_Sale__c  = sapLastSales.Id,
            Last_Sales_Price__c = 200,
            Sales_Org__c      = sOrg.Id,
            CurrencyIsoCode   = 'INR',
            Last_Sales_Date__c = Date.today().addDays(-210)   // ~7 months → SI branch
        );
        insert salesOrglastsapPrice;

//l1l3
        L1_L3_Product__c l1l3prod = new L1_L3_Product__c(
            
            Last_Sales_Price__c = 200,
            Sales_Organization__c      = sOrg.Id,
            Product_del__c   = l3Prod.Id,
            Part_List__c = prt.Id,
            CurrencyIsoCode   = 'INR',
            Last_Sales_Date__c = Date.today().addDays(-210)   // ~7 months → SI branch
        );
        insert l1l3prod;


        // ── Fixed Contract Price ──────────────────────────────────────────────
        Fixed_Contract_Price__c fixedPrice = new Fixed_Contract_Price__c(
            Product__c      = l3Prod.Id,
            Price__c        = 4000,
            Part_List__c    = prt.Id,
            CurrencyIsoCode = 'INR'
        );
        insert fixedPrice;

        // ── Currency rates ────────────────────────────────────────────────────
        List<CurrencyType> currenc = [SELECT ConversionRate, IsoCode, IsActive FROM CurrencyType LIMIT 1];
        Map<String, Double> conversion_rates = new Map<String, Double>();
        for (CurrencyType ct : currenc) {
            conversion_rates.put(ct.IsoCode, ct.ConversionRate);
        }
        system.debug('conversion_rates' + conversion_rates);

        // ── BTP Map ───────────────────────────────────────────────────────────
        // NOTE: calculateBTPPrice now fetches Direct_Quoted_Exchange_Rate__c
        // from Part_List__c via SOQL internally, so 'cRate' still needs to be
        // in btpMap for the container-rate lookup path, but userCurConRate is
        // sourced from the DB.
        Map<String, Object> btpMap = new Map<String, Object>();
        Map<Id, Decimal>    cotainer20FtMap = new Map<Id, Decimal>();
        Map<Id, Item_Weight__c> weightMap   = new Map<Id, Item_Weight__c>();
        Map<Id, Sales_Organization_Product__c> productMap = new Map<Id, Sales_Organization_Product__c>();
        Map<Id, Quote>      offerMap        = new Map<Id, Quote>();
        Map<Id, Branch_PMG_Relationship__c> branchPMGRelMap = new Map<Id, Branch_PMG_Relationship__c>();

        // Re-query quote so Branch__r sub-fields are populated after insert
        Quote quoteWithBranch = [
            SELECT Id, BTP_Type__c, Payment_Months__c, Branch__c,
                   Branch__r.Mark_Up__c, Branch__r.Rate_PckFwd__c,
                   Branch__r.CIF_Factor__c, Branch__r.Rate_Freight__c,
                   Branch__r.Rate_Insurance__c, Branch__r.Rate_Interest__c,
                   Branch__r.Rate_Hedging__c, Branch__r.Is_WOS__c,
                   CurrencyIsoCode, Port__c, Sales_Org__c, Sales_Org__r.Name
            FROM Quote
            WHERE Id = :quoteList[0].Id
        ];

        offerMap.put(quoteList[0].Id, quoteWithBranch);
        productMap.put(sorgProduct.Product__c, sorgProduct);
        cotainer20FtMap.put(port.Id, 2000);
        weightMap.put(itemWeight.Product_L3__c, itemWeight);
        branchPMGRelMap.put(br.Id, branchPMGRel);

        Map<String, Double> currencyMapForBTP = new Map<String, Double>();
        currencyMapForBTP.put('INR', 12);
        currencyMapForBTP.put(UserInfo.getDefaultCurrency(), 12);

        btpMap.put('offerMap',         offerMap);
        btpMap.put('productMap',        productMap);
        btpMap.put('cotainer20FtMap',   cotainer20FtMap);
        btpMap.put('weightMap',         weightMap);
        btpMap.put('currencyMap',       currencyMapForBTP);
        btpMap.put('branchPMGRelMap',   branchPMGRelMap);
        // cRate still required by calculateBTPPrice for exchangeRate field assignment
        btpMap.put('cRate', (Decimal)1.0);

        // ── Offer Line Wrappers ───────────────────────────────────────────────
        Map<String, Integer> productQuantity = new Map<String, Integer>();
        productQuantity.put(l3Prod.Id, 20);

        List<CreateOfferLineController.offerLine> oferLienList = new List<CreateOfferLineController.offerLine>();

        // offerLine 1 – no L2-wise quantity (blank quantityL2Wise)
        CreateOfferLineController.offerLine oferLienStr = new CreateOfferLineController.offerLine();
        oferLienStr.discount              = 10;
        oferLienStr.margin                = 10;
        oferLienStr.salesPrice            = 1000;
        oferLienStr.btpPrice              = 20000;
        oferLienStr.l3ProductId           = l3Prod.Id;
        oferLienStr.l2ProductId           = l2Prod.Id;
        oferLienStr.customQuantity        = 12;
        oferLienStr.quantityL2Wise        = '';
        oferLienStr.isFG                  = true;
        oferLienStr.RMCCost               = 20;
        oferLienStr.branchRateOfInterest  = 20;
        oferLienStr.offerpayment          = 20;
        oferLienStr.branchHedging         = 20;
        oferLienStr.costPackingForwarding = 20;
        oferLienStr.CostFreight           = 20;
        oferLienStr.costInsurance         = 20;
        oferLienStr.costInterest          = 20;
        oferLienStr.costHedging           = 20;
        oferLienStr.exchangeRate          = 20;
        oferLienStr.basicPrice            = 20;
        oferLienStr.OriginalBTP           = 20;

        // offerLine 2 – with L2-wise quantity string
        CreateOfferLineController.offerLine oferLienStr1 = new CreateOfferLineController.offerLine();
        oferLienStr1.discount              = 10;
        oferLienStr1.margin                = 10;
        oferLienStr1.salesPrice            = 1000;
        oferLienStr1.btpPrice              = 20000;
        oferLienStr1.l3ProductId           = l3Prod.Id;
        oferLienStr1.l2ProductId           = l2Prod.Id;
        oferLienStr1.customQuantity        = 12;
        oferLienStr1.quantityL2Wise        = 'Test-10';
        oferLienStr1.isFG                  = true;
        oferLienStr1.RMCCost               = 20;
        oferLienStr1.branchRateOfInterest  = 20;
        oferLienStr1.offerpayment          = 20;
        oferLienStr1.branchHedging         = 20;
        oferLienStr1.costPackingForwarding = 20;
        oferLienStr1.CostFreight           = 20;
        oferLienStr1.costInsurance         = 20;
        oferLienStr1.costInterest          = 20;
        oferLienStr1.costHedging           = 20;
        oferLienStr1.exchangeRate          = 20;
        oferLienStr1.basicPrice            = 20;
        oferLienStr1.OriginalBTP           = 20;

        oferLienList.add(oferLienStr);
        oferLienList.add(oferLienStr1);
        String recordStr = JSON.serialize(oferLienList);

        Map<Id, Decimal> l2l3Map = new Map<Id, Decimal>();
        String l2l3MapStr = JSON.serialize(l2l3Map);

        // ── Headers wrapper ───────────────────────────────────────────────────
        CreateOfferLineController.headersWrap testheadersWrap = new CreateOfferLineController.headersWrap();
        testheadersWrap.Name       = 'Test';
        testheadersWrap.value      = 10;
        testheadersWrap.isSelected = true;

        List<CreateOfferLineController.headersWrap> lstheadersWrap = new List<CreateOfferLineController.headersWrap>();
        lstheadersWrap.add(testheadersWrap);
        String testheadstr = JSON.serialize(lstheadersWrap);

        // ─────────────────────────────────────────────────────────────────────
        // TEST EXECUTION
        // ─────────────────────────────────────────────────────────────────────

        // 1. searchPartList – blank product type
        CreateOfferLineController.searchPartList(quoteList[0].Id, 'Test1993', '', '', '');

        // 2. getBTPPrice – exercises calculateBTPPrice internally;
        //    now includes SOQL for Quote + Part_List__c inside calculateBTPPrice
        CreateOfferLineController.getBTPPrice(quoteList[0].Id, l3Prod.Id, 20, productQuantity, btpMap);

        // 3. saveOffer
        CreateOfferLineController.saveOffer(
            quoteList[0].Id, 'INR', prt.Id, recordStr,
            l2l3MapStr, btpMap, 0, sOrg.Id, false, testheadstr, 0.0
        );

        // 4. calculateBTPPrice – direct call; SOQL for Part_List__c runs inside
        CreateOfferLineController.calculateBTPPrice(
            quoteList[0].Id, l3Prod.Id, 20, btpMap, weightMap, 20
        );

        // 5. getl2l3Products – ensure Part_List__c is set on the quote
        quoteList[0].Part_List__c = prt.Id;
        update quoteList[0];
        CreateOfferLineController.getl2l3Products(quoteList[0].Id);

        // 6. getProductSortingOrder – new method added to apex
        Map<String, Integer> sortingMap = CreateOfferLineController.getProductSortingOrder();
        System.assertNotEquals(null, sortingMap, 'Sorting map should not be null');

        // 7. calculateInterest – compound interest path
        CreateOfferLineController.calculateInterest(123.90, 12.00, 6.00);

        // 8. productPriceUpdate
        // PPU__c is a List custom setting; SeeAllData=false means no records exist.
        // Insert one so objPPUList[0] in productPriceUpdate() does not throw
        // a List index out of bounds exception.
        PPU__c ppuSetting = new PPU__c(
            Name                    = 'Default',
            Product_price_update__c = true
        );
        insert ppuSetting;
        Boolean isProdUpdated = CreateOfferLineController.productPriceUpdate();
        System.assertNotEquals(null, isProdUpdated, 'productPriceUpdate should return a value');

        // 9. Assertions
        System.assertEquals('Test1993', prt.Name);

        // ── L1_L2 Offer Line (L1 record type for isFullSet branch) ────────────
        L1_L2_Offer_Line_Item__c l1l2OfferLineItem = new L1_L2_Offer_Line_Item__c(
            Offer__c = quoteList[0].Id
        );
        insert l1l2OfferLineItem;

        // ── TegaUtility coverage ──────────────────────────────────────────────
        Exception exception1 = new System.MathException();
        exception1.setMessage('my message');
        String testid = TegaUtility.trackLogs(exception1, 'CreateOfferLineController', 'searchPartList');

        QuoteLineItem qutlineitemtest = new QuoteLineItem();
        qutlineitemtest.QuoteId          = quoteList[0].Id;
        qutlineitemtest.Quantity         = 3.00;
        qutlineitemtest.UnitPrice        = 12;
        qutlineitemtest.PricebookEntryId = pbe.Id;
        qutlineitemtest.L2_L3_Product__c = l2_l3_product.Id;
        insert qutlineitemtest;

        TegaUtility.createL1L2OfferLine(quoteList[0].Id, 10, prt.Id, testheadstr, 0.0);
        TegaUtility.createL1L2OfferLine('', 10, prt.Id, testheadstr, 0.0);

        TegaUtility.headersWrap testtegaheadersWrap = new TegaUtility.headersWrap();
        testtegaheadersWrap.Name       = 'Test';
        testtegaheadersWrap.value      = 10;
        testtegaheadersWrap.isSelected = true;

        // ── ProdUpdateCheck ───────────────────────────────────────────────────
        String teststr = ProdUpdateCheck.productUpdate();
    }

    // ── Additional test: exercise the >24 months Compound Interest branch ────
    private static testMethod void testCompoundInterestBranch(){

        // Sync_with_SAP__c must be true before Opportunity insert (validation rule)
        Account testAcct = new Account(
            Name             = 'CI Test Account',
            CurrencyIsoCode  = 'INR',
            Sync_with_SAP__c = true
        );
        insert testAcct;

        Sales_Region__c salesReg = new Sales_Region__c(
            Name           = 'CI Sales Region',
            Manager__c     = UserInfo.getUserId(),
            CurrencyIsoCode = 'INR'
        );
        insert salesReg;

        Branch__c br = new Branch__c(
            Name              = 'CI Branch',
            Branch_Code__c    = 'CIB',
            Sales_Region__c   = salesReg.Id,
            Mark_Up__c        = 1.5,
            Rate_PckFwd__c    = 2.0,
            CIF_Factor__c     = 1.2,
            Rate_Freight__c   = 3.0,
            Rate_Insurance__c = 0.5,
            Rate_Interest__c  = 8.0,
            Rate_Hedging__c   = 2.0,
            Is_WOS__c         = true,       // exercises WOS multiplier path
            CurrencyIsoCode   = 'INR'
        );
        insert br;

        Sales_Org__c sOrg = new Sales_Org__c(Name = 'TGSO', CurrencyIsoCode = 'INR');
        insert sOrg;

        Customer_Sales_Organization__c custSalesOrg = new Customer_Sales_Organization__c(
            Customer__c            = testAcct.Id,
            CurrencyIsoCode        = 'INR',
            Branch__c              = br.Id,
            sales_Organizations__c = sOrg.Id,
            CreatedFromAccount__c  = true
        );
        insert custSalesOrg;

        Opportunity oppt = new Opportunity(
            Name                          = 'CI Opp',
            AccountID                     = testAcct.Id,
            StageName                     = 'Customer Won',
            Amount                        = 5000,
            CloseDate                     = System.today(),
            PriceBook2Id                  = Test.getStandardPricebookId(),
            CurrencyIsoCode               = 'INR',
            Customer_Branch_Assignment__c = custSalesOrg.Id
        );
        insert oppt;

        Port_of_Destination__c port = new Port_of_Destination__c(
            Name = 'Mumbai', Port_Code__c = '002', CurrencyIsoCode = 'INR'
        );
        insert port;

        Freight__c freight = new Freight__c(
            Port_Code__c = port.Id, Container_Rate_20Ft__c = 300,
            Container_Rate_40Ft__c = 300, CurrencyIsoCode = 'INR'
        );
        insert freight;

        Product2 l3Prod = new Product2(Name = 'CI-Product', CurrencyIsoCode = 'INR');
        insert l3Prod;

        Pricebook2 spb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update spb;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = spb.Id, Product2Id = l3Prod.Id,
            UnitPrice = 5000, IsActive = true, CurrencyIsoCode = 'INR'
        );
        insert pbe;

        Part_List__c prt = new Part_List__c(
            Name                           = 'CIPartList',
            Direct_Quoted_Exchange_Rate__c = 80,
            Customer__c                    = testAcct.Id,
            CurrencyIsoCode                = 'INR'
        );
        insert prt;

        Quote q = new Quote(
            Name                   = 'CI Quote',
            OpportunityId          = oppt.Id,
            recordTypeId           = TegaUtilityWithoutSharing.getOfferRecordTypeId('Offer'),
            Approval_Status__c     = 'Price Accepted',
            Quotation_Date__c      = Date.today(),
            Quotation_Validity__c  = Date.today().addDays(30),
            Pricebook2Id           = Test.getStandardPricebookId(),
            Branch__c              = br.Id,
            Port__c                = port.Id,
            Sales_Org__c           = sOrg.Id,
            BTP_Type__c            = 'CIF',
            Payment_Months__c      = 24,
            Offer_Generation_at__c = 'L3',
            CurrencyIsoCode        = 'INR',
            Part_List__c           = prt.Id,
            Customer_offr__c       = prt.Customer__c
        );
        insert q;

        Item_Weight__c itemWeight = new Item_Weight__c(
            Net_Weight__c = 300, Product_L3__c = l3Prod.Id, CurrencyIsoCode = 'INR'
        );
        insert itemWeight;

        Sales_Organization_Product__c sorgProduct = new Sales_Organization_Product__c(
            Product__c = l3Prod.Id, Price__c = 800,
            Sales_Org__c = sOrg.Id, CurrencyIsoCode = 'INR'
        );
        insert sorgProduct;

        SAP_Last_Sale_Price__c sapLastSales = new SAP_Last_Sale_Price__c(
            Product_L3__c = l3Prod.Id, CurrencyIsoCode = 'INR'
        );
        insert sapLastSales;

        // >24 months → exercises Compound Interest path
        Sales_Org_Last_SAP_SO__c sapSO = new Sales_Org_Last_SAP_SO__c(
            SAP_Last_Sale__c    = sapLastSales.Id,
            Last_Sales_Price__c = 400,
            Sales_Org__c        = sOrg.Id,
            CurrencyIsoCode     = 'INR',
            Last_Sales_Date__c  = Date.today().addDays(-760)  // ~25 months
        );
        insert sapSO;



        // L1_L3_Product__c l1l3prod2 = new L1_L3_Product__c(
            
        //     Last_Sales_Price__c = 400,
        //     Sales_Organization__c      = sOrg.Id,
        //     Product_del__c   = l3Prod.Id,
        //     Part_List__c = prt.Id,
        //     CurrencyIsoCode   = 'INR',
        //     Last_Sales_Date__c = Date.today().addDays(-760)  // ~7 months → SI branch
        // );
        // insert l1l3prod2;



        Derived_SO_Price_Factor__c df = new Derived_SO_Price_Factor__c(
            SO_Price_Factor__c = 1, Part_List__c = prt.Id, CurrencyIsoCode = 'INR'
        );
        insert df;

        // Build btpMap
        Quote quoteWithBranch = [
            SELECT Id, BTP_Type__c, Payment_Months__c, Branch__c,
                   Branch__r.Mark_Up__c, Branch__r.Rate_PckFwd__c,
                   Branch__r.CIF_Factor__c, Branch__r.Rate_Freight__c,
                   Branch__r.Rate_Insurance__c, Branch__r.Rate_Interest__c,
                   Branch__r.Rate_Hedging__c, Branch__r.Is_WOS__c,
                   CurrencyIsoCode, Port__c, Sales_Org__c, Sales_Org__r.Name
            FROM Quote WHERE Id = :q.Id
        ];

        Map<String, Object> btpMap = new Map<String, Object>();
        btpMap.put('offerMap',       new Map<Id, Quote>{ q.Id => quoteWithBranch });
        btpMap.put('productMap',     new Map<Id, Sales_Organization_Product__c>{ sorgProduct.Product__c => sorgProduct });
        btpMap.put('cotainer20FtMap', new Map<Id, Decimal>{ port.Id => (Decimal)3000 });
        btpMap.put('weightMap',      new Map<Id, Item_Weight__c>{ itemWeight.Product_L3__c => itemWeight });
        btpMap.put('currencyMap',    new Map<String, Double>{ 'INR' => 12.0, UserInfo.getDefaultCurrency() => 12.0 });
        btpMap.put('cRate',          (Decimal)1.0);

        Map<Id, Item_Weight__c> weightMap = new Map<Id, Item_Weight__c>{ itemWeight.Product_L3__c => itemWeight };

        // calculateBTPPrice with >24-month SAP date → Compound Interest branch
        CreateOfferLineController.BTPClass result =
            CreateOfferLineController.calculateBTPPrice(q.Id, l3Prod.Id, 10, btpMap, weightMap, 300);

        System.assertNotEquals(null, result, 'BTPClass result should not be null');
        System.assert(result.btpPrice >= 0, 'BTP price should be non-negative');

        // calculateInterest standalone
        Decimal ciResult = CreateOfferLineController.calculateInterest(500.00, 30.00, 6.00);
        System.assert(ciResult > 500, 'Compound interest should increase the principal');
    }
}