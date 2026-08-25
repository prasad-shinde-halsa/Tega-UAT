@isTest
public class ProcessListViewInstApexControllerTest {
    
    @isTest
    public static void test1(){
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        list<user>lstUsers = new list<user>();
        for(integer i=0;i<3;i++)
        {
            user usr = new user();
            usr.Alias = 'sales'+string.ValueOf(i);
            usr.Email = 'sales'+string.ValueOf(i)+'@testorg.com';
            usr.EmailEncodingKey = 'UTF-8'; 
            usr.firstname = 'Test'; 
            usr.LastName = 'Leadassign'+string.ValueOf(i);
            usr.LanguageLocaleKey = 'en_US';
            usr.LocaleSidKey = 'en_US'; 
            usr.ProfileId = p.Id; 
            usr.TimeZoneSidKey = 'America/Los_Angeles';
            usr.UserName = 'salesuser1'+string.ValueOf(i)+'@testorg.com';
            lstUsers.add(usr);
        }
        insert lstUsers;
        Sales_Region__c salesReg = new Sales_Region__c(Name = 'Test Sales Region', Manager__c = lstUsers[0].Id);
        insert salesReg;
        Account acc = new Account(Name = 'Test Account',CurrencyIsoCode = 'USD');
        insert acc;
        system.debug('Account'+acc);
        Branch__c branch = new Branch__c(Name = 'Test Branch', Sales_Region__c = salesReg.Id,Branch_Code__c = 'TBR');
        insert branch;
        Customer_Sales_Organization__c custSalesOrg1 = new Customer_Sales_Organization__c(CreatedFromAccount__c =true,Customer__c = acc.Id, Branch__c = branch.Id);
        insert custSalesOrg1;
        acc.Status__c = 'Sync with SAP';
        update acc;
        
        
        RecordType proInvRecType = [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Invoice__c' AND DeveloperName = 'Proforma'];
        Id proformaInvoiceRecTypeId = proInvRecType.Id;
        Invoice__c invoice = new Invoice__c();
        invoice.SAP_Invoice_Number__c = '12';
        invoice.Customer__c = acc.id;
        invoice.Consignee__c = acc.id;
        invoice.GST_Number__c = 'test';
        invoice.VAT_Number__c = '1234';
        invoice.RecordTypeId = proformaInvoiceRecTypeId;
        invoice.CurrencyIsoCode = 'INR';
        invoice.is_Manual_Line_Item_Applicable__c=true;
        insert invoice;
        
        
        Invoice_Line_Item__c testLineItem = new Invoice_Line_Item__c();
        testLineItem.Invoice__c = invoice.id;
        testLineItem.Item_Number__c = 10;
        testLineItem.Item_Code__c = 'T32-03725A000-0102';
        testLineItem.Item_Description__c= 'T32-03725A000-0102';
        testLineItem.Product_Type__c = 'FERT';
        testLineItem.Product_Group__c = 'SERVICE';
        testLineItem.Item_Quantity__c = 20;
        testLineItem.SO_Item_Quantity__c = 10;
        testLineItem.UOM__c = 'EA';
        testLineItem.Item_Value__c = 1234;
        insert testLineItem;
        
               
        RecordType expInvRecType = [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Customer_Equipments__c' AND DeveloperName = 'Mill'];
        Id exportInvoiceRecTypeId = expInvRecType.Id;
        Customer_Equipments__c testCE = new Customer_Equipments__c();
        testCE.RecordTypeId = exportInvoiceRecTypeId;
        testCE.Customer__c = acc.id;
        string values = 'Launder;Bunker';
        testCE.Equipment_Type__c = 'Scrubber';
        insert testCE;
        
        Part_List__c prt = new Part_List__c(Name = 'Test1993', Customer__c = acc.Id);
        insert prt;
        
        RecordType ProdRecType = [Select Id,Name From RecordType  Where SobjectType = 'Product2' and DeveloperName = 'Product_Zone_L2'];
        list<Product2> lstprod = new list<Product2>();
        Product2 l2Prod = new Product2(Name = 'PLM-01256-02-SHELL',
                                      RecordTypeId=ProdRecType.id,
                                      Part_List__c= prt.id);
        lstprod.add(l2Prod);
        

        Product2 l3Prod = new Product2(Name = 'M34-01026O000-0102',
                                      RecordTypeId=ProdRecType.id,
                                      Part_List__c= prt.id);
        lstprod.add(l3Prod);
        
        insert lstprod;
         

         List<Customer_Inventory_Stock__c> lstcsi = new List<Customer_Inventory_Stock__c>();
        Customer_Inventory_Stock__c stock = new Customer_Inventory_Stock__c();
        stock.Item_Code__c = 'Test';
        stock.Item__c=l3Prod.id;
        stock.Quantity__c = 14;
        stock.Customer__c = acc.id;
        stock.Group_Items__c = true;
        stock.Installation_Quantity__c =13;
        stock.Where_it_is__c='Inventory';
        stock.Invoice_Line_Item__c=testLineItem.id;
        //insert stock;
        lstcsi.add(stock);
        
        Customer_Inventory_Stock__c stock1 = new Customer_Inventory_Stock__c();
        stock1.Item_Code__c = 'Test';
        stock1.Quantity__c = 14;
        stock1.Item__c=l3Prod.id;
        stock1.Customer__c = acc.id;
        stock1.Group_Items__c = false;
        stock1.Installation_Quantity__c =13;
        stock1.Where_it_is__c='Inventory';
        stock1.Invoice_Line_Item__c=testLineItem.id;
        //insert stock1;
        lstcsi.add(stock1);
        insert lstcsi;
        
        List<String> invIds = new List<String>();
        invIds.add(stock.Id);
        invIds.add(stock1.Id);
        
         L2_L3_product__c l2l3Pro = new L2_L3_product__c(Part_List__c = prt.Id, 
                                                        Product_L2__c= l2Prod.Id,
                                                        Product_L3__c = l3Prod.Id ,
                                                       	Quantity__c = 16.0);
        insert l2l3Pro; 
        
        Installation__c tstInstallation = new Installation__c();
        tstInstallation.Name = 'Demo WC Sales Rep';
        tstInstallation.Customer__c = acc.Id;
        tstInstallation.Equipment_Installed_At__c = testCE.Id;
        tstInstallation.Material_Handled__c = 'Aggregate';
        tstInstallation.Moisture_Content_max__c = 10;
        tstInstallation.Shape_of_Material__c = 'Round';
        tstInstallation.Max_Lump_Size_mm__c = 12;
        tstInstallation.Bulk_Density_t_m3__c= 12;
        tstInstallation.Max_Temperature_C__c= 12;
        tstInstallation.Part_List__c= prt.id;
        tstInstallation.Product__c=l2Prod.Id;
        insert tstInstallation;
        
        /*Installation_line_Items__c instLineItem = new Installation_line_items__c(
            Installation__c=tstInstallation.Id, 
            Installed_Quantity__c=10,
            Equipment_has_been_Installed_at__c = testCE.Id, 
            Customer_Inventory_Line_Stock__c = stock.Id);
        insert instLineItem;*/
        
        Test.startTest();
        ProcessListViewInstApexController.fetchInvs(stock.id);
        ProcessListViewInstApexController.createInstallationLines(tstInstallation.Id,invIds);
        
       /* stock.Quantity__c = 8;
        update stock;
        ProcessListViewInstApexController.createInstallationLines(tstInstallation.Id,invIds);*/

        //ProcessListViewInstApexController.createInstallationLinesPartial(tstInstallation.Id,instLineItem,stock);
        Test.stopTest();
    }
    
}