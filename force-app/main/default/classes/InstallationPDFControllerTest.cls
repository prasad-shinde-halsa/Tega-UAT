@isTest
public class InstallationPDFControllerTest {
    
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
        
        //List<RecordType> equipRecordTypeList = [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType WHERE SobjectType  = 'Customer_Equipments__c'];

        //Customer_Equipments__c custEquip = new Customer_Equipments__c(Customer__c = acc.id);
        //insert custEquip;
        //
         id  CustConveyerRecordTypeId = Schema.SObjectType.Customer_Equipments__c.getRecordTypeInfosByDeveloperName().get('Conveyor_Component').getRecordTypeId();
        
        Customer_Equipments__c custEquip = new Customer_Equipments__c(
            CurrencyIsoCode = 'EUR',
            Circuit_diagram_available__c = false,
            Dia_m__c = 123.0,
            Mill_Type__c = 'SAG Mill',
            Tag__c = 'Test AK Mill 6 Jul',
            Type_of_Discharge__c = 'Grate',
            Customer__c = acc.id,
            Recordtypeid = CustConveyerRecordTypeId);
        insert custEquip;
        
        Customer_Inventory_Stock__c stock = new Customer_Inventory_Stock__c();
        stock.Item_Code__c = 'Test';
        stock.Quantity__c = 12;
        stock.Customer__c = acc.id;
        insert stock;
        
        List<Customer_Inventory_Stock__c> lstcsi = new List<Customer_Inventory_Stock__c>();
        lstcsi.add(stock);
        
        id ConveyerRecordTypeId = Schema.SObjectType.Installation__c.getRecordTypeInfosByDeveloperName().get('Conveyor_Component').getRecordTypeId();

        Installation__c inst = new Installation__c(
            Name='Test Installation',
            Customer__c=acc.Id,
            Equipment_Installed_At__c=custEquip.Id,
     	    Ore__c='Alumina', BWI_Kwh_t_metric__c=10,
            Motor_Power_Kwh__c=10, F80_mm__c=10,
            Media_Top_Size_mm__c=10,
            Mill_Speed_rpm__c=10, 
            Charge_Volume__c=10,
            Throughput_tph__c=10,
            Type_of_Grinding__c='Wet',
            Circuit_Type__c='Open',
            RecordTypeId=ConveyerRecordTypeId,
            Circulating_Load_if_closed_tph__c=10,
            Max_Temperature_C__c=10, pH_Value_of_the_Slurry__c=10);
        insert inst;
        
        Installation_PDF_Template__c instTemp = new Installation_PDF_Template__c(
            Tag_Line__c='abc',
            Logo__c='xyz',
            Introduction_Letter__c='hi'
        );
        insert instTemp;
        
        Installation_line_Items__c instLineItem = new Installation_line_items__c(Installation__c=inst.Id, Equipment_has_been_Installed_at__c = custEquip.Id, 
                                                                                Customer_Inventory_Line_Stock__c = stock.Id);
        insert instLineItem;
        
        List<Installation_line_Items__c> instLineItemList = new List<Installation_line_Items__c>();
        instLineItemList.add(instLineItem);
        
        /*Test.startTest();
        Test.setCurrentPage(Page.InstallationPDF);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstcsi);
        stdSetController.setSelected(lstcsi);
        InstallationPDFController ext = new InstallationPDFController(stdSetController);
        ext.InstallationPDFController();*/

       test.startTest();
        Test.setCurrentPage(Page.InstallationPDF);
        InstallationPDFController IPC = new InstallationPDFController(new ApexPages.StandardController(inst));
		IPC.getInstallationlineItemsDetails();
        IPC.currentInstallation();
        IPC.getFields();
        IPC.getInstallation();
        IPC.getInstallationDetails();
        test.stopTest();
    }
    
}
        
   /*      id ConveyerRecordTypeId = Schema.SObjectType.Product_Proposal_Form__c.getRecordTypeInfosByDeveloperName().get('Conveyer_Component').getRecordTypeId();

        Installation__c inst = new Installation__c(
            Name='Test Installation',
            Customer__c=acc.Id,
            Equipment_Installed_At__c=custEquip.Id,
     	    Ore__c='Alumina', BWI_Kwh_t_metric__c=10,
            Motor_Power_Kwh__c=10, F80_mm__c=10,
            Media_Top_Size_mm__c=10,
            Mill_Speed_rpm__c=10, 
            Charge_Volume__c=10,
            Throughput_tph__c=10,
            Type_of_Grinding__c='Wet',
            Circuit_Type__c='Open',
            RecordTypeId=ConveyerRecordTypeId,
            Circulating_Load_if_closed_tph__c=10,
            Max_Temperature_C__c=10, pH_Value_of_the_Slurry__c=10);
        insert inst;
        
        Installation_PDF_Template__c instTemp = new Installation_PDF_Template__c(
            Tag_Line__c='abc',
            Logo__c='xyz',
            Introduction_Letter__c='hi'
        );
        insert instTemp;
        
        Installation_line_Items__c instLineItem = new Installation_line_items__c(
            Installation__c=inst.Id,
            Equipment_has_been_Installed_at__c = custEquip.Id,
            Customer_Inventory_Line_Stock__c = stock.Id);
        insert instLineItem;
        
        List<Installation_line_Items__c> instLineItemList = new List<Installation_line_Items__c>();
        instLineItemList.add(instLineItem);
        
        test.startTest();
        Test.setCurrentPage(Page.InstallationPDF);
        InstallationPDFController IPC = new InstallationPDFController(new ApexPages.StandardController(inst));
		IPC.getInstallationlineItemsDetails();
        IPC.currentInstallation();
        IPC.getFields();
        IPC.getInstallation();
        IPC.getInstallationDetails();
        test.stopTest();
       // ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstcsi);
        //stdSetController.setSelected(lstcsi);
        //InstallationPDFController ext = new InstallationPDFController(stdSetController);
        //ext.InstallationPDFController();
                
        Dismantle__c dism = new Dismantle__c(Name='Test Dismantle');
        insert dism;
        
        String dismId = (String)dism.Id;
        String instLineId = (String)instLineItem.Id;
        List<String> instIdList = new List<String>();
        instIdList.add(instLineId);
        
        //DismantleApexController dismApexCtrl = new DismantleApexController();
        DismantleApexController.fetchDismRecs(instLineItem.Id);
        DismantleApexController.dismantleInstLineItems(dismId,instIdList);
    }
    
}*/