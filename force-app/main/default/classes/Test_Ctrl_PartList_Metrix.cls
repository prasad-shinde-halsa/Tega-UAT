@isTest
public class Test_Ctrl_PartList_Metrix {
    
    static testmethod void Ctrl_PartList_Metrix(){
        
        Profile prof = [Select Id from Profile Where Name = 'System Administrator'];
      
      	User usr = new User();
        usr.FirstName = 'fname01';
        usr.LastName = 'lname01';
        usr.Email = 'test@test1.com';
        usr.Alias = 'flname2';
        usr.EmailEncodingKey='UTF-8';
        usr.LanguageLocaleKey='en_US'; 
        usr.LocaleSidKey='en_US';
        usr.TimeZoneSidKey='America/Los_Angeles';
        usr.UserName='admin01@testdev.com';
        usr.ProfileId = prof.Id;
        insert usr;
        
        Account acc = new Account();
        acc.name = 'test acc';
        insert acc;
        system.debug('acc: '+ acc);
        
        Product2 prd = new Product2();
        prd.Name = 'M33-00076O000-0102';
        prd.Description = 'M33-00076O000-0102';
        insert prd;
        
        Product2 prd1 = new Product2();
        prd1.Name = 'PLM-00197-01-SHELL';
        insert prd1;
        
        Integration_Transaction__c it = new Integration_Transaction__c();
        it.Operation__c = 'Create Partlist';
        it.Request__c = 'Create Partlist:PLS-14631-01';
        it.Record_Id__c = 'PLS-14631-01';
        insert it;
        
        Part_List__c p = new Part_List__c();
        p.Customer__c = acc.id;
        p.Description__c = 'PLS-14631-01';
        p.Name = 'PLS-14631-01';
        insert p;
        
        //Part_List__c p = [SELECT id,name FROM Part_List__c WHERE name=:it.Record_Id__c];
        
        Product_Sorting_Data__c psd = new Product_Sorting_Data__c();
        psd.Product_Catagory__c = 'PLM';
        psd.Sorting_Key__c = 'M33';
        psd.Sorting_Number__c = 1;
        insert psd;
        
        List<L2_L3_product__c> l2l3List = new List<L2_L3_product__c>();
        L2_L3_product__c l2l3 = new L2_L3_product__c();
        l2l3.Quantity__c = 20;
        l2l3.Part_List__c = p.Id;
        l2l3.Product_L2__c =prd1.id;
        l2l3.Product_L3__c = prd.id;
        l2l3List.add(l2l3);
        insert l2l3List;
        
        PageReference pageRef = Page.vf_PartList_MetrixPLM;
        //pageRef.getParameters().put('Id',p.Id);
        //Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',p.Id);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(p);
        Ctrl_PartList_Metrix ext = new Ctrl_PartList_Metrix(stdController);
        
        ext.FilterQuantity = 20;
        Ctrl_PartList_Metrix.L2L3Wrapper w = new Ctrl_PartList_Metrix.L2L3Wrapper(l2l3.Id);
        w.strQuantity = 10;
        w.dehQuantity = 12;
        w.fehQuantity = 10;
        w.ItemDescription = 'test desc';
        w.L2ProductName = l2l3.Id;
        w.mfbQuantity =10;
        w.PLMtotalQuantity = 50;
        w.PLStotalQuantity = 60;
        w.PLTtotalQuantity = 70;
        w.pnlQuantity = 5;
        w.sfbQuantity = 6;
        w.shellQuantity = 7;
        w.sortingOrder = '3';
        w.spareQuantity = 4;
        w.sprlQuantity = 8;
        w.SrNo = 1;
        List<Ctrl_PartList_Metrix.L2L3Wrapper> wrpLst = new List<Ctrl_PartList_Metrix.L2L3Wrapper>();
        wrpLst.add(w);
        
        ext.filterList = wrpLst;
        ext.filterList2 = wrpLst;
        ext.filterList3 = wrpLst;
        ext.excelExportData = wrpLst;
        ext.PDFExportData = wrpLst;
        
        ext.downloadExcelPLM();
        ext.downloadExcelPLS();
        ext.downloadExcelPLT();
        ext.downloadPDFPLM();
        ext.downloadPDFPLS();
        ext.downloadPDFPLT();
    }
}