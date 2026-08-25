@isTest
public class CIS_Line_Controller_test {
    static testmethod void datacover(){
        Sales_Region__c sr = new Sales_Region__c();
        sr.Name = 'AFRICA';
		insert sr;
        
        Company__c c = new Company__c();
        c.Name = 'Tega Industries Limited';
        insert c;
        
        Branch__c b = new Branch__c();
        b.Sales_Region__c = sr.Id;
        b.Name = 'Middle East Asia';
        b.Branch_Code__c = 'MEA';
        insert b;
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Status__c = 'Sync with SAP';
        acc.Sales_Region__c = sr.Id;
        insert acc;
        
        Customer_Sales_Organization__c cso = new Customer_Sales_Organization__c();
        cso.Customer__c = acc.Id;
        cso.Company__c = c.Id;
        cso.Branch__c = b.Id;
        cso.CreatedFromAccount__c = true;
        insert cso;
        
		Id OppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Mill').getRecordTypeId();

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.RecordTypeId = OppRecordTypeId;
        opp.AccountId = acc.Id;
        opp.CloseDate = system.today();
        opp.StageName = 'Offer';
        opp.Customer_Branch_Assignment__c = cso.Id;
        insert opp;
        
        Id PFRecordTypeId = Schema.SObjectType.Proposal_Form__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        
        Proposal_Form__c pf = new Proposal_Form__c();
        pf.RecordTypeId = PFRecordTypeId;
        pf.Opportunity__c = opp.Id;
        insert pf; 
        
        Cost_Information_sheet__c cis = new Cost_Information_sheet__c();
        cis.Name = 'Test CIS';
        cis.Proposal_Form__c = pf.Id;
        insert cis;
        
        List<Cost_Information__c>CiList = new List<Cost_Information__c>();
        Cost_Information__c ci = new Cost_Information__c();
        ci.Item_Desc__c = 'Rubber 102';
        ci.Rate_Kg__c = 10;
        ci.Total_Weight__c = 100;
        ci.Remarks__c = 'Test Rem';
        ci.Cost_Information_Sheet__c = cis.id;
        CiList.add(ci);
        insert CiList;
        
        Test.startTest();
        PageReference pageRef = Page.vf_CIS_Line;
        pageRef.getParameters().put('rowIndex', '1');
        pageRef.getParameters().put('Id', cis.Id);
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(cis);
        CIS_Line_Controller cisl = new CIS_Line_Controller(sc);
        
        cisl.addNewRow();
        System.assertEquals(2, cisl.cislineList.size(), 'Row was not added.');

        cisl.removeRow();
        System.assertEquals(1, cisl.cislineList.size(), 'Row was not removed.');

        PageReference saveResult = cisl.save();
        System.assertEquals(null, saveResult, 'Save should have returned null.');
        
        cisl.cislineList[0].Item_Desc__c = 'Rubber 102';
        cisl.cislineList[0].Rate_Kg__c = 10;
        cisl.cislineList[0].Total_Weight__c = 100;
        cisl.cislineList[0].Remarks__c = 'Test Rem';
        saveResult = cisl.save();
       // System.assertNotEquals(null, saveResult, 'Save should have returned a PageReference.');
       
        cisl.fakeMethod();
        cisl.cancel();
        Test.stopTest();
    }
}