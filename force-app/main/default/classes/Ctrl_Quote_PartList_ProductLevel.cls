public class Ctrl_Quote_PartList_ProductLevel {
    
    public id Pageid{get;set;}
    public Quote QuoteRecord{get;set;}
    public Part_List__c PL{get;set;}
    public List<Part_List__c> plList{get;set;}
    public List<ProductLevelWrapper> filterList { get;set; }
    public List<ProductLevelWrapper> excelExportData { get; set; }
    public List<ProductLevelWrapper> PDFExportData { get; set; }
    
    public Decimal productLevelGrandTotal { get; set; }
    public Decimal customGrandTotal { get; set; }
    public Decimal overallGrandTotal { get; set; }
    
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
    
    public String getProductLevelAmountInWords() {
        if(productLevelGrandTotal == null || productLevelGrandTotal == 0) return 'Zero Only';
        return amountInWords(productLevelGrandTotal);
    }
    
    public String getCustomAmountInWords() {
        if(customGrandTotal == null || customGrandTotal == 0) return 'Zero Only';
        return amountInWords(customGrandTotal);
    }
    
    public Ctrl_Quote_PartList_ProductLevel(ApexPages.StandardController controller){
        Pageid = ApexPages.CurrentPage().getparameters().get('id');
        
        QuoteRecord = [SELECT Id, Name, Part_List__c, Branch__c, QuoteNumber, Enquiry_Number__c, 
                       Quotation_Validity__c, Branch__r.Name, GrandTotal, CurrencyIsoCode, 
                       ExpirationDate, Delivery_Schedule__c 
                       FROM Quote WHERE Id = :Pageid LIMIT 1];
        
        if(QuoteRecord.Part_List__c == null){
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 'No Part List associated with this Quote.'));
            return;
        }
        
        PL = [SELECT id, Name, Customer__c, Description__c, Customer_Name__c, Part_List_Type__c 
              FROM Part_List__c WHERE id = :QuoteRecord.Part_List__c];
        
        plList = [SELECT id, Name, Customer__c, Description__c, Customer_Name__c, Part_List_Type__c 
                  FROM Part_List__c WHERE id = :QuoteRecord.Part_List__c];
        
        // ---------------------------------------------------------------
        // Fetch L2L3 records to resolve Product_Category_Test__c
        // ---------------------------------------------------------------
        List<L2_L3_product__c> L2L3List = [
            SELECT id, Product_L3__c, Item_Description__c,
                   Product_Category_Test__c, Quantity__c
            FROM L2_L3_product__c 
            WHERE Part_List__c = :PL.id 
            ORDER BY Sorting__c asc
        ];
        
        // Map: L2L3 Id → L2L3 record
        Map<Id, L2_L3_product__c> l2l3ById = new Map<Id, L2_L3_product__c>(L2L3List);
        
        // ---------------------------------------------------------------
        // Fetch all QLIs
        // ---------------------------------------------------------------
        List<QuoteLineItem> quoteLines = [
            SELECT Id, Product2Id, Product2.Name, Product2.Product_Level__c,
                   UnitPrice, Quantity, L2_L3_Product__c, settingType__c
            FROM QuoteLineItem 
            WHERE QuoteId = :Pageid
        ];
        
        // Full-Set categories
        Set<String> fullSetCategories = new Set<String>{'FEH', 'DEH', 'SHELL', 'SPARE'};
        
        // Single summary accumulators
        Decimal totalFullSetQty   = 0;
        Decimal totalFullSetValue = 0;
        Decimal totalCustomQty    = 0;
        Decimal totalCustomValue  = 0;
        
        for(QuoteLineItem qli : quoteLines){
            Decimal qty   = qli.Quantity  != null ? qli.Quantity  : 0;
            Decimal price = qli.UnitPrice != null ? qli.UnitPrice : 0;
            
            if(String.isNotBlank(qli.L2_L3_Product__c)){
                L2_L3_product__c linkedL2L3 = l2l3ById.get(qli.L2_L3_Product__c);
                if(linkedL2L3 != null && 
                   fullSetCategories.contains(linkedL2L3.Product_Category_Test__c)){
                    totalFullSetQty   += qty;
                    totalFullSetValue += (qty * price);
                }
            } else {
                // Custom: no L2L3 link
                totalCustomQty   += qty;
                totalCustomValue += (qty * price);
            }
        }
        
        System.debug('totalFullSetQty: '   + totalFullSetQty);
        System.debug('totalFullSetValue: ' + totalFullSetValue);
        
        filterList = new List<ProductLevelWrapper>();
        
        // Single "Full Set" summary row
        if(totalFullSetQty > 0){
            ProductLevelWrapper wrapper  = new ProductLevelWrapper();
            wrapper.SrNo                 = 1;
            wrapper.productLevelQuantity = totalFullSetQty;
            wrapper.productLevelTotal    = totalFullSetValue;
            // Each = Total ÷ Qty (overall effective unit value across all full-set items)
            wrapper.fullSetEachPrice     = totalFullSetValue / totalFullSetQty;
            filterList.add(wrapper);
        }
        
        // Custom stays as-is (individual rows per product, unchanged)
        // Re-build custom per product for custom table on page 2
        Map<Id, Decimal>       customQuantityMap = new Map<Id, Decimal>();
        Map<Id, Decimal>       customTotalMap    = new Map<Id, Decimal>();
        Map<Id, QuoteLineItem> productPriceMap   = new Map<Id, QuoteLineItem>();
        
        for(QuoteLineItem qli : quoteLines){
            if(!productPriceMap.containsKey(qli.Product2Id)){
                productPriceMap.put(qli.Product2Id, qli);
            }
            if(String.isBlank(qli.L2_L3_Product__c)){
                Decimal qty   = qli.Quantity  != null ? qli.Quantity  : 0;
                Decimal price = qli.UnitPrice != null ? qli.UnitPrice : 0;
                if(customQuantityMap.containsKey(qli.Product2Id)){
                    customQuantityMap.put(qli.Product2Id, customQuantityMap.get(qli.Product2Id) + qty);
                    customTotalMap.put(qli.Product2Id,    customTotalMap.get(qli.Product2Id)    + (qty * price));
                } else {
                    customQuantityMap.put(qli.Product2Id, qty);
                    customTotalMap.put(qli.Product2Id,    qty * price);
                }
            }
        }
        
        // Append custom rows (page 2 uses filterList too)
        Set<Id> allProductIds = customQuantityMap.keySet();
        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, Name, Description FROM Product2 WHERE Id IN :allProductIds
        ]);
        
        Map<Id, String> productDescriptionMap = new Map<Id, String>();
        for(L2_L3_product__c l2l3 : L2L3List){
            if(l2l3.Product_L3__c != null && String.isNotBlank(l2l3.Item_Description__c)){
                productDescriptionMap.put(l2l3.Product_L3__c, l2l3.Item_Description__c);
            }
        }
        
        for(Id productId : allProductIds){
            Product2 prod = productMap.get(productId);
            if(prod == null) continue;
            
            ProductLevelWrapper wrapper  = new ProductLevelWrapper();
            wrapper.productId            = productId;
            wrapper.productName          = prod.Name;
            wrapper.itemDescription      = productDescriptionMap.containsKey(productId) ?
                                           productDescriptionMap.get(productId) : prod.Description;
            wrapper.unitPrice            = productPriceMap.containsKey(productId) ?
                                           productPriceMap.get(productId).UnitPrice : 0;
            wrapper.customQuantity       = customQuantityMap.get(productId);
            wrapper.customTotal          = customTotalMap.get(productId);
            filterList.add(wrapper);
        }
        
        // Grand totals
        productLevelGrandTotal = totalFullSetValue;
        customGrandTotal       = totalCustomValue;
        overallGrandTotal      = productLevelGrandTotal;
    }
    
    public class ProductLevelWrapper{
        public Integer SrNo                 { get; set; }
        public Id      productId            { get; set; }
        public String  productName          { get; set; }
        public String  itemDescription      { get; set; }
        public Decimal unitPrice            { get; set; }
        public Decimal fullSetEachPrice     { get; set; }
        public Decimal productLevelQuantity { get; set; }
        public Decimal customQuantity       { get; set; }
        public Decimal totalQuantity        { get; set; }
        public Decimal productLevelTotal    { get; set; }
        public Decimal customTotal          { get; set; }
        public Decimal totalValue           { get; set; }
        
        public ProductLevelWrapper() {
            this.unitPrice            = 0;
            this.fullSetEachPrice     = 0;
            this.productLevelQuantity = 0;
            this.customQuantity       = 0;
            this.totalQuantity        = 0;
            this.productLevelTotal    = 0;
            this.customTotal          = 0;
            this.totalValue           = 0;
        }
    }
}