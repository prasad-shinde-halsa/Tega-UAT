global class TopFieldStagingProcessor2 implements Database.Batchable<sObject>, Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new TopFieldStagingProcessor(), 50);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, product2Name__c, partListName__c, salesOrgId__c, partListRevisionNo__c,
                   Direct_Quoted_Exchange_Rate__c, L1L3_CurrencyIsoCode__c, Last_Sales_Date__c,
                   Last_Sales_Price__c, Net_Weight__c, Order_Number__c, partList_CurrencyIsoCode__c,
                   Price__c, Status__c, Error_Log__c
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
        List<Part_List__c> partLists = new List<Part_List__c>();
        if (!partListNames.isEmpty()) {
            partLists = [SELECT Id, Name, Version_Number_Component__c, CurrencyIsoCode, Direct_Quoted_Exchange_Rate__c 
                         FROM Part_List__c 
                         WHERE Name IN :partListNames OR Version_Number_Component__c IN :revNos];
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>();
        if (!productNames.isEmpty()) {
            productMap = new Map<Id, Product2>([SELECT Id, Name FROM Product2 WHERE Name IN :productNames]);
        }

        List<L2_L3_Product__c> l2l3Products = new List<L2_L3_Product__c>();
        if (!productNames.isEmpty() && !partListNames.isEmpty()) {
            l2l3Products = [SELECT Id, Name, Product_L3__c, Product_L3__r.Name, Part_List__c, Part_List__r.Name 
                            FROM L2_L3_Product__c 
                            WHERE Product_L3__r.Name IN :productNames AND Part_List__r.Name IN :partListNames];
        }

        List<Item_Weight__c> itemWeights = new List<Item_Weight__c>();
        List<Sales_Organization_Product__c> salesOrgProds = new List<Sales_Organization_Product__c>();
        List<Sales_Org_Last_SAP_SO__c> salesOrgSapSOs = new List<Sales_Org_Last_SAP_SO__c>(); 

        if (!productMap.isEmpty()) {
            itemWeights = [SELECT Id, Name, Product_L3__c, Product_L3__r.Name, Net_Weight__c 
                           FROM Item_Weight__c WHERE Product_L3__c IN :productMap.keySet()];
                           
            if (!salesOrgIds.isEmpty()) {
                salesOrgProds = [SELECT Id, Name, Product__c, Product__r.Name, Sales_Org__c, Price__c 
                                 FROM Sales_Organization_Product__c 
                                 WHERE Product__c IN :productMap.keySet() AND Sales_Org__c IN :salesOrgIds];
            }

            salesOrgSapSOs = [SELECT Id, Name, SAP_Last_Sale__c, SAP_Last_Sale__r.Product_L3__c, 
                                     Order_Number__c, Last_Sales_Price__c, Last_Sales_Date__c, CurrencyIsoCode
                              FROM Sales_Org_Last_SAP_SO__c 
                              WHERE SAP_Last_Sale__r.Product_L3__c IN :productMap.keySet()];
        }

        List<L1_L3_Product__c> l1l3Products = new List<L1_L3_Product__c>();
        if (!productNames.isEmpty() && !partListNames.isEmpty()) {
            l1l3Products = [SELECT Id, Name, Product_del__c, Product_del__r.Name, Part_List__c, Part_List__r.Name, Part_List__r.Version_Number_Component__c,
                                   CurrencyIsoCode, Last_Sales_Date__c, Last_Sales_Price__c, Order_Number__c
                            FROM L1_L3_Product__c 
                            WHERE Product_del__r.Name IN :productNames 
                            AND Part_List__r.Name IN :partListNames];
        }

        Map<Id, sObject> targetRecordsToUpdate = new Map<Id, sObject>();
        List<TOP_Field_Staging__c> stagingRecordsToUpdate = new List<TOP_Field_Staging__c>();

        System.debug('======================================================================');
        System.debug('>>> STARTING BATCH CHUNK PROCESSING - SCOPE SIZE: ' + scope.size());
        System.debug('======================================================================');

        // ==========================================================
        // PROCESS STAGING RECORDS
        // ==========================================================
        for (TOP_Field_Staging__c stg : scope) {
            Boolean isSuccess = true;
            String errorMsg = '';
            
            System.debug('----------------------------------------------------------------------');
            System.debug('>>> PROCESSING STAGING RECORD: ' + stg.Name + ' (Id: ' + stg.Id + ')');

            try {
                Boolean hasProd = String.isNotBlank(stg.product2Name__c);
                Boolean hasPart = String.isNotBlank(stg.partListName__c);

                if (!hasProd && !hasPart) {
                    throw new CustomException('Missing required fields: At least one of Product Name or Part List Name is required.');
                }

                // ─────────────────────────────────────────────────────────────
                // SCENARIO A : Both product2Name AND partListName
                // ─────────────────────────────────────────────────────────────
                if (hasProd && hasPart) {
                    System.debug('   [ENTERED] SCENARIO A: Both Product (' + stg.product2Name__c + ') and Part List (' + stg.partListName__c + ') provided.');
                    
                    Set<Id> validProdIds = new Set<Id>();
                    Set<Id> validPartIds = new Set<Id>();
                    
                    for (L2_L3_Product__c l2l3 : l2l3Products) {
                        if (l2l3.Product_L3__r.Name == stg.product2Name__c && l2l3.Part_List__r.Name == stg.partListName__c) {
                            if (l2l3.Product_L3__c != null) validProdIds.add(l2l3.Product_L3__c);
                            if (l2l3.Part_List__c != null) validPartIds.add(l2l3.Part_List__c);
                        }
                    }

                    // 1. Update Part_List__c
                    if (!validPartIds.isEmpty() && String.isNotBlank(stg.partListRevisionNo__c)) {
                        for (Part_List__c pl : partLists) {
                            if (validPartIds.contains(pl.Id) && pl.Version_Number_Component__c == stg.partListRevisionNo__c) {
                                String updates = '';
                                if (stg.Direct_Quoted_Exchange_Rate__c != null) { pl.Direct_Quoted_Exchange_Rate__c = stg.Direct_Quoted_Exchange_Rate__c; updates += 'ExchangeRate, '; }
                                if (String.isNotBlank(stg.partList_CurrencyIsoCode__c)) { pl.CurrencyIsoCode = stg.partList_CurrencyIsoCode__c; updates += 'Currency, '; }
                                
                                if (updates != '') {
                                    targetRecordsToUpdate.put(pl.Id, pl);
                                    System.debug('      [+] SCENARIO A Update Queue -> Part_List__c | Name: ' + pl.Name + ' | ID: ' + pl.Id + ' | Fields updated: ' + updates.removeEnd(', '));
                                }
                            }
                        }
                    }

                    // 2. Update Item_Weight__c
                    if (!validProdIds.isEmpty()) {
                        for (Item_Weight__c iw : itemWeights) {
                            if (validProdIds.contains(iw.Product_L3__c)) {
                                if (stg.Net_Weight__c != null) {
                                    iw.Net_Weight__c = stg.Net_Weight__c;
                                    targetRecordsToUpdate.put(iw.Id, iw);
                                    System.debug('      [+] SCENARIO A Update Queue -> Item_Weight__c | Name: ' + iw.Name + ' | ID: ' + iw.Id + ' | Fields updated: Net_Weight__c');
                                }
                            }
                        }
                    }

                    // 3. Update Sales_Organization_Product__c
                    if (!validProdIds.isEmpty() && String.isNotBlank(stg.salesOrgId__c)) {
                        for (Sales_Organization_Product__c sop : salesOrgProds) {
                            if (validProdIds.contains(sop.Product__c) && sop.Sales_Org__c == stg.salesOrgId__c) {
                                if (stg.Price__c != null) {
                                    sop.Price__c = stg.Price__c;
                                    targetRecordsToUpdate.put(sop.Id, sop);
                                    System.debug('      [+] SCENARIO A Update Queue -> Sales_Org_Product__c | Name: ' + sop.Name + ' | ID: ' + sop.Id + ' | Fields updated: Price__c');
                                }
                            }
                        }
                    }

                    // 4. Update L1_L3_Product__c (Both match)
                    for (L1_L3_Product__c l1l3 : l1l3Products) {
                        Boolean matchProduct = (l1l3.Product_del__r.Name == stg.product2Name__c);
                        Boolean matchPart = (l1l3.Part_List__r.Name == stg.partListName__c);
                        Boolean matchRev = String.isNotBlank(stg.partListRevisionNo__c) ? (l1l3.Part_List__r.Version_Number_Component__c == stg.partListRevisionNo__c) : true;

                        if (matchProduct && matchPart && matchRev) {
                            String updates = '';
                            if (stg.Last_Sales_Date__c != null) { l1l3.Last_Sales_Date__c = stg.Last_Sales_Date__c; updates += 'Last_Sales_Date__c, '; }
                            if (stg.Last_Sales_Price__c != null) { l1l3.Last_Sales_Price__c = stg.Last_Sales_Price__c; updates += 'Last_Sales_Price__c, '; }
                            if (String.isNotBlank(stg.Order_Number__c)) { l1l3.Order_Number__c = stg.Order_Number__c; updates += 'Order_Number__c, '; }
                            if (String.isNotBlank(stg.L1L3_CurrencyIsoCode__c)) { l1l3.CurrencyIsoCode = stg.L1L3_CurrencyIsoCode__c; updates += 'CurrencyIsoCode, '; }
                            
                            if (updates != '') {
                                targetRecordsToUpdate.put(l1l3.Id, l1l3);
                                System.debug('      [+] SCENARIO A Update Queue -> L1_L3_Product__c | Name: ' + l1l3.Name + ' | ID: ' + l1l3.Id + ' | Fields updated: ' + updates.removeEnd(', '));
                            }
                        }
                    }

                    // 5. Update Sales_Org_Last_SAP_SO__c
                    if (!validProdIds.isEmpty()) {
                        for (Sales_Org_Last_SAP_SO__c sapSO : salesOrgSapSOs) {
                            if (sapSO.SAP_Last_Sale__c != null && validProdIds.contains(sapSO.SAP_Last_Sale__r.Product_L3__c)) {
                                String updates = '';
                                if (String.isNotBlank(stg.Order_Number__c)) { sapSO.Order_Number__c = stg.Order_Number__c; updates += 'Order_Number__c, '; }
                                if (stg.Last_Sales_Price__c != null) { sapSO.Last_Sales_Price__c = stg.Last_Sales_Price__c; updates += 'Last_Sales_Price__c, '; }
                                if (stg.Last_Sales_Date__c != null) { sapSO.Last_Sales_Date__c = stg.Last_Sales_Date__c; updates += 'Last_Sales_Date__c, '; }
                                if (String.isNotBlank(stg.L1L3_CurrencyIsoCode__c)) { sapSO.CurrencyIsoCode = stg.L1L3_CurrencyIsoCode__c; updates += 'CurrencyIsoCode, '; }
                                
                                if (updates != '') {
                                    targetRecordsToUpdate.put(sapSO.Id, sapSO);
                                    System.debug('      [+] SCENARIO A Update Queue -> Sales_Org_Last_SAP_SO__c | Name: ' + sapSO.Name + ' | ID: ' + sapSO.Id + ' | Fields updated: ' + updates.removeEnd(', '));
                                }
                            }
                        }
                    }
                }
                // ─────────────────────────────────────────────────────────────
                // SCENARIO B : Only partListName
                // ─────────────────────────────────────────────────────────────
                else if (hasPart && !hasProd) {
                    System.debug('   [ENTERED] SCENARIO B: ONLY Part List (' + stg.partListName__c + ') provided.');
                    
                    // ONLY Update Part_List__c
                    for (Part_List__c pl : partLists) {
                        if (pl.Name == stg.partListName__c) {
                            String updates = '';
                            if (stg.Direct_Quoted_Exchange_Rate__c != null) { pl.Direct_Quoted_Exchange_Rate__c = stg.Direct_Quoted_Exchange_Rate__c; updates += 'ExchangeRate, '; }
                            if (String.isNotBlank(stg.partList_CurrencyIsoCode__c)) { pl.CurrencyIsoCode = stg.partList_CurrencyIsoCode__c; updates += 'Currency, '; }
                            
                            if (updates != '') {
                                targetRecordsToUpdate.put(pl.Id, pl);
                                System.debug('      [+] SCENARIO B Update Queue -> Part_List__c | Name: ' + pl.Name + ' | ID: ' + pl.Id + ' | Fields updated: ' + updates.removeEnd(', '));
                            }
                        }
                    }
                }
                // ─────────────────────────────────────────────────────────────
                // SCENARIO C : Only product2Name
                // ─────────────────────────────────────────────────────────────
                else if (hasProd && !hasPart) {
                    System.debug('   [ENTERED] SCENARIO C: ONLY Product Name (' + stg.product2Name__c + ') provided.');
                    
                    // ONLY Update Item_Weight__c
                    for (Item_Weight__c iw : itemWeights) {
                        if (iw.Product_L3__r.Name == stg.product2Name__c) {
                            if (stg.Net_Weight__c != null) {
                                iw.Net_Weight__c = stg.Net_Weight__c;
                                targetRecordsToUpdate.put(iw.Id, iw);
                                System.debug('      [+] SCENARIO C Update Queue -> Item_Weight__c | Name: ' + iw.Name + ' | ID: ' + iw.Id + ' | Fields updated: Net_Weight__c');
                            }
                        }
                    }

                    // ONLY Update Sales_Organization_Product__c (Requires Sales Org)
                    if (String.isNotBlank(stg.salesOrgId__c)) {
                        for (Sales_Organization_Product__c sop : salesOrgProds) {
                            if (sop.Product__r.Name == stg.product2Name__c && sop.Sales_Org__c == stg.salesOrgId__c) {
                                if (stg.Price__c != null) {
                                    sop.Price__c = stg.Price__c;
                                    targetRecordsToUpdate.put(sop.Id, sop);
                                    System.debug('      [+] SCENARIO C Update Queue -> Sales_Org_Product__c | Name: ' + sop.Name + ' | ID: ' + sop.Id + ' | Fields updated: Price__c');
                                }
                            }
                        }
                    }
                }

            } catch (Exception e) {
                isSuccess = false;
                errorMsg = 'Processing Error: ' + e.getMessage();
                System.debug('!!! ERROR processing Staging Record ' + stg.Name + ': ' + errorMsg);
            }

            if (isSuccess) {
                stg.Status__c = 'Completed';
                stg.Error_Log__c = null; 
            } else {
                stg.Status__c = 'Error';
                stg.Error_Log__c = errorMsg;
            }
            stagingRecordsToUpdate.add(stg);
        }

        System.debug('======================================================================');
        System.debug('>>> COMMITTING DML UPDATES FOR BATCH CHUNK');
        System.debug('Total records queued for DML Update: ' + targetRecordsToUpdate.size());
        
        try {
            if (!targetRecordsToUpdate.isEmpty()) {
                update targetRecordsToUpdate.values();
                System.debug('>>> SUCCESS: Target records updated successfully.');
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