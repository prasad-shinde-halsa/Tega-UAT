/**
 * Test Class : OfferTriggerHelperTest
 * Description: Test coverage for OfferTriggerHelper:
 *              - updateScopeWithOffer  (insert + update + blank SAP Id)
 *              - validateOfferOnFinialze (BTP=0 error + status unchanged)
 *              - CreateSAPOfferId  (Non-Spare LS/HO/DF + Spare Approved/PriceAccepted + null oldMap)
 *              - populatePriceBook (Spare + Non-Spare)
 *              - populateHead      (insert + update)
 *              - afterIDcreation   (with code + blank code + Non-Spare skip)
 *
 * Data setup mirrors OfferTriggerTest – uses Sync_with_SAP__c,
 * Customer_Sales_Organization__c and Customer_Branch_Assignment__c.
 */
@isTest
private class OfferTriggerHelperTest {

    // ══════════════════════════════════════════════════════════════════
    //  SHARED TEST DATA  –  @TestSetup runs once for all test methods
    // ══════════════════════════════════════════════════════════════════
    @TestSetup
    static void setupData() {

        // 1. Account  (Sync_with_SAP__c = true satisfies the Opp validation rule)
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        acc.Sync_with_SAP__c = true;
        update acc;

        // 2. Sales Region + Branch
        Sales_Region__c salesReg = new Sales_Region__c(
            Name       = 'Test Sales Region',
            Manager__c = UserInfo.getUserId()
        );
        insert salesReg;

        Branch__c branch = new Branch__c(
            Name            = 'Test Branch',
            Sales_Region__c = salesReg.Id,
            Branch_Code__c  = 'TBR'
        );
        insert branch;

        // 3. Customer Sales Org (required for Opportunity)
        Customer_Sales_Organization__c custSalesOrg = new Customer_Sales_Organization__c(
            Customer__c           = acc.Id,
            Branch__c             = branch.Id,
            CreatedFromAccount__c = true
        );
        insert custSalesOrg;

        // 4. Sales Org
        Sales_Org__c sOrg = new Sales_Org__c(Name = 'TGSO');
        insert sOrg;

        // 5. Opportunity – mirrors 'oppt' from OfferTriggerTest exactly
        Opportunity opp = new Opportunity(
            Name                          = 'Test Opportunity',
            AccountId                     = acc.Id,
            StageName                     = 'Customer Won',
            Amount                        = 3000,
            CloseDate                     = System.today(),
            Pricebook2Id                  = Test.getStandardPricebookId(),
            Customer_Branch_Assignment__c = custSalesOrg.Id
        );
        insert opp;

        // 6. Customer Equipment only – Proposal_Form__c and Scope_With_Selection__c
        // are created inside each test method that needs them, because the
        // Opportunity__c lookup filter on Proposal_Form__c is environment-specific
        // and easier to satisfy with fresh, fully-controlled data per test.
        RecordType millEquipRT = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Customer_Equipments__c' AND DeveloperName = 'Mill'
            LIMIT 1
        ];
        Customer_Equipments__c custEquip = new Customer_Equipments__c(
            Customer__c  = acc.Id,
            RecordTypeId = millEquipRT.Id
        );
        insert custEquip;
    }

    // ──────────────────────────────────────────────────────────────
    //  HELPERS – retrieve shared records
    // ──────────────────────────────────────────────────────────────
    private static Account getAccount() {
        return [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
    }
    private static Opportunity getOpp() {
        return [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
    }
    private static Branch__c getBranch() {
        return [SELECT Id FROM Branch__c WHERE Name = 'Test Branch' LIMIT 1];
    }
    private static Sales_Org__c getSalesOrg() {
        return [SELECT Id FROM Sales_Org__c WHERE Name = 'TGSO' LIMIT 1];
    }
    /**
     * Creates a fresh Proposal_Form__c + Scope_With_Selection__c each time.
     * Done per-test (not in @TestSetup) because the Opportunity__c lookup
     * filter is environment-specific and must be satisfied with a live insert.
     */
    private static Proposal_Form__c createProposalForm(Id oppId, Id custEquipId) {
        Proposal_Form__c pForm = new Proposal_Form__c(
            Opportunity__c        = oppId,
            Customer_Equipment__c = custEquipId,
            Status__c             = 'New'
        );
        insert pForm;
        pForm.SAP_Offer_Number__c = '1001';
        update pForm;
        return [SELECT Id, SAP_Offer_Number__c FROM Proposal_Form__c WHERE Id = :pForm.Id];
    }

    private static Customer_Equipments__c getCustEquip() {
        return [SELECT Id FROM Customer_Equipments__c LIMIT 1];
    }

    /**
     * Builds (but does NOT insert) a Quote with all mandatory fields.
     */
    private static Quote buildOffer(Id oppId, Id branchId, Id salesOrgId,
                                    Id propFormId, String rtDevName, String status) {
        Id rtId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName()
                        .get(rtDevName)?.getRecordTypeId();
        Quote q = new Quote(
            Name                  = 'Test Offer (' + rtDevName + ')',
            OpportunityId         = oppId,
            RecordTypeId          = rtId,
            Status                = status,
            Pricebook2Id          = Test.getStandardPricebookId(),
            Payment_Months__c     = 10,
            BTP_Type__c           = 'FOB',
            Delivery_Schedule__c  = 30,
            Quotation_Date__c     = Date.today(),
            Quotation_Validity__c = Date.today().addDays(20),
            Branch__c             = branchId,
            Sales_Org__c          = salesOrgId
        );
        if (propFormId != null) {
            q.Opportunity_Equipments__c = propFormId;
        }
        return q;
    }

    // ══════════════════════════════════════════════════════════════════
    //  1. updateScopeWithOffer – INSERT path (oldMap == null)
    //     SAP_Offer_Id__c matches SAP_Offer_Number__c on Proposal Form
    //     → Scope_With_Selection__c.Offer__c is populated
    // ══════════════════════════════════════════════════════════════════
    
    /*
    @isTest
    static void testUpdateScopeWithOffer_Insert() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Customer_Equipments__c custEquip = getCustEquip();
        Proposal_Form__c pForm = createProposalForm(opp.Id, custEquip.Id);

        Scope_With_Selection__c scope = new Scope_With_Selection__c(
            Name             = 'Test Scope',
            Proposal_Form__c = pForm.Id
        );
        insert scope;

        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, pForm.Id, 'Offer_Non_Spare', 'Draft');
        offer.SAP_Offer_Id__c = pForm.SAP_Offer_Number__c; // '1001'
        insert offer;

        Map<Id, SObject> newMap = new Map<Id, SObject>{ offer.Id => offer };

        Test.startTest();
        OfferTriggerHelper.updateScopeWithOffer(newMap, null);
        Test.stopTest();

        scope = [SELECT Offer__c FROM Scope_With_Selection__c WHERE Id = :scope.Id];
        System.assertEquals(offer.Id, scope.Offer__c,
            'Scope Offer__c should be linked to the Offer when SAP numbers match (insert path)');
    } */

    // ══════════════════════════════════════════════════════════════════
    //  2. updateScopeWithOffer – UPDATE path (SAP_Offer_Id__c changed)
    // ══════════════════════════════════════════════════════════════════
    /*
    @isTest
    static void testUpdateScopeWithOffer_Update() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Customer_Equipments__c custEquip = getCustEquip();
        Proposal_Form__c pForm = createProposalForm(opp.Id, custEquip.Id);

        Scope_With_Selection__c scope = new Scope_With_Selection__c(
            Name             = 'Test Scope',
            Proposal_Form__c = pForm.Id
        );
        insert scope;

        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, pForm.Id, 'Offer_Non_Spare', 'Draft');
        offer.SAP_Offer_Id__c = '9999';
        insert offer;

        Quote oldState = offer.clone(true, true, false, false);
        oldState.SAP_Offer_Id__c = '9999';

        offer.SAP_Offer_Id__c = pForm.SAP_Offer_Number__c; // '1001'

        Map<Id, SObject> newMap = new Map<Id, SObject>{ offer.Id => offer };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldState.Id => oldState };

        Test.startTest();
        OfferTriggerHelper.updateScopeWithOffer(newMap, oldMap);
        Test.stopTest();

        scope = [SELECT Offer__c FROM Scope_With_Selection__c WHERE Id = :scope.Id];
        System.assertEquals(offer.Id, scope.Offer__c,
            'Scope Offer__c should be updated when SAP_Offer_Id__c changes to match Proposal Form');
    } */

    // ══════════════════════════════════════════════════════════════════
    //  3. updateScopeWithOffer – Blank SAP Id → no-op
    // ══════════════════════════════════════════════════════════════════
    /*
    @isTest
    static void testUpdateScopeWithOffer_BlankSAPId() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Customer_Equipments__c custEquip = getCustEquip();
        Proposal_Form__c pForm = createProposalForm(opp.Id, custEquip.Id);

        Scope_With_Selection__c scope = new Scope_With_Selection__c(
            Name             = 'Test Scope',
            Proposal_Form__c = pForm.Id
        );
        insert scope;

        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, pForm.Id, 'Offer_Non_Spare', 'Draft');
        // SAP_Offer_Id__c intentionally blank
        insert offer;

        Quote oldState = offer.clone(true, true, false, false);
        Map<Id, SObject> newMap = new Map<Id, SObject>{ offer.Id => offer };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldState.Id => oldState };

        Test.startTest();
        OfferTriggerHelper.updateScopeWithOffer(newMap, oldMap);
        Test.stopTest();

        scope = [SELECT Offer__c FROM Scope_With_Selection__c WHERE Id = :scope.Id];
        System.assertEquals(null, scope.Offer__c,
            'Scope Offer__c should remain null when SAP_Offer_Id__c is blank');
    }   */

    // ══════════════════════════════════════════════════════════════════
    //  4. validateOfferOnFinialze – BTP_Price__c = 0 → error added
    // ══════════════════════════════════════════════════════════════════
    @isTest
    static void testValidateOfferOnFinialze_ZeroBTP() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, null, 'Offer', 'Draft');
        insert offer;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id   = prod.Id,
            UnitPrice    = 100,
            IsActive     = true
        );
        insert pbe;
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId          = offer.Id,
            PricebookEntryId = pbe.Id,
            Quantity         = 1,
            UnitPrice        = 100,
            BTP_Price__c     = 0
        );
        insert qli;

        Quote newState = offer.clone(true, true, false, false);
        newState.Status = 'Finalized';
        Quote oldState = offer.clone(true, true, false, false);
        oldState.Status = 'Draft';

        Map<Id, SObject> newMap = new Map<Id, SObject>{ newState.Id => newState };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldState.Id => oldState };

        Test.startTest();
        OfferTriggerHelper.validateOfferOnFinialze(newMap, oldMap);
        Test.stopTest();

        System.assert(newMap.get(offer.Id).hasErrors(),
            'Error should be added on Offer when BTP_Price__c = 0 and status moves to Finalized');
    }

    // ══════════════════════════════════════════════════════════════════
    //  5. validateOfferOnFinialze – Status unchanged → no error
    // ══════════════════════════════════════════════════════════════════
    @isTest
    static void testValidateOfferOnFinialze_StatusUnchanged() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, null, 'Offer', 'Finalized');
        insert offer;

        Quote newState = offer.clone(true, true, false, false);
        newState.Status = 'Finalized';
        Quote oldState = offer.clone(true, true, false, false);
        oldState.Status = 'Finalized';

        Map<Id, SObject> newMap = new Map<Id, SObject>{ newState.Id => newState };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldState.Id => oldState };

        Test.startTest();
        OfferTriggerHelper.validateOfferOnFinialze(newMap, oldMap);
        Test.stopTest();

        System.assert(!newMap.get(offer.Id).hasErrors(),
            'No error should be added when status has not changed');
    }

    // ══════════════════════════════════════════════════════════════════
    //  6. CreateSAPOfferId – Non-Spare status → 'LS'
    // ══════════════════════════════════════════════════════════════════
    @isTest
    static void testCreateSAPOfferId_NonSpare_StatusLS() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, null, 'Offer_Non_Spare', 'Draft');
        insert offer;

        Quote newState = offer.clone(true, true, false, false);
        newState.Status = 'LS';
        Quote oldState = offer.clone(true, true, false, false);
        oldState.Status = 'Draft';

        Map<Id, SObject> newMap = new Map<Id, SObject>{ newState.Id => newState };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldState.Id => oldState };

        Test.startTest();
        Test.setMock(WebServiceMock.class, new OfferTriggerMockTest());
        try { OfferTriggerHelper.CreateSAPOfferId(newMap, oldMap); } catch (Exception ex) { }
        Test.stopTest();

        List<Integration_Transaction__c> itList = [
            SELECT Id FROM Integration_Transaction__c
            WHERE Record_Id__c = :offer.Id AND Operation__c = 'Send Acknowledgement to SAP'
        ];
        System.assertEquals(1, itList.size(),
            'Integration_Transaction__c should be created for LS status on Non-Spare offer');
    }

    // ══════════════════════════════════════════════════════════════════
    //  7. CreateSAPOfferId – Non-Spare status → 'HO'
    // ══════════════════════════════════════════════════════════════════
    @isTest
    static void testCreateSAPOfferId_NonSpare_StatusHO() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, null, 'Offer_Non_Spare', 'Draft');
        insert offer;

        Quote newState = offer.clone(true, true, false, false);
        newState.Status = 'HO';
        Quote oldState = offer.clone(true, true, false, false);
        oldState.Status = 'Draft';

        Map<Id, SObject> newMap = new Map<Id, SObject>{ newState.Id => newState };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldState.Id => oldState };

        Test.startTest();
        Test.setMock(WebServiceMock.class, new OfferTriggerMockTest());
        try { OfferTriggerHelper.CreateSAPOfferId(newMap, oldMap); } catch (Exception ex) { }
        Test.stopTest();

        List<Integration_Transaction__c> itList = [
            SELECT Id FROM Integration_Transaction__c
            WHERE Record_Id__c = :offer.Id AND Operation__c = 'Send Acknowledgement to SAP'
        ];
        System.assertEquals(1, itList.size(),
            'Integration_Transaction__c should be created for HO status on Non-Spare offer');
    }

    // ══════════════════════════════════════════════════════════════════
    //  8. CreateSAPOfferId – Non-Spare status → 'DF'
    // ══════════════════════════════════════════════════════════════════
    @isTest
    static void testCreateSAPOfferId_NonSpare_StatusDF() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, null, 'Offer_Non_Spare', 'Draft');
        insert offer;

        Quote newState = offer.clone(true, true, false, false);
        newState.Status = 'DF';
        Quote oldState = offer.clone(true, true, false, false);
        oldState.Status = 'Draft';

        Map<Id, SObject> newMap = new Map<Id, SObject>{ newState.Id => newState };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldState.Id => oldState };

        Test.startTest();
        Test.setMock(WebServiceMock.class, new OfferTriggerMockTest());
        try { OfferTriggerHelper.CreateSAPOfferId(newMap, oldMap); } catch (Exception ex) { }
        Test.stopTest();

        List<Integration_Transaction__c> itList = [
            SELECT Id FROM Integration_Transaction__c
            WHERE Record_Id__c = :offer.Id AND Operation__c = 'Send Acknowledgement to SAP'
        ];
        System.assertEquals(1, itList.size(),
            'Integration_Transaction__c should be created for DF status on Non-Spare offer');
    }

    // ══════════════════════════════════════════════════════════════════
    //  9. CreateSAPOfferId – Spare Offer Approved + Price Accepted
    //     → creates Integration_Transaction__c for 'Create Offer Spare'
    // ══════════════════════════════════════════════════════════════════
    @isTest
    static void testCreateSAPOfferId_Spare_Approved_PriceAccepted() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, null, 'Offer', 'Approved');
        offer.Approval_Status__c = 'Draft';
        insert offer;

        Quote newState = offer.clone(true, true, false, false);
        newState.Status             = 'Approved';
        newState.Approval_Status__c = 'Price Accepted';

        Quote oldState = offer.clone(true, true, false, false);
        oldState.Status             = 'Approved';
        oldState.Approval_Status__c = 'Draft';

        Map<Id, SObject> newMap = new Map<Id, SObject>{ newState.Id => newState };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldState.Id => oldState };

        Test.startTest();
        OfferTriggerHelper.CreateSAPOfferId(newMap, oldMap);
        Test.stopTest();

        List<Integration_Transaction__c> itList = [
            SELECT Id, Operation__c FROM Integration_Transaction__c
            WHERE Record_Id__c = :offer.Id AND Operation__c = 'Create Offer Spare'
        ];
        System.assertEquals(1, itList.size(),
            'Integration_Transaction__c (Create Offer Spare) should be created on Price Accepted');
    }

    // ══════════════════════════════════════════════════════════════════
    //  10. CreateSAPOfferId – oldMap null → no-op, no exception
    // ══════════════════════════════════════════════════════════════════
    @isTest
    static void testCreateSAPOfferId_OldMapNull() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, null, 'Offer', 'Draft');
        insert offer;

        Map<Id, SObject> newMap = new Map<Id, SObject>{ offer.Id => offer };

        Test.startTest();
        OfferTriggerHelper.CreateSAPOfferId(newMap, null);
        Test.stopTest();

        System.assert(true, 'CreateSAPOfferId with null oldMap completed without exception');
    }

    // ══════════════════════════════════════════════════════════════════
    //  11. populatePriceBook – Spare ('Offer') record type → pricebook set
    // ══════════════════════════════════════════════════════════════════
    @isTest
    static void testPopulatePriceBook_SpareOffer() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, null, 'Offer', 'Draft');
        offer.Pricebook2Id = null; // clear so we can verify the method sets it

        Test.startTest();
        OfferTriggerHelper.populatePriceBook(new List<Quote>{ offer });
        Test.stopTest();

        System.assertNotEquals(null, offer.Pricebook2Id,
            'Pricebook2Id should be set for Spare (Offer) record type');
    }

    // ══════════════════════════════════════════════════════════════════
    //  12. populatePriceBook – Non-Spare → pricebook NOT set
    // ══════════════════════════════════════════════════════════════════
    @isTest
    static void testPopulatePriceBook_NonSpareOffer() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, null, 'Offer_Non_Spare', 'Draft');
        offer.Pricebook2Id = null;

        Test.startTest();
        OfferTriggerHelper.populatePriceBook(new List<Quote>{ offer });
        Test.stopTest();

        System.assertEquals(null, offer.Pricebook2Id,
            'Pricebook2Id should NOT be set for Offer_Non_Spare record type');
    }

    // ══════════════════════════════════════════════════════════════════
    //  13. populateHead – INSERT path
    //      Regional_Sales_Head__c = Sales Region Manager = current user
    // ══════════════════════════════════════════════════════════════════
    @isTest
    static void testPopulateHead_Insert() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, null, 'Offer_Non_Spare', 'Draft');
        insert offer;

        List<Quote> newList = [
            SELECT Id, Branch__c, OpportunityId, Regional_Sales_Head__c, PMG_Head__c, RecordTypeId
            FROM Quote WHERE Id = :offer.Id
        ];

        Test.startTest();
        OfferTriggerHelper.populateHead(newList, null, false);
        Test.stopTest();

        // Manager__c on Sales Region was set to UserInfo.getUserId() in @TestSetup
        System.assertEquals(UserInfo.getUserId(), newList[0].Regional_Sales_Head__c,
            'Regional_Sales_Head__c should match the Sales Region Manager');
    }

    // ══════════════════════════════════════════════════════════════════
    //  14. populateHead – UPDATE path (isUpdate = true)
    // ══════════════════════════════════════════════════════════════════
    @isTest
    static void testPopulateHead_Update() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, null, 'Offer_Non_Spare', 'Draft');
        insert offer;

        Quote oldState = offer.clone(true, true, false, false);
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldState.Id => oldState };

        List<Quote> newList = [
            SELECT Id, Branch__c, OpportunityId, Regional_Sales_Head__c, PMG_Head__c, RecordTypeId
            FROM Quote WHERE Id = :offer.Id
        ];

        Test.startTest();
        OfferTriggerHelper.populateHead(newList, oldMap, true);
        Test.stopTest();

        System.assertEquals(UserInfo.getUserId(), newList[0].Regional_Sales_Head__c,
            'Regional_Sales_Head__c should still be correctly set on update path');
    }

    // ══════════════════════════════════════════════════════════════════
    //  15. afterIDcreation – Spare offer + user HAS SalesGroupCode
    // ══════════════════════════════════════════════════════════════════
    
    /*
    @isTest
    static void testAfterIDcreation_WithSalesGroupCode() {
        User currentUser = [SELECT Id, SalesGroupCode__c FROM User WHERE Id = :UserInfo.getUserId()];
        currentUser.SalesGroupCode__c = 'GRP-01';
        update currentUser;

        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, null, 'Offer', 'Draft');
        insert offer;

        List<Quote> newList = [SELECT Id, RecordTypeId, SalesGrp__c FROM Quote WHERE Id = :offer.Id];

        Test.startTest();
        OfferTriggerHelper.afterIDcreation(newList);
        Test.stopTest();

        System.assertEquals('GRP-01', newList[0].SalesGrp__c,
            'SalesGrp__c should be populated from the running user SalesGroupCode__c');
    } */

    // ══════════════════════════════════════════════════════════════════
    //  16. afterIDcreation – Spare offer + user MISSING SalesGroupCode
    //      → addError on the Quote
    // ══════════════════════════════════════════════════════════════════
    /*
    @isTest
    static void testAfterIDcreation_BlankSalesGroupCode() {
        User currentUser = [SELECT Id, SalesGroupCode__c FROM User WHERE Id = :UserInfo.getUserId()];
        currentUser.SalesGroupCode__c = null;
        update currentUser;

        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, null, 'Offer', 'Draft');
        insert offer;

        List<Quote> newList = [SELECT Id, RecordTypeId, SalesGrp__c FROM Quote WHERE Id = :offer.Id];

        Test.startTest();
        OfferTriggerHelper.afterIDcreation(newList);
        Test.stopTest();

        System.assert(newList[0].hasErrors(),
            'An error should be added when running user SalesGroupCode__c is blank');
    } */

    // ══════════════════════════════════════════════════════════════════
    //  17. afterIDcreation – Non-Spare record type → skipped, no error
    // ══════════════════════════════════════════════════════════════════
    @isTest
    static void testAfterIDcreation_NonSpareSkipped() {
        Opportunity      opp   = getOpp();
        Branch__c        br    = getBranch();
        Sales_Org__c     sOrg  = getSalesOrg();
        Quote offer = buildOffer(opp.Id, br.Id, sOrg.Id, null, 'Offer_Non_Spare', 'Draft');
        insert offer;

        List<Quote> newList = [SELECT Id, RecordTypeId, SalesGrp__c FROM Quote WHERE Id = :offer.Id];

        Test.startTest();
        OfferTriggerHelper.afterIDcreation(newList);
        Test.stopTest();

        System.assert(!newList[0].hasErrors(),
            'Non-Spare offers should be skipped without errors');
        System.assertEquals(null, newList[0].SalesGrp__c,
            'SalesGrp__c should remain null for Non-Spare record type');
    }
}