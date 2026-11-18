public with sharing class FinalizeOfferController {
    @AuraEnabled
    public static Void finalOffer(Id offerId){
        try {
            Quote offer = new Quote(Id = offerId, status='Finalized', Approval_Status__c = 'Submitted');
            update offer;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
// SK - 211122 : Passing custom label in finalize offer component
    @AuraEnabled
    public static string customLabelItem(){
       List <String> custmValP = new List <String>();
       String custmLbl = Label.Offer_Finalize_lable;
       String custmLblMsg = String.format(custmlbl,custmValP);
       System.debug('CustomLabelValue'+custmLblMsg);
       return custmLblMsg;
    }
@AuraEnabled
public static String checkCurrencies(Id quoteId) {
    Quote q = [SELECT CurrencyIsoCode, Opportunity.CurrencyIsoCode, Opportunity.Account.CurrencyIsoCode,Opportunity.Account.Currency__c FROM Quote WHERE Id = :quoteId LIMIT 1];
    if (q.CurrencyIsoCode == null || q.OpportunityId == null || q.Opportunity.CurrencyIsoCode == null || q.Opportunity.AccountId == null || q.Opportunity.Account.Currency__c == null) {
        return 'MISSING';
    }
    if (q.CurrencyIsoCode != q.Opportunity.CurrencyIsoCode || q.CurrencyIsoCode != q.Opportunity.Account.CurrencyIsoCode) {
        return 'MISMATCH';
    }
    return 'MATCH';
}
@AuraEnabled
public static Map<String, String> getErrorLabels() {
    Map<String, String> labels = new Map<String, String>();
    labels.put('missing', Label.Missing_Currency_Error);
    labels.put('mismatch', Label.Currency_Mismatch_Error);
    labels.put('genericError', Label.Currency_Generic_Error);
    labels.put('finalizeSuccess', Label.Offer_Finalize_Success);
    return labels;
}
}