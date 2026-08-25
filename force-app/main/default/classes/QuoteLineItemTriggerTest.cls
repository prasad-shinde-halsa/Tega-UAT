@isTest
public class QuoteLineItemTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // 1. Create standard pricebook Id
        Id pricebookId = Test.getStandardPricebookId();
        
        // 2. Create an Account (WITH VALIDATION BYPASS)
        Account acc = new Account(
            Name = 'Test Account',
            Sync_with_SAP__c = true
        );
        insert acc;
        
        // 3. Create an Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
        
        // 4. Create a Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert prod;
        
        // 5. Create a Standard Pricebook Entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbe;
        
        // 6. Create a Quote (Added Customer_offr__c to bypass lookup filters)
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = pricebookId,
            Customer_offr__c = acc.Id
        );
        insert q;
    }
    
    @isTest
    static void testInsertAndUpdate() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        Test.startTest();
        
        // --- TEST INSERT ---
        // Using valid picklist values instead of TypeA/TypeB
        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            settingType__c = 'FEH;DEH' 
        );
        insert qli1;
        
        // Verify Insert
        Quote updatedQuote = [SELECT settingType__c FROM Quote WHERE Id = :testQuote.Id];
        System.assertNotEquals(null, updatedQuote.settingType__c, 'settingType__c should not be null after insert');
        System.assert(updatedQuote.settingType__c.contains('FEH'), 'Should contain FEH');
        System.assert(updatedQuote.settingType__c.contains('DEH'), 'Should contain DEH');
        
        // --- TEST INSERT MULTIPLE (Merging sets) ---
        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 200,
            settingType__c = 'DEH;SHELL'
        );
        insert qli2;
        
        // Verify union of values (DEH shouldn't duplicate in a Set, but we check presence)
        updatedQuote = [SELECT settingType__c FROM Quote WHERE Id = :testQuote.Id];
        System.assert(updatedQuote.settingType__c.contains('FEH'), 'Should contain FEH');
        System.assert(updatedQuote.settingType__c.contains('DEH'), 'Should contain DEH');
        System.assert(updatedQuote.settingType__c.contains('SHELL'), 'Should contain SHELL');
        
        // --- TEST UPDATE ---
        // Change QLI1 from 'FEH;DEH' to 'fullset'
        qli1.settingType__c = 'fullset';
        update qli1;
        
        // Verify Update (FEH should be gone because it's no longer on ANY line item. 'fullset' is added. DEH and SHELL remain from QLI2)
        updatedQuote = [SELECT settingType__c FROM Quote WHERE Id = :testQuote.Id];
        System.assert(updatedQuote.settingType__c.contains('fullset'), 'Should contain fullset');
        System.assert(!updatedQuote.settingType__c.contains('FEH'), 'FEH should be removed');
        System.assert(updatedQuote.settingType__c.contains('DEH'), 'Should still contain DEH from QLI2');
        
        Test.stopTest();
    }
    /*
    @isTest
    static void testDeleteAndUndelete() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        // Create a QLI to test deletion using a valid picklist value
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            settingType__c = 'FEH'
        );
        insert qli;
        
        Test.startTest();
        
        // --- TEST DELETE ---
        delete qli;
        
        Quote updatedQuote = [SELECT settingType__c FROM Quote WHERE Id = :testQuote.Id];
        System.assertEquals('', updatedQuote.settingType__c, 'settingType__c should be empty after all QLIs are deleted');
        
        // --- TEST UNDELETE ---
        undelete qli;
        
        updatedQuote = [SELECT settingType__c FROM Quote WHERE Id = :testQuote.Id];
        System.assert(updatedQuote.settingType__c.contains('FEH'), 'settingType__c should be restored after undelete');
        
        Test.stopTest();
    } */
}