@isTest
public class L2L3ProductBatch_Test {
    static testmethod void datacover(){
        Account acc = new Account();
        acc.name = 'test acc';
        insert acc;
        
        Part_List__c p = new Part_List__c();
        p.Customer__c = acc.id;
        p.Description__c = 'test desc';
        insert p;
        
        L2_L3_product__c l2l3 = new L2_L3_product__c();
        l2l3.Quantity__c = 20;
        l2l3.Part_List__c = p.Id;
        insert l2l3;
        
        system.schedule('run psd', '0 0 13 * * ? ', new L2L3ProductBatchScheduler());
        
        L2L3ProductBatch b = new L2L3ProductBatch();
        Database.executeBatch(b);
    }
}