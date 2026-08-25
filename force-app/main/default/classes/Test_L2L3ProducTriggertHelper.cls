@isTest
public class Test_L2L3ProducTriggertHelper {
    static testmethod void datacover(){
        
        Account acc = new Account();
        acc.name = 'test acc';
        insert acc;
        
        Product2 prd = new Product2();
        prd.Name = 'M33-00076O000-0102';
        insert prd;
        
        Product2 prd1 = new Product2();
        prd1.Name = 'PLM-00197-01-Test';
        insert prd1;
        
        Part_List__c p = new Part_List__c();
        p.Customer__c = acc.id;
        p.Description__c = 'test desc';
        p.Name = 'PLM-00197-01-Test';
        insert p;
        
        Part_List__c p1 = new Part_List__c();
        p1.Customer__c = acc.id;
        p1.Description__c = 'test desc';
        p1.Name = 'PLS-00197-01-Test';
        insert p1;
                
        Product_Sorting_Data__c psd = new Product_Sorting_Data__c();
        psd.Product_Catagory__c = 'PLM';
        psd.Sorting_Key__c = 'M33';
        psd.Sorting_Number__c = 1;
        insert psd;
        
        system.debug('psd: ' + psd);
        
        Product_Sorting_Data__c psd2 = new Product_Sorting_Data__c();
        psd2.Product_Catagory__c = 'PLS';
        psd2.Sorting_Key__c = 'M42';
        psd2.Sorting_Number__c = 2;
        insert psd2;
        system.debug('psd2: ' + psd2);
        
        List<L2_L3_product__c> l2l3List = new List<L2_L3_product__c>();
        L2_L3_product__c l2l3 = new L2_L3_product__c();
        l2l3.Quantity__c = 20;
        l2l3.Product_Sorting_Data__c = psd2.id;
        l2l3.Part_List__c = p.Id;
        l2l3.Product_L2__c =prd1.id;
        l2l3.Product_L3__c = prd1.id;
        l2l3List.add(l2l3);
        
        insert l2l3List;
        l2l3.Quantity__c = 22;
        update l2l3;
        delete l2l3;
        undelete l2l3;
        
    }
    
    static testmethod void createL1L3RecordTest(){
        
        Account acc = new Account();
        acc.name = 'test acc';
        insert acc;
        
        Product2 prd = new Product2();
        prd.Name = 'M33-00076O000-0102';
        insert prd;
        
        Product2 prd1 = new Product2();
        prd1.Name = 'PLM-00197-01-Test';
        insert prd1;
        
        Part_List__c p = new Part_List__c();
        p.Customer__c = acc.id;
        p.Description__c = 'test desc';
        p.Name = 'PLM-00197-01-Test';
        insert p;
        
        Part_List__c p1 = new Part_List__c();
        p1.Customer__c = acc.id;
        p1.Description__c = 'test desc';
        p1.Name = 'PLS-00197-01-Test';
        insert p1;
                
        
        List<L2_L3_product__c> l2l3List = new List<L2_L3_product__c>();
        L2_L3_product__c l2l3 = new L2_L3_product__c();
        l2l3.Quantity__c = 20;
        l2l3.Part_List__c = p.Id;
        l2l3.Product_L2__c =prd1.id;
        l2l3.Product_L3__c = prd1.id;
        l2l3List.add(l2l3);
        
        insert l2l3List;
        List<L1_L3_Product__c> newL1L2List = [Select Id from L1_L3_Product__c where Part_List__c =: p.Id];
        System.AssertEquals(newL1L2List.isEmpty(),false);      
    }
}