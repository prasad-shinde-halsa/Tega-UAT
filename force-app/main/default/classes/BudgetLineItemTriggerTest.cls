@isTest
public class BudgetLineItemTriggerTest {

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
        Sales_Org__c sOrg = new Sales_Org__c(Name = 'TGSO');
        insert sOrg;
        Company__c company1 = new Company__c(Name='TEGA INDUSTRIES AFRICA (PTY) LTD' , Sales_Organization__c = sOrg.id);
        insert company1;
        Sales_Org_Branch_Relationship__c salesOrgBranch = new Sales_Org_Branch_Relationship__c(Name='Test Branch-TGSO', Branch__c = branch.Id,Company__c = company1.Id, Currency_Code__c = 'INR');
        insert salesOrgBranch;
        
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
    
     private static testMethod void BudgetDetail(){
        system.debug('entered budgetDetail');
        Account account = [Select Id,Name,Status__c from Account where Name = 'Test Account'];
         system.debug(account);
        Customer_Equipments__c customer_equipments = [SELECT id, name from Customer_Equipments__c WHERE Createddate = today order by CreatedDate DESC LIMIT 1];
        Customer_Sales_Organization__c customer_sales_organization = [Select Id from Customer_Sales_Organization__c where Branch__r.Name = 'Test Branch'];
        Branch__c branch =[SELECT id from Branch__c WHERE name = 'Test Branch'];
        
        User user = [Select Id,Email from User where Email = 'ayush.khanna1@ibm.com' limit 1];
        
        User_Mappings__c globalSalesHead = new User_Mappings__c(User_Type__c='Global Sales Head',Object_Name__c = 'User_Budget__c',User__c = user.Id); 
        insert globalSalesHead;
         
        RecordType budgetRecType = [Select Id,Name From RecordType  Where SobjectType = 'Budget__c' and DeveloperName = 'Budget'];
        
         
         Budget__c budget = new Budget__c(
         Name='Test HD budget',
         Customer__c=account.id,
         Customer_Branch_Assignment__c=customer_sales_organization.id,
         PMG__c='Mill',
         CurrencyIsoCode='INR',
         Budget_For_Financial_Year__c='Current FY Year',
         RecordTypeId=budgetRecType.id
         //  Financial_Year__c=2023-2024
           
         );
         insert budget;
       
        
         
       RecordType budgetLineRecType = [Select Id,Name From RecordType  Where SobjectType = 'L2_Budget_Line_Item__c' and DeveloperName = 'Budget_Line_Item'];
  
        L2_Budget_Line_Item__c budgetLineItem = new L2_Budget_Line_Item__c(
            Budget__c = budget.id,
            Order_Type__c   ='Spares',
            Installation_Date__c= Date.newInstance(2023, 10, 4),
            CurrencyIsoCode='EUR',
            RecordTypeId=budgetLineRecType.id
            
        );
         insert budgetLineItem;
         
         delete budgetLineItem;
        undelete budgetLineItem;
         
         List<Monthly_Budget_Detail__c> monthlyBudgetList = new List<Monthly_Budget_Detail__c>();
          Monthly_Budget_Detail__c monthRec = new Monthly_Budget_Detail__c(
         L2_Budget_Line_Item__c = budgetLineItem.Id
         ); 
         monthlyBudgetList.add(monthRec);

         
          Monthly_Budget_Detail__c monthRecord = new Monthly_Budget_Detail__c(
         L2_Budget_Line_Item__c = budgetLineItem.Id
         ); 
         monthlyBudgetList.add(monthRecord);

         insert monthlyBudgetList;
         
          
         
         budgetLineItem.Order_Occurence__c=10;
         update budgetLineItem;
         budgetLineItem.Quantity__c=10;
         update budgetLineItem;

      
     }
}