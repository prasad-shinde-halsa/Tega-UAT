@isTest
public class PPRLineItemTriggerTest {
    
    @testSetup static void setup(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        
        Group g1 = new Group(Name='Mill-PPR-TG01-CCDI', type='Queue');
        insert g1;
            
            /*List<QueuesObject> queueList = new List<QueuesObject>();
            QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Task');
            queueList.add(q1);
            QueuesObject q2 = new QueueSObject(QueueID = g1.id, SobjectType = 'Task');
            queueList.add(q2);
            insert queueList;*/
        
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
        
         GroupMember member = new GroupMember();
			member.UserOrGroupId = lstUsers[0].id;
			member.GroupId = g1.Id;
           insert member;
       
        
       
        
    }
    
    private static testMethod void PPrTrigger(){
        system.debug('entered PPrApproval');
        
       
       
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
            usr.UserName = 'salesuser'+string.ValueOf(i)+'@testorg.com';
            lstUsers.add(usr);
        }
        insert lstUsers;

        
        Sales_Region__c salesReg = new Sales_Region__c(Name = 'Test Sales Region', Manager__c = lstUsers[0].Id);
        insert salesReg;
        Account acc = new Account(Name = 'Test Account' , Status__c = 'Sync with SAP');
        insert acc;
        system.debug('Account'+acc);
        Branch__c branch1 = new Branch__c(Name = 'Test Branch', Sales_Region__c = salesReg.Id,Branch_Code__c = 'TBR');
        insert branch1;
        Sales_Org__c sOrg = new Sales_Org__c(Name = 'TGSO');
        insert sOrg;
        Company__c company1 = new Company__c(Name='TEGA INDUSTRIES LTD' , Sales_Organization__c = sOrg.id , Company_Code__c='TG01');
        insert company1;
        Customer_Sales_Organization__c custSalesOrg1 = new Customer_Sales_Organization__c(company__c=company1.id,Customer__c = acc.Id, Branch__c = branch1.Id , CreatedFromAccount__c = true);
        insert custSalesOrg1;
        
         Account account = [Select Id,Name,Status__c from Account where Name = 'Test Account'];
        system.debug(account);
        Branch__c branch =[SELECT id from Branch__c WHERE name = 'Test Branch'];
        Company__c company = [Select Id,Name,Company_Code__c from Company__c where Name =: 'TEGA INDUSTRIES LTD'];
        Customer_Sales_Organization__c customer_sales_organization = [Select Id , company__c from Customer_Sales_Organization__c where Branch__c =: branch.id];
        
        id  MillRecordTypeId = Schema.SObjectType.Customer_Equipments__c.getRecordTypeInfosByDeveloperName().get('Mill').getRecordTypeId();
        
        Customer_Equipments__c customer_equipment = new Customer_Equipments__c(
            CurrencyIsoCode = 'EUR',
            Circuit_diagram_available__c = false,
            Dia_m__c = 123.0,
            Mill_Type__c = 'SAG Mill',
            Tag__c = 'Test AK Mill 6 Jul',
            Type_of_Discharge__c = 'Grate',
            Customer__c = acc.id,
            Recordtypeid = MillRecordTypeId);
        insert customer_equipment;
        
       Customer_Equipments__c customer_equipments = [SELECT id, name from Customer_Equipments__c WHERE Createddate = today order by CreatedDate DESC LIMIT 1];

        
        User user = [Select Id,Email from User where Email = 'ayush.khanna1@ibm.com' limit 1];
        
        
        Part_List__c prt = new Part_List__c(Name = 'Test1993', Customer__c = account.Id);
        insert prt;
       	RecordType ProdRecType = [Select Id,Name From RecordType  Where SobjectType = 'Product2' and DeveloperName = 'Product_L3'];

        Product2 l3Prod = new Product2(Name = 'L3Product',
                                       RecordTypeId=ProdRecType.id,
                                       Part_List__c = prt.id);
        insert l3Prod;
        
        L2_L3_product__c l2l3Pro = new L2_L3_product__c(Part_List__c = prt.Id, 
                                                        Product_L3__c = l3Prod.Id
                                                       );
        insert l2l3Pro;                                          
        
         Pricebook2 pricebook2 = new Pricebook2(
            Name = 'Standard Price Book',
            CurrencyIsoCode = 'USD',
            IsActive = true);
        insert pricebook2;
        
        Order ord = new Order();
        ord.Name= 'test';
        ord.Pricebook2Id = pricebook2.id;
        ord.AccountId = account.id;
        ord.EffectiveDate = date.newInstance(2022, 12, 10);
        ord.Status = 'Draft';
        ord.CurrencyIsoCode = 'INR';
        insert ord;
        
        PPR_Line_Item__c PPRLIRec = new PPR_Line_Item__c(
           // Branch__c=branch.id,
           // Company__c=company1.id,
            Customer_Branch_Assignment__c=customer_sales_organization.id,
            Customer_Name__c=account.id,
            Equipment__c=customer_equipments.id,
            PMG__c='Mill',
            Installed__c=false,
            Failure_Category__c='Fitment Problem',
            Part_List__c=prt.id,
            Installation_date__c=Date.newInstance(2023, 1, 1),
            Problem_detection_date__c=Date.newInstance(2023, 1, 11),
            Description_of_Problem__c='budget is not enough',
            Cause_Give_Your_Opinion__c='should not remove existing resouces',
            Sales_Order_Number__c=ord.id,
            FRO_required_for_this_item__c='No'
        );
        insert PPRLIRec;
        system.debug('PPRLIRec==>'+PPRLIRec);
        
        PPR_Line_Item__c PPRLIRec1 = new PPR_Line_Item__c(
           // Branch__c=branch.id,
           // Company__c=company1.id,
            Customer_Branch_Assignment__c=customer_sales_organization.id,
            Customer_Name__c=account.id,
            Equipment__c=customer_equipment.id,
            PMG__c='Mill',
            Installed__c=false,
            Failure_Category__c='Fitment Problem',
            Part_List__c=prt.id,
            Installation_date__c=Date.newInstance(2023, 1, 1),
            Problem_detection_date__c=Date.newInstance(2023, 1, 1),
            Description_of_Problem__c='budget is not enough',
            Cause_Give_Your_Opinion__c='should not remove existing resouces',
            Sales_Order_Number__c=ord.id,
            FRO_required_for_this_item__c='yes'
        );
        insert PPRLIRec1;
		system.debug('PPRLIRec1==>'+PPRLIRec1);

        
        PPR_Product_Relationship__c PPrRelationRec = new PPR_Product_Relationship__c(
        	PPR_Line_Item__c=PPRLIRec.id,
            Part_List__c=prt.id,
            Product__c=l3Prod.id,
            FRO_Quantity__c=2.0,
            Required_Quantity__c=5,
            Deadline_for_action__c=Date.newInstance(2024, 2, 1),
        	FRO_Applicable__c=true
       
        );
        insert PPrRelationRec;
        
         Task TaskRec = new Task(
            //WhatId=PPRLIRec.id,
            PPR_Line_Item__c=PPRLIRec.id,
            Subject='Long Term',
            Department_Name__c='CCDI'
        
        );
        insert TaskRec;
        
        PPRLIRec.Status__c ='Submit to Department';
        update PPRLIRec;
     
        List<String> userBud = new List<String>();
        userBud.add(PPRLIRec.id);
        //userBud.add('L2');
        
        List<List<String>> UserBudgetList = new List<List<String>>();
        UserBudgetList.add(userBud);
        delete PPRLIRec;
        undelete PPRLIRec;
        
        
    }
}