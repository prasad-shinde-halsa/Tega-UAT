/**********************************************************************************
@Developer Name : Ranjeet Kumar
*********************************************************************************/

public class Ctrl_Quote_PartList_Metrix {
    
    public id Pageid{get;set;}
    public Quote QuoteRecord{get;set;}
    public Part_List__c PL{get;set;}
    public List<Part_List__c> plList{get;set;}
    public List<L2_L3_product__c> L2L3List{get;set;}
    public Map<String,List<L2_L3_product__c>>L2L3Map{get;set;}
    public List<L2L3Wrapper> filterList { get;set; }
    public List<L2L3Wrapper> filterList2 { get;set; }
    public List<L2L3Wrapper> filterList3 { get;set; }
    public Integer FilterQuantity{get;set;}
    public List<L2L3Wrapper> excelExportData { get; set; }
    public List<L2L3Wrapper> PDFExportData { get; set; }
    
    public Decimal fehGrandTotal { get; set; }
    public Decimal dehGrandTotal { get; set; }
    public Decimal shellGrandTotal { get; set; }
    public Decimal spareGrandTotal { get; set; }
    public Decimal customGrandTotal { get; set; }
    public Decimal fullSetGrandTotal { get; set; }
    
    
    public Boolean showFullSet {get;set;}
    public Boolean showFEH {get;set;}
    public Boolean showDEH {get;set;}
    public Boolean showSHELL {get;set;}
    public Boolean showSPARE {get;set;}
    public Boolean showCUSTOM {get;set;}
    
    
    /********************************************************************
    This method is used for convert amoint in words
    *********************************************************************/
    public static String amountInWords(Decimal amount) {
        
        Integer num = amount.intValue();
        
        if (num == 0) {
            return 'Zero';
        }
        
        return convert(num).trim() + ' Only';
    }

    private static String convert(Integer n) {
        
        String[] ones = new String[]{
            '', 'One', 'Two', 'Three', 'Four', 'Five',
                'Six', 'Seven', 'Eight', 'Nine', 'Ten',
                'Eleven', 'Twelve', 'Thirteen', 'Fourteen',
                'Fifteen', 'Sixteen', 'Seventeen',
                'Eighteen', 'Nineteen'
                };

    String[] tens = new String[]{
        '', '', 'Twenty', 'Thirty', 'Forty',
        'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    };

    if (n < 20) {
        return ones[n];
    }
    else if (n < 100) {
        return tens[n / 10] + ' ' + ones[Math.mod(n, 10)];
    }
    else if (n < 1000) {
        return ones[n / 100] + ' Hundred ' + convert(Math.mod(n, 100));
    }
    else if (n < 100000) {
        return convert(n / 1000) + ' Thousand ' + convert(Math.mod(n, 1000));
    }
    else if (n < 10000000) {
        return convert(n / 100000) + ' Lakh ' + convert(Math.mod(n, 100000));
    }
    else {
        return convert(n / 10000000) + ' Crore ' + convert(Math.mod(n, 10000000));
    }
}
    
    
    public String getAmountInWords() {

    if(QuoteRecord == null || QuoteRecord.GrandTotal == null){
        return '';
    }

    return amountInWords(QuoteRecord.GrandTotal); }
    
    public String getFEHAmountInWords() {
        if(fehGrandTotal == null || fehGrandTotal == 0){
            return 'Zero Only';
        }
        return amountInWords(fehGrandTotal);
    }
    
    public String getDEHAmountInWords() {
        if(dehGrandTotal == null || dehGrandTotal == 0){
            return 'Zero Only';
        }
        return amountInWords(dehGrandTotal);
    }
    
    public String getShellAmountInWords() {
        if(shellGrandTotal == null || shellGrandTotal == 0){
            return 'Zero Only';
        }
        return amountInWords(shellGrandTotal);
    }
    
    public String getSpareAmountInWords() {
        if(spareGrandTotal == null || spareGrandTotal == 0){
            return 'Zero Only';
        }
        return amountInWords(spareGrandTotal);
    }
    
    public String getCustomAmountInWords() {
        if(customGrandTotal == null || customGrandTotal == 0){
            return 'Zero Only';
        }
        return amountInWords(customGrandTotal);
    }
    
    public String getFullSetAmountInWords() {
    if(fullSetGrandTotal == null || fullSetGrandTotal == 0){
        return 'Zero Only';
    }
    return amountInWords(fullSetGrandTotal);
}
    
    
    /********************************************************************
    @Description : This method is used for L2Product and L3Product
    Product sorting from Quote record with pricing information
    *********************************************************************/
    
    public Ctrl_Quote_PartList_Metrix(ApexPages.StandardController controller){
        Pageid = ApexPages.CurrentPage().getparameters().get('id');
        
        // Get Quote record with Part List lookup
        QuoteRecord = [SELECT Id, Name, Part_List__c , Branch__c,QuoteNumber,Enquiry_Number__c, Quotation_Validity__c,Branch__r.Name,GrandTotal FROM Quote WHERE Id = :Pageid LIMIT 1];
        
        // Check if Part List is associated
        if(QuoteRecord.Part_List__c == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Part List associated with this Quote.'));
            return;
        }
        
        PL = new Part_List__c();
        PL = [SELECT id,Name,Customer__c,Description__c,Customer_Name__c,Part_List_Type__c ,Version_Number_Component__c
              FROM Part_List__c WHERE id=: QuoteRecord.Part_List__c];
        
        plList = new List<Part_List__c>();
        plList = [SELECT id,Name,Customer__c,Description__c,Customer_Name__c,Part_List_Type__c 
                  FROM Part_List__c WHERE id=: QuoteRecord.Part_List__c];
        
        // Fetch Quote Line Items for pricing
        Map<Id, QuoteLineItem> productPriceMap = new Map<Id, QuoteLineItem>();
        Map<String, QuoteLineItem> l2l3ProductPriceMap = new Map<String, QuoteLineItem>();
        Map<Id, Decimal> customQuantityMap = new Map<Id, Decimal>();
        
        List<QuoteLineItem> quoteLines = [SELECT Id, Product2Id, Product2.Name, UnitPrice, Quantity, 
                                          BTP_Price__c, Margin__c, L2_L3_Product__c, 
                                          L2_L3_Product__r.L3_Prod_Name__c, settingType__c
                                          FROM QuoteLineItem 
                                          WHERE QuoteId = :Pageid 
                                          ORDER BY Product2.Name];
        
        System.debug('Total QuoteLineItems found: ' + quoteLines.size());
        
        for(QuoteLineItem qli : quoteLines){
            
            if(String.isNotBlank(qli.settingType__c)){

        List<String> settingList = qli.settingType__c.split(';');

        // If FULLSET exists then show everything
        if(settingList.contains('fullset')){
            showFullSet = true;
            showFEH = true;
            showDEH = true;
            showSHELL = true;
            showSPARE = true;
        }
        else{

            if(settingList.contains('FEH')){
                showFEH = true;
            }

            if(settingList.contains('DEH')){
                showDEH = true;
            }

            if(settingList.contains('SHELL')){
                showSHELL = true;
            }
			/*
            if(settingList.contains('SPARE')){
                showSPARE = true;
            } */
        }

        // CUSTOM condition
        /*
        if(qli.L2_L3_Product__c == null){
            showCUSTOM = true;
        } */
    }
            // Map by Product2Id for general lookup
            if(!productPriceMap.containsKey(qli.Product2Id)){
                productPriceMap.put(qli.Product2Id, qli);
            }
            
            // Map by L2_L3_Product__c for category-specific pricing
            if(String.isNotBlank(qli.L2_L3_Product__c)){
                String mapKey = qli.L2_L3_Product__c;
                if(!l2l3ProductPriceMap.containsKey(mapKey)){
                    l2l3ProductPriceMap.put(mapKey, qli);
                }
            } else {
                // This is a custom quantity (no L2_L3_Product__c link)
                if(customQuantityMap.containsKey(qli.Product2Id)){
                    customQuantityMap.put(qli.Product2Id, customQuantityMap.get(qli.Product2Id) + qli.Quantity);
                } else {
                    customQuantityMap.put(qli.Product2Id, qli.Quantity);
                }
            }
        }
        
        System.debug('productPriceMap size: ' + productPriceMap.size());
        System.debug('customQuantityMap: ' + customQuantityMap);
        
        L2L3List = [SELECT id,Part_List__c,L2_Prod_Name__c,L3_Prod_Name__c,Product_L2__c,Product_L3__c,
                    Quantity__c,Item_Description__c,Product_Category__c,Product_Category_Test__c,
                    Product_Sorting_Data__c 
                    FROM L2_L3_product__c 
                    WHERE Part_List__c =:PL.id 
                    ORDER BY Sorting__c asc];
        
        Set<String>PCT = new set<String>();
        
        for(L2_L3_product__c l2:L2L3List){
            PCT.add(l2.Product_Category_Test__c);
        }
        system.debug('PCT: '+PCT);
        
        List<String>listOfPCT = new List<String>(PCT);
        
        Map<String,List<L2_L3_product__c>>L2L3Map = new Map<String,List<L2_L3_product__c>>();
        
        for(L2_L3_product__c plm:L2L3List){
            if(L2L3Map.containsKey(plm.L3_Prod_Name__c)){
                L2L3Map.get(plm.L3_Prod_Name__c).add(plm);
            }
            else{
                List<L2_L3_product__c> L2L3 =new List<L2_L3_product__c>();
                L2L3.add(plm);
                L2L3Map.put(plm.L3_Prod_Name__c,L2L3);
            }                
        }
        system.debug('Map: '+ L2L3Map);
        FilterQuantity = L2L3Map.size();
        system.debug('FilterQuantity:'+ FilterQuantity);
        
        filterList = new List<L2L3Wrapper>();
        filterList2 = new List<L2L3Wrapper>();
        filterList3 = new List<L2L3Wrapper>();
        
        for(String key:L2L3Map.keyset()){
            
            L2L3Wrapper l2l3p = new L2L3Wrapper();
            l2l3p.L2ProductName = key;
            
            // Initialize all quantities to 0
            l2l3p.fehQuantity = 0;
            l2l3p.dehQuantity = 0;
            l2l3p.shellQuantity = 0;
            l2l3p.spareQuantity = 0;
            l2l3p.pnlQuantity = 0;
            l2l3p.sfbQuantity = 0;
            l2l3p.mfbQuantity = 0;
            l2l3p.strQuantity = 0;
            l2l3p.sprlQuantity = 0;
            l2l3p.customQuantity = 0;
            l2l3p.unitPrice = 0;
            
            Id productL3Id = null;
            
            for(L2_L3_product__c l2l3:L2L3Map.get(key)){
                
                productL3Id = l2l3.Product_L3__c;
                
                // Get unit price from QuoteLineItem - Use first available price
                if(l2l3p.unitPrice == 0){
                    if(l2l3ProductPriceMap.containsKey(l2l3.Id)){
                        l2l3p.unitPrice = l2l3ProductPriceMap.get(l2l3.Id).UnitPrice;
                    } else if(productPriceMap.containsKey(l2l3.Product_L3__c)){
                        l2l3p.unitPrice = productPriceMap.get(l2l3.Product_L3__c).UnitPrice;
                    }
                }
                
                // Populate quantities based on Product Category
                if(l2l3.Product_Category_Test__c == 'FEH'){
                    l2l3p.fehQuantity = l2l3.Quantity__c != null ? l2l3.Quantity__c : 0;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                
                if(l2l3.Product_Category_Test__c == 'DEH'){
                    l2l3p.dehQuantity = l2l3.Quantity__c != null ? l2l3.Quantity__c : 0;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                
                if(l2l3.Product_Category_Test__c == 'SHELL'){
                    l2l3p.shellQuantity = l2l3.Quantity__c != null ? l2l3.Quantity__c : 0;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                
                if(l2l3.Product_Category_Test__c == 'SPARE'){
                    l2l3p.spareQuantity = l2l3.Quantity__c != null ? l2l3.Quantity__c : 0;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                
                if(l2l3.Product_Category_Test__c == 'PNL'){
                    l2l3p.pnlQuantity = l2l3.Quantity__c != null ? l2l3.Quantity__c : 0;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                
                if(l2l3.Product_Category_Test__c == 'SFB'){
                    l2l3p.sfbQuantity = l2l3.Quantity__c != null ? l2l3.Quantity__c : 0;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                
                if(l2l3.Product_Category_Test__c == 'MFB'){
                    l2l3p.mfbQuantity = l2l3.Quantity__c != null ? l2l3.Quantity__c : 0;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                
                if(l2l3.Product_Category_Test__c == 'STR'){
                    l2l3p.strQuantity = l2l3.Quantity__c != null ? l2l3.Quantity__c : 0;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                
                if(l2l3.Product_Category_Test__c == 'SPRL'){
                    l2l3p.sprlQuantity = l2l3.Quantity__c != null ? l2l3.Quantity__c : 0;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
            }
            
            // Add custom quantity if exists
            if(productL3Id != null && customQuantityMap.containsKey(productL3Id)){
                l2l3p.customQuantity = customQuantityMap.get(productL3Id);
            }
            
            // Calculate category totals (Quantity × Unit Price)
            if(l2l3p.unitPrice != null && l2l3p.unitPrice > 0){
                l2l3p.fehTotal = l2l3p.fehQuantity * l2l3p.unitPrice;
                l2l3p.dehTotal = l2l3p.dehQuantity * l2l3p.unitPrice;
                l2l3p.shellTotal = l2l3p.shellQuantity * l2l3p.unitPrice;
                l2l3p.spareTotal = l2l3p.spareQuantity * l2l3p.unitPrice;
                l2l3p.pnlTotal = l2l3p.pnlQuantity * l2l3p.unitPrice;
                l2l3p.sfbTotal = l2l3p.sfbQuantity * l2l3p.unitPrice;
                l2l3p.mfbTotal = l2l3p.mfbQuantity * l2l3p.unitPrice;
                l2l3p.strTotal = l2l3p.strQuantity * l2l3p.unitPrice;
                l2l3p.sprlTotal = l2l3p.sprlQuantity * l2l3p.unitPrice;
                l2l3p.customTotal = l2l3p.customQuantity * l2l3p.unitPrice;
            } else {
                l2l3p.fehTotal = 0;
                l2l3p.dehTotal = 0;
                l2l3p.shellTotal = 0;
                l2l3p.spareTotal = 0;
                l2l3p.pnlTotal = 0;
                l2l3p.sfbTotal = 0;
                l2l3p.mfbTotal = 0;
                l2l3p.strTotal = 0;
                l2l3p.sprlTotal = 0;
                l2l3p.customTotal = 0;
            }
            
            // Calculate total quantities
            l2l3p.PLMtotalQuantity = l2l3p.fehQuantity + l2l3p.dehQuantity + l2l3p.shellQuantity + l2l3p.spareQuantity ;//+ l2l3p.customQuantity;
            l2l3p.PLStotalQuantity = l2l3p.pnlQuantity + l2l3p.sfbQuantity + l2l3p.mfbQuantity + l2l3p.spareQuantity + l2l3p.customQuantity;
            l2l3p.PLTtotalQuantity = l2l3p.strQuantity + l2l3p.pnlQuantity + l2l3p.sprlQuantity + l2l3p.spareQuantity + l2l3p.customQuantity;
            
            // Calculate total values
            l2l3p.PLMtotalValue = l2l3p.fehTotal + l2l3p.dehTotal + l2l3p.shellTotal + l2l3p.spareTotal;// + l2l3p.customTotal;
            l2l3p.PLStotalValue = l2l3p.pnlTotal + l2l3p.sfbTotal + l2l3p.mfbTotal + l2l3p.spareTotal + l2l3p.customTotal;
            l2l3p.PLTtotalValue = l2l3p.strTotal + l2l3p.pnlTotal + l2l3p.sprlTotal + l2l3p.spareTotal + l2l3p.customTotal;
            
            system.debug('l2l3p: ' +l2l3p);	
            filterList.add(l2l3p);
            filterList2.add(l2l3p);
            filterList3.add(l2l3p);
        }
        System.debug('filterList: '+filterList);
        
        fehGrandTotal = 0;
        dehGrandTotal = 0;
        shellGrandTotal = 0;
        spareGrandTotal = 0;
        customGrandTotal = 0;
        
        for(L2L3Wrapper wrapper : filterList) {
            fehGrandTotal += wrapper.fehTotal != null ? wrapper.fehTotal : 0;
            dehGrandTotal += wrapper.dehTotal != null ? wrapper.dehTotal : 0;
            shellGrandTotal += wrapper.shellTotal != null ? wrapper.shellTotal : 0;
            spareGrandTotal += wrapper.spareTotal != null ? wrapper.spareTotal : 0;
            customGrandTotal += wrapper.customTotal != null ? wrapper.customTotal : 0;
            fullSetGrandTotal = fehGrandTotal + dehGrandTotal + shellGrandTotal + spareGrandTotal ;// + customGrandTotal; // exclude custom quantity total 
            
        }
        
        System.debug('fehGrandTotal: ' + fehGrandTotal);
        System.debug('dehGrandTotal: ' + dehGrandTotal);
        System.debug('shellGrandTotal: ' + shellGrandTotal);
        System.debug('spareGrandTotal: ' + spareGrandTotal);
        System.debug('customGrandTotal: ' + customGrandTotal);
        System.debug('fullSetGrandTotal:' +fullSetGrandTotal);
        
        System.debug('showFullSet: ' + showFullSet);
        System.debug('showFEH: ' + showFEH);
        System.debug('showDEH: ' + showDEH);
        System.debug('showSHELL: ' + showSHELL);
        System.debug('showSPARE: ' + showSPARE);
        System.debug('showCUSTOM: ' + showCUSTOM);
    }
    
    /**********************************************************
    @Description : This class used as a data container with pricing fields.
    ***********************************************************/
    
    public class L2L3Wrapper{
        public String sortingOrder { get; set; }
        public Integer SrNo { get; set; }
        public string L2ProductName { get; set; }
        public string ItemDescription { get; set; }
        
        // Unit Price (same for all categories of this product)
        public decimal unitPrice { get; set; }
        
        // Quantities
        public decimal fehQuantity { get; set; }
        public decimal dehQuantity { get; set; }
        public decimal shellQuantity { get; set; }
        public decimal pnlQuantity { get; set; }
        public decimal sfbQuantity { get; set; }
        public decimal mfbQuantity { get; set; }
        public decimal strQuantity { get; set; }
        public decimal sprlQuantity { get; set; }
        public decimal spareQuantity { get; set; }
        public decimal customQuantity { get; set; }
        
        // Category Totals (Qty × Unit Price)
        public decimal fehTotal { get; set; }
        public decimal dehTotal { get; set; }
        public decimal shellTotal { get; set; }
        public decimal spareTotal { get; set; }
        public decimal pnlTotal { get; set; }
        public decimal sfbTotal { get; set; }
        public decimal mfbTotal { get; set; }
        public decimal strTotal { get; set; }
        public decimal sprlTotal { get; set; }
        public decimal customTotal { get; set; }
        
        // Overall Totals
        public decimal PLMtotalQuantity {get; set;}
        public decimal PLStotalQuantity {get; set;}
        public decimal PLTtotalQuantity {get; set;}
        public decimal PLMtotalValue {get; set;}
        public decimal PLStotalValue {get; set;}
        public decimal PLTtotalValue {get; set;}
        
        public L2L3Wrapper(String l2ProductName) {
            this.L2ProductName = l2ProductName;
            this.unitPrice = 0;
            this.fehQuantity = 0;
            this.dehQuantity = 0;
            this.shellQuantity = 0;
            this.spareQuantity = 0;
            this.pnlQuantity = 0;
            this.sfbQuantity = 0;
            this.mfbQuantity = 0;
            this.strQuantity = 0;
            this.sprlQuantity = 0;
            this.customQuantity = 0;
            this.fehTotal = 0;
            this.dehTotal = 0;
            this.shellTotal = 0;
            this.spareTotal = 0;
            this.pnlTotal = 0;
            this.sfbTotal = 0;
            this.mfbTotal = 0;
            this.strTotal = 0;
            this.sprlTotal = 0;
            this.customTotal = 0;
            this.PLMtotalQuantity = 0;
            this.PLStotalQuantity = 0;
            this.PLTtotalQuantity = 0;
            this.PLMtotalValue = 0;
            this.PLStotalValue = 0;
            this.PLTtotalValue = 0;
        }
        
        public L2L3Wrapper(){
            this.unitPrice = 0;
            this.fehQuantity = 0;
            this.dehQuantity = 0;
            this.shellQuantity = 0;
            this.spareQuantity = 0;
            this.pnlQuantity = 0;
            this.sfbQuantity = 0;
            this.mfbQuantity = 0;
            this.strQuantity = 0;
            this.sprlQuantity = 0;
            this.customQuantity = 0;
            this.fehTotal = 0;
            this.dehTotal = 0;
            this.shellTotal = 0;
            this.spareTotal = 0;
            this.pnlTotal = 0;
            this.sfbTotal = 0;
            this.mfbTotal = 0;
            this.strTotal = 0;
            this.sprlTotal = 0;
            this.customTotal = 0;
            this.PLMtotalQuantity = 0;
            this.PLStotalQuantity = 0;
            this.PLTtotalQuantity = 0;
            this.PLMtotalValue = 0;
            this.PLStotalValue = 0;
            this.PLTtotalValue = 0;
        }
    }
    
    /************************************************************
    @description : This methods are for Downloading the Excel
    *************************************************************/
    
    public PageReference downloadExcelPLM() {
        List<L2L3Wrapper> excelData = new List<L2L3Wrapper>();
        Integer srNo = 1;
        for (L2L3Wrapper PLM : filterList) {
            L2L3Wrapper excelRow = new L2L3Wrapper(PLM.L2ProductName);
            excelRow.SrNo = srNo;
            excelRow.ItemDescription = PLM.ItemDescription;
            excelRow.unitPrice = PLM.unitPrice;
            excelRow.fehQuantity = PLM.fehQuantity;
            excelRow.fehTotal = PLM.fehTotal;
            excelRow.dehQuantity = PLM.dehQuantity;
            excelRow.dehTotal = PLM.dehTotal;
            excelRow.shellQuantity = PLM.shellQuantity;
            excelRow.shellTotal = PLM.shellTotal;
            excelRow.spareQuantity = PLM.spareQuantity;
            excelRow.spareTotal = PLM.spareTotal;
            excelRow.customQuantity = PLM.customQuantity;
            excelRow.customTotal = PLM.customTotal;
            excelRow.PLMtotalQuantity = PLM.PLMtotalQuantity;
            excelRow.PLMtotalValue = PLM.PLMtotalValue;
            excelData.add(excelRow);
            srNo++;
        }
        
        excelExportData = excelData;
        
        return Page.vf_ExcelPage_PLM;
        
    }
    
    public PageReference downloadExcelPLS() {
        List<L2L3Wrapper> excelData = new List<L2L3Wrapper>();
        Integer srNo = 1;
        for (L2L3Wrapper PLM : filterList2) {
            L2L3Wrapper excelRow = new L2L3Wrapper(PLM.L2ProductName);
            excelRow.SrNo = srNo;
            excelRow.ItemDescription = PLM.ItemDescription;
            excelRow.unitPrice = PLM.unitPrice;
            excelRow.pnlQuantity = PLM.pnlQuantity;
            excelRow.pnlTotal = PLM.pnlTotal;
            excelRow.sfbQuantity = PLM.sfbQuantity;
            excelRow.sfbTotal = PLM.sfbTotal;
            excelRow.mfbQuantity = PLM.mfbQuantity;
            excelRow.mfbTotal = PLM.mfbTotal;
            excelRow.spareQuantity = PLM.spareQuantity;
            excelRow.spareTotal = PLM.spareTotal;
            excelRow.customQuantity = PLM.customQuantity;
            excelRow.customTotal = PLM.customTotal;
            excelRow.PLStotalQuantity = PLM.PLStotalQuantity;
            excelRow.PLStotalValue = PLM.PLStotalValue;
            excelData.add(excelRow);
            srNo++;
        }
        
        excelExportData = excelData;
        
        return Page.vf_ExcelPage_PLS;
    } 
    
    public PageReference downloadExcelPLT() {
        List<L2L3Wrapper> excelData = new List<L2L3Wrapper>();
        Integer srNo = 1;
        for (L2L3Wrapper PLT : filterList3) {
            L2L3Wrapper excelRow = new L2L3Wrapper(PLT.L2ProductName);
            excelRow.SrNo = srNo;
            excelRow.ItemDescription = PLT.ItemDescription;
            excelRow.unitPrice = PLT.unitPrice;
            excelRow.strQuantity = PLT.strQuantity;
            excelRow.strTotal = PLT.strTotal;
            excelRow.pnlQuantity = PLT.pnlQuantity;
            excelRow.pnlTotal = PLT.pnlTotal;
            excelRow.sprlQuantity = PLT.sprlQuantity;
            excelRow.sprlTotal = PLT.sprlTotal;
            excelRow.spareQuantity = PLT.spareQuantity;
            excelRow.spareTotal = PLT.spareTotal;
            excelRow.customQuantity = PLT.customQuantity;
            excelRow.customTotal = PLT.customTotal;
            excelRow.PLTtotalQuantity = PLT.PLTtotalQuantity;
            excelRow.PLTtotalValue = PLT.PLTtotalValue;
            excelData.add(excelRow);
            srNo++;
        }
        
        excelExportData = excelData;
        
        return Page.vf_ExcelPage_PLT;
    } 
    
    /************************************************************
    @description : This methods are for Downloading the PDF
    *************************************************************/
    
    public PageReference downloadPDFPLM() {
        List<L2L3Wrapper> PDFData = new List<L2L3Wrapper>();
        Integer srNo = 1;
        for (L2L3Wrapper PLM : filterList) {
            L2L3Wrapper pdfRow = new L2L3Wrapper(PLM.L2ProductName);
            pdfRow.SrNo = srNo;
            pdfRow.ItemDescription = PLM.ItemDescription;
            pdfRow.unitPrice = PLM.unitPrice;
            pdfRow.fehQuantity = PLM.fehQuantity;
            pdfRow.fehTotal = PLM.fehTotal;
            pdfRow.dehQuantity = PLM.dehQuantity;
            pdfRow.dehTotal = PLM.dehTotal;
            pdfRow.shellQuantity = PLM.shellQuantity;
            pdfRow.shellTotal = PLM.shellTotal;
            pdfRow.spareQuantity = PLM.spareQuantity;
            pdfRow.spareTotal = PLM.spareTotal;
            pdfRow.customQuantity = PLM.customQuantity;
            pdfRow.customTotal = PLM.customTotal;
            pdfRow.PLMtotalQuantity = PLM.PLMtotalQuantity;
            pdfRow.PLMtotalValue = PLM.PLMtotalValue;
            PDFData.add(pdfRow);
            srNo++;
        }
        
        PDFExportData = PDFData;
        string pageURL =  '/apex/vf_PDF_PLM?'+PDFExportData;
        
        PageReference downloadPDFpage = new PageReference(pageURL);
        downloadPDFpage.getHeaders().put('content-disposition', 'attachment; filename=PLM_PartList_Data.pdf');
        
        return downloadPDFpage;
        
    }
    
    /*
    public PageReference downloadPDFPLS() {
        List<L2L3Wrapper> PDFData = new List<L2L3Wrapper>();
        Integer srNo = 1;
        for (L2L3Wrapper PLM : filterList2) {
            L2L3Wrapper pdfRow = new L2L3Wrapper(PLM.L2ProductName);
            pdfRow.SrNo = srNo;
            pdfRow.ItemDescription = PLM.ItemDescription;
            pdfRow.unitPrice = PLM.unitPrice;
            pdfRow.pnlQuantity = PLM.pnlQuantity;
            pdfRow.pnlTotal = PLM.pnlTotal;
            pdfRow.sfbQuantity = PLM.sfbQuantity;
            pdfRow.sfbTotal = PLM.sfbTotal;
            pdfRow.mfbQuantity = PLM.mfbQuantity;
            pdfRow.mfbTotal = PLM.mfbTotal;
            pdfRow.spareQuantity = PLM.spareQuantity;
            pdfRow.spareTotal = PLM.spareTotal;
            pdfRow.customQuantity = PLM.customQuantity;
            pdfRow.customTotal = PLM.customTotal;
            pdfRow.PLStotalQuantity = PLM.PLStotalQuantity;
            pdfRow.PLStotalValue = PLM.PLStotalValue;
            PDFData.add(pdfRow);
            srNo++;
        }
        
        PDFExportData = PDFData;
        string pageURL =  '/apex/vf_PDF_PLS?'+PDFExportData;
        
        PageReference downloadPDFpage = new PageReference(pageURL);
        downloadPDFpage.getHeaders().put('content-disposition', 'attachment; filename=PLS_PartList_Data.pdf');
        
        return downloadPDFpage;
        
    }
    
    public PageReference downloadPDFPLT() {
        List<L2L3Wrapper> PDFData = new List<L2L3Wrapper>();
        Integer srNo = 1;
        for (L2L3Wrapper PLM : filterList3) {
            L2L3Wrapper pdfRow = new L2L3Wrapper(PLM.L2ProductName);
            pdfRow.SrNo = srNo;
            pdfRow.ItemDescription = PLM.ItemDescription;
            pdfRow.unitPrice = PLM.unitPrice;
            pdfRow.strQuantity = PLM.strQuantity;
            pdfRow.strTotal = PLM.strTotal;
            pdfRow.pnlQuantity = PLM.pnlQuantity;
            pdfRow.pnlTotal = PLM.pnlTotal;
            pdfRow.sprlQuantity = PLM.sprlQuantity;
            pdfRow.sprlTotal = PLM.sprlTotal;
            pdfRow.spareQuantity = PLM.spareQuantity;
            pdfRow.spareTotal = PLM.spareTotal;
            pdfRow.customQuantity = PLM.customQuantity;
            pdfRow.customTotal = PLM.customTotal;
            pdfRow.PLTtotalQuantity = PLM.PLTtotalQuantity;
            pdfRow.PLTtotalValue = PLM.PLTtotalValue;
            PDFData.add(pdfRow);
            srNo++;
        }
        
        PDFExportData = PDFData;
        string pageURL =  '/apex/vf_PDF_PLT?'+PDFExportData;
        
        PageReference downloadPDFpage = new PageReference(pageURL);
        downloadPDFpage.getHeaders().put('content-disposition', 'attachment; filename=PLT_PartList_Data.pdf');
        
        return downloadPDFpage;
        
    }
    */
}