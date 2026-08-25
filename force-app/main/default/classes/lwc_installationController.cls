public with sharing class lwc_installationController {

        @AuraEnabled(cacheable=true)
        public static Installation__c getInstallationData(Id installationId) {
            System.debug('Inside class:');
            Installation__c installation = [
                SELECT Id, Customer__c, Customer__r.Name, Part_List__c, Part_List__r.Name, SO_Number__c, SO_Number__r.Name, SO_Number__r.OrderNumber,Salesorder_No__c
                FROM Installation__c
                WHERE Id = :installationId limit 1
            ];
            System.debug('Data is '+installation);  
            return installation;
        }

        @AuraEnabled
    public static String getSoNumber(Id installationId) {
        System.debug('InstallationId'+ installationId);
    // Query the SO number based on the recordId
    return [SELECT SO_Number__c FROM Installation__c WHERE Id = :installationId LIMIT 1].SO_Number__c;
}

        @AuraEnabled(cacheable=true)
        public static List<Map<String, String>> getSoDescriptions(Id solistId) {
            List<Map<String, String>> soDescriptions = new List<Map<String, String>>();

            try {
                // Query to fetch OrderItems related to the Sales Order
                List<OrderItem> orderItems = [
                    SELECT Id, Short_Description__c, Product2.Name, Quantity, Product2Id
                    FROM OrderItem
                    WHERE OrderId = :solistId
                ];
            // Loop through the OrderItems and map the required fields
            for (OrderItem orderItem : orderItems) {
                Map<String, String> soEntry = new Map<String, String>();
                soEntry.put('Id', orderItem.Id);
                soEntry.put('Name', orderItem.Short_Description__c);
                soEntry.put('ItemCode', orderItem.Product2.name);
                soEntry.put('Quantity', String.valueOf(orderItem.Quantity));
                soEntry.put('ProductId', orderItem.Product2Id);
                soDescriptions.add(soEntry);
            }
            System.debug('soDescriptions: ' + soDescriptions);
        }
        catch (Exception e) {
            System.debug('Error fetching SO Descriptions: ' + e.getMessage());
            throw new AuraHandledException('Error fetching SO Descriptions: ' + e.getMessage());
        }
        return soDescriptions;
        }


        @AuraEnabled(cacheable=true)
        public static List<Map<String, String>> getPartDescriptions(Id partlistId) {
            List<Map<String, String>> partDescriptions = new List<Map<String, String>>();

            try {
                // Query 1: Fetch Part List details
                List<Part_List__c> partlist = [
                    SELECT Id, Name, Description__c
                    FROM Part_List__c
                    WHERE Id = :partlistId
                ];

                // Add Part List details to the result
                for (Part_List__c pl : partlist) {
                    Map<String, String> partlistEntry = new Map<String, String>();
                    partlistEntry.put('Id', pl.Id);
                    partlistEntry.put('Name', pl.Name);
                    partlistEntry.put('ItemCode', pl.Name);
                    partDescriptions.add(partlistEntry);
                }

                // Query 2: Fetch L2 Products associated with the Part List
                List<Product2> l2Products = [
                    SELECT Id, Name, Part_List__c, Description
                    FROM Product2
                    WHERE Part_List__c = :partlistId
                ];

                // Add L2 Products to the result
                for (Product2 l2 : l2Products) {
                    Map<String, String> l2Entry = new Map<String, String>();
                    l2Entry.put('Id', l2.Id);
                    l2Entry.put('Name', l2.Name);
                    l2Entry.put('ItemCode', l2.Name);
                    partDescriptions.add(l2Entry);
                }

                // Query 3: Fetch L3 Products associated with the L2 Products
                List<L2_L3_Product__c> l3Products = [
                    SELECT Id, Name, Product_L2__c, Product_L3__c,Product_L3__r.name, Quantity__c, Part_List__c, L3_Product_Description__c
                    FROM L2_L3_Product__c
                    WHERE Product_L2__c IN :l2Products
                ];

                // Add L3 Products to the result
                for (L2_L3_Product__c l3 : l3Products) {
                    Map<String, String> l3Entry = new Map<String, String>();
                    l3Entry.put('Id', l3.Id);
                    l3Entry.put('Name', l3.L3_Product_Description__c);
                    l3Entry.put('ItemCode', l3.Product_L3__r.name);
                    l3Entry.put('L3id', l3.Product_L3__c);
                    partDescriptions.add(l3Entry);
                }
                system.debug('partDescriptions: ' + partDescriptions);
                // Filter out products whose names contain 'SPARE'
        List<Map<String, String>> filteredPartDescriptions = new List<Map<String, String>>();
        for (Map<String, String> part : partDescriptions) {
            String name = part.get('Name');
            if (name == null || !name.toUpperCase().contains('SPARE')) {
                filteredPartDescriptions.add(part);
            }
        }

        partDescriptions = filteredPartDescriptions;

        System.debug('Filtered partDescriptions: ' + partDescriptions);

            } catch (Exception e) {
                System.debug('Error fetching Part Descriptions: ' + e.getMessage());
                throw new AuraHandledException('Error fetching Part Descriptions: ' + e.getMessage());
            }

            return partDescriptions;
        }
        // Fetch Quantity__c from L2_L3_product__c
    @AuraEnabled(cacheable=true)
    public static Decimal getL2L3ProductQuantity(String plmId, String productL3, String compName) {
        System.debug('plmId: ' + plmId + ' ProductL3: ' + productL3 + ' Component: ' + compName);
        try {
            L2_L3_product__c l2l3Record = [
                SELECT Quantity__c
                FROM L2_L3_product__c
                WHERE Part_List__c = :plmId
                AND Product_L3__c = :productL3
                AND Product_L2__r.Name LIKE :('%' + compName)
                LIMIT 1
        ];
            system.debug('l2l3Record'+l2l3Record);
            return l2l3Record.Quantity__c;
        } catch (Exception e) {
            System.debug('Error fetching Quantity__c: ' + e.getMessage());
            return 0; // Return default value
        }
    }



    @AuraEnabled(cacheable=true)
    public static Integer checkFilledData(Id installationId) {

        Installation__c installationObj = new Installation__c();
        installationObj = [SELECT Id, Part_List__c, SO_Number__c FROM Installation__c WHERE id = :installationId];
        if(installationObj.Part_List__c != null && installationObj.SO_Number__c != null){
            //product will be fetched from plm
            return 1;
        }
        else if(installationObj.Part_List__c != null){
            //product will be fetched from plm
            return 2;
        }
        else if(installationObj.Part_List__c == null && installationObj.SO_Number__c != null){
            //product will be fetched from SO
            return 3;
        }
        else if(installationObj.Part_List__c == null && installationObj.SO_Number__c == null){
            //Manual Entry
            return 4;
        }
        return 0;
    }

    @AuraEnabled
    public static void saveInstallationLineItems(List<Map<String, Object>> lineItems) {
        system.debug('lineItems'+lineItems);
        try {
            List<Installation_Line_Items__c> recordsToInsert = new List<Installation_Line_Items__c>();
            for (Map<String, Object> lineItem : lineItems) {
                
                Installation_Line_Items__c record = new Installation_Line_Items__c();
                record.Installation__c = (Id) lineItem.get('Installation__c');
                record.Item_Description__c = (String) lineItem.get('Item_Description__c');
                record.Item__c = (Id) lineItem.get('Item__c');
                record.Component__c=(String) lineItem.get('Component__c');
                //record.Total_Quantity__c = (Decimal) lineItem.get('Total_Quantity__c');
                record.Installed_Quantity__c = Decimal.valueOf((String) lineItem.get('Installed_Quantity__c'));
                record.Problem__c = (Boolean) lineItem.get('Problem__c');
                record.Dimension_Received_at_Site_if_any__c = (String) lineItem.get('Dimension_Received__c');
                record.Remarks__c = (String) lineItem.get('Remarks__c');
                recordsToInsert.add(record);
                system.debug('recordsToInsert'+recordsToInsert);
                system.debug('recordsToInsert'+recordsToInsert.size());
            }

            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }
        } catch (Exception e) {
            System.debug('Error saving Installation Line Items: ' + e.getMessage());
            throw new AuraHandledException('Error saving Installation Line Items: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveInstallationLineItemsSo(List<Map<String, Object>> lineItems) {
        system.debug('lineItems'+lineItems);
        try {
            List<Installation_Line_Items__c> recordsToInsert = new List<Installation_Line_Items__c>();
            for (Map<String, Object> lineItem : lineItems) {
                
                Installation_Line_Items__c record = new Installation_Line_Items__c();
                record.Installation__c = (Id) lineItem.get('Installation__c');
                record.Item_Description__c = (String) lineItem.get('Item_Description__c');
                record.Item__c = (Id) lineItem.get('Item__c');
                record.Component__c=(String) lineItem.get('Component__c');
                record.Installed_Quantity__c = Decimal.valueOf((String) lineItem.get('Installed_Quantity__c'));
                record.Problem__c = (Boolean) lineItem.get('Problem__c');
                record.Dimension_Received_at_Site_if_any__c = (String) lineItem.get('Dimension_Received__c');
                record.Remarks__c = (String) lineItem.get('Remarks__c');
                recordsToInsert.add(record);
                system.debug('recordsToInsert'+recordsToInsert);
                system.debug('recordsToInsert'+recordsToInsert.size());
            }

            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }
        } catch (Exception e) {
            System.debug('Error saving Installation Line Items: ' + e.getMessage());
            throw new AuraHandledException('Error saving Installation Line Items: ' + e.getMessage());
        }
    }
    }