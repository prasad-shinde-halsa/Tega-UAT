@isTest(SeeAllData=false)
public class FinalizeOfferControllerTest {
    static testmethod void FinalOfferControllerMethod(){        
        User u = new User();
        u.Id = UserInfo.getUserId();
        u.SalesGroupCode__c = 'Test';
        update u;
        
		Sales_Region__c salesReg = new Sales_Region__c(Name = 'Test Sales Region', Manager__c = UserInfo.getUserId());
        insert salesReg;
        
        Account acc = new Account (Name = 'My Test Account',Sales_Region__c = salesReg.Id);
        insert acc;
        
        Branch__c branch = new Branch__c(Name = 'Test Branch', Sales_Region__c = salesReg.Id, Branch_Code__c = 'TBR');
        insert branch;
        
        Customer_Sales_Organization__c custSalesOrg1 = new Customer_Sales_Organization__c(
            Customer__c = acc.Id,
            Branch__c = branch.Id,
            CreatedFromAccount__c =true
        );
        
        insert custSalesOrg1;
        
        acc.Sync_with_SAP__c = true;
        update acc;
        
        Opportunity oppt = new Opportunity(Name ='tega',
                                           AccountID = acc.Id,
                                           StageName = 'Customer Won',
                                           Amount = 3000,
                                           CloseDate = System.today(),
                                           PriceBook2Id = Test.getStandardPricebookId(),
                                           Customer_Branch_Assignment__c = custSalesOrg1.Id
                                          );
        
        insert oppt;
        
        Sales_Org__c sOrg = new Sales_Org__c(Name = 'TGSO');
        insert sOrg;
        
        system.assertEquals('TGSO', sOrg.Name);
        
        List<Quote> quoteList = new List<Quote>();
        Id offerRecordTypeId = TegaUtilityWithoutSharing.getOfferRecordTypeId('Offer');
        Quote quote = new Quote(Name = 'tegaTest1' ,
                                OpportunityId=oppt.Id,
                                recordTypeId = offerRecordTypeId,
                                Approval_Status__c = 'Price Accepted' ,
                                Quotation_Date__c = Date.today(),
                                Quotation_Validity__c = Date.today().adddays(20),
                                Branch__c = branch.Id, 
                                Sales_Org__c = sOrg.Id,
                                SalesGrp__c = 'ABCDE',
                                Status = 'Draft',
                                BTP_Type__c = 'FOB',
                                Payment_Months__c = 0,
                                Pricebook2Id =  Test.getStandardPricebookId() );
        
        insert quote;
        
        //FinalizeOfferController Finalofferins = new FinalizeOfferController();
        //FinalizeOfferController.finalOffer(quote.id);
        FinalizeOfferController.customLabelItem();
        FinalizeOfferController.checkCurrencies(quote.id);
        FinalizeOfferController.getErrorLabels();
        Quote testquote = [select id,name,status,Approval_Status__c from Quote where Name = 'tegaTest1' ];
       // System.assertEquals('Finalized', testquote.status);
       // System.assertEquals('Submitted', testquote.Approval_Status__c);
    }
    
    static testmethod void FinalOfferControllerMethod_MisMatchCurrency(){ 
        try{
            User u = new User();
            u.Id = UserInfo.getUserId();
            u.SalesGroupCode__c = 'Test';
            update u;
            
            Sales_Region__c salesReg = new Sales_Region__c(Name = 'Test Sales Region', Manager__c = UserInfo.getUserId());
            insert salesReg;
            
            Account acc = new Account (Name = 'My Test Account',Sales_Region__c = salesReg.Id,CurrencyIsoCode = 'INR',Currency__c = 'INR');
            insert acc;
            
            Branch__c branch = new Branch__c(Name = 'Test Branch', Sales_Region__c = salesReg.Id, Branch_Code__c = 'TBR');
            insert branch;
            
            Customer_Sales_Organization__c custSalesOrg1 = new Customer_Sales_Organization__c(
                Customer__c = acc.Id,
                Branch__c = branch.Id,
                CreatedFromAccount__c =true
            );
            
            insert custSalesOrg1;
            
            acc.Sync_with_SAP__c = true;
            update acc;
            
            Opportunity oppt = new Opportunity(Name ='tega',
                                               AccountID = acc.Id,
                                               StageName = 'Customer Won',
                                               Amount = 3000,
                                               CloseDate = System.today(),
                                               CurrencyIsoCode = 'EUR',
                                               PriceBook2Id = Test.getStandardPricebookId(),
                                               Customer_Branch_Assignment__c = custSalesOrg1.Id
                                              );
            
            insert oppt;
            
            Sales_Org__c sOrg = new Sales_Org__c(Name = 'TGSO');
            insert sOrg;
            
            system.assertEquals('TGSO', sOrg.Name);
            
            List<Quote> quoteList = new List<Quote>();
            Id offerRecordTypeId = TegaUtilityWithoutSharing.getOfferRecordTypeId('Offer');
            Quote quote = new Quote(Name = 'tegaTest1' ,
                                    OpportunityId=oppt.Id,
                                    recordTypeId = offerRecordTypeId,
                                    Approval_Status__c = 'Price Accepted' ,
                                    Quotation_Date__c = Date.today(),
                                    Quotation_Validity__c = Date.today().adddays(20),
                                    Branch__c = branch.Id, 
                                    Sales_Org__c = sOrg.Id,
                                    SalesGrp__c = 'ABCDE',
                                    Status = 'Draft',
                                    BTP_Type__c = 'FOB',
                                    Payment_Months__c = 0,
                                    Pricebook2Id =  Test.getStandardPricebookId() );
            
            insert quote;
            
            //FinalizeOfferController Finalofferins = new FinalizeOfferController();
        
            FinalizeOfferController.finalOffer(quote.id);
        
        
        	FinalizeOfferController.checkCurrencies(quote.id);
        }catch(Exception e){}
    }
}