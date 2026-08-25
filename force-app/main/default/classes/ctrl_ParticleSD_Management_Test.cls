@isTest
public class ctrl_ParticleSD_Management_Test {
    Static testmethod void datacover() {
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        Id customerEQRecordTypeId = Schema.SObjectType.Customer_Equipments__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        
        Customer_Equipments__c ce = new Customer_Equipments__c();
        ce.RecordTypeId = customerEQRecordTypeId;
        ce.Customer__c = acc.Id;
        ce.Equipment_Type__c = 'PbM';
        insert ce;
        
        Id opRecordTypeId = Schema.SObjectType.Operating_Parameters__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Operating_Parameters__c op = new Operating_Parameters__c();
        op.RecordTypeId = opRecordTypeId;
        op.Customer_Equipment__c = ce.Id;
        op.Customer__c = acc.Id;
        insert op;
        
        Id psdRecordTypeId = Schema.SObjectType.Particle_Size_Distribution__c.getRecordTypeInfosByName().get('Mill').getRecordTypeId();
        Particle_Size_Distribution__c psd = new Particle_Size_Distribution__c();
        psd.Operating_Parameters__c = op.Id;
        psd.RecordTypeId = psdRecordTypeId;
        psd.Type__c = 'Feed Particle Size Distribuition';
        psd.Today_s_Date__c = System.today();
        insert psd;
        
        List<Particle_Size_Distribution_Line_Item__c> psdlList = new list<Particle_Size_Distribution_Line_Item__c>();
        Particle_Size_Distribution_Line_Item__c psdl = new Particle_Size_Distribution_Line_Item__c();
        psdl.Sieve_mm__c = 34;
        psdl.Weight__c = 20;
        psdl.Particle_Size_Distribution__c = psd.Id;
        psdlList.add(psdl);
        insert psdlList;
        
        Test.startTest();
        PageReference pageRef = Page.vf_ParticleSD_Management;
        pageRef.getParameters().put('rowIndex', '1');
        pageRef.getParameters().put('Id', op.Id);
        Test.setCurrentPage(pageRef);

        ApexPages.StandardController sc = new ApexPages.StandardController(op);
        ctrl_ParticleSD_Management psdm = new ctrl_ParticleSD_Management(sc);

        psdm.addNewRow();
        System.assertEquals(2, psdm.psdlineList.size(), 'Row was not added.');

        psdm.removeRow();
        System.assertEquals(1, psdm.psdlineList.size(), 'Row was not removed.');

        PageReference saveResult = psdm.save();
        System.assertEquals(null, saveResult, 'Save should have returned null.');

        psdm.psd.Type__c = 'Feed Particle Size Distribuition';
        psdm.psdlineList[0].Sieve_mm__c = 34;
        psdm.psdlineList[0].Weight__c = 20;
        saveResult = psdm.save();
        System.assertNotEquals(null, saveResult, 'Save should have returned a PageReference.');
        
        psdm.cancel();

        Test.stopTest();
    }
}