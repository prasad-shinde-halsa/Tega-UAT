//for class ShowQuestionariesController by Himanshi
@isTest
public class ShowQuestionariesControllerTest {
		
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
        Company__c company = new Company__c(Name = 'TEGA INDUSTRIES AFRICA (PTY) LTD');
        insert company;
        id  MillRecordTypeId = Schema.SObjectType.Customer_Equipments__c.getRecordTypeInfosByDeveloperName().get('Mill').getRecordTypeId();
        
        Customer_Equipments__c customer_equipments = new Customer_Equipments__c(
            CurrencyIsoCode = 'EUR',
            Circuit_diagram_available__c = false,
            Dia_m__c = 123.0,
            Mill_Type__c = 'SAG Mill',
            Tag__c = 'Test AK Mill 6 Jul',
            Type_of_Discharge__c = 'Grate',
            Customer__c = acc.id,
            Recordtypeid = MillRecordTypeId);
        insert customer_equipments;
        
        
        
    }
    
    private static testMethod void ShowQuestions(){
        
		system.debug('entered budgetDetail');
        Account account = [Select Id,Name,Status__c from Account where Name = 'Test Account'];
        system.debug(account);
        Customer_Equipments__c customer_equipments = [SELECT id, name from Customer_Equipments__c WHERE Createddate = today order by CreatedDate DESC LIMIT 1];
        Customer_Sales_Organization__c customer_sales_organization = [Select Id from Customer_Sales_Organization__c where Branch__r.Name = 'Test Branch'];
        Branch__c branch =[SELECT id from Branch__c WHERE name = 'Test Branch'];
        Company__c company1 = [Select Id,Name from Company__c where Name =: 'TEGA INDUSTRIES AFRICA (PTY) LTD'];

        User user = [Select Id,Email from User where Email = 'ayush.khanna1@ibm.com' limit 1];
        
        
        Part_List__c prt = new Part_List__c(Name = 'Test1993', Customer__c = account.Id);
        insert prt;
        Product2 l2Prod = new Product2(Name = 'PLM-01256-02-SHELL',
                                       Part_List__c = prt.id);
        insert l2Prod;
        
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
            Failure_Category__c='Bolt Breakage;De-bonding;Poor Life of Rubber / Faster Wear',
            Part_List__c=prt.id,
            Installation_date__c=Date.newInstance(2023, 1, 1),
            Problem_detection_date__c=Date.newInstance(2023, 1, 1),
            Description_of_Problem__c='budget is not enough',
            Cause_Give_Your_Opinion__c='should not remove existing resouces',
            Sales_Order_Number__c=ord.id,
            FRO_required_for_this_item__c='No'
        );
        insert PPRLIRec;
        
        List<Question_Master__c> QmList = new List<Question_Master__c>();
        Question_Master__c QmRec = new Question_Master__c(
        	Default_Value__c='xyz',
            Failure_Category__c='De-bonding',
            PMG__c='Mill',
            Question_Label__c='what is the next project',
            Question_Type__c='Text',
            Sequence__c =1,
            Drop_Down_Options__c='select all',
            Mandatory__c=true
        );
        QmList.add(QmRec);
        Question_Master__c QmRec1 = new Question_Master__c(
        	Default_Value__c='xyz',
            Failure_Category__c='De-bonding',
            PMG__c='Mill',
            Question_Label__c='what is the next project',
            Question_Type__c='Date',
            Sequence__c =1,
            Drop_Down_Options__c='select all',
            Mandatory__c=true
        );
        QmList.add(QmRec1);
        Question_Master__c QmRec2 = new Question_Master__c(
        	Default_Value__c='xyz',
            Failure_Category__c='De-bonding',
            PMG__c='Mill',
            Question_Label__c='what is the next project',
            Question_Type__c='Drop-Down',
            Sequence__c =1,
            Drop_Down_Options__c='select all',
            Mandatory__c=true
        );
         QmList.add(QmRec2);
         Question_Master__c QmRec3 = new Question_Master__c(
        	Default_Value__c='xyz',
            Failure_Category__c='De-bonding',
            PMG__c='Mill',
            Question_Label__c='what is the next project',
            Question_Type__c='Drop-Down',
            Sequence__c =1,
            Drop_Down_Options__c='select all'
        );
        QmList.add(QmRec3);
        insert QmList;
        
        PPR_Question_Answer__c PPrQnA = new PPR_Question_Answer__c(
        	Answer__c='why is budget less',
            PPR_Line_Item__c=PPRLIRec.id,
            //Question__c='',
            Question_Master__c=QmRec.id,
            Question_Label__c='Removal of resources'
           
        );
        insert PPrQnA;
        
        //wrapList[count] = PPRLIRec +';'+ QuestionMaster +';' + Answer ;
        String pprId = PPRLIRec.id;
        String qmId = QmRec.id;
       	String ans = PPrQnA.Answer__c;
       	string finalStr= pprId +';'+ qmId +';' + ans;  
        List<string> WrapList = new List<string>();
        WrapList.add(finalStr);
        
        ShowQuestionariesController.createMultipleRecord(WrapList);
        ShowQuestionariesController.getQuestionaWrapperList(PPRLIRec.id);
        
    }
        
}