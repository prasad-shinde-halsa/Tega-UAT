@isTest
public class UserBudgetTestClass {
    
    @testSetup static void setup(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        
        Group g1 = new Group(Name='Mill-Budget-TGSO-PMG Head', type='Queue');
        insert g1;
        
        List<QueuesObject> queueList = new List<QueuesObject>();
        QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Budget__c');
        queueList.add(q1);
        QueuesObject q2 = new QueueSObject(QueueID = g1.id, SobjectType = 'User_Budget__c');
        queueList.add(q2);
        insert queueList;
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
    
    private static testMethod void UserBudgetApproval(){
        
        system.debug('entered budgetDetail');
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        
        list<user>lstUsers = new list<user>();
        for(integer i=0;i<3;i++)
        {
            user usr = new user();
            usr.Alias = 'sales'+string.ValueOf(i);
            usr.Email = 'sales'+string.ValueOf(i)+'@testorg.com';
            usr.EmailEncodingKey = 'UTF-8';
            usr.firstname = 'Tst';
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
        Branch__c branch = new Branch__c(Name = 'Test Branch', Sales_Region__c = salesReg.Id,Branch_Code__c = 'TBR');
        insert branch;
        Sales_Org__c sOrg = new Sales_Org__c(Name = 'TGSO');
        insert sOrg;
        Company__c company1 = new Company__c(Name='TEGA INDUSTRIES AFRICA (PTY) LTD' , Sales_Organization__c = sOrg.id);
        insert company1;
        Sales_Org_Branch_Relationship__c salesOrgBranch = new Sales_Org_Branch_Relationship__c(Name='Test Branch-TGSO', Branch__c = branch.Id,Company__c = company1.Id, Currency_Code__c = 'INR');
        insert salesOrgBranch;
        Customer_Sales_Organization__c custSalesOrg1 = new Customer_Sales_Organization__c(Customer__c = acc.Id, Branch__c = branch.Id ,Company__c=company1.id, CreatedFromAccount__c = true);
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
        
        Account account = [Select Id,Name,Status__c from Account where Name = 'Test Account'];
        system.debug(account);
        Customer_Equipments__c customer_equipment = [SELECT id, name from Customer_Equipments__c WHERE Createddate = today order by CreatedDate DESC LIMIT 1];
        Customer_Sales_Organization__c customer_sales_org = [Select Id,branch__c,company__c,customer__c from Customer_Sales_Organization__c where Branch__r.Name = 'Test Branch'];
        system.debug('customer_sales_org===>'+customer_sales_org);
        Branch__c branch1 =[SELECT id from Branch__c WHERE name = 'Test Branch'];
        Company__c company = [Select Id,Name from Company__c where Name =: 'TEGA INDUSTRIES AFRICA (PTY) LTD'];
        String userId = UserInfo.getUserId();
        
        User user = [Select Id,Email from User where id=:userId  ];
        
        
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
        
        
        
        User_Budget__c ParentUserBudget = new User_Budget__c(
            Name='Test ParetUserBudget',
            Branch__c=branch.id,
            Company__c=company1.id,
            Status__c='New',
            Approver__c=user.id,
            //PMG__c='Mill',
            Financial_Year_Tenure__c='Current FY Year' );
        insert ParentUserBudget;
        system.debug('ParentUserBudget=rc==>'+ParentUserBudget.branch__c);
        User_Budget__c ChildUserBudget = new User_Budget__c(
            Name='Test ChildUserBudget',
            Branch__c=branch.id,
            Parent_User_Budget__c=ParentUserBudget.id,
            Company__c=company1.id,
            Status__c='New',
            Approver__c=user.id,
            PMG__c='Mill',
            Financial_Year_Tenure__c='Current FY Year' );
        insert ChildUserBudget;
        
        ChildUserBudget.Name = 'Changed Name';
        update ChildUserBudget;
        
        delete ChildUserBudget;
        
        undelete ChildUserBudget;
        
    }
}