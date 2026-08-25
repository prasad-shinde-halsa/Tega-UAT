@IsTest(SeeAllData=false)
public class ProductDetailSowTriggerTest {
    
    @testSetup static void setup(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
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
        
        
        Account acc = new Account(Name = 'Test Account' , Status__c = 'Sync with SAP');
        insert acc;
        system.debug('Account'+acc);
        Branch__c branch = new Branch__c(Name = 'Test Branch', Sales_Region__c = salesReg.Id,Branch_Code__c = 'TBR');
        insert branch;
        Customer_Sales_Organization__c custSalesOrg1 = new Customer_Sales_Organization__c(Customer__c = acc.Id, Branch__c = branch.Id , CreatedFromAccount__c = true);
        insert custSalesOrg1;
        
        id  ConveyerRecordTypeId = Schema.SObjectType.Customer_Equipments__c.getRecordTypeInfosByDeveloperName().get('Conveyor_Component').getRecordTypeId();
        
        Customer_Equipments__c customer_equipments = new Customer_Equipments__c(
            CurrencyIsoCode = 'EUR',
            Circuit_diagram_available__c = false,
            Dia_m__c = 123.0,
            Mill_Type__c = 'SAG Mill',
            Tag__c = 'Test AK Mill 6 Jul',
            Type_of_Discharge__c = 'Grate',
            Customer__c = acc.id,
            Recordtypeid = ConveyerRecordTypeId);
        insert customer_equipments;
    }     
    
    private static testMethod void ProductDetail(){
        
        Account account = [Select Id,Name,Status__c from Account where Name = 'Test Account'];
        Customer_Equipments__c customer_equipments = [SELECT id, name from Customer_Equipments__c WHERE Createddate = today order by CreatedDate DESC LIMIT 1];
        Customer_Sales_Organization__c customer_sales_organization = [Select Id from Customer_Sales_Organization__c where Branch__r.Name = 'Test Branch'];
        Branch__c branch =[SELECT id from Branch__c WHERE name = 'Test Branch'];
        
        User user = [Select Id,Email from User where Email = 'ayush.khanna1@ibm.com' limit 1];
        
        RecordType CCRecType = [Select Id,Name From RecordType  Where SobjectType = 'Opportunity' and DeveloperName = 'Conveyor_Component'];
        
        Opportunity opportunity = new Opportunity(
            AccountId = account.id,
            Name = 'Test AK OPP 6 Jul',
            Customer_Branch_Assignment__c  = customer_sales_organization.id,
            status__c = 'closed',
            Probability = 100.0,
            CloseDate = Date.newInstance(2022,07,21),
            ForecastCategoryName = 'Closed',
            CurrencyIsoCode = 'USD',
            stagename='closed won',
            RecordTypeId =CCRecType.Id,
            OwnerId = user.id
            
        );
        insert opportunity;
        
        
        RecordType CCRecTypeop = [Select Id,Name From RecordType  Where SobjectType = 'Operating_Parameters__c' and DeveloperName = 'Conveyor_Component'];
        
        Operating_Parameters__c operating_parameters = new Operating_Parameters__c(
            CurrencyIsoCode = 'USD',
            Bulk_Density_t_m3__c = 10.0,
            Circuit_diagram_available__c = false,
            Customer_Equipment__c = customer_equipments.id,
            Silica_Content__c = 20.0,
            Status__c = 'Current',
            Moisture__c = 30.0,
            Ore__c = 'Betonite, 100 mesh',
            Shape_of_Particles__c = 'Round',
            customer__c = account.id,
            Recordtypeid = CCRecTypeop.id);
        insert operating_parameters;
        
        
        
        RecordType CCRecTypeprf = [Select Id,Name From RecordType  Where SobjectType = 'Proposal_Form__c' and DeveloperName = 'Conveyor_Component'];
        
        Proposal_Form__c proposal_form = new Proposal_Form__c(
            CurrencyIsoCode = 'EUR',
            Customer_Equipment__c = customer_equipments.id,
            Opportunity__c = opportunity.id,
            Conversion__c = 'Converted potential',
            Conversion_sub_type__c = 'Application conversion',
            Spares__c = 'Spares Without Modification',
            Type__c = 'Conversion',
            Status__c = 'New',
            Recordtypeid = CCRecTypeprf.id,
            Operating_Parameters__c= operating_parameters.id
            //Design_Parameter__c = DesignParam.id
        );
        insert proposal_form;
        
        Location__c loc = new Location__c(
            Customer_Equipment__c = customer_equipments.Id,
            Name='Test Location CC1 w/ Product Installed'
        );
        insert loc;
        
        
        List<string> ListOfProdtype = new List<string>{
            'Belt Tracker Roller','Belt Scrapers','Side Skirt Sealing','Rear Skirt Sealing',
                'Impact Pad Without Frame','Impact Bed System','Ceramic Pulley Lagging','Ceradisc'
                };
                    
        List<RecordType> PiRecordTypeList = [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType WHERE SobjectType  = 'Product_Installed__c'];
        
        List<Product_Installed__c> piList = new List<Product_Installed__c>();

        //id RecTypeId = Schema.SObjectType.Product_Installed__c.getRecordTypeInfosByDeveloperName().get('CeraDisc').getRecordTypeId();
        for(RecordType recType : PiRecordTypeList){
            for(string productType: ListOfProdtype){
                Product_Installed__c pi = new Product_Installed__c();
                pi.Location__c=loc.Id;
                pi.Price__c = 20;
                pi.RecordTypeId = recType.id;
                pi.N_of_Rollers__c=3;
                pi.Roller_Dia__c=5;
                pi.Roller_Length__c=1;
                pi.Trough_Angle__c=2;
                pi.Present_Sway__c=3;
                pi.Return_Belt_Condition__c='Skew/mis-aligned belt joint';
                pi.Type_of_Pulley__c='Magnetic';
                pi.Crowning_of_Pulley__c='Yes';
                pi.Belt_Run_Back__c='Yes';
                pi.Any_Special_Paint__c='no';
                pi.Any_Other_Special_Requirement__c='no';
                pi.Gap_Between_Skirt_and_Belt_Edge__c=8;
                pi.Free_Fall_Height__c=7;
                pi.Length_of_Impact_Bed__c=1;
                pi.Face_Width__c=7;
                pi.Dia_of_Pulley__c=8;
                piList.add(pi);       
            } 
        }
        
        insert piList;
        update piList;
        delete piList;
        undelete piList;
        
        id ConveyerRecordTypeId = Schema.SObjectType.Product_Proposal_Form__c.getRecordTypeInfosByDeveloperName().get('Conveyer_Component').getRecordTypeId();
        
        List<Product_Proposal_Form__c> pdSowList = new List<Product_Proposal_Form__c>();
        
        for(String ProdType :ListOfProdtype) {         
            Product_Proposal_Form__c pdsow = new Product_Proposal_Form__c();
            pdsow.Customer_Equipment__c = customer_equipments.id;
            pdsow.Location__c=loc.id ;
            pdsow.Proposal_Form__c= proposal_form.id;
            pdsow.Product_Type__c= ProdType;
            pdsow.RecordTypeId=ConveyerRecordTypeId;
            pdSowList.add(pdsow);
            
        }
        
        insert pdSowList;
        update pdSowList;
        delete pdSowList;
        undelete pdSowList;
        
    }
    
}