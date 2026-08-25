/////////////////////////////////////////////
//      Dev Name - Ranjeet Kumar          ///
/////////////////////////////////////////////

/**
 * Processes TOP_Field_Staging__c records that are "In Progress".
 * Replicates the exact logic of ProductDataRetrieverAPI2 but reads
 * input from the staging object instead of a REST request body.
 *
 * Schedule (every hour) by running once in Developer Console:
 *   System.schedule('ProductDataStagingProcessor - Hourly',
 *                   '0 0 * * * ?',
 *                   new ProductDataStagingProcessor());
 */

global class ProductDataStagingProcessor implements Schedulable {

    // ── Schedulable entry point ───────────────────────────────────────────────
    global void execute(SchedulableContext sc) {
        processInProgressRecords();
    }

    // ── Can also be called manually / from a trigger if needed ────────────────
    public static void processInProgressRecords() {

        List<TOP_Field_Staging__c> stagingRecords = [
            SELECT Id,
                   product2Name__c,
                   partListName__c,
                   salesOrgId__c,
                   partListRevisionNo__c,
                   Status__c
            FROM   TOP_Field_Staging__c
            WHERE  Status__c = 'In Progress'
        ];

        if (stagingRecords.isEmpty()) {
            return;
        }

        List<TOP_Field_Staging__c> toUpdate = new List<TOP_Field_Staging__c>();

        for (TOP_Field_Staging__c staging : stagingRecords) {
            try {
                processSingleRecord(staging);
                staging.Status__c = 'Completed';
            } catch (Exception e) {
                staging.Status__c     = 'Error';
                staging.Error_Log__c  = 'Message: ' + e.getMessage()
                                      + '\nType: '    + e.getTypeName()
                                      + '\nLine: '    + e.getLineNumber()
                                      + '\nStack: '   + e.getStackTraceString();
            }
            toUpdate.add(staging);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    // ── Core logic (mirrors ProductDataRetrieverAPI2.getProductRelatedData) ───
    private static void processSingleRecord(TOP_Field_Staging__c staging) {

        // ----- Read inputs from the staging record -----
        String product2Name       = staging.product2Name__c;
        String partListName       = staging.partListName__c;
        String salesOrgId         = staging.salesOrgId__c;
        String partListRevisionNo = staging.partListRevisionNo__c;

        // Validate – mirrors the API validation rules
        if (String.isBlank(product2Name) && String.isBlank(partListName)) {
            throw new ProductDataException(
                'At least one of Product Name or Part List Name is required');
        }
        if (String.isBlank(salesOrgId)) {
            throw new ProductDataException('Sales Org ID is required');
        }

        Boolean hasProduct2Name = String.isNotBlank(product2Name);
        Boolean hasPartListName = String.isNotBlank(partListName);

        Set<Id> productIds  = new Set<Id>();
        Set<Id> partListIds = new Set<Id>();

        // ─────────────────────────────────────────────────────────────────────
        // SCENARIO A : Both product2Name AND partListName are provided
        // ─────────────────────────────────────────────────────────────────────
        if (hasProduct2Name && hasPartListName) {

            List<L2_L3_Product__c> l2l3Products = [
                SELECT Id, Name, Product_L3__c, Part_List__c,
                       Product_L3__r.Id, Product_L3__r.Name,
                       Part_List__r.Id,  Part_List__r.Name
                FROM   L2_L3_Product__c
                WHERE  Product_L3__r.Name = :product2Name
                AND    Part_List__r.Name  = :partListName
            ];

            if (!l2l3Products.isEmpty()) {

                for (L2_L3_Product__c l2l3 : l2l3Products) {
                    if (l2l3.Product_L3__c != null) productIds.add(l2l3.Product_L3__c);
                    if (l2l3.Part_List__c  != null) partListIds.add(l2l3.Part_List__c);
                }

                // Step 2 – Part_List__c (only when revision no. is present)
                if (!partListIds.isEmpty() && String.isNotBlank(partListRevisionNo)) {
                    List<Part_List__c> partLists = [
                        SELECT Id, Name, Alternative_BOM__c, BOM__c, CreatedById,
                               CurrencyIsoCode, Customer__c, Customer_Equipment__c,
                               Customer_ID__c, Customer_Name__c, DCR_Blocked__c,
                               Delivery_Req__c, Description__c,
                               Direct_Quoted_Exchange_Rate__c, Equipment_Record_Type__c,
                               HSN_Code__c, LastModifiedById, Last_Offer_Number__c,
                               Last_Offer_Value_Foreign_Currency__c,
                               Version_Number_Component__c, Part_List_Type__c,
                               Reference_score_DEH__c, Reference_score_FEH__c,
                               Reference_score_Shel__c, Revision__c, Zone_Priority__c
                        FROM   Part_List__c
                        WHERE  Id IN :partListIds
                        AND    Version_Number_Component__c = :partListRevisionNo
                    ];
                    // Results available in partLists – add downstream logic here
                    // e.g. store them, call another service, write to child records, etc.
                }

                // Step 3 – Item_Weight__c
                if (!productIds.isEmpty()) {
                    List<Item_Weight__c> itemWeights = [
                        SELECT Id, Name, Product_L3__c, Net_Weight__c, Plant__c,
                               Description__c, CreatedById, CurrencyIsoCode,
                               LastModifiedById, OwnerId
                        FROM   Item_Weight__c
                        WHERE  Product_L3__c IN :productIds
                    ];
                    // Results available in itemWeights
                }

                // Step 4 – Sales_Organization_Product__c
                if (!productIds.isEmpty()) {
                    List<Sales_Organization_Product__c> salesOrgProducts = [
                        SELECT Id, Name, Product__c, Price__c, Sales_Org__c
                        FROM   Sales_Organization_Product__c
                        WHERE  Product__c IN :productIds
                        AND    Sales_Org__c = :salesOrgId
                    ];
                    // Results available in salesOrgProducts
                }

                // Step 5 – L1_L3_Product__c (only when revision no. is present)
                if (String.isNotBlank(partListRevisionNo)) {
                    List<L1_L3_Product__c> l1l3Records = [
                        SELECT Id, Name, CurrencyIsoCode, L1L3_Code__c, LastModifiedById,
                               Last_Sales_Date__c, Last_Sales_Price__c, Offer_Number__c,
                               OfferDate__c, Order_Number__c, OrderDate__c, Part_List__c,
                               Product_del__c, Sales_Order__c, Sales_Organization__c,
                               SAP_Last_Sale_Price__c, CreatedById
                        FROM   L1_L3_Product__c
                        WHERE  Product_del__r.Name                      = :product2Name
                        AND    Part_List__r.Name                        = :partListName
                        AND    Part_List__r.Version_Number_Component__c = :partListRevisionNo
                    ];
                    // Results available in l1l3Records

                    // ── Populate staging fields from queried data ──────────────
                    if (!l1l3Records.isEmpty()) {
                        L1_L3_Product__c first = l1l3Records[0];
                        staging.Last_Sales_Date__c  = first.Last_Sales_Date__c;
                        staging.Last_Sales_Price__c = first.Last_Sales_Price__c;
                        staging.Order_Number__c     = first.Order_Number__c;
                        staging.L1L3_CurrencyIsoCode__c = first.CurrencyIsoCode;
                    }
                }

                // ── Populate staging fields from Part_List__c data ─────────────
                if (!partListIds.isEmpty() && String.isNotBlank(partListRevisionNo)) {
                    List<Part_List__c> matchedPL = [
                        SELECT Id, CurrencyIsoCode, Direct_Quoted_Exchange_Rate__c,
                               Version_Number_Component__c
                        FROM   Part_List__c
                        WHERE  Id IN :partListIds
                        AND    Version_Number_Component__c = :partListRevisionNo
                        LIMIT  1
                    ];
                    if (!matchedPL.isEmpty()) {
                        staging.partList_CurrencyIsoCode__c     = matchedPL[0].CurrencyIsoCode;
                        staging.Direct_Quoted_Exchange_Rate__c  = matchedPL[0].Direct_Quoted_Exchange_Rate__c;
                        staging.partListRevisionNo__c           = matchedPL[0].Version_Number_Component__c;
                    }
                }

                // ── Populate staging fields from Sales_Organization_Product__c ─
                if (!productIds.isEmpty()) {
                    List<Sales_Organization_Product__c> matchedSOP = [
                        SELECT Id, Price__c, Sales_Org__c
                        FROM   Sales_Organization_Product__c
                        WHERE  Product__c IN :productIds
                        AND    Sales_Org__c = :salesOrgId
                        LIMIT  1
                    ];
                    if (!matchedSOP.isEmpty()) {
                        staging.Price__c      = matchedSOP[0].Price__c;
                        staging.salesOrgId__c = matchedSOP[0].Sales_Org__c;
                    }
                }

                // ── Populate staging fields from Item_Weight__c ────────────────
                if (!productIds.isEmpty()) {
                    List<Item_Weight__c> matchedIW = [
                        SELECT Id, Net_Weight__c
                        FROM   Item_Weight__c
                        WHERE  Product_L3__c IN :productIds
                        LIMIT  1
                    ];
                    if (!matchedIW.isEmpty()) {
                        staging.Net_Weight__c = matchedIW[0].Net_Weight__c;
                    }
                }
            }

        // ─────────────────────────────────────────────────────────────────────
        // SCENARIO B : Only partListName is provided
        // ─────────────────────────────────────────────────────────────────────
        } else if (hasPartListName && !hasProduct2Name) {

            List<Part_List__c> directPartLists = [
                SELECT Id, Name, CurrencyIsoCode, Direct_Quoted_Exchange_Rate__c,
                       Version_Number_Component__c
                FROM   Part_List__c
                WHERE  Name = :partListName
            ];

            if (!directPartLists.isEmpty()) {
                staging.partListName__c                 = directPartLists[0].Name;
                staging.partList_CurrencyIsoCode__c     = directPartLists[0].CurrencyIsoCode;
                staging.Direct_Quoted_Exchange_Rate__c  = directPartLists[0].Direct_Quoted_Exchange_Rate__c;
                staging.partListRevisionNo__c           = directPartLists[0].Version_Number_Component__c;
            }

        // ─────────────────────────────────────────────────────────────────────
        // SCENARIO C : Only product2Name is provided
        // ─────────────────────────────────────────────────────────────────────
        } else if (hasProduct2Name && !hasPartListName) {

            List<Product2> products = [
                SELECT Id, Name, ProductCode, Description, IsActive,
                       Family, CreatedById, LastModifiedById
                FROM   Product2
                WHERE  Name = :product2Name
            ];

            if (!products.isEmpty()) {
                for (Product2 p : products) {
                    productIds.add(p.Id);
                }

                // Item_Weight__c
                if (!productIds.isEmpty()) {
                    List<Item_Weight__c> matchedIW = [
                        SELECT Id, Net_Weight__c
                        FROM   Item_Weight__c
                        WHERE  Product_L3__c IN :productIds
                        LIMIT  1
                    ];
                    if (!matchedIW.isEmpty()) {
                        staging.Net_Weight__c = matchedIW[0].Net_Weight__c;
                    }
                }

                // Sales_Organization_Product__c
                if (!productIds.isEmpty()) {
                    List<Sales_Organization_Product__c> matchedSOP = [
                        SELECT Id, Price__c, Sales_Org__c
                        FROM   Sales_Organization_Product__c
                        WHERE  Product__c IN :productIds
                        AND    Sales_Org__c = :salesOrgId
                        LIMIT  1
                    ];
                    if (!matchedSOP.isEmpty()) {
                        staging.Price__c      = matchedSOP[0].Price__c;
                        staging.salesOrgId__c = matchedSOP[0].Sales_Org__c;
                    }
                }
            }
        }
    }

    // ── Custom exception ──────────────────────────────────────────────────────
    public class ProductDataException extends Exception {}
}