@RestResource(urlMapping='/api/productData/*')
global class ProductDataRetrieverAPI {
    
    // Cache for field configurations
    private static Map<String, Set<String>> fieldConfigCache;
    
    @HttpPost
    global static void getProductRelatedData() {
        ResponseWrapper response = new ResponseWrapper();
        
        try {
            // Initialize field configuration cache
            initializeFieldConfigCache();
            
            // Parse the incoming JSON request
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            RequestWrapper requestData = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);
            
            // Validate input
            if (String.isBlank(requestData.product2Name) || String.isBlank(requestData.partListName)) {
                response.success = false;
                response.message = 'Product2 Name and Part List Name are required';
                sendResponse(response);
                return;
            }
            
            // Store values in local variables for binding
            String product2Name = requestData.product2Name;
            String partListName = requestData.partListName;
            
            // Build dynamic queries based on metadata configuration
            String partListFields = buildFieldList('Part_List__c');
            String itemWeightFields = buildFieldList('Item_Weight__c');
            String salesOrgProductFields = buildFieldList('Sales_Organization_Product__c');
            String salesOrgSOFields = buildFieldList('Sales_Org_Last_SAP_SO__c');
            
            // Step 1: Get all Product2 records with Part_List__c reference
            String productQuery = 'SELECT Id, Name, Part_List__c, Part_List__r.' + 
                                  String.join(new List<String>(fieldConfigCache.get('Part_List__c')), ', Part_List__r.') +
                                  ' FROM Product2 WHERE Name = :product2Name AND Part_List__r.Name = :partListName';
            
            List<Product2> products = Database.query(productQuery);
            
            if (products.isEmpty()) {
                response.success = false;
                response.message = 'No matching Product2 records found';
                sendResponse(response);
                return;
            }
            
            // Collect all Product2 IDs
            Set<Id> productIds = new Set<Id>();
            for (Product2 product : products) {
                productIds.add(product.Id);
            }
            
            // Step 2: Get all Item_Weight__c for these Product2s
            String itemWeightQuery = 'SELECT ' + itemWeightFields + 
                                    ' FROM Item_Weight__c WHERE Product_L3__c IN :productIds';
            List<Item_Weight__c> itemWeightsList = Database.query(itemWeightQuery);
            
            Map<Id, List<SObject>> itemWeightsByProduct = new Map<Id, List<SObject>>();
            for (Item_Weight__c iw : itemWeightsList) {
                Id productId = (Id)iw.get('Product_L3__c');
                if (!itemWeightsByProduct.containsKey(productId)) {
                    itemWeightsByProduct.put(productId, new List<SObject>());
                }
                itemWeightsByProduct.get(productId).add(iw);
            }
            
            // Step 3: Get all Sales_Organization_Product__c for these Product2s
            String salesOrgProductQuery = 'SELECT ' + salesOrgProductFields + 
                                         ' FROM Sales_Organization_Product__c WHERE Product__c IN :productIds';
            List<Sales_Organization_Product__c> salesOrgProductsList = Database.query(salesOrgProductQuery);
            
            Map<Id, List<SObject>> salesOrgProductsByProduct = new Map<Id, List<SObject>>();
            for (Sales_Organization_Product__c sop : salesOrgProductsList) {
                Id productId = (Id)sop.get('Product__c');
                if (!salesOrgProductsByProduct.containsKey(productId)) {
                    salesOrgProductsByProduct.put(productId, new List<SObject>());
                }
                salesOrgProductsByProduct.get(productId).add(sop);
            }
            
            // Step 4: Get all SAP_Last_Sale_Price__c for these Product2s
            List<SAP_Last_Sale_Price__c> allSapPrices = [
                SELECT Id, Name, Product_L3__c 
                FROM SAP_Last_Sale_Price__c 
                WHERE Product_L3__c IN :productIds
            ];
            
            Map<Id, List<SAP_Last_Sale_Price__c>> sapPricesByProduct = new Map<Id, List<SAP_Last_Sale_Price__c>>();
            Set<Id> sapPriceIds = new Set<Id>();
            for (SAP_Last_Sale_Price__c sp : allSapPrices) {
                if (!sapPricesByProduct.containsKey(sp.Product_L3__c)) {
                    sapPricesByProduct.put(sp.Product_L3__c, new List<SAP_Last_Sale_Price__c>());
                }
                sapPricesByProduct.get(sp.Product_L3__c).add(sp);
                sapPriceIds.add(sp.Id);
            }
            
            // Step 5: Get all Sales_Org_Last_SAP_SO__c related to SAP_Last_Sale_Price__c
            Map<Id, List<SObject>> salesOrgSOBySapPrice = new Map<Id, List<SObject>>();
            if (!sapPriceIds.isEmpty()) {
                String salesOrgSOQuery = 'SELECT ' + salesOrgSOFields + 
                                        ' FROM Sales_Org_Last_SAP_SO__c WHERE SAP_Last_Sale__c IN :sapPriceIds';
                List<Sales_Org_Last_SAP_SO__c> salesOrgSOList = Database.query(salesOrgSOQuery);
                
                for (Sales_Org_Last_SAP_SO__c so : salesOrgSOList) {
                    Id sapPriceId = (Id)so.get('SAP_Last_Sale__c');
                    if (!salesOrgSOBySapPrice.containsKey(sapPriceId)) {
                        salesOrgSOBySapPrice.put(sapPriceId, new List<SObject>());
                    }
                    salesOrgSOBySapPrice.get(sapPriceId).add(so);
                }
            }
            
            // Prepare results for each Product2
            List<ProductDataWrapper> dataList = new List<ProductDataWrapper>();
            
            for (Product2 product : products) {
                ProductDataWrapper productData = new ProductDataWrapper();
                
                // Part_List__c data with dynamic fields
                SObject partListRecord = product.getSObject('Part_List__r');
                productData.partList = buildDynamicObject(partListRecord, 'Part_List__c');
                
                // Get all Item_Weight__c with dynamic fields
                productData.itemWeights = new List<Map<String, Object>>();
                if (itemWeightsByProduct.containsKey(product.Id)) {
                    for (SObject iw : itemWeightsByProduct.get(product.Id)) {
                        productData.itemWeights.add(buildDynamicObject(iw, 'Item_Weight__c'));
                    }
                }
                
                // Get all Sales_Organization_Product__c with dynamic fields
                productData.salesOrganizationProducts = new List<Map<String, Object>>();
                if (salesOrgProductsByProduct.containsKey(product.Id)) {
                    for (SObject sop : salesOrgProductsByProduct.get(product.Id)) {
                        productData.salesOrganizationProducts.add(buildDynamicObject(sop, 'Sales_Organization_Product__c'));
                    }
                }
                
                // Get all Sales_Org_Last_SAP_SO__c with dynamic fields
                productData.salesOrgLastSAPSO = new List<Map<String, Object>>();
                if (sapPricesByProduct.containsKey(product.Id)) {
                    for (SAP_Last_Sale_Price__c sp : sapPricesByProduct.get(product.Id)) {
                        if (salesOrgSOBySapPrice.containsKey(sp.Id)) {
                            for (SObject so : salesOrgSOBySapPrice.get(sp.Id)) {
                                productData.salesOrgLastSAPSO.add(buildDynamicObject(so, 'Sales_Org_Last_SAP_SO__c'));
                            }
                        }
                    }
                }
                
                dataList.add(productData);
            }
            
            response.success = true;
            response.message = 'Data retrieved successfully';
            response.data = dataList;
            
        } catch (Exception e) {
            response.success = false;
            response.message = 'Error: ' + e.getMessage();
            response.errorDetails = e.getStackTraceString();
        }
        
        sendResponse(response);
    }
    
    // Helper method to send JSON response
    private static void sendResponse(ResponseWrapper response) {
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
        RestContext.response.statusCode = response.success ? 200 : 400;
    }
    
    // Initialize field configuration cache from Custom Metadata
    private static void initializeFieldConfigCache() {
        if (fieldConfigCache != null) {
            return;
        }
        
        fieldConfigCache = new Map<String, Set<String>>();
        
        List<API_Field_Configuration__mdt> configs = [
            SELECT Object_API_Name__c, Field_API_Name__c, Is_Active__c
            FROM API_Field_Configuration__mdt
            WHERE Is_Active__c = true
            ORDER BY Display_Order__c
        ];
        
        for (API_Field_Configuration__mdt config : configs) {
            if (!fieldConfigCache.containsKey(config.Object_API_Name__c)) {
                fieldConfigCache.put(config.Object_API_Name__c, new Set<String>());
            }
            fieldConfigCache.get(config.Object_API_Name__c).add(config.Field_API_Name__c);
        }
        
        // Ensure mandatory fields are always included (Sets automatically handle duplicates)
        ensureMandatoryField('Part_List__c', 'Id');
        ensureMandatoryField('Part_List__c', 'Name');
        
        ensureMandatoryField('Item_Weight__c', 'Id');
        ensureMandatoryField('Item_Weight__c', 'Product_L3__c');
        
        ensureMandatoryField('Sales_Organization_Product__c', 'Id');
        ensureMandatoryField('Sales_Organization_Product__c', 'Product__c');
        
        ensureMandatoryField('Sales_Org_Last_SAP_SO__c', 'Id');
        ensureMandatoryField('Sales_Org_Last_SAP_SO__c', 'SAP_Last_Sale__c');
    }
    
    // Helper method to ensure mandatory fields exist
    private static void ensureMandatoryField(String objectApiName, String fieldApiName) {
        if (!fieldConfigCache.containsKey(objectApiName)) {
            fieldConfigCache.put(objectApiName, new Set<String>());
        }
        fieldConfigCache.get(objectApiName).add(fieldApiName);
    }
    
    // Build field list for SOQL query
    private static String buildFieldList(String objectApiName) {
        Set<String> fields = fieldConfigCache.get(objectApiName);
        if (fields == null || fields.isEmpty()) {
            return 'Id, Name';
        }
        
        // Convert Set to List to ensure consistent ordering and avoid duplicates
        List<String> fieldList = new List<String>(fields);
        return String.join(fieldList, ', ');
    }
    
    // Build dynamic object with configured fields
    private static Map<String, Object> buildDynamicObject(SObject record, String objectApiName) {
        Map<String, Object> result = new Map<String, Object>();
        
        if (record == null) {
            return result;
        }
        
        Set<String> fields = fieldConfigCache.get(objectApiName);
        if (fields == null || fields.isEmpty()) {
            result.put('Id', record.get('Id'));
            result.put('Name', record.get('Name'));
            return result;
        }
        
        for (String field : fields) {
            try {
                Object fieldValue = record.get(field);
                result.put(field, fieldValue);
            } catch (Exception e) {
                // Field doesn't exist or can't be accessed, skip it
                System.debug('Error accessing field ' + field + ': ' + e.getMessage());
            }
        }
        
        return result;
    }
    
    // Request wrapper class
    global class RequestWrapper {
        public String product2Name;
        public String partListName;
    }
    
    // Response wrapper class
    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public List<ProductDataWrapper> data;
        public String errorDetails;
        
        public ResponseWrapper() {
            this.success = false;
            this.data = new List<ProductDataWrapper>();
        }
    }
    
    // Product data wrapper
    global class ProductDataWrapper {
        public Map<String, Object> partList;
        public List<Map<String, Object>> itemWeights;
        public List<Map<String, Object>> salesOrganizationProducts;
        public List<Map<String, Object>> salesOrgLastSAPSO;
        
        public ProductDataWrapper() {
            this.itemWeights = new List<Map<String, Object>>();
            this.salesOrganizationProducts = new List<Map<String, Object>>();
            this.salesOrgLastSAPSO = new List<Map<String, Object>>();
        }
    }
}