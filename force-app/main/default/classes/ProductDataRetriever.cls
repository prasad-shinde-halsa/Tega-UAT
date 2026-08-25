public class ProductDataRetriever {
    
    public static List<Map<String, Object>> getProductRelatedData(String product2Name, String partListName) {
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
        
        // Step 1: Get all Product2 records with Part_List__c reference
        List<Product2> products = [
            SELECT Id, Name, Part_List__c, Part_List__r.Id, Part_List__r.Name
            FROM Product2
            WHERE Name = :product2Name
            AND Part_List__r.Name = :partListName
        ];
        
        if (products.isEmpty()) {
            return resultList; // No matching records found
        }
        
        // Collect all Product2 IDs
        Set<Id> productIds = new Set<Id>();
        for (Product2 product : products) {
            productIds.add(product.Id);
        }
        
        // Step 2: Get all Item_Weight__c for these Product2s
        Map<Id, List<Item_Weight__c>> itemWeightsByProduct = new Map<Id, List<Item_Weight__c>>();
        for (Item_Weight__c iw : [SELECT Id, Name, Product_L3__c FROM Item_Weight__c WHERE Product_L3__c IN :productIds]) {
            if (!itemWeightsByProduct.containsKey(iw.Product_L3__c)) {
                itemWeightsByProduct.put(iw.Product_L3__c, new List<Item_Weight__c>());
            }
            itemWeightsByProduct.get(iw.Product_L3__c).add(iw);
        }
        
        // Step 3: Get all Sales_Organization_Product__c for these Product2s
        Map<Id, List<Sales_Organization_Product__c>> salesOrgProductsByProduct = new Map<Id, List<Sales_Organization_Product__c>>();
        for (Sales_Organization_Product__c sop : [SELECT Id, Name, Product__c FROM Sales_Organization_Product__c WHERE Product__c IN :productIds]) {
            if (!salesOrgProductsByProduct.containsKey(sop.Product__c)) {
                salesOrgProductsByProduct.put(sop.Product__c, new List<Sales_Organization_Product__c>());
            }
            salesOrgProductsByProduct.get(sop.Product__c).add(sop);
        }
        
        // Step 4: Get all SAP_Last_Sale_Price__c for these Product2s
        Map<Id, List<SAP_Last_Sale_Price__c>> sapPricesByProduct = new Map<Id, List<SAP_Last_Sale_Price__c>>();
        List<SAP_Last_Sale_Price__c> allSapPrices = [SELECT Id, Name, Product_L3__c FROM SAP_Last_Sale_Price__c WHERE Product_L3__c IN :productIds];
        
        Set<Id> sapPriceIds = new Set<Id>();
        for (SAP_Last_Sale_Price__c sp : allSapPrices) {
            if (!sapPricesByProduct.containsKey(sp.Product_L3__c)) {
                sapPricesByProduct.put(sp.Product_L3__c, new List<SAP_Last_Sale_Price__c>());
            }
            sapPricesByProduct.get(sp.Product_L3__c).add(sp);
            sapPriceIds.add(sp.Id);
        }
        
        // Step 5: Get all Sales_Org_Last_SAP_SO__c related to SAP_Last_Sale_Price__c
        Map<Id, List<Sales_Org_Last_SAP_SO__c>> salesOrgSOBySapPrice = new Map<Id, List<Sales_Org_Last_SAP_SO__c>>();
        if (!sapPriceIds.isEmpty()) {
            for (Sales_Org_Last_SAP_SO__c so : [SELECT Id, Name, SAP_Last_Sale__c FROM Sales_Org_Last_SAP_SO__c WHERE SAP_Last_Sale__c IN :sapPriceIds]) {
                if (!salesOrgSOBySapPrice.containsKey(so.SAP_Last_Sale__c)) {
                    salesOrgSOBySapPrice.put(so.SAP_Last_Sale__c, new List<Sales_Org_Last_SAP_SO__c>());
                }
                salesOrgSOBySapPrice.get(so.SAP_Last_Sale__c).add(so);
            }
        }
        
        // Prepare results for each Product2
        for (Product2 product : products) {
            Map<String, Object> result = new Map<String, Object>();
            
            // Part_List__c data
            result.put('Part_List_Id', product.Part_List__r.Id);
            result.put('Part_List_Name', product.Part_List__r.Name);
            
            // Get all Item_Weight__c IDs
            List<Id> itemWeightIds = new List<Id>();
            if (itemWeightsByProduct.containsKey(product.Id)) {
                for (Item_Weight__c iw : itemWeightsByProduct.get(product.Id)) {
                    itemWeightIds.add(iw.Id);
                }
            }
            result.put('Item_Weight_c', itemWeightIds);
            
            // Get all Sales_Organization_Product__c IDs
            List<Id> salesOrgProductIds = new List<Id>();
            if (salesOrgProductsByProduct.containsKey(product.Id)) {
                for (Sales_Organization_Product__c sop : salesOrgProductsByProduct.get(product.Id)) {
                    salesOrgProductIds.add(sop.Id);
                }
            }
            result.put('Sales_Organization_Product_c', salesOrgProductIds);
            
            // Get all Sales_Org_Last_SAP_SO__c IDs
            List<Id> salesOrgSOIds = new List<Id>();
            if (sapPricesByProduct.containsKey(product.Id)) {
                for (SAP_Last_Sale_Price__c sp : sapPricesByProduct.get(product.Id)) {
                    if (salesOrgSOBySapPrice.containsKey(sp.Id)) {
                        for (Sales_Org_Last_SAP_SO__c so : salesOrgSOBySapPrice.get(sp.Id)) {
                            salesOrgSOIds.add(so.Id);
                        }
                    }
                }
            }
            result.put('Sales_Org_Last_SAP_SO_c', salesOrgSOIds);
            
            resultList.add(result);
        }
        
        return resultList;
    }
}