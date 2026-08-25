public with sharing class OfferLinePrintController {

    @AuraEnabled
    public static Map<String, Object> getOfferPrintData(String offerId) {

        Map<String, Object> result = new Map<String, Object>();

        // ── 1. Quote header ──────────────────────────────────────────
        List<Quote> quoteList = [
            SELECT Id, Name, CurrencyIsoCode, BTP_Type__c, Status,
                   Account.Name,
                   Sales_Org__r.Name,
                   Branch__r.Name,
                   Part_List__r.Name,
                   Part_List__c,
                   Sales_Org__c
            FROM   Quote
            WHERE  Id = :offerId
            LIMIT  1
        ];

        if (quoteList.isEmpty()) {
            result.put('quoteData',  null);
            result.put('lineItems',  new List<Object>());
            result.put('headers',    new List<String>());
            return result;
        }

        Quote q = quoteList[0];

        Map<String, Object> quoteData = new Map<String, Object>();
        quoteData.put('Name',           q.Name);
        quoteData.put('CurrencyIsoCode', q.CurrencyIsoCode);
        quoteData.put('AccountName',    q.Account  != null ? q.Account.Name          : '—');
        quoteData.put('SalesOrg',       q.Sales_Org__r != null ? q.Sales_Org__r.Name : '—');
        quoteData.put('Branch',         q.Branch__r    != null ? q.Branch__r.Name    : '—');
        quoteData.put('PartList',       q.Part_List__r != null ? q.Part_List__r.Name : '—');
        quoteData.put('BTPType',        q.BTP_Type__c  != null ? q.BTP_Type__c       : '—');
        quoteData.put('Status',         q.Status       != null ? q.Status            : '—');
        quoteData.put('PrintDate',      DateTime.now().format('dd MMM yyyy, HH:mm'));
        result.put('quoteData', quoteData);

        // ── 2. Fixed price map ───────────────────────────────────────
        Map<Id, Decimal> fixedMap = new Map<Id, Decimal>();
        if (q.Part_List__c != null) {
            for (Fixed_Contract_Price__c fx : [
                SELECT Product__c, Price__c
                FROM   Fixed_Contract_Price__c
                WHERE  Part_List__c = :q.Part_List__c
            ]) {
                fixedMap.put(fx.Product__c, fx.Price__c);
            }
        }

        // ── 3. Quote line items ──────────────────────────────────────
        List<QuoteLineItem> qlis = [
            SELECT Id,
                   Product2Id,
                   Product2.Name,
                   Product2.ProductCode,
                   Product2.Description,
                   Product2.Product_Type__c,
                   Quantity,
                   UnitPrice,
                   BTP_Price__c,
                   Margin_Discount__c,
                   L2_L3_Product__c,
                   L2_L3_Product__r.Product_L2__r.Name,
                   settingType__c
            FROM   QuoteLineItem
            WHERE  QuoteId        = :offerId
            AND    Quote.Part_List__c != null
            ORDER BY Product2.Name ASC, L2_L3_Product__c ASC NULLS LAST
        ];

        // ── 4. Last SAP prices ───────────────────────────────────────
        Set<Id> l3Ids = new Set<Id>();
        for (QuoteLineItem q2 : qlis) { l3Ids.add(q2.Product2Id); }

        Map<Id, Decimal> sapPriceMap = new Map<Id, Decimal>();
        Map<Id, String>  sapDateMap  = new Map<Id, String>();

        if (!l3Ids.isEmpty() && q.Sales_Org__c != null) {
            for (Sales_Org_Last_SAP_SO__c sap : [
                SELECT SAP_Last_Sale__r.Product_L3__c,
                       Last_Sales_Price__c,
                       Last_Sales_Date__c
                FROM   Sales_Org_Last_SAP_SO__c
                WHERE  Sales_Org__c = :q.Sales_Org__c
                AND    SAP_Last_Sale__r.Product_L3__c IN :l3Ids
                ORDER BY CreatedDate DESC
            ]) {
                Id pid = sap.SAP_Last_Sale__r.Product_L3__c;
                if (!sapPriceMap.containsKey(pid)) {
                    sapPriceMap.put(pid, sap.Last_Sales_Price__c);
                    sapDateMap.put(pid,
                        sap.Last_Sales_Date__c != null
                            ? sap.Last_Sales_Date__c.format()
                            : '');
                }
            }
        }

        // ── 5. Collect L2 header names (ordered, unique) ─────────────
        List<String>   headerList  = new List<String>();
        Set<String>    headerSet   = new Set<String>();

        for (QuoteLineItem qli : qlis) {
            if (String.isNotBlank(qli.L2_L3_Product__c)
                && qli.L2_L3_Product__r.Product_L2__r != null) {

                String l2Full = qli.L2_L3_Product__r.Product_L2__r.Name;
                String[] parts = l2Full.split('-');
                String hdr = parts.size() >= 4 ? parts[3] : l2Full;

                if (!headerSet.contains(hdr)) {
                    headerSet.add(hdr);
                    headerList.add(hdr);
                }
            }
        }
        result.put('headers', headerList);

        // ── 6. Aggregate by product ──────────────────────────────────
        // productKey → row map
        Map<Id, Map<String, Object>> productRows = new Map<Id, Map<String, Object>>();
        // productKey → l2Header → qty
        Map<Id, Map<String, Decimal>> l2QtyByProduct = new Map<Id, Map<String, Decimal>>();

        for (QuoteLineItem qli : qlis) {
            Id pid = qli.Product2Id;

            if (!productRows.containsKey(pid)) {
                // Init row
                Map<String, Object> row = new Map<String, Object>();
                row.put('ProductName',   qli.Product2.Name);
                row.put('ProductCode',   qli.Product2.ProductCode  != null ? qli.Product2.ProductCode  : '');
                row.put('Description',   qli.Product2.Description  != null ? qli.Product2.Description  : '');
                row.put('BTPPrice',      qli.BTP_Price__c  != null ? qli.BTP_Price__c.setScale(2)  : 0);
                row.put('SalesPrice',    qli.UnitPrice     != null ? qli.UnitPrice.setScale(2)      : 0);
                row.put('Margin',        qli.Margin_Discount__c != null ? qli.Margin_Discount__c.setScale(2) : 0);
                row.put('LastSalePrice', sapPriceMap.containsKey(pid) ? sapPriceMap.get(pid).setScale(2) : 0);
                row.put('LastSODate',    sapDateMap.containsKey(pid)  ? sapDateMap.get(pid)  : '');
                row.put('IsFixed',       fixedMap.containsKey(pid));
                row.put('CustomQty',     0);
                row.put('TotalQty',      0);
                productRows.put(pid, row);
                l2QtyByProduct.put(pid, new Map<String, Decimal>());
            }

            Decimal qty = qli.Quantity != null ? qli.Quantity : 0;

            if (String.isNotBlank(qli.L2_L3_Product__c)
                && qli.L2_L3_Product__r.Product_L2__r != null) {
                // L2 line
                String l2Full = qli.L2_L3_Product__r.Product_L2__r.Name;
                String[] parts = l2Full.split('-');
                String hdr = parts.size() >= 4 ? parts[3] : l2Full;

                Map<String, Decimal> l2Map = l2QtyByProduct.get(pid);
                Decimal existing = l2Map.containsKey(hdr) ? l2Map.get(hdr) : 0;
                l2Map.put(hdr, existing + qty);

                // Add to total
                Map<String, Object> row = productRows.get(pid);
                Decimal tot = (Decimal)(row.get('TotalQty') != null ? row.get('TotalQty') : 0);
                row.put('TotalQty', tot + qty);
            } else {
                // Custom qty line
                Map<String, Object> row = productRows.get(pid);
                Decimal cq = (Decimal)(row.get('CustomQty') != null ? row.get('CustomQty') : 0);
                row.put('CustomQty', cq + qty);
            }
        }

        // ── 7. Build final list with ordered L2 qty array ────────────
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>();

        for (Id pid : productRows.keySet()) {
            Map<String, Object> row = productRows.get(pid);
            Map<String, Decimal> l2Map = l2QtyByProduct.get(pid);

            // Build L2Quantities list in same order as headerList
            List<Decimal> l2Quantities = new List<Decimal>();
            for (String hdr : headerList) {
                l2Quantities.add(l2Map.containsKey(hdr) ? l2Map.get(hdr) : 0);
            }
            row.put('L2Quantities', l2Quantities);
            lineItems.add(row);
        }

        // Sort by product name
        lineItems.sort(new ProductNameSorter());

        result.put('lineItems', lineItems);
        return result;
    }

    // Simple comparator to sort by ProductName
    private class ProductNameSorter implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            String nameA = (String)(a.get('ProductName') != null ? a.get('ProductName') : '');
            String nameB = (String)(b.get('ProductName') != null ? b.get('ProductName') : '');
            return nameA.compareTo(nameB);
        }
    }
}