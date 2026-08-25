global class TOPFieldstagging implements Database.Batchable<sObject>, Schedulable {
    //changes need to be done for best practice 
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new TOPFieldstagging(), 50);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, product2Name__c, partListName__c, salesOrgId__c, partListRevisionNo__c,
                   Direct_Quoted_Exchange_Rate__c, L1L3_CurrencyIsoCode__c, Last_Sales_Date__c,
                   Last_Sales_Price__c, Net_Weight__c, Order_Number__c, partList_CurrencyIsoCode__c,
                   Price__c, SOP_CurrencyIsoCode__c, Status__c, Error_Log__c
            FROM TOP_Field_Staging__c
            WHERE Status__c = 'In Progress'
        ]);
    }

    global void execute(Database.BatchableContext bc, List<TOP_Field_Staging__c> scope) {
        Set<String> productNames = new Set<String>();
        Set<String> partListNames = new Set<String>();
        Set<String> revNos = new Set<String>();
        Set<String> salesOrgIds = new Set<String>();

        for (TOP_Field_Staging__c stg : scope) {
            if (String.isNotBlank(stg.product2Name__c)) productNames.add(stg.product2Name__c);
            if (String.isNotBlank(stg.partListName__c)) partListNames.add(stg.partListName__c);
            if (String.isNotBlank(stg.partListRevisionNo__c)) revNos.add(stg.partListRevisionNo__c);
            if (String.isNotBlank(stg.salesOrgId__c)) salesOrgIds.add(stg.salesOrgId__c);
        }

        // ==========================================================
        // BULK QUERIES
        // ==========================================================
        
        // 1. Query Part Lists
        List<Part_List__c> partLists = new List<Part_List__c>();
        if (!partListNames.isEmpty()) {
            partLists = [SELECT Id, Name, Version_Number_Component__c, CurrencyIsoCode, Direct_Quoted_Exchange_Rate__c 
                         FROM Part_List__c 
                         WHERE Name IN :partListNames OR Version_Number_Component__c IN :revNos];
        }

        // 2. Query Product & Related Objects (Weight, Sales Org)
        Map<Id, Product2> productMap = new Map<Id, Product2>();
        List<Item_Weight__c> itemWeights = new List<Item_Weight__c>();
        List<Sales_Organization_Product__c> salesOrgProds = new List<Sales_Organization_Product__c>();

        if (!productNames.isEmpty()) {
            productMap = new Map<Id, Product2>([SELECT Id, Name FROM Product2 WHERE Name IN :productNames]);
            
            if (!productMap.isEmpty()) {
                itemWeights = [SELECT Id, Name, Product_L3__c, Product_L3__r.Name, Net_Weight__c 
                               FROM Item_Weight__c WHERE Product_L3__c IN :productMap.keySet()];
                               
                if (!salesOrgIds.isEmpty()) {
                    salesOrgProds = [SELECT Id, Name, Product__c, Product__r.Name, Sales_Org__c, Price__c 
                                     FROM Sales_Organization_Product__c 
                                     WHERE Product__c IN :productMap.keySet() AND Sales_Org__c IN :salesOrgIds];
                }
            }
        }

        // Query L1_L3_Product__c directly (Only needed if we have both Product and Part List)
        List<L1_L3_Product__c> l1l3Products = new List<L1_L3_Product__c>();
        if (!productNames.isEmpty() && !partListNames.isEmpty()) {
            l1l3Products = [SELECT Id, Name, Product_del__r.Name, Part_List__r.Name, Part_List__r.Version_Number_Component__c,
                                   CurrencyIsoCode, Last_Sales_Date__c, Last_Sales_Price__c, Order_Number__c
                            FROM L1_L3_Product__c 
                            WHERE Product_del__r.Name IN :productNames 
                            AND Part_List__r.Name IN :partListNames];
        }

        // Separate maps for each sObject type to avoid chunking limit
        Map<Id, Part_List__c> partListsToUpdate = new Map<Id, Part_List__c>();
        Map<Id, Item_Weight__c> itemWeightsToUpdate = new Map<Id, Item_Weight__c>();
        Map<Id, Sales_Organization_Product__c> sopToUpdate = new Map<Id, Sales_Organization_Product__c>();
        Map<Id, L1_L3_Product__c> l1l3ToUpdate = new Map<Id, L1_L3_Product__c>();
        List<TOP_Field_Staging__c> stagingRecordsToUpdate = new List<TOP_Field_Staging__c>();

        System.debug('======================================================================');
        System.debug('>>> STARTING BATCH CHUNK PROCESSING - SCOPE SIZE: ' + scope.size());
        System.debug('======================================================================');

        // ==========================================================
        // PROCESS STAGING RECORDS
        // ==========================================================
        for (TOP_Field_Staging__c stg : scope) {
            Boolean isSuccess = true;
            List<String> errorMessages = new List<String>();
            
            System.debug('----------------------------------------------------------------------');
            System.debug('>>> PROCESSING STAGING RECORD: ' + stg.Name + ' (Id: ' + stg.Id + ')');

            try {
                Boolean hasProd = String.isNotBlank(stg.product2Name__c);
                Boolean hasPart = String.isNotBlank(stg.partListName__c);

                // ─────────────────────────────────────────────────────────────
                // as per Biswa da - validation checks need to be done before processing - 
                // ─────────────────────────────────────────────────────────────
                
                // Validation 1: Check if partListName__c exists in Part_List__c
                if (hasPart) {
                    Boolean partListFound = false;
                    if (!partLists.isEmpty()) {
                        for (Part_List__c pl : partLists) {
                            if (pl.Name == stg.partListName__c) {
                                partListFound = true;
                                break;
                            }
                        }
                    }
                    if (!partListFound) {
                        errorMessages.add('ERROR: Part List not found in database - Field: partListName__c, Value: "' + stg.partListName__c + '"');
                        isSuccess = false;
                        System.debug('!!! VALIDATION ERROR: Part List not found - ' + stg.partListName__c);
                    }
                }

                // Validation 2: Check if product2Name__c exists in Product2
                if (hasProd) {
                    Boolean productFound = false;
                    if (!productMap.isEmpty()) {
                        for (Id prodId : productMap.keySet()) {
                            if (productMap.get(prodId).Name == stg.product2Name__c) {
                                productFound = true;
                                break;
                            }
                        }
                    }
                    if (!productFound) {
                        errorMessages.add('ERROR: Product not found in database - Field: product2Name__c, Value: "' + stg.product2Name__c + '"');
                        isSuccess = false;
                        System.debug('!!! VALIDATION ERROR: Product not found - ' + stg.product2Name__c);
                    }
                }

                // Validation 3: Net_Weight__c requires product2Name__c
                if (stg.Net_Weight__c != null && !hasProd) {
                    errorMessages.add('Missing required field: product2Name__c is required for updating Net_Weight__c');
                }
                
                // Validation 4: Direct_Quoted_Exchange_Rate__c and partList_CurrencyIsoCode__c require partListName__c
                if ((stg.Direct_Quoted_Exchange_Rate__c != null || String.isNotBlank(stg.partList_CurrencyIsoCode__c)) && !hasPart) {
                    errorMessages.add('Missing required field: partListName__c is required for updating Direct_Quoted_Exchange_Rate__c or partList_CurrencyIsoCode__c');
                }
                
                // Validation 5: Price__c and SOP_CurrencyIsoCode__c must both be present
                if (stg.Price__c != null || String.isNotBlank(stg.SOP_CurrencyIsoCode__c)) {
                    List<String> missingSOPFields = new List<String>();
                    if (stg.Price__c == null) missingSOPFields.add('Price__c');
                    if (String.isBlank(stg.SOP_CurrencyIsoCode__c)) missingSOPFields.add('SOP_CurrencyIsoCode__c');
                    if (!hasProd) missingSOPFields.add('product2Name__c');
                    if (String.isBlank(stg.salesOrgId__c)) missingSOPFields.add('salesOrgId__c');
                    
                    if (!missingSOPFields.isEmpty()) {
                        errorMessages.add('Missing required fields for Sales Organization Product update: ' + String.join(missingSOPFields, ', '));
                    }
                }
                
                // Validation 6: L1L3 fields - all must be present together
                Boolean hasAnyL1L3Field = (stg.Last_Sales_Date__c != null || 
                                          stg.Last_Sales_Price__c != null || 
                                          String.isNotBlank(stg.Order_Number__c) || 
                                          String.isNotBlank(stg.L1L3_CurrencyIsoCode__c));
                
                if (hasAnyL1L3Field) {
                    List<String> missingL1L3Fields = new List<String>();
                    if (stg.Last_Sales_Date__c == null) missingL1L3Fields.add('Last_Sales_Date__c');
                    if (stg.Last_Sales_Price__c == null) missingL1L3Fields.add('Last_Sales_Price__c');
                    if (String.isBlank(stg.Order_Number__c)) missingL1L3Fields.add('Order_Number__c');
                    if (String.isBlank(stg.L1L3_CurrencyIsoCode__c)) missingL1L3Fields.add('L1L3_CurrencyIsoCode__c');
                    if (!hasProd) missingL1L3Fields.add('product2Name__c');
                    if (!hasPart) missingL1L3Fields.add('partListName__c');
                    
                    if (!missingL1L3Fields.isEmpty()) {
                        errorMessages.add('Missing required fields for L1L3 Product update: ' + String.join(missingL1L3Fields, ', '));
                    }
                }

                // If validation errors exist, skip processing and mark as error
                if (!errorMessages.isEmpty()) {
                    isSuccess = false;
                    System.debug('!!! VALIDATION FAILED - Errors: ' + String.join(errorMessages, '; '));
                }

                // ─────────────────────────────────────────────────────────────
                // BLOCK 1: PART LIST SCENARIO (Updates Part_List__c)
                // ─────────────────────────────────────────────────────────────
               // ─────────────────────────────────────────────────────────────

if (isSuccess && hasPart && (stg.Direct_Quoted_Exchange_Rate__c != null || String.isNotBlank(stg.partList_CurrencyIsoCode__c))) {

    Boolean revisionMatchedForPartList = false;

  	for (Part_List__c pl : partLists) {

        Boolean matchName = (pl.Name == stg.partListName__c);

        Boolean matchRev = String.isBlank(stg.partListRevisionNo__c) || 
                           (pl.Version_Number_Component__c == stg.partListRevisionNo__c);

        if (matchName && matchRev) {

            revisionMatchedForPartList = true;

            System.debug('      [+] Part List Revision Matched: ' + stg.partListRevisionNo__c);

            String updates = '';

            if (stg.Direct_Quoted_Exchange_Rate__c != null) {

                pl.Direct_Quoted_Exchange_Rate__c = stg.Direct_Quoted_Exchange_Rate__c;

                updates += 'Direct_Quoted_Exchange_Rate__c, ';
            }

            if (String.isNotBlank(stg.partList_CurrencyIsoCode__c)) {

                pl.CurrencyIsoCode = stg.partList_CurrencyIsoCode__c;

                updates += 'CurrencyIsoCode, ';
            }

            if (updates != '') {

                partListsToUpdate.put(pl.Id, pl);

                System.debug('      [+] Queued -> Part_List__c | Name: ' + pl.Name + ' | Fields: ' + updates.removeEnd(', '));
            }
        }
    }

    if (String.isNotBlank(stg.partListRevisionNo__c) && !revisionMatchedForPartList) {

        System.debug('!!! REVISION MISMATCH ERROR: No Part_List__c record found with Revision Number: ' + stg.partListRevisionNo__c);

        errorMessages.add('Part list revision not matched');

        isSuccess = false;
    }
}

                // ─────────────────────────────────────────────────────────────
                // BLOCK 2: PRODUCT SCENARIO (Updates Item_Weight__c & Sales_Org_Product__c)
                // ─────────────────────────────────────────────────────────────
                if (isSuccess && hasProd) {
                    // Item Weight Update
                    if (stg.Net_Weight__c != null) {
                        for (Item_Weight__c iw : itemWeights) {
                            if (iw.Product_L3__r.Name == stg.product2Name__c) {
                                iw.Net_Weight__c = stg.Net_Weight__c;
                                itemWeightsToUpdate.put(iw.Id, iw);
                                System.debug('      [+] Queued -> Item_Weight__c | Name: ' + iw.Name + ' | Fields: Net_Weight__c');
                            }
                        }
                    }

                    // Sales Org Product Update (both Price__c and SOP_CurrencyIsoCode__c must be present)
                    if (stg.Price__c != null && String.isNotBlank(stg.SOP_CurrencyIsoCode__c) && String.isNotBlank(stg.salesOrgId__c)) {
                        for (Sales_Organization_Product__c sop : salesOrgProds) {
                            if (sop.Product__r.Name == stg.product2Name__c && sop.Sales_Org__c == stg.salesOrgId__c) {
                                sop.Price__c = stg.Price__c;
                                sop.CurrencyIsoCode = stg.SOP_CurrencyIsoCode__c;
                                
                                sopToUpdate.put(sop.Id, sop);
                                System.debug('      [+] Queued -> Sales_Organization_Product__c | Name: ' + sop.Name + ' | Fields: Price__c, CurrencyIsoCode');
                            }
                        }
                    }
                }

                // ─────────────────────────────────────────────────────────────
                // BLOCK 3: COMBINED SCENARIO (Updates L1_L3_Product__c Directly)
                // ─────────────────────────────────────────────────────────────
                // ─────────────────────────────────────────────────────────────

if (isSuccess && hasProd && hasPart && hasAnyL1L3Field) {

    Boolean revisionMatchedForL1L3 = false;

    for (L1_L3_Product__c l1l3 : l1l3Products) {

        Boolean matchProduct = (l1l3.Product_del__r.Name == stg.product2Name__c);

        Boolean matchPart = (l1l3.Part_List__r.Name == stg.partListName__c);

        Boolean matchRev = String.isBlank(stg.partListRevisionNo__c) || 
                           (l1l3.Part_List__r.Version_Number_Component__c == stg.partListRevisionNo__c);

        if (matchProduct && matchPart && matchRev) {

            revisionMatchedForL1L3 = true;

            System.debug('      [+] L1_L3 Revision Matched: ' + stg.partListRevisionNo__c);

            l1l3.Last_Sales_Date__c = stg.Last_Sales_Date__c;

            l1l3.Last_Sales_Price__c = stg.Last_Sales_Price__c;

            l1l3.Order_Number__c = stg.Order_Number__c;

            l1l3.CurrencyIsoCode = stg.L1L3_CurrencyIsoCode__c;

            l1l3ToUpdate.put(l1l3.Id, l1l3);

            System.debug('      [+] Queued -> L1_L3_Product__c | Name: ' + l1l3.Name + ' | Fields: Last_Sales_Date__c, Last_Sales_Price__c, Order_Number__c, CurrencyIsoCode');
        }
    }

    if (String.isNotBlank(stg.partListRevisionNo__c) && !revisionMatchedForL1L3) {

        System.debug('!!! REVISION MISMATCH ERROR: No L1_L3_Product__c record found with Revision Number: ' + stg.partListRevisionNo__c);

        errorMessages.add('Part list revision not matched');

        isSuccess = false;
    }
}

            } catch (Exception e) {
                isSuccess = false;
                System.debug('!!! ERROR processing Staging Record ' + stg.Name + ': ' + e.getMessage());
                errorMessages.add(e.getMessage());
            }

            if (isSuccess) {
                stg.Status__c = 'Completed';
                stg.Error_Log__c = null; 
            } else {
                stg.Status__c = 'Error';
                stg.Error_Log__c = String.join(errorMessages, '; ');
            }
            stagingRecordsToUpdate.add(stg);
        }

        System.debug('======================================================================');
        System.debug('>>> COMMITTING DML UPDATES FOR BATCH CHUNK');
        System.debug('Total Part_List__c records queued: ' + partListsToUpdate.size());
        System.debug('Total Item_Weight__c records queued: ' + itemWeightsToUpdate.size());
        System.debug('Total Sales_Organization_Product__c records queued: ' + sopToUpdate.size());
        System.debug('Total L1_L3_Product__c records queued: ' + l1l3ToUpdate.size());
        
        try {
            
            if (!partListsToUpdate.isEmpty()) {
                update partListsToUpdate.values();
                System.debug('>>> SUCCESS: Part_List__c records updated.');
            }
            
            if (!itemWeightsToUpdate.isEmpty()) {
                update itemWeightsToUpdate.values();
                System.debug('>>> SUCCESS: Item_Weight__c records updated.');
            }
            
            if (!sopToUpdate.isEmpty()) {
                update sopToUpdate.values();
                System.debug('>>> SUCCESS: Sales_Organization_Product__c records updated.');
            }
            
            if (!l1l3ToUpdate.isEmpty()) {
                update l1l3ToUpdate.values();
                System.debug('>>> SUCCESS: L1_L3_Product__c records updated.');
            }
            
        } catch (Exception dmlEx) {
            System.debug('!!! CRITICAL DML ERROR updating target records: ' + dmlEx.getMessage());
            for (TOP_Field_Staging__c stg : stagingRecordsToUpdate) {
                if (stg.Status__c == 'Completed') {
                    stg.Status__c = 'Error';
                    stg.Error_Log__c = 'Target Record DML Error: ' + dmlEx.getMessage();
                }
            }
        }

        update stagingRecordsToUpdate;
        System.debug('======================================================================');
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('>>> BATCH PROCESSING COMPLETE.');
    }

    public class CustomException extends Exception {}
}