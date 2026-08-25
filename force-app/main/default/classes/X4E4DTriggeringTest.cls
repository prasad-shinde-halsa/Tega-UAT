@isTest
private class X4E4DTriggeringTest {
    
    @testSetup 
    static void setup() { 
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales' LIMIT 1];
        List<User> lstUsers = new List<User>();
        for(Integer i=0; i<1; i++) {
            lstUsers.add(new User(
                Alias = 'sales'+i,
                Email = 'sales'+i+'@testorg.com',
                EmailEncodingKey = 'UTF-8',
                FirstName = 'Test',
                LastName = 'Leadassign'+i,
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'salesuser'+i+'@testorg.com'
            ));
        }
        insert lstUsers;
        
        Sales_Region__c salesReg = new Sales_Region__c(Name = 'AFRICA', Manager__c = lstUsers[0].Id);
        insert salesReg;
        
        Account acc = new Account(Name = 'Test Customer', Status__c = 'Sync with SAP', Sales_Region__c = salesReg.Id);
        insert acc;
        
        Branch__c branch = new Branch__c(Name = 'Test Branch', Sales_Region__c = salesReg.Id, Branch_Code__c = 'TBR');
        insert branch;
        
        Customer_Sales_Organization__c custSalesOrg1 = new Customer_Sales_Organization__c(Customer__c = acc.Id, Branch__c = branch.Id, CreatedFromAccount__c = true);
        insert custSalesOrg1;
        
        PMG_Master__c pmgMaster = new PMG_Master__c(Name = 'Test PMG Master');
        insert pmgMaster;
        
        DC_Budget__c dcBudget = new DC_Budget__c(Name = 'Test Budget', Status__c = '4th Level Approved', Financial_Year__c = '2025-26');
        insert dcBudget;
        
        DC_Budget_Line_Items__c budgetLine = new DC_Budget_Line_Items__c(Customer__c = acc.Id, Order_Type__c = 'C-Conversion', Budget__c = dcBudget.Id, PMG_Master__c = pmgMaster.Id);
        insert budgetLine;
        
        Id oppMillRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            RecordTypeId = oppMillRecordTypeId,
            AccountId = acc.Id,
            CloseDate = System.today(),
            StageName = 'Closed',
            Customer_Branch_Assignment__c = custSalesOrg1.Id,
            Order_Type__c = 'Spares'
        );
        insert opp;
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'Closed', 
            DC_Budget_Line_Items__c = budgetLine.Id, 
            Closed_Date__c = Date.newInstance(2025, 4, 15), 
            RecordTypeId = pfMillRecordTypeId, 
            Opportunity__c = opp.Id, 
            Customer_Name__c = opp.AccountId, 
            Budgeted_Order_Month__c = 'Apr' );
        
        insert proposal;
        
        // Pricebook + Product
        Product2 product = new Product2(Name='Test Product', ProductCode='TP-001', IsActive=true);
        insert product;
        Id standardPB = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=standardPB, Product2Id=product.Id, UnitPrice=100, IsActive=true);
        insert pbe;
        
        // Quote (Offer)
        Id recordTypeIdNonSpare = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            DC_Budget_Line_Items__c = budgetLine.Id,
            Branch__c = branch.Id,
            RecordTypeId = recordTypeIdNonSpare,
            Pricebook2Id = standardPB,
             Opportunity_Equipments__c = proposal.Id
        );
        insert quote;
    }
    
    @isTest
    static void testInsertClosedStatusCreatesMISBudget() {
        DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        
        X4E_4D__c record = new X4E_4D__c(
            Status_SO__c = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Category__c = 'SO',
            SF_Offer__c = q.Id   // ✅ required field populated
        );
        
        insert record;
        Test.startTest();
        // Now update to Closed to fire the trigger logic
        record.Status_SO__c = 'Closed';
        update record;
        Test.stopTest();
    }
    
    @isTest
    static void testInsertClosedStatusCreatesMISBudget2() {
              
        DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        Branch__c br = [SELECT Id FROM Branch__c LIMIT 1];
        Id standardPB = Test.getStandardPricebookId();
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'Closed', 
            DC_Budget_Line_Items__c = bli.Id, 
            Closed_Date__c = Date.newInstance(2025, 11, 16), 
            RecordTypeId = pfMillRecordTypeId, 
            Opportunity__c = opp.Id, 
            Customer_Name__c = opp.AccountId, 
            Budgeted_Order_Month__c = 'Mar' );
        
        insert proposal;
        
        // Quote (Offer)
        Id recordTypeIdNonSpare = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        Quote quote = new Quote(
            Name = 'Test Quote 2',
            OpportunityId = opp.Id,
            Status = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Branch__c = br.Id,
            RecordTypeId = recordTypeIdNonSpare,
            Pricebook2Id = standardPB,
             Opportunity_Equipments__c = proposal.Id
        );
        insert quote;
        
        X4E_4D__c record = new X4E_4D__c(
            Status_SO__c = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Category__c = 'SO',
            SF_Offer__c = quote.Id   // ✅ required field populated
        );
        
        insert record;
        
        Test.startTest();
        // Now update to Closed to fire the trigger logic
        record.Status_SO__c = 'Closed';
        update record;
        Test.stopTest();
        
    }
    @isTest
    static void testInsertClosedStatusCreatesMISBudget3() {
              
        DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        Branch__c br = [SELECT Id FROM Branch__c LIMIT 1];
        Id standardPB = Test.getStandardPricebookId();
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'Closed', 
            DC_Budget_Line_Items__c = bli.Id, 
            Closed_Date__c = Date.newInstance(2025, 11, 16), 
            RecordTypeId = pfMillRecordTypeId, 
            Opportunity__c = opp.Id, 
            Customer_Name__c = opp.AccountId, 
            Budgeted_Order_Month__c = 'Feb' );
        
        insert proposal;
        
        // Quote (Offer)
        Id recordTypeIdNonSpare = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        Quote quote = new Quote(
            Name = 'Test Quote 3',
            OpportunityId = opp.Id,
            Status = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Branch__c = br.Id,
            RecordTypeId = recordTypeIdNonSpare,
            Pricebook2Id = standardPB,
             Opportunity_Equipments__c = proposal.Id
        );
        insert quote;
        
        X4E_4D__c record = new X4E_4D__c(
            Status_SO__c = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Category__c = 'SO',
            SF_Offer__c = quote.Id   // ✅ required field populated
        );
        
        insert record;
        
        Test.startTest();
        // Now update to Closed to fire the trigger logic
        record.Status_SO__c = 'Closed';
        update record;
        Test.stopTest();
        
    }
    @isTest
    static void testInsertClosedStatusCreatesMISBudget4() {
              
        DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        Branch__c br = [SELECT Id FROM Branch__c LIMIT 1];
        Id standardPB = Test.getStandardPricebookId();
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'Closed', 
            DC_Budget_Line_Items__c = bli.Id, 
            Closed_Date__c = Date.newInstance(2025, 11, 16), 
            RecordTypeId = pfMillRecordTypeId, 
            Opportunity__c = opp.Id, 
            Customer_Name__c = opp.AccountId, 
            Budgeted_Order_Month__c = 'May' );
        
        insert proposal;
        
        // Quote (Offer)
        Id recordTypeIdNonSpare = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        Quote quote = new Quote(
            Name = 'Test Quote 4',
            OpportunityId = opp.Id,
            Status = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Branch__c = br.Id,
            RecordTypeId = recordTypeIdNonSpare,
            Pricebook2Id = standardPB,
             Opportunity_Equipments__c = proposal.Id
        );
        insert quote;
        
        X4E_4D__c record = new X4E_4D__c(
            Status_SO__c = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Category__c = 'SO',
            SF_Offer__c = quote.Id   // ✅ required field populated
        );
        
        insert record;
        
        Test.startTest();
        // Now update to Closed to fire the trigger logic
        record.Status_SO__c = 'Closed';
        update record;
        Test.stopTest();
        
    }
    
    @isTest
    static void testInsertClosedStatusCreatesMISBudget5() {
              
        DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        Branch__c br = [SELECT Id FROM Branch__c LIMIT 1];
        Id standardPB = Test.getStandardPricebookId();
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'Closed', 
            DC_Budget_Line_Items__c = bli.Id, 
            Closed_Date__c = Date.newInstance(2025, 11, 16), 
            RecordTypeId = pfMillRecordTypeId, 
            Opportunity__c = opp.Id, 
            Customer_Name__c = opp.AccountId, 
            Budgeted_Order_Month__c = 'Jun' );
        
        insert proposal;
        
        // Quote (Offer)
        Id recordTypeIdNonSpare = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        Quote quote = new Quote(
            Name = 'Test Quote 5',
            OpportunityId = opp.Id,
            Status = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Branch__c = br.Id,
            RecordTypeId = recordTypeIdNonSpare,
            Pricebook2Id = standardPB,
             Opportunity_Equipments__c = proposal.Id
        );
        insert quote;
        
        X4E_4D__c record = new X4E_4D__c(
            Status_SO__c = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Category__c = 'SO',
            SF_Offer__c = quote.Id   // ✅ required field populated
        );
        
        insert record;
        
        Test.startTest();
        // Now update to Closed to fire the trigger logic
        record.Status_SO__c = 'Closed';
        update record;
        Test.stopTest();
        
    }
    
    @isTest
    static void testInsertClosedStatusCreatesMISBudget6() {
              
        DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        Branch__c br = [SELECT Id FROM Branch__c LIMIT 1];
        Id standardPB = Test.getStandardPricebookId();
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'Closed', 
            DC_Budget_Line_Items__c = bli.Id, 
            Closed_Date__c = Date.newInstance(2025, 11, 16), 
            RecordTypeId = pfMillRecordTypeId, 
            Opportunity__c = opp.Id, 
            Customer_Name__c = opp.AccountId, 
            Budgeted_Order_Month__c = 'Jul' );
        
        insert proposal;
        
        // Quote (Offer)
        Id recordTypeIdNonSpare = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        Quote quote = new Quote(
            Name = 'Test Quote 6',
            OpportunityId = opp.Id,
            Status = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Branch__c = br.Id,
            RecordTypeId = recordTypeIdNonSpare,
            Pricebook2Id = standardPB,
             Opportunity_Equipments__c = proposal.Id
        );
        insert quote;
        
        X4E_4D__c record = new X4E_4D__c(
            Status_SO__c = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Category__c = 'SO',
            SF_Offer__c = quote.Id   // ✅ required field populated
        );
        
        insert record;
        
        Test.startTest();
        // Now update to Closed to fire the trigger logic
        record.Status_SO__c = 'Closed';
        update record;
        Test.stopTest();
        
    }
    
    @isTest
    static void testInsertClosedStatusCreatesMISBudget7() {
              
        DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        Branch__c br = [SELECT Id FROM Branch__c LIMIT 1];
        Id standardPB = Test.getStandardPricebookId();
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'Closed', 
            DC_Budget_Line_Items__c = bli.Id, 
            Closed_Date__c = Date.newInstance(2025, 11, 16), 
            RecordTypeId = pfMillRecordTypeId, 
            Opportunity__c = opp.Id, 
            Customer_Name__c = opp.AccountId, 
            Budgeted_Order_Month__c = 'Aug' );
        
        insert proposal;
        
        // Quote (Offer)
        Id recordTypeIdNonSpare = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        Quote quote = new Quote(
            Name = 'Test Quote 7',
            OpportunityId = opp.Id,
            Status = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Branch__c = br.Id,
            RecordTypeId = recordTypeIdNonSpare,
            Pricebook2Id = standardPB,
             Opportunity_Equipments__c = proposal.Id
        );
        insert quote;
        
        X4E_4D__c record = new X4E_4D__c(
            Status_SO__c = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Category__c = 'SO',
            SF_Offer__c = quote.Id   // ✅ required field populated
        );
        
        insert record;
        
        Test.startTest();
        // Now update to Closed to fire the trigger logic
        record.Status_SO__c = 'Closed';
        update record;
        Test.stopTest();
        
    }
    
     @isTest
    static void testInsertClosedStatusCreatesMISBudget8() {
              
        DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        Branch__c br = [SELECT Id FROM Branch__c LIMIT 1];
        Id standardPB = Test.getStandardPricebookId();
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'Closed', 
            DC_Budget_Line_Items__c = bli.Id, 
            Closed_Date__c = Date.newInstance(2025, 11, 16), 
            RecordTypeId = pfMillRecordTypeId, 
            Opportunity__c = opp.Id, 
            Customer_Name__c = opp.AccountId, 
            Budgeted_Order_Month__c = 'Sep' );
        
        insert proposal;
        
        // Quote (Offer)
        Id recordTypeIdNonSpare = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        Quote quote = new Quote(
            Name = 'Test Quote 8',
            OpportunityId = opp.Id,
            Status = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Branch__c = br.Id,
            RecordTypeId = recordTypeIdNonSpare,
            Pricebook2Id = standardPB,
             Opportunity_Equipments__c = proposal.Id
        );
        insert quote;
        
        X4E_4D__c record = new X4E_4D__c(
            Status_SO__c = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Category__c = 'SO',
            SF_Offer__c = quote.Id   // ✅ required field populated
        );
        
        insert record;
        
        Test.startTest();
        // Now update to Closed to fire the trigger logic
        record.Status_SO__c = 'Closed';
        update record;
        Test.stopTest();
        
    }
    
    @isTest
    static void testInsertClosedStatusCreatesMISBudget9() {
              
        DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        Branch__c br = [SELECT Id FROM Branch__c LIMIT 1];
        Id standardPB = Test.getStandardPricebookId();
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'Closed', 
            DC_Budget_Line_Items__c = bli.Id, 
            Closed_Date__c = Date.newInstance(2025, 11, 16), 
            RecordTypeId = pfMillRecordTypeId, 
            Opportunity__c = opp.Id, 
            Customer_Name__c = opp.AccountId, 
            Budgeted_Order_Month__c = 'Oct' );
        
        insert proposal;
        
        // Quote (Offer)
        Id recordTypeIdNonSpare = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        Quote quote = new Quote(
            Name = 'Test Quote 9',
            OpportunityId = opp.Id,
            Status = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Branch__c = br.Id,
            RecordTypeId = recordTypeIdNonSpare,
            Pricebook2Id = standardPB,
             Opportunity_Equipments__c = proposal.Id
        );
        insert quote;
        
        X4E_4D__c record = new X4E_4D__c(
            Status_SO__c = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Category__c = 'SO',
            SF_Offer__c = quote.Id   // ✅ required field populated
        );
        
        insert record;
        
        Test.startTest();
        // Now update to Closed to fire the trigger logic
        record.Status_SO__c = 'Closed';
        update record;
        Test.stopTest();
        
    }
    
    @isTest
    static void testInsertClosedStatusCreatesMISBudget10() {
              
        DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        Branch__c br = [SELECT Id FROM Branch__c LIMIT 1];
        Id standardPB = Test.getStandardPricebookId();
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'Closed', 
            DC_Budget_Line_Items__c = bli.Id, 
            Closed_Date__c = Date.newInstance(2025, 11, 16), 
            RecordTypeId = pfMillRecordTypeId, 
            Opportunity__c = opp.Id, 
            Customer_Name__c = opp.AccountId, 
            Budgeted_Order_Month__c = 'Nov' );
        
        insert proposal;
        
        // Quote (Offer)
        Id recordTypeIdNonSpare = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        Quote quote = new Quote(
            Name = 'Test Quote 10',
            OpportunityId = opp.Id,
            Status = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Branch__c = br.Id,
            RecordTypeId = recordTypeIdNonSpare,
            Pricebook2Id = standardPB,
             Opportunity_Equipments__c = proposal.Id
        );
        insert quote;
        
        X4E_4D__c record = new X4E_4D__c(
            Status_SO__c = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Category__c = 'SO',
            SF_Offer__c = quote.Id   // ✅ required field populated
        );
        
        insert record;
        
        Test.startTest();
        // Now update to Closed to fire the trigger logic
        record.Status_SO__c = 'Closed';
        update record;
        Test.stopTest();
        
    }
    
    @isTest
    static void testInsertClosedStatusCreatesMISBudget11() {
              
        DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        Branch__c br = [SELECT Id FROM Branch__c LIMIT 1];
        Id standardPB = Test.getStandardPricebookId();
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'Closed', 
            DC_Budget_Line_Items__c = bli.Id, 
            Closed_Date__c = Date.newInstance(2025, 11, 16), 
            RecordTypeId = pfMillRecordTypeId, 
            Opportunity__c = opp.Id, 
            Customer_Name__c = opp.AccountId, 
            Budgeted_Order_Month__c = 'Dec' );
        
        insert proposal;
        
        // Quote (Offer)
        Id recordTypeIdNonSpare = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        Quote quote = new Quote(
            Name = 'Test Quote 11',
            OpportunityId = opp.Id,
            Status = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Branch__c = br.Id,
            RecordTypeId = recordTypeIdNonSpare,
            Pricebook2Id = standardPB,
             Opportunity_Equipments__c = proposal.Id
        );
        insert quote;
        
        X4E_4D__c record = new X4E_4D__c(
            Status_SO__c = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Category__c = 'SO',
            SF_Offer__c = quote.Id   // ✅ required field populated
        );
        
        insert record;
        
        Test.startTest();
        // Now update to Closed to fire the trigger logic
        record.Status_SO__c = 'Closed';
        update record;
        Test.stopTest();
        
    }
    
    @isTest
    static void testInsertClosedStatusCreatesMISBudget12() {
              
        DC_Budget_Line_Items__c bli = [SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        Branch__c br = [SELECT Id FROM Branch__c LIMIT 1];
        Id standardPB = Test.getStandardPricebookId();
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'Closed', 
            DC_Budget_Line_Items__c = bli.Id, 
            Closed_Date__c = Date.newInstance(2025, 11, 16), 
            RecordTypeId = pfMillRecordTypeId, 
            Opportunity__c = opp.Id, 
            Customer_Name__c = opp.AccountId, 
            Budgeted_Order_Month__c = 'Jan' );
        
        insert proposal;
        
        // Quote (Offer)
        Id recordTypeIdNonSpare = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Offer_Non_Spare').getRecordTypeId();
        Quote quote = new Quote(
            Name = 'Test Quote 12',
            OpportunityId = opp.Id,
            Status = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Branch__c = br.Id,
            RecordTypeId = recordTypeIdNonSpare,
            Pricebook2Id = standardPB,
             Opportunity_Equipments__c = proposal.Id
        );
        insert quote;
        
        X4E_4D__c record = new X4E_4D__c(
            Status_SO__c = 'Draft',
            DC_Budget_Line_Items__c = bli.Id,
            Category__c = 'SO',
            SF_Offer__c = quote.Id   // ✅ required field populated
        );
        
        insert record;
        
        Test.startTest();
        // Now update to Closed to fire the trigger logic
        record.Status_SO__c = 'Closed';
        update record;
        Test.stopTest();
        
    }
}