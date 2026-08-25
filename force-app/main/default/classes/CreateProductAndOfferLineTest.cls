@isTest(SeeAllData=false)
public class CreateProductAndOfferLineTest {
    @isTest
    static void testCoverMethod() {
        Quote offer = new Quote();
        Pricebook2 pb = new Pricebook2();
        NonSparesServiceNewV2.ZofferDtlsSfdcResponse_element response = new NonSparesServiceNewV2.ZofferDtlsSfdcResponse_element();
        Integration_Transaction__c it = new Integration_Transaction__c();

        CreateProductAndOfferLine myClassInstance = new CreateProductAndOfferLine(offer, pb, response, it);

        Test.startTest();
        myClassInstance.coverMethod();
        Test.stopTest();
    }
    
}