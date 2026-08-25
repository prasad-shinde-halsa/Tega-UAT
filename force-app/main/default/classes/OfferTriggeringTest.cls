@isTest
public class OfferTriggeringTest {
    
    @TestSetup
    static void setupTestData() {
        // Create Sales Region
        Sales_Region__c sr = new Sales_Region__c(
            Name = 'AFRICA'
        );
        insert sr;
        
        // Create Company
        Company__c comp = new Company__c(
            Name = 'Tega Industries Limited',
            Company_Code__c = 'TG01'
        );
        insert comp;
        
        // Create Branch
        Branch__c branch = new Branch__c(
            Sales_Region__c = sr.Id,
            Name = 'Middle East Asia',
            Branch_Code__c = 'MEA'
        );
        insert branch;
        
        // Create Account
        Account customer = new Account(
            Name = 'Test Customer',
            Status__c = 'Sync with SAP',
            Sales_Region__c = sr.Id
        );
        insert customer;
        
        // Create Customer Sales Organization
        Customer_Sales_Organization__c cso = new Customer_Sales_Organization__c(
            Customer__c = customer.Id,
            Company__c = comp.Id,
            Branch__c = branch.Id,
            CreatedFromAccount__c = true
        );
        insert cso;
        
        // Create Opportunity
        Id oppMillRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            RecordTypeId = oppMillRecordTypeId,
            AccountId = customer.Id,
            CloseDate = System.today(),
            StageName = 'Offer',
            Customer_Branch_Assignment__c = cso.Id,
            Order_Type__c = 'Spares'
        );
        insert opp;
        
        // Create PMG Master
        PMG_Master__c pmgMaster = new PMG_Master__c(
            Name = 'Test PMG Master'
        );
        insert pmgMaster;
        
        // Create DC Budget
        DC_Budget__c dcBudget = new DC_Budget__c(
            Name = 'Test Budget',
            Status__c = 'Draft',
            Financial_Year__c = '2025-26'
        );
        insert dcBudget;
        
        // // Create Budget Line Item
        // DC_Budget_Line_Items__c budgetLineItem = new DC_Budget_Line_Items__c(
        //     Order_Type__c = 'C-Conversion',
        //     Budget__c = dcBudget.Id,
        //     Customer__c = customer.Id,
        //     PMG_Master__c = pmgMaster.Id
        // );
        // insert budgetLineItem;
        
        // Create Product
        Product2 product = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-001',
            IsActive = true
        );
        insert product;
        
        // Create Standard Price Book Entry
        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPBE;
    }
    
    @isTest
    static void testQuoteLostStatus() {
        // Get prerequisite records
        //DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Branch__c branch = [SELECT Id FROM Branch__c LIMIT 1];
        Customer_Sales_Organization__c cso = [SELECT Id FROM Customer_Sales_Organization__c LIMIT 1];
        Map<Id, SObject> newItemsMap = new Map<Id, SObject>();
        Map < Id, SObject > oldItemsMap = new Map<Id, SObject>();
        
        // Create Quote/Offer
        Id recordTypeIdNonSpare = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            //DC_Budget_Line_Items__c = bli.Id,
            Branch__c = branch.Id,
            RecordTypeId = recordTypeIdNonSpare,
           // Company_Branch_Assignment__c = cso.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        
        Test.startTest();
        insert quote;
        
        // Update to Lost Status
        Quote newcreatedquote = [Select ID,Status,RecordTypeId from Quote where ID =: quote.Id];
        newcreatedquote.Status = 'LS';
        newcreatedquote.Lost_Date__c = Date.newInstance(2025, 4, 15);
        update newcreatedquote;
               
        newItemsMap.put(newcreatedquote.Id,newcreatedquote);
        oldItemsMap.put(quote.Id,quote);
        offerTriggerHelper.CreateSAPOfferId(newItemsMap,oldItemsMap);
        Test.stopTest();
        
        // Verify MIS Budget record
        // List<MIS_Budget__c> misRecords = [
        //     SELECT Id, Order_Expected_Stage_Apr__c, 
        //            Order_Expected_Month_Apr__c
        //     FROM MIS_Budget__c 
        //     WHERE Budget_Line_Items__c = :bli.Id
        // ];
        
        // System.assertEquals(1, misRecords.size(), 'One MIS record should be created');
        //System.assertEquals('Lost', misRecords[0].Order_Expected_Stage_Apr__c, 'Stage should be set to Lost');
        //System.assertEquals('Apr, 2025', misRecords[0].Order_Expected_Month_Apr__c, 'Month should be set correctly');
    }
    
    @isTest
    static void testExistingMISUpdate() {
       // DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Branch__c branch = [SELECT Id FROM Branch__c LIMIT 1];
        Customer_Sales_Organization__c cso = [SELECT Id FROM Customer_Sales_Organization__c LIMIT 1];
        
        // MIS_Budget__c existingMIS = new MIS_Budget__c(
        //     //Budget_Line_Items__c = bli.Id,
        //     Order_Type__c = 'C-Conversion'
        // );
        // insert existingMIS;
        
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            // DC_Budget_Line_Items__c = bli.Id,
            Branch__c = branch.Id,
            Company_Branch_Assignment__c = cso.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        
        Test.startTest();
        insert quote;
        
        quote.Status = 'LS';
        quote.Lost_Date__c = Date.newInstance(2025, 5, 15);
        update quote;
        Test.stopTest();
        
        // MIS_Budget__c updatedMIS = [
        //     SELECT Id, Order_Expected_Stage_May__c, 
        //            Order_Expected_Month_May__c
        //     FROM MIS_Budget__c 
        //     WHERE Id = :existingMIS.Id
        // ];
        
        //System.assertEquals('Lost', updatedMIS.Order_Expected_Stage_May__c);
        //System.assertEquals('May, 2025', updatedMIS.Order_Expected_Month_May__c);
    }
    
    @isTest
    static void testSpareOffer() {
        //DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Branch__c branch = [SELECT Id FROM Branch__c LIMIT 1];
        Customer_Sales_Organization__c cso = [SELECT Id FROM Customer_Sales_Organization__c LIMIT 1];
		Id offerRecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer').getRecordTypeId();
        Map<Id, SObject> newItemsMap = new Map<Id, SObject>();
        Map < Id, SObject > oldItemsMap = new Map<Id, SObject>();
        
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            //DC_Budget_Line_Items__c = bli.Id,
            Branch__c = branch.Id,
            Company_Branch_Assignment__c = cso.Id,
            RecordTypeId = offerRecordTypeId,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        
        Test.startTest();
        insert quote;
        
        Quote newcreatedquote = [Select ID,Status,RecordTypeId from Quote where ID =: quote.Id];
        System.debug('newcreatedquote**'+newcreatedquote);
        newcreatedquote.Status = 'Finalized';
        update newcreatedquote;
        
        newItemsMap.put(newcreatedquote.Id,newcreatedquote);
        oldItemsMap.put(quote.Id,quote);
        offerTriggerHelper.CreateSAPOfferId(newItemsMap,oldItemsMap);
        System.debug('newcreatedquote**'+newcreatedquote);
        Test.stopTest();
    }
}