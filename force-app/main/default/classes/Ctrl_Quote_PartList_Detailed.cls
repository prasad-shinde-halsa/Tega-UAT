public class Ctrl_Quote_PartList_Detailed {

    public Id      Pageid         { get; set; }
    public Quote   QuoteRecord    { get; set; }
    public Part_List__c PL        { get; set; }

    // Rows for the combined detailed table
    public List<DetailedRowWrapper> detailedRows { get; set; }

    // Grand totals
    public Decimal fullSetGrandTotal { get; set; }
    public Decimal customGrandTotal  { get; set; }
    public Decimal overallGrandTotal { get; set; }

    /********************************************************************
     Amount in words helpers
    *********************************************************************/
    public static String amountInWords(Decimal amount) {
        Integer num = amount.intValue();
        if (num == 0) return 'Zero';
        return convert(num).trim() + ' Only';
    }

    private static String convert(Integer n) {
        String[] ones = new String[]{
            '', 'One', 'Two', 'Three', 'Four', 'Five',
            'Six', 'Seven', 'Eight', 'Nine', 'Ten',
            'Eleven', 'Twelve', 'Thirteen', 'Fourteen',
            'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
        };
        String[] tens = new String[]{
            '', '', 'Twenty', 'Thirty', 'Forty',
            'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
        };
        if (n < 20)            return ones[n];
        else if (n < 100)      return tens[n / 10] + ' ' + ones[Math.mod(n, 10)];
        else if (n < 1000)     return ones[n / 100] + ' Hundred ' + convert(Math.mod(n, 100));
        else if (n < 100000)   return convert(n / 1000) + ' Thousand ' + convert(Math.mod(n, 1000));
        else if (n < 10000000) return convert(n / 100000) + ' Lakh ' + convert(Math.mod(n, 100000));
        else                   return convert(n / 10000000) + ' Crore ' + convert(Math.mod(n, 10000000));
    }

    public String getOverallAmountInWords() {
        if (overallGrandTotal == null || overallGrandTotal == 0) return 'Zero Only';
        return amountInWords(overallGrandTotal);
    }

    /********************************************************************
     Constructor
    *********************************************************************/
    public Ctrl_Quote_PartList_Detailed(ApexPages.StandardController controller) {
        Pageid = ApexPages.CurrentPage().getParameters().get('id');

        QuoteRecord = [
            SELECT Id, Name, Part_List__c, Branch__c, QuoteNumber, Enquiry_Number__c,
                   Quotation_Validity__c, Branch__r.Name, GrandTotal, CurrencyIsoCode,
                   ExpirationDate, Delivery_Schedule__c
            FROM Quote WHERE Id = :Pageid LIMIT 1
        ];

        if (QuoteRecord.Part_List__c == null) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 'No Part List associated with this Quote.'));
            return;
        }

        PL = [
            SELECT id, Name, Customer__c, Description__c, Customer_Name__c, Part_List_Type__c
            FROM Part_List__c WHERE id = :QuoteRecord.Part_List__c
        ];

        // ---------------------------------------------------------------
        // Fetch L2L3 records — for category and item description
        // ---------------------------------------------------------------
        List<L2_L3_product__c> L2L3List = [
            SELECT id, Product_L3__c, Item_Description__c,
                   Product_Category_Test__c, Quantity__c, L3_Prod_Name__c
            FROM L2_L3_product__c
            WHERE Part_List__c = :PL.id
            ORDER BY Sorting__c asc
        ];

        Map<Id, L2_L3_product__c> l2l3ById = new Map<Id, L2_L3_product__c>(L2L3List);

        // ---------------------------------------------------------------
        // Fetch all QLIs
        // ---------------------------------------------------------------
        List<QuoteLineItem> quoteLines = [
            SELECT Id, Product2Id, Product2.Name, Product2.Description,
                   Product2.Product_Level__c,
                   UnitPrice, Quantity,
                   L2_L3_Product__c, L2_L3_Product__r.L3_Prod_Name__c,
                   L2_L3_Product__r.Item_Description__c, settingType__c
            FROM QuoteLineItem
            WHERE QuoteId = :Pageid
            ORDER BY Product2.Name
        ];

        // Full-Set categories that get their own row
        Set<String> fullSetCategories = new Set<String>{ 'FEH', 'DEH', 'SHELL', 'SPARE' };

        // Per-category accumulators: category → {qty, total, itemDesc}
        // Key = category string (FEH / DEH / SHELL / SPARE)
        Map<String, Decimal> catQtyMap   = new Map<String, Decimal>();
        Map<String, Decimal> catTotalMap = new Map<String, Decimal>();
        Map<String, String>  catDescMap  = new Map<String, String>();

        // Maintain insertion order for category rows
        List<String> categoryOrder = new List<String>{ 'FEH', 'DEH', 'SHELL', 'SPARE' };
        for (String cat : categoryOrder) {
            catQtyMap.put(cat, 0);
            catTotalMap.put(cat, 0);
            catDescMap.put(cat, '');
        }

        // Custom accumulators: Product2Id → {qty, total, unitPrice, name, desc}
        Map<Id, Decimal>       customQtyMap   = new Map<Id, Decimal>();
        Map<Id, Decimal>       customTotalMap = new Map<Id, Decimal>();
        Map<Id, QuoteLineItem> customPriceMap = new Map<Id, QuoteLineItem>();

        // Product descriptions from L2L3
        Map<Id, String> productDescMap = new Map<Id, String>();
        for (L2_L3_product__c l2l3 : L2L3List) {
            if (l2l3.Product_L3__c != null && String.isNotBlank(l2l3.Item_Description__c)) {
                productDescMap.put(l2l3.Product_L3__c, l2l3.Item_Description__c);
            }
        }

        for (QuoteLineItem qli : quoteLines) {
            Decimal qty   = qli.Quantity  != null ? qli.Quantity  : 0;
            Decimal price = qli.UnitPrice != null ? qli.UnitPrice : 0;

            if (String.isNotBlank(qli.L2_L3_Product__c)) {
                L2_L3_product__c linkedL2L3 = l2l3ById.get(qli.L2_L3_Product__c);
                if (linkedL2L3 != null &&
                    fullSetCategories.contains(linkedL2L3.Product_Category_Test__c)) {

                    String cat = linkedL2L3.Product_Category_Test__c;
                    catQtyMap.put(cat,   catQtyMap.get(cat)   + qty);
                    catTotalMap.put(cat, catTotalMap.get(cat) + (qty * price));

                    // Use item description from L2L3 if not already set for this category
                    if (String.isBlank(catDescMap.get(cat)) &&
                        String.isNotBlank(linkedL2L3.Item_Description__c)) {
                        catDescMap.put(cat, linkedL2L3.Item_Description__c);
                    }
                }
            } else {
                // Custom item
                if (!customPriceMap.containsKey(qli.Product2Id)) {
                    customPriceMap.put(qli.Product2Id, qli);
                }
                if (customQtyMap.containsKey(qli.Product2Id)) {
                    customQtyMap.put(qli.Product2Id,   customQtyMap.get(qli.Product2Id)   + qty);
                    customTotalMap.put(qli.Product2Id, customTotalMap.get(qli.Product2Id) + (qty * price));
                } else {
                    customQtyMap.put(qli.Product2Id,   qty);
                    customTotalMap.put(qli.Product2Id, qty * price);
                }
            }
        }

        // ---------------------------------------------------------------
        // Build detailedRows
        // Section 1: FEH, DEH, SHELL, SPARE — no Item No., blank item no cell
        // Section 2: Custom items — numbered 1, 2, 3...
        // ---------------------------------------------------------------
        detailedRows = new List<DetailedRowWrapper>();

        fullSetGrandTotal = 0;

        for (String cat : categoryOrder) {
            Decimal qty   = catQtyMap.get(cat);
            Decimal total = catTotalMap.get(cat);
            if (qty == null || qty == 0) continue;

            DetailedRowWrapper row = new DetailedRowWrapper();
            row.isFullSetRow    = true;
            row.itemNo          = '';                          // blank item no for full-set rows
            row.qty             = qty;
            //row.itemDescription = catDescMap.get(cat);  
            row.itemDescription = cat+'-'+PL.Description__c;  
            //    // item description from L2L3
            // Tega Part Number = PL.Name + '-' + category  e.g. PLM-00771-02-FEH
            row.tegaPartNumber  = PL.Name + '-' + cat;
            row.unitPrice       = (qty > 0) ? (total / qty) : 0;  // each = total / qty
            row.lineTotal       = total;
            detailedRows.add(row);

            fullSetGrandTotal += total;
        }

        // Custom rows
        Set<Id> customProductIds = customQtyMap.keySet();
        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, Name, Description FROM Product2 WHERE Id IN :customProductIds
        ]);

        customGrandTotal = 0;
        Integer custNum  = 1;

        for (Id productId : customProductIds) {
            Product2 prod = productMap.get(productId);
            if (prod == null) continue;

            Decimal qty   = customQtyMap.get(productId);
            Decimal total = customTotalMap.get(productId);
            Decimal price = customPriceMap.containsKey(productId) ?
                            customPriceMap.get(productId).UnitPrice : 0;

            DetailedRowWrapper row = new DetailedRowWrapper();
            row.isFullSetRow    = false;
            row.itemNo          = String.valueOf(custNum);
            row.qty             = qty;
            row.itemDescription = productDescMap.containsKey(productId) ?
                                  productDescMap.get(productId) : prod.Description;
            row.tegaPartNumber  = prod.Name;
            row.unitPrice       = price;
            row.lineTotal       = total;
            detailedRows.add(row);

            customGrandTotal += total;
            custNum++;
        }

        overallGrandTotal = fullSetGrandTotal + customGrandTotal;
    }

    /********************************************************************
     Row wrapper
    *********************************************************************/
    public class DetailedRowWrapper {
        public Boolean isFullSetRow    { get; set; }
        public String  itemNo          { get; set; }  // blank for full-set rows
        public Decimal qty             { get; set; }
        public String  itemDescription { get; set; }
        public String  tegaPartNumber  { get; set; }
        public Decimal unitPrice       { get; set; }
        public Decimal lineTotal       { get; set; }

        public DetailedRowWrapper() {
            this.isFullSetRow    = false;
            this.qty             = 0;
            this.unitPrice       = 0;
            this.lineTotal       = 0;
        }
    }
}