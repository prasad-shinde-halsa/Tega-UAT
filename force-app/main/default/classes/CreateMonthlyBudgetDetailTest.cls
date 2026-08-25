@isTest
public class CreateMonthlyBudgetDetailTest {
    
    //Test Class on Hold till we finalise budget code
    
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
        Sales_Org_Branch_Relationship__c salesOrgBranch = new Sales_Org_Branch_Relationship__c(Name='Test Branch-TGSO', Branch__c = branch.Id, Company__c=company1.Id,Currency_Code__c = 'INR');
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
    
    private static testMethod void MonthlyBudgetDetail(){
        system.debug('entered budgetDetail');
        Account account = [Select Id,Name,Status__c from Account where Name = 'Test Account'];
        system.debug(account);
        Customer_Equipments__c customer_equipments = [SELECT id, name from Customer_Equipments__c WHERE Createddate = today order by CreatedDate DESC LIMIT 1];
        Customer_Sales_Organization__c customer_sales_organization = [Select Id from Customer_Sales_Organization__c where Branch__r.Name = 'Test Branch'];
        Branch__c branch =[SELECT id from Branch__c WHERE name = 'Test Branch'];
        
        User user = [Select Id,Email from User where Email = 'ayush.khanna1@ibm.com' limit 1];
        
        
        Part_List__c prt = new Part_List__c(Name = 'Test1993', Customer__c = account.Id);
        insert prt;
        Product2 l2Prod = new Product2(Name = 'PLM-01256-02-SHELL',
                                       Part_List__c = prt.id);
        insert l2Prod;
        
        
        
        
        Inventory_Score_Simulation__c invScoreSim = new Inventory_Score_Simulation__c
            (Customer__c = account.Id,
             All_Customer_Inventory_applicable__c=true);
        insert invScoreSim;
        
        // List<Inventory_Score_Relationship__c> lstRelationship = new List<Inventory_Score_Relationship__c>();
        Inventory_Score_Relationship__c tstScoreRelation = new Inventory_Score_Relationship__c(
            Customer__c = account.id,
            Inventory_Score_Simulation__c = invScoreSim.id,
            Part_List__c = prt.id,
            Priority__c = '4',
            L2_Set_Qty__c = 2.0);
        insert tstScoreRelation;
        
        RecordType budgetRecType = [Select Id,Name From RecordType  Where SobjectType = 'Budget__c' and DeveloperName = 'Budget'];
        
        User_Mappings__c globalSalesHead = new User_Mappings__c(User_Type__c='Global Sales Head',Object_Name__c = 'User_Budget__c',User__c = user.Id); 
        insert globalSalesHead;
        
        Budget__c budget = new Budget__c(
            Name='Test HD budget',
            Customer__c=account.id,
            Customer_Branch_Assignment__c=customer_sales_organization.id,
            PMG__c='Mill',
            CurrencyIsoCode='INR',
            Part_List__c=prt.id,
            Budget_For_Financial_Year__c='Current FY Year',
            Inventory_Part_List_Relationship__c=tstScoreRelation.Id,
           RecordTypeId=budgetRecType.id
            // Financial_Year__c=2023-2024 
        );
        insert budget;
        
        Zone_Identification_For_Budget__c zoneId = new Zone_Identification_For_Budget__c(
            Name = 'Test HD Zone',
            Lead_Time_Months__c=7,
            Negotitation_Time_Months__c=10,
            Life__c=6,
            Transit_Time_Months__c=11,
            Part_List__c=prt.id,
            Budget__c = budget.id
        );
        insert zoneId;
        
        RecordType budgetLineRecType = [Select Id,Name From RecordType  Where SobjectType = 'L2_Budget_Line_Item__c' and DeveloperName = 'Budget_Line_Item'];
        
        List<List<L2_Budget_Line_Item__c>> budlineList = new List<List<L2_Budget_Line_Item__c>>();
        List<L2_Budget_Line_Item__c> bliList = new List<L2_Budget_Line_Item__c>();
        L2_Budget_Line_Item__c budgetLineItem = new L2_Budget_Line_Item__c(
            Budget__c = budget.id,
            Order_Type__c   ='Spares',
            Order_Occurence__c=2,
            Recurring_Order_Time_Interval_Months__c=3,
            Installation_Date__c= Date.newInstance(2023, 1, 1),
            CurrencyIsoCode='EUR',
            Zone_Identification_For_Budget__c=zoneId.id,
            RecordTypeId=budgetLineRecType.id,
            Product_L2__c=l2Prod.id);
        bliList.add(budgetLineItem);
        
        L2_Budget_Line_Item__c budgetLineItem1 = new L2_Budget_Line_Item__c(
            Budget__c = budget.id,
            Order_Type__c   ='Spares',
            Order_Occurence__c=2,
            Installation_Date__c= Date.newInstance(2023, 1, 1),
            CurrencyIsoCode='EUR',
            Recurring_Order_Time_Interval_Months__c=3,
            Zone_Identification_For_Budget__c=zoneId.id,
            RecordTypeId=budgetLineRecType.id,
            Product_L2__c=l2Prod.id);
        bliList.add(budgetLineItem1);
        insert bliList;
        budlineList.add(bliList);
        
        
        //insert budlineList;
        
        //lstRelationship.add(tstScoreRelation);
        
        /* Inventory_Score_Relationship__c tstScoreRelation1 = new Inventory_Score_Relationship__c(
Customer__c = account.id,
Inventory_Score_Simulation__c = invScoreSim.id,
Part_List__c = prt.id,
Priority__c = '2',
L2_Set_Qty__c = 2.0);
lstRelationship.add(tstScoreRelation1);
insert lstRelationship;*/
        
        Product2 product2 = new Product2(
            Name = 'PLM-03960-02-FEH',
            ProductCode = 'PLM-03960-02-FEH',
            Description = 'FEH-BALL DIA- 2400 X 4300 MM EGL',
            IsActive = false,
            CurrencyIsoCode = 'USD',
            Part_List__c = prt.id,
            Product_Level__c = 'L2',
            Quantity__c = 1.0);
        insert product2;
        
        Zone_Priority_Selection__c tstZone1 = new Zone_Priority_Selection__c(
            Inventory_Part_List_Relationship__c = tstScoreRelation.Id,
            Part_List__c = prt.Id,
            Priority__c =2,
            Zone_L2__c=l2Prod.id,
            Score__c=66.0
            );
        insert tstZone1;
        /* List<Monthly_Budget_Detail__c> monthlyBudgetList = new List<Monthly_Budget_Detail__c>();
Monthly_Budget_Detail__c monthRec = new Monthly_Budget_Detail__c(
L2_Budget_Line_Item__c = budgetLineItem.Id
);  
monthlyBudgetList.add(monthRec);


Monthly_Budget_Detail__c monthRecord = new Monthly_Budget_Detail__c(
L2_Budget_Line_Item__c = budgetLineItem.Id
);  
monthlyBudgetList.add(monthRecord);

insert monthlyBudgetList;*/
        
        List<id> iDs = new List<id>();
        iDs.add(budgetLineItem.id);
        
        /* budgetLineItem.budget_against_po__c=10;
update budgetLineItem;
budgetLineItem.payment_against_dispatch__c=10;
update budgetLineItem;

delete budgetLineItem;
undelete budgetLineItem;*/
        
        
        CreateMonthlyBudgetDetail.createMonthlyBudgetDetailMethod(iDs);
        
       // CreateMonthlyBudgetDetailManual.createMonthDetManualSingleYear(budlineList);
        
        
         List<List<L2_Budget_Line_Item__c>> budgetlineList = new List<List<L2_Budget_Line_Item__c>>();
        List<L2_Budget_Line_Item__c> budliList = new List<L2_Budget_Line_Item__c>();
        L2_Budget_Line_Item__c budgetLineItemDonotInsert = new L2_Budget_Line_Item__c(
            Budget__c = budget.id,
            Order_Type__c   ='Spares',
            Order_Occurence__c=2,
            Installation_Date__c= Date.newInstance(2023, 1, 1),
            CurrencyIsoCode='EUR',
            Recurring_Order_Time_Interval_Months__c=3,
            Zone_Identification_For_Budget__c=zoneId.id,
            RecordTypeId=budgetLineRecType.id,
            Product_L2__c=l2Prod.id);
         budliList.add(budgetLineItemDonotInsert);
        budgetlineList.add(budliList);
       CreateBLIMultiYear.createMultiBLIMultiYear(budgetlineList);
        
        List<List<L2_Budget_Line_Item__c>> budgetlineList1 = new List<List<L2_Budget_Line_Item__c>>();
        List<L2_Budget_Line_Item__c> budliList1 = new List<L2_Budget_Line_Item__c>();
        L2_Budget_Line_Item__c budgetLineItemDonotInsert1 = new L2_Budget_Line_Item__c(
            Budget__c = budget.id,
            Order_Type__c   ='Spares',
            Order_Occurence__c=2,
            Installation_Date__c= Date.newInstance(2023, 1, 1),
            CurrencyIsoCode='EUR',
            Recurring_Order_Time_Interval_Months__c=3,
            Zone_Identification_For_Budget__c=zoneId.id,
            RecordTypeId=budgetLineRecType.id,
            Product_L2__c=l2Prod.id);
         budliList1.add(budgetLineItemDonotInsert1);
        budgetlineList1.add(budliList1);
       CreateMonthlyBudgetDetailManual.createMonthDetManualSingleYear(budgetlineList1);

    }
}