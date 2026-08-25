@isTest
private class PreventEditHelperTest {

    @isTest
    static void testPreventEdit() {
        Account acc = new Account();
        acc.Name = 'Test Acc';
        acc.Sync_with_SAP__c = true;
        insert acc;
        
        Opportunity opp = new opportunity();
        opp.Name = 'Test Opp';
        Opp.AccountId = acc.id;
        opp.StageName = 'Open';
        opp.CloseDate = System.today();
        insert opp;
        
        Quote testQuote1 = new Quote();
        testQuote1.Name = 'Test Quote 1';
        testQuote1.OpportunityId = opp.id;
        testQuote1.BTP_Type__c = 'FOB';
        testQuote1.Payment_Months__c = 10;

        Quote testQuote2 = new Quote();
        testQuote2.Name = 'Test Quote 2';
        testQuote2.OpportunityId = opp.id;
        testQuote2.Description = 'insert';
        testQuote2.BTP_Type__c = 'FOB';
        testQuote2.Payment_Months__c = 10;

        List<Quote> testQuotes = new List<Quote>{testQuote1, testQuote2};
		insert testQuotes;
        Test.startTest();
        PreventEditHelper.preventEdit(testQuotes);
        
        testQuote2.Description = 'SAP123';
        update testQuote2;
        Test.stopTest();

        for (Quote resultQuote : testQuotes) {
            if (resultQuote.SAP_Offer_Id__c != null) {
                System.assertEquals(1, resultQuote.getErrors().size(), 'Error message should be added');
                System.assertEquals('Editing is not allowed when SAP Offer Id has a value.', resultQuote.getErrors()[0].getMessage(), 'Incorrect error message');
            } else {
                System.assertEquals(0, resultQuote.getErrors().size(), 'No error message should be added');
            }
        }
    }
}