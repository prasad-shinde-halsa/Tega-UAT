({
    loadData: function(component, event, helper) {
        var offerId = component.get('v.recordId');

        var action = component.get('c.getOfferPrintData');
        action.setParams({ offerId: offerId });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                var result = response.getReturnValue();

                // ── Quote header ──
                component.set('v.quoteData', result.quoteData);

                // ── L2 header names (dynamic columns) ──
                var headers = result.headers || [];
                component.set('v.headers', headers);

                // ── Line items ──
                var items = result.lineItems || [];
                component.set('v.lineItems', items);

                // ── Totals ──
                var totalBTP   = 0;
                var totalSales = 0;

                for (var i = 0; i < items.length; i++) {
                    var it  = items[i];
                    var qty = (parseFloat(it.TotalQty)   || 0)
                            + (parseFloat(it.CustomQty)  || 0);

                    var btp   = parseFloat(it.BTPPrice)   || 0;
                    var sales = parseFloat(it.SalesPrice) || 0;

                    totalBTP   += btp   * qty;
                    totalSales += sales * qty;
                }

                var pct = totalBTP > 0
                    ? ((totalSales / totalBTP) * 100).toFixed(2)
                    : '0.00';

                component.set('v.totalBTP',      totalBTP.toFixed(2));
                component.set('v.totalSales',    totalSales.toFixed(2));
                component.set('v.totalSalesPct', pct);

                component.set('v.isLoading', false);

            } else {
                component.set('v.isLoading', false);
                var errors = response.getError();
                console.error('OfferLinePrint load error:', errors);
            }
        });

        $A.enqueueAction(action);
    }
})