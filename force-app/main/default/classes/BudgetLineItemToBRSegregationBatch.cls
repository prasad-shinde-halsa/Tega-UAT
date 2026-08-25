public class BudgetLineItemToBRSegregationBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Include all month fields in SELECT
        String soql = 'SELECT Id, Active_Status__c,' +
                      'Apr_Order__c, May_Order__c, Jun_Order__c, Jul_Order__c, Aug_Order__c, Sep_Order__c, ' +
                      'Oct_Order__c, Nov_Order__c, Dec_Order__c, Jan_Order__c, Feb_Order__c, Mar_Order__c, ' +
            		  'Apr_Order_Actual__c, May_Order_Actual__c, Jun_Order_Actual__c, Jul_Order_Actual__c,' +
                      'Aug_Order_Actual__c, Sep_Order_Actual__c, Oct_Order_Actual__c, Nov_Order_Actual__c,' +
                      'Dec_Order_Actual__c, Jan_Order_Actual__c, Feb_Order_Actual__c, Mar_Order_Actual__c, '+
                      'April_Order_Offer_Submitted__c, May_Order_Offer_Submitted__c, June_Order_Offer_Submitted__c,'+
                      'July_Order_Offer_Submitted__c, August_Order_Offer_Submitted__c, September_Order_Offer_Submitted__c,'+
                      'October_Order_Offer_Submitted__c, November_Order_Offer_Submitted__c, December_Order_Offer_Submitted__c,'+
                      'January_Order_Offer_Submitted__c, February_Order_Offer_Submitted__c, March_Order_Offer_Submitted__c '+
                      'FROM DC_Budget_Line_Items__c ' +
                      'WHERE Active_Status__c = true and Id = \'a1gS2000003BdVlIAK\'';
        return Database.getQueryLocator(soql);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scopes) {
        if (scopes.isEmpty()) return;

        List<DC_Budget_Line_Items__c> scope = (List<DC_Budget_Line_Items__c>) scopes;

        // Collect all BLI Ids
        Set<Id> bliIds = new Set<Id>();
        for (DC_Budget_Line_Items__c bli : scope) {
            bliIds.add(bli.Id);
        }

        // Query existing segregation records
        Map<String, Budget_Report_Segregation__c> existingSegByKey = new Map<String, Budget_Report_Segregation__c>();
        for (Budget_Report_Segregation__c seg : [
            SELECT Id, Budget_Line_Items__c, Budgeted_Month__c, Budgeted_Value__c
            FROM Budget_Report_Segregation__c
            WHERE Budget_Line_Items__c IN :bliIds
        ]) {
            String monthAbbrev = '';
            if (seg.Budgeted_Month__c != null && seg.Budgeted_Month__c.length() >= 3) {
                monthAbbrev = seg.Budgeted_Month__c.substring(0, 1).toUpperCase() +
                              seg.Budgeted_Month__c.substring(1, 3).toLowerCase();
            } else if (seg.Budgeted_Month__c != null) {
                monthAbbrev = seg.Budgeted_Month__c;
            }

            Decimal amount = seg.Budgeted_Value__c != null ? seg.Budgeted_Value__c.setScale(2) : 0;

            String key = buildSegKey(seg.Budget_Line_Items__c, monthAbbrev, amount);
            existingSegByKey.put(key, seg);
        }

        // Map month fields to full names
        Map<String, String> monthFieldToName = new Map<String, String>{
            'Apr_Order__c' => 'April',
            'May_Order__c' => 'May',
            'Jun_Order__c' => 'June',
            'Jul_Order__c' => 'July',
            'Aug_Order__c' => 'August',
            'Sep_Order__c' => 'September',
            'Oct_Order__c' => 'October',
            'Nov_Order__c' => 'November',
            'Dec_Order__c' => 'December',
            'Jan_Order__c' => 'January',
            'Feb_Order__c' => 'February',
            'Mar_Order__c' => 'March'
        };

        List<Budget_Report_Segregation__c> toInsert = new List<Budget_Report_Segregation__c>();

        // Iterate over each BLI
        for (DC_Budget_Line_Items__c bli : scope) {
            for (String fld : monthFieldToName.keySet()) {
                Object val = bli.get(fld);
                if (val == null) continue;

                // Convert value to Decimal with 2 decimal places
                Decimal monthAmount = 0;
                if (val instanceof Decimal) {
                    monthAmount = ((Decimal) val).setScale(2);
                } else if (val instanceof String) {
                    monthAmount = extractAmount((String) val).setScale(2);
                    if (monthAmount == 0) continue; // skip if no numeric value
                }

                // Month abbreviation (Title Case 3 letters)
                String monthFull = monthFieldToName.get(fld);
                String monthAbbrev = monthFull.substring(0, 1).toUpperCase() + monthFull.substring(1, 3).toLowerCase();

                String key = buildSegKey(bli.Id, monthAbbrev, monthAmount);

                // Skip if BLI already has this month + amount in segregation
                if (existingSegByKey.containsKey(key)) continue;
				
                
                // Create new segregation record
                Budget_Report_Segregation__c rec = new Budget_Report_Segregation__c();
                rec.Budget_Line_Items__c = bli.Id;
                rec.Budgeted_Month__c = monthAbbrev;
                rec.Budgeted_Value__c = monthAmount;
                
                toInsert.add(rec);
                existingSegByKey.put(key, rec); // prevent duplicates in this batch
            }
        }

        // Insert new segregation records
        if (!toInsert.isEmpty()) {
            //Database.SaveResult[] results = Database.insert(toInsert, false);
            System.debug(toInsert);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch completed successfully.');
    }

    // Build unique key for deduplication: BLI Id + Month + Amount
    private static String buildSegKey(Id bliId, String monthAbbrev, Decimal amount) {
        return String.valueOf(bliId) + '|' +
               String.valueOf(monthAbbrev) + '|' +
               String.valueOf(amount);
    }

    // Extract first numeric value from a string (handles currency strings)
    private static Decimal extractAmount(String s) {
        if (String.isBlank(s)) return 0;

        Pattern p = Pattern.compile('[0-9]+\\.?[0-9]*');
        Matcher m = p.matcher(s);
        if (m.find()) {
            return Decimal.valueOf(m.group(0)).setScale(2);
        }
        return 0;
    }
}