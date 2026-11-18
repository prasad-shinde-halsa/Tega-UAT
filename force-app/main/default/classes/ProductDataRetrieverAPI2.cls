/////////////////////////////////////////////
//      Dev Name - Ranjeet Kumar          ///
/////////////////////////////////////////////


@RestResource(urlMapping='/api/getProductData/*')
global class ProductDataRetrieverAPI2 {
    
    @HttpPost
    global static void getProductRelatedData() {
        ResponseWrapper response = new ResponseWrapper();
        
        try {
            // Parse the incoming JSON request
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            RequestWrapper requestData = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);
            
            // Validate input - at least one of product2Name or partListName must be provided
            if (String.isBlank(requestData.product2Name) && String.isBlank(requestData.partListName)) {
                response.success = false;
                response.message = 'At least one of Product Name or Part List Name is required';
                sendResponse(response);
                return;
            }
            
            if (String.isBlank(requestData.salesOrgId)) {
                response.success = false;
                response.message = 'Sales Org ID is required';
                sendResponse(response);
                return;
            }
            
            // Store in local variables for bind variable support
            String product2Name       = requestData.product2Name;
            String partListName       = requestData.partListName;
            String salesOrgId         = requestData.salesOrgId;
            String partListRevisionNo = requestData.partListRevisionNo;
            
            Boolean hasProduct2Name = String.isNotBlank(product2Name);
            Boolean hasPartListName = String.isNotBlank(partListName);
            
            Set<Id> productIds  = new Set<Id>();
            Set<Id> partListIds = new Set<Id>();
            
            // ─────────────────────────────────────────────────────────────
            // SCENARIO A : Both product2Name AND partListName are provided
            //              → original L2_L3_Product__c join query
            // ─────────────────────────────────────────────────────────────
            if (hasProduct2Name && hasPartListName) {
                
                List<L2_L3_Product__c> l2l3Products = [
                    SELECT Id, Name, Product_L3__c, Part_List__c,
                           Product_L3__r.Id, Product_L3__r.Name,
                           Part_List__r.Id,  Part_List__r.Name
                    FROM L2_L3_Product__c
                    WHERE Product_L3__r.Name = :product2Name
                    AND   Part_List__r.Name  = :partListName
                ];
                
                if (l2l3Products.isEmpty()) {
                    response.partList                  = noRecords();
                    response.itemWeights               = noRecords();
                    response.salesOrganizationProducts = noRecords();
                    response.L1L3product               = noRecords();
                } else {
                    
                    for (L2_L3_Product__c l2l3 : l2l3Products) {
                        if (l2l3.Product_L3__c != null) productIds.add(l2l3.Product_L3__c);
                        if (l2l3.Part_List__c  != null) partListIds.add(l2l3.Part_List__c);
                    }
                    
                    // Step 2: Part_List__c
                    if (!partListIds.isEmpty() && String.isNotBlank(partListRevisionNo)) {
                        List<Map<String, Object>> partListData = new List<Map<String, Object>>();
                        for (Part_List__c pl : [
                            SELECT Id, Name, Alternative_BOM__c, BOM__c, CreatedById, CurrencyIsoCode,
                                   Customer__c, Customer_Equipment__c, Customer_ID__c, Customer_Name__c,
                                   DCR_Blocked__c, Delivery_Req__c, Description__c, Direct_Quoted_Exchange_Rate__c,
                                   Equipment_Record_Type__c, HSN_Code__c, LastModifiedById, Last_Offer_Number__c,
                                   Last_Offer_Value_Foreign_Currency__c, Version_Number_Component__c,
                                   Part_List_Type__c, Reference_score_DEH__c, Reference_score_FEH__c,
                                   Reference_score_Shel__c, Revision__c, Zone_Priority__c
                            FROM Part_List__c
                            WHERE Id IN :partListIds
                            AND   Version_Number_Component__c = :partListRevisionNo
                        ]) {
                            Map<String, Object> plMap = new Map<String, Object>();
                            plMap.put('Id',                             pl.Id);
                            plMap.put('Name',                           pl.Name);
                            plMap.put('Part List Revision No',          pl.Version_Number_Component__c);
                            plMap.put('CurrencyIsoCode',                pl.CurrencyIsoCode);
                            plMap.put('Direct_Quoted_Exchange_Rate__c', pl.Direct_Quoted_Exchange_Rate__c);
                            partListData.add(plMap);
                        }
                        response.partList = partListData.isEmpty() ? noRecords() : partListData;
                    } else {
                        response.partList = noRecords();
                    }
                    
                    // Step 3: Item_Weight__c
                    if (!productIds.isEmpty()) {
                        List<Map<String, Object>> itemWeightsData = new List<Map<String, Object>>();
                        for (Item_Weight__c iw : [
                            SELECT Id, Name, Product_L3__c, Net_Weight__c, Plant__c, Description__c,
                                   CreatedById, CurrencyIsoCode, LastModifiedById, OwnerId
                            FROM Item_Weight__c
                            WHERE Product_L3__c IN :productIds
                        ]) {
                            Map<String, Object> iwMap = new Map<String, Object>();
                            iwMap.put('Id',            iw.Id);
                            iwMap.put('Net_Weight__c', iw.Net_Weight__c);
                            itemWeightsData.add(iwMap);
                        }
                        response.itemWeights = itemWeightsData.isEmpty() ? noRecords() : itemWeightsData;
                    } else {
                        response.itemWeights = noRecords();
                    }
                    
                    // Step 4: Sales_Organization_Product__c
                    if (!productIds.isEmpty()) {
                        List<Map<String, Object>> salesOrgData = new List<Map<String, Object>>();
                        for (Sales_Organization_Product__c sop : [
                            SELECT Id, Name, Product__c, Price__c, Sales_Org__c
                            FROM Sales_Organization_Product__c
                            WHERE Product__c IN :productIds
                            AND   Sales_Org__c = :salesOrgId
                        ]) {
                            Map<String, Object> sopMap = new Map<String, Object>();
                            sopMap.put('Id',           sop.Id);
                            sopMap.put('Price__c',     sop.Price__c);
                            sopMap.put('Sales_Org__c', sop.Sales_Org__c);
                            salesOrgData.add(sopMap);
                        }
                        response.salesOrganizationProducts = salesOrgData.isEmpty() ? noRecords() : salesOrgData;
                    } else {
                        response.salesOrganizationProducts = noRecords();
                    }
                    
                    // Step 5: L1_L3_Product__c
                    if (String.isNotBlank(partListRevisionNo)) {
                        List<Map<String, Object>> l1l3Data = new List<Map<String, Object>>();
                        for (L1_L3_Product__c l1l3 : [
                            SELECT Id, Name, CurrencyIsoCode, L1L3_Code__c, LastModifiedById,
                                   Last_Sales_Date__c, Last_Sales_Price__c, Offer_Number__c,
                                   OfferDate__c, Order_Number__c, OrderDate__c, Part_List__c,
                                   Product_del__c, Sales_Order__c, Sales_Organization__c,
                                   SAP_Last_Sale_Price__c, CreatedById
                            FROM L1_L3_Product__c
                            WHERE Product_del__r.Name                      = :product2Name
                            AND   Part_List__r.Name                        = :partListName
                            AND   Part_List__r.Version_Number_Component__c = :partListRevisionNo
                        ]) {
                            Map<String, Object> l1l3Map = new Map<String, Object>();
                            l1l3Map.put('Id',                  l1l3.Id);
                            l1l3Map.put('CurrencyIsoCode',     l1l3.CurrencyIsoCode);
                            l1l3Map.put('L1L3_Code__c',        l1l3.L1L3_Code__c);
                            l1l3Map.put('Last_Sales_Date__c',  l1l3.Last_Sales_Date__c);
                            l1l3Map.put('Last_Sales_Price__c', l1l3.Last_Sales_Price__c);
                            l1l3Map.put('Order_Number__c',     l1l3.Order_Number__c);
                            l1l3Data.add(l1l3Map);
                        }
                        response.L1L3product = l1l3Data.isEmpty() ? noRecords() : l1l3Data;
                    } else {
                        response.L1L3product = noRecords();
                    }
                }
                
            // ─────────────────────────────────────────────────────────────
            // SCENARIO B : Only partListName is provided
            //              → query directly on Part_List__c only
            // ─────────────────────────────────────────────────────────────
            } else if (hasPartListName && !hasProduct2Name) {
                
                List<Part_List__c> directPartLists = [
                    SELECT Id, Name, Alternative_BOM__c, BOM__c, CreatedById, CurrencyIsoCode,
                           Customer__c, Customer_Equipment__c, Customer_ID__c, Customer_Name__c,
                           DCR_Blocked__c, Delivery_Req__c, Description__c, Direct_Quoted_Exchange_Rate__c,
                           Equipment_Record_Type__c, HSN_Code__c, LastModifiedById, Last_Offer_Number__c,
                           Last_Offer_Value_Foreign_Currency__c, Version_Number_Component__c,
                           Part_List_Type__c, Reference_score_DEH__c, Reference_score_FEH__c,
                           Reference_score_Shel__c, Revision__c, Zone_Priority__c
                    FROM Part_List__c
                    WHERE Name = :partListName
                ];
                
                if (directPartLists.isEmpty()) {
                    response.partList = noRecords();
                } else {
                    List<Map<String, Object>> partListData = new List<Map<String, Object>>();
                    for (Part_List__c pl : directPartLists) {
                        Map<String, Object> plMap = new Map<String, Object>();
                        plMap.put('Id',                             pl.Id);
                        plMap.put('Name',                           pl.Name);
                        plMap.put('Part List Revision No',          pl.Version_Number_Component__c);
                        plMap.put('CurrencyIsoCode',                pl.CurrencyIsoCode);
                        plMap.put('Direct_Quoted_Exchange_Rate__c', pl.Direct_Quoted_Exchange_Rate__c);
                        partListData.add(plMap);
                    }
                    response.partList = partListData;
                }
                
                response.itemWeights               = noRecords();
                response.salesOrganizationProducts = noRecords();
                response.L1L3product               = noRecords();
                
            // ─────────────────────────────────────────────────────────────
            // SCENARIO C : Only product2Name is provided
            //              → query Product2, Item_Weight, SalesOrg only
            // ─────────────────────────────────────────────────────────────
            } else if (hasProduct2Name && !hasPartListName) {
                
                List<Product2> products = [
                    SELECT Id, Name, ProductCode, Description, IsActive,
                           Family, CreatedById, LastModifiedById
                    FROM Product2
                    WHERE Name = :product2Name
                ];
                
                response.partList    = noRecords();
                response.L1L3product = noRecords();
                
                if (products.isEmpty()) {
                    response.itemWeights               = noRecords();
                    response.salesOrganizationProducts = noRecords();
                } else {
                    for (Product2 p : products) {
                        productIds.add(p.Id);
                    }
                    
                    // Item_Weight__c
                    List<Map<String, Object>> itemWeightsData = new List<Map<String, Object>>();
                    for (Item_Weight__c iw : [
                        SELECT Id, Name, Product_L3__c, Net_Weight__c, Plant__c, Description__c,
                               CreatedById, CurrencyIsoCode, LastModifiedById, OwnerId
                        FROM Item_Weight__c
                        WHERE Product_L3__c IN :productIds
                    ]) {
                        Map<String, Object> iwMap = new Map<String, Object>();
                        iwMap.put('Id',            iw.Id);
                        iwMap.put('Net_Weight__c', iw.Net_Weight__c);
                        itemWeightsData.add(iwMap);
                    }
                    response.itemWeights = itemWeightsData.isEmpty() ? noRecords() : itemWeightsData;
                    
                    // Sales_Organization_Product__c
                    List<Map<String, Object>> salesOrgData = new List<Map<String, Object>>();
                    for (Sales_Organization_Product__c sop : [
                        SELECT Id, Name, Product__c, Price__c, Sales_Org__c
                        FROM Sales_Organization_Product__c
                        WHERE Product__c IN :productIds
                        AND   Sales_Org__c = :salesOrgId
                    ]) {
                        Map<String, Object> sopMap = new Map<String, Object>();
                        sopMap.put('Id',           sop.Id);
                        sopMap.put('Price__c',     sop.Price__c);
                        sopMap.put('Sales_Org__c', sop.Sales_Org__c);
                        salesOrgData.add(sopMap);
                    }
                    response.salesOrganizationProducts = salesOrgData.isEmpty() ? noRecords() : salesOrgData;
                }
            }
            
            response.success = true;
            response.message = 'Data retrieved successfully';
            
        } catch (Exception e) {
            response.success = false;
            response.message      = 'Error: ' + e.getMessage();
            response.errorDetails = e.getStackTraceString();
        }
        
        sendResponse(response);
    }
    
    // ── Utility: single "No records found" entry ──────────────────────────────
    private static List<Map<String, Object>> noRecords() {
        Map<String, Object> entry = new Map<String, Object>();
        entry.put('message', 'No records found');
        return new List<Map<String, Object>>{ entry };
    }
    
    // ── Helper ────────────────────────────────────────────────────────────────
    private static void sendResponse(ResponseWrapper response) {
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
        RestContext.response.statusCode   = response.success ? 200 : 400;
    }
    
    // ── Request Wrapper ───────────────────────────────────────────────────────
    global class RequestWrapper {
        public String product2Name;
        public String partListName;
        public String salesOrgId;
        public String partListRevisionNo;
    }
    
    // ── Response Wrapper ──────────────────────────────────────────────────────
    global class ResponseWrapper {
        public Boolean success;
        public String  message;
        public String  errorDetails;
        public List<Map<String, Object>> partList;
        public List<Map<String, Object>> itemWeights;
        public List<Map<String, Object>> salesOrganizationProducts;
        public List<Map<String, Object>> L1L3product;
        
        public ResponseWrapper() {
            this.success = false;
        }
    }
}