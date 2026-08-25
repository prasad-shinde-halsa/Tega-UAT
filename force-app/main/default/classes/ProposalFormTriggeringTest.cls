@isTest
public class ProposalFormTriggeringTest {
    
    @TestSetup
    static void setupTestData() {
        
       Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser@example.org.test'
        );
        insert testUser;
         System.runAs(testUser) {
        
        Sales_Region__c sr = new Sales_Region__c(
            Name = 'AFRICA',
            Manager__c = testUser.Id
        );
        insert sr;
        
        Company__c comp = new Company__c(
            Name = 'Tega Industries Limited',
            Company_Code__c = 'TG1'
        );
        insert comp;
        
        Branch__c branch = new Branch__c(
            Sales_Region__c = sr.Id,
            Name = 'Middle East Asia',
            Branch_Code__c = 'MEA'
        );
        insert branch;
        
        Account customer = new Account(
            Name = 'Test Customer',
            Status__c = 'Sync with SAP',
            Sales_Region__c = sr.Id
        );
        insert customer;
        
        Customer_Sales_Organization__c cso = new Customer_Sales_Organization__c(
            Customer__c = customer.Id,
            Company__c = comp.Id,
            Branch__c = branch.Id,
            CreatedFromAccount__c = true
        );
        insert cso;
        
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
        
        PMG_Master__c pmgMaster = new PMG_Master__c(
            Name = 'Test PMG Master'
        );
        insert pmgMaster;
        
        DC_Budget__c dcBudget = new DC_Budget__c(
            Name = 'Test Budget',
            Status__c = '4th Level Approved',
            Financial_Year__c = '2025-26'
        );
        insert dcBudget;
        
        DC_Budget_Line_Items__c budgetLineItem = new DC_Budget_Line_Items__c(
            Order_Type__c = 'C-Conversion',
            Budget__c = dcBudget.Id,
            Customer__c = customer.Id,
            PMG_Master__c = pmgMaster.Id
        );
        insert budgetLineItem;

        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            DC_Budget_Line_Items__c = budgetLineItem.Id,
            Branch__c = branch.Id,
           Company_Branch_Assignment__c = cso.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        
        insert quote;
         }
    }
    
    
    @isTest
    static void testProposalClosing() {
        DC_Budget_Line_Items__c bli = [SELECT Id, Budget__r.Financial_Year__c 
                                     FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'New',
            DC_Budget_Line_Items__c = bli.Id,
            Closed_Date__c = Date.newInstance(2025, 4, 15),
            RecordTypeId = pfMillRecordTypeId,
            Opportunity__c = opp.Id,
            Budgeted_Order_Month__c = 'Jan',
            Customer_Name__c = opp.AccountId
        );
        
        Test.startTest();
        insert proposal;
        
        Cost_Information_sheet__c cis = new Cost_Information_sheet__c(
            Name = 'Test CIS',
            Proposal_Form__c = proposal.Id
        );
        insert cis;
        
        proposal.Status__c = 'Closed';
        update proposal;
        Test.stopTest();
        
    }

   @isTest
    static void testProposalClosing2() {
        DC_Budget_Line_Items__c bli = [SELECT Id, Budget__r.Financial_Year__c 
                                     FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'New',
            DC_Budget_Line_Items__c = bli.Id,
            Closed_Date__c = Date.newInstance(2025, 4, 15),
            RecordTypeId = pfMillRecordTypeId,
            Opportunity__c = opp.Id,
            Budgeted_Order_Month__c = 'Feb',
            Customer_Name__c = opp.AccountId
        );
        
        Test.startTest();
        insert proposal;
        
        Cost_Information_sheet__c cis = new Cost_Information_sheet__c(
            Name = 'Test CIS',
            Proposal_Form__c = proposal.Id
        );
        insert cis;
        
        proposal.Status__c = 'Closed';
        update proposal;
        Test.stopTest();
        
    }
    @isTest
    static void testProposalClosing3() {
        DC_Budget_Line_Items__c bli = [SELECT Id, Budget__r.Financial_Year__c 
                                     FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'New',
            DC_Budget_Line_Items__c = bli.Id,
            Closed_Date__c = Date.newInstance(2025, 4, 15),
            RecordTypeId = pfMillRecordTypeId,
            Opportunity__c = opp.Id,
            Budgeted_Order_Month__c = 'Mar',
            Customer_Name__c = opp.AccountId
        );
        
        Test.startTest();
        insert proposal;
        
        Cost_Information_sheet__c cis = new Cost_Information_sheet__c(
            Name = 'Test CIS',
            Proposal_Form__c = proposal.Id
        );
        insert cis;
        
        proposal.Status__c = 'Closed';
        update proposal;
        Test.stopTest();
        
    }
    
    @isTest
    static void testProposalClosing4() {
        DC_Budget_Line_Items__c bli = [SELECT Id, Budget__r.Financial_Year__c 
                                     FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'New',
            DC_Budget_Line_Items__c = bli.Id,
            Closed_Date__c = Date.newInstance(2025, 4, 15),
            RecordTypeId = pfMillRecordTypeId,
            Opportunity__c = opp.Id,
            Budgeted_Order_Month__c = 'Apr',
            Customer_Name__c = opp.AccountId
        );
        
        Test.startTest();
        insert proposal;
        
        Cost_Information_sheet__c cis = new Cost_Information_sheet__c(
            Name = 'Test CIS',
            Proposal_Form__c = proposal.Id
        );
        insert cis;
        
        proposal.Status__c = 'Closed';
        update proposal;
        Test.stopTest();
        
    }
    
    @isTest
    static void testProposalClosing5() {
        DC_Budget_Line_Items__c bli = [SELECT Id, Budget__r.Financial_Year__c 
                                     FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'New',
            DC_Budget_Line_Items__c = bli.Id,
            Closed_Date__c = Date.newInstance(2025, 4, 15),
            RecordTypeId = pfMillRecordTypeId,
            Opportunity__c = opp.Id,
            Budgeted_Order_Month__c = 'May',
            Customer_Name__c = opp.AccountId
        );
        
        Test.startTest();
        insert proposal;
        
        Cost_Information_sheet__c cis = new Cost_Information_sheet__c(
            Name = 'Test CIS',
            Proposal_Form__c = proposal.Id
        );
        insert cis;
        
        proposal.Status__c = 'Closed';
        update proposal;
        Test.stopTest();
        
    }
    
    @isTest
    static void testProposalClosing6() {
        DC_Budget_Line_Items__c bli = [SELECT Id, Budget__r.Financial_Year__c 
                                     FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'New',
            DC_Budget_Line_Items__c = bli.Id,
            Closed_Date__c = Date.newInstance(2025, 4, 15),
            RecordTypeId = pfMillRecordTypeId,
            Opportunity__c = opp.Id,
            Budgeted_Order_Month__c = 'Jun',
            Customer_Name__c = opp.AccountId
        );
        
        Test.startTest();
        insert proposal;
        
        Cost_Information_sheet__c cis = new Cost_Information_sheet__c(
            Name = 'Test CIS',
            Proposal_Form__c = proposal.Id
        );
        insert cis;
        
        proposal.Status__c = 'Closed';
        update proposal;
        Test.stopTest();
        
    }
    
    @isTest
    static void testProposalClosing7() {
        DC_Budget_Line_Items__c bli = [SELECT Id, Budget__r.Financial_Year__c 
                                     FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'New',
            DC_Budget_Line_Items__c = bli.Id,
            Closed_Date__c = Date.newInstance(2025, 4, 15),
            RecordTypeId = pfMillRecordTypeId,
            Opportunity__c = opp.Id,
            Budgeted_Order_Month__c = 'Jul',
            Customer_Name__c = opp.AccountId
        );
        
        Test.startTest();
        insert proposal;
        
        Cost_Information_sheet__c cis = new Cost_Information_sheet__c(
            Name = 'Test CIS',
            Proposal_Form__c = proposal.Id
        );
        insert cis;
        
        proposal.Status__c = 'Closed';
        update proposal;
        Test.stopTest();
        
    }
    @isTest
    static void testProposalClosing8() {
        DC_Budget_Line_Items__c bli = [SELECT Id, Budget__r.Financial_Year__c 
                                     FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'New',
            DC_Budget_Line_Items__c = bli.Id,
            Closed_Date__c = Date.newInstance(2025, 4, 15),
            RecordTypeId = pfMillRecordTypeId,
            Opportunity__c = opp.Id,
            Budgeted_Order_Month__c = 'Aug',
            Customer_Name__c = opp.AccountId
        );
        
        Test.startTest();
        insert proposal;
        
        Cost_Information_sheet__c cis = new Cost_Information_sheet__c(
            Name = 'Test CIS',
            Proposal_Form__c = proposal.Id
        );
        insert cis;
        
        proposal.Status__c = 'Closed';
        update proposal;
        Test.stopTest();
        
    }
    @isTest
    static void testProposalClosing9() {
        DC_Budget_Line_Items__c bli = [SELECT Id, Budget__r.Financial_Year__c 
                                     FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'New',
            DC_Budget_Line_Items__c = bli.Id,
            Closed_Date__c = Date.newInstance(2025, 4, 15),
            RecordTypeId = pfMillRecordTypeId,
            Opportunity__c = opp.Id,
            Budgeted_Order_Month__c = 'Sep',
            Customer_Name__c = opp.AccountId
        );
        
        Test.startTest();
        insert proposal;
        
        Cost_Information_sheet__c cis = new Cost_Information_sheet__c(
            Name = 'Test CIS',
            Proposal_Form__c = proposal.Id
        );
        insert cis;
        
        proposal.Status__c = 'Closed';
        update proposal;
        Test.stopTest();
        
    }
    @isTest
    static void testProposalClosing10() {
        DC_Budget_Line_Items__c bli = [SELECT Id, Budget__r.Financial_Year__c 
                                     FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'New',
            DC_Budget_Line_Items__c = bli.Id,
            Closed_Date__c = Date.newInstance(2025, 4, 15),
            RecordTypeId = pfMillRecordTypeId,
            Opportunity__c = opp.Id,
            Budgeted_Order_Month__c = 'Oct',
            Customer_Name__c = opp.AccountId
        );
        
        Test.startTest();
        insert proposal;
        
        Cost_Information_sheet__c cis = new Cost_Information_sheet__c(
            Name = 'Test CIS',
            Proposal_Form__c = proposal.Id
        );
        insert cis;
        
        proposal.Status__c = 'Closed';
        update proposal;
        Test.stopTest();
        
    }
    @isTest
    static void testProposalClosing11() {
        DC_Budget_Line_Items__c bli = [SELECT Id, Budget__r.Financial_Year__c 
                                     FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'New',
            DC_Budget_Line_Items__c = bli.Id,
            Closed_Date__c = Date.newInstance(2025, 4, 15),
            RecordTypeId = pfMillRecordTypeId,
            Opportunity__c = opp.Id,
            Budgeted_Order_Month__c = 'Nov',
            Customer_Name__c = opp.AccountId
        );
        
        Test.startTest();
        insert proposal;
        
        Cost_Information_sheet__c cis = new Cost_Information_sheet__c(
            Name = 'Test CIS',
            Proposal_Form__c = proposal.Id
        );
        insert cis;
        
        proposal.Status__c = 'Closed';
        update proposal;
        Test.stopTest();
        
    }
    @isTest
    static void testProposalClosing12() {
        DC_Budget_Line_Items__c bli = [SELECT Id, Budget__r.Financial_Year__c 
                                     FROM DC_Budget_Line_Items__c LIMIT 1];
        Opportunity opp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        
        Id pfMillRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Proposal_Form__c proposal = new Proposal_Form__c(
            Status__c = 'New',
            DC_Budget_Line_Items__c = bli.Id,
            Closed_Date__c = Date.newInstance(2025, 4, 15),
            RecordTypeId = pfMillRecordTypeId,
            Opportunity__c = opp.Id,
            Budgeted_Order_Month__c = 'Dec',
            Customer_Name__c = opp.AccountId
        );
        
        Test.startTest();
        insert proposal;
        
        Cost_Information_sheet__c cis = new Cost_Information_sheet__c(
            Name = 'Test CIS',
            Proposal_Form__c = proposal.Id
        );
        insert cis;
        
        proposal.Status__c = 'Closed';
        update proposal;
        Test.stopTest();
        
    }
}