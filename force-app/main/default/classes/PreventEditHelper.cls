public class PreventEditHelper {
    public static void preventEdit(List<Quote> newQuotes) {
        for (Quote record : newQuotes) {
            if (record.SAP_Offer_Id__c != null) {
                record.addError('Editing is not allowed when SAP Offer Id has a value.');
            }
        }
    }
}