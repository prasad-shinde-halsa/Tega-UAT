//CreateOfferLineController.js
({
    doInit: function (component, event, helper) {
        let records = component.get("v.records");
        console.log("Record after getting init: ", records);
        
        // ── NEW: Check Quote Status and Approval_Status__c ──────────────
    var statusAction = component.get("c.getQuoteStatus");
    statusAction.setParams({
    offerId: component.get("v.recordId")
});
    statusAction.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
            var result = response.getReturnValue();
            console.log("Quote Status =>", result.status);
            console.log("Quote Approval_Status__c =>", result.approvalStatus);

            var isAllowed = (result.status === 'PD' && result.approvalStatus === 'Draft');
            component.set("v.isButtonDisabled", !isAllowed);

            if (result.approvalStatus == 'Price Rejected') {
                component.set("v.isButtonDisabled", false);
            }

            
        } else {
            console.error("Error fetching quote status");
            // Default to disabled if we can't determine status
            //component.set("v.isButtonDisabled", true);
        }
    });
    $A.enqueueAction(statusAction);
    // ── END NEW ──────────────────
        
        // SK-061222 : Check if product prices is updated - True : Show Error - False : continue to TOP Screen
        var action = component.get("c.productPriceUpdate");
        action.setCallback(this, function (response) {


            var isTOPVisible = response.getReturnValue();
            if (isTOPVisible === true) {
                helper.showToast2("", "Error", "The product prices are Updated, Please contact your Admin..!");
                console.log('@insideIF');
                $A.get("e.force:closeQuickAction").fire();
            }
            else {
                //helper.showToast("Success","Success","The product prices aren't Updated.");

                helper.getl2l3products(component, event, helper);

   
            }
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set('v.isTOPScreen', response.getReturnValue());
                
            }

        });
        $A.enqueueAction(action);

        // Get product sorting order from custom metadata
        var sortingAction = component.get("c.getProductSortingOrder");
        sortingAction.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var sortingMap = response.getReturnValue();
                component.set("v.sapCodeSortOrder", sortingMap);
              
                helper.applySorting(component, event, helper);
            }
        });
        $A.enqueueAction(sortingAction);

        //helper.getProductType(component, event, helper); 
        //helper.getl2l3products(component, event, helper);

        // SK - 221122 : Sort 
        /* var sortBy = component.get("v.sortBy");
        var sortOrder = component.get("v.sortOrder");
        var action = component.get("c.getl2l3Products");
        action.setParams({"sortby" : sortBy,
                        "sortorder" : sortOrder
                        });
        action.setCallback(this, function(response){
            var state = response.getState();

            if (state == "SUCCESS"){
                var record = response.getReturnValue();
                component.set('v.records',record);
            }
        });
        $A.enqueueAction(action);*/

    },

    formatNumberConditional: function (value) {
        if (value === null || value === undefined || value === '') return '0';

        let num = parseFloat(value);
        if (isNaN(num)) return '0';

        // Handle very small numbers
        if (Math.abs(num) < 0.005) return '0';

        // Round to 2 decimal places
        let rounded = Math.round(num * 100) / 100;

        // Check if the rounded number has decimal places
        if (rounded % 1 === 0) {
            return rounded.toString(); // Integer - no decimals
        } else {
            return rounded.toFixed(2); // Show 2 decimal places
        }
    },

    search: function (component, event, helper) {

        component.set("v.isLoad", true);
        var offerId = component.get("v.recordId");

        var InputSearchKeyword = component.get("v.searchKeyword");
        var pickselected = component.find("PicklistId").get("v.value");
        var l2Map = new Map();



        var action = component.get("c.searchPartList");

        action.setParams({
            offerId: offerId,
            SearchProducts: InputSearchKeyword,
            picklistProductType: pickselected
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.isLoad", false);
                var resultdata = response.getReturnValue();
                if (resultdata.isErr === false) {
                    //component.set("v.currencyMismatchError", ""); // clear error on success
                   
                    var obj = resultdata.data; // response.getReturnValue(); 
                   
                    component.set("v.BTPMap", resultdata.BTP);
                    component.set("v.offCurrency", resultdata.offerCurrency);
                    component.set("v.derivedSOfactor", resultdata.SOFactor);
                    component.set("v.sOrgId", resultdata.sOrgId);
                    component.set("v.wos", resultdata.isWos);
                    component.set("v.directCustomer", resultdata.isDirectCustomer);
                    component.set("v.partId", obj.partListId);
                    component.set("v.L3ProductQty", resultdata.L3ProdQtyMap);

                    var result = obj.products;
                    var sapPriceMap = obj.sapPriceMap;
                    var sapDateMap = obj.sapDateMap;
                    var salesprice = sapPriceMap;
                    let fixedPrice = obj.fixedPriceMap;
                   
                    var recordsFromServer = JSON.parse(JSON.stringify(result));
                   
                    var productHeaders = new Set();
                    var records = [];
                    var quantityMap = new Map();



                    for (var key in recordsFromServer) {
                        var record = recordsFromServer[key];
                      
                        var prodName = record.Product_L2__r.Name.split('-');
                        recordsFromServer[key].ProductL2Name = prodName[3];
                        productHeaders.add(prodName[3]);
                        var mapRow = new Map();
                        if (quantityMap.has(record.Product_L3__r.Name)) {
                            mapRow = quantityMap.get(record.Product_L3__r.Name);
                        }
                        mapRow.set(record.ProductL2Name, record.Quantity__c);
            
                        quantityMap.set(record.Product_L3__r.Name, mapRow);
                       
                        // Sending 1 l2l3 for each header in l2Map
                        /*if (!l2Map.has(prodName[3])){
                            console.log('Inside l2Map IF');
                            l2Map.set(prodName[3], record.Id);
                            console.log('After 117',l2Map);
                        }*/

                        //AK Fixes 13/12/22
                        let text = record.Product_L2__r.Name;
                        const myArray = text.split("-");
                        let l2Level = myArray[3];
                        let result = record.Product_L3__c + "-" + l2Level;

                        //AK Fixes 08/12/22 => L2Map has now all L2L3 Records from that PartList along with header name like FEH as key
                        l2Map.set(result, record.Id);
                    }
                  
                    var uniqueL3 = new Set();
                    var uniqueRecords = new Array();
                    for (var key in recordsFromServer) {
                        var record = recordsFromServer[key];

                        var quantityMapRecord = quantityMap.get(record.Product_L3__r.Name);
                        var columnsString = [];
                        var TotalQuantity = [];
                        var level2CustomQuantityValues = new Map();
                        var customQuantityValues = new Map();
                        const iterator1 = productHeaders.values();
                        var total = 0;
                        for (var i = 0; i < productHeaders.size; i++) {
                            var headerVal = iterator1.next().value;
                            var value = quantityMapRecord.get(headerVal) ? quantityMapRecord.get(headerVal) : 0;
                            var column = '<div class="slds-truncate">' + value + '</div>';
                            var total = total + value;
                            columnsString.push(column);
                            TotalQuantity.push(total);

                        }
                        record.product2Quantities = columnsString;
                        record.productquantities = total;
                        record.quantityMapRecord = quantityMapRecord;
                        record.customQuantity = 0;
                        record.level2customQuantity = 0;
                        record.isLLP = false;

                        //AK 02/12/22 Changes
                        record.isDirectCustomer = component.get("v.directCustomer");
                        record.isWos = component.get("v.wos");
                        record.RMCCost = 0;
                        record.branchRateOfInterest = 0;
                        record.offerpayment = 0;
                        record.branchHedging = 0;
                        record.basicPrice = 0;
                        record.costPackingForwarding = 0;
                        record.CostFreight = 0;
                        record.costInsurance = 0;
                        record.costInterest = 0;
                        record.costHedging = 0;
                        record.exchangeRate = 0;

                      
                        //record.btpPrice = fixedPrice[record.Product_L3__c];
                    
                        if (fixedPrice[record.Product_L3__c]) {
                         
                            record.isFixedBTP = true;
                            record.isLLP = true;
                        } else {
                         
                            record.isFixedBTP = false;
                        }

                        record.margin = 0;
                        record.discount = 0;
                        record.mySalesPrice = 0;
                        record.cusBtpPrice = 0;
                        record.L2btpPrice = 0;


                        record.inputDisable = true;
                        // console.log('conversionRate-->>', obj.conversionRate);
                        let lsalesPrice = 0;
                        if (sapPriceMap[record.Product_L3__c]) {
                            
                            //lsalesPrice = (sapPriceMap[record.Product_L3__c] * obj.conversionRate).toFixed(5);
                            lsalesPrice = (sapPriceMap[record.Product_L3__c]).toFixed(5);
                            record.isLLP = true;
                        }

                        //code added by Ranjeet for isWos check 
                        if (record.isWos && record.isDirectCustomer !== true && lsalesPrice > 0) {
                            lsalesPrice = parseFloat(lsalesPrice) / 0.75;
                        }
                        // end 

                       
                        record.SAP_Price = lsalesPrice;

                        if (sapDateMap[record.Product_L3__c]) {
                            record.SAP_Date = sapDateMap[record.Product_L3__c];
                        }


                        record.SAP_PriceOld = sapPriceMap[record.Product_L3__c];
                        record.customQuantityValues = new Map(Object.entries(JSON.parse(JSON.stringify(quantityMapRecord))));//customQuantityValues ;
                        record.level2CustomQuantityValues = new Map(Object.entries(JSON.parse(JSON.stringify(quantityMapRecord))));//customQuantityValues ;
                        record.headers = headers;
                        record.errMsg = '';


                        let ProType = record.Product_L3__r.Product_Type__c;
                        if (ProType && ProType.slice(0, 2) == 'FG') {
                            record.SAP_Price = Math.ceil(lsalesPrice);
                        }

                        if (uniqueL3.has(record.Product_L3__r.Name)) {
                            continue;
                        }
                        else {
                            
                            uniqueL3.add(record.Product_L3__r.Name);
                      
                            uniqueRecords.push(record);
                        }
                    }
                    
                    component.set('v.record', total);
                    var headers = [];
                    const iterator1 = productHeaders.values();
                    for (var i = 0; i < productHeaders.size; i++) {
                        var header = new Object();
                        header.Name = iterator1.next().value;
                        header.isSelected = false;
                        header.value = 0;
                        headers.push(header);
                    }

                    component.set('v.records', uniqueRecords);

                    //subham
                    console.log('subham records--> ', uniqueRecords);

                    component.set('v.headers', headers);
                    component.set('v.headersName', productHeaders);
                    component.set('v.L2ProductMap', l2Map);
                    helper.applySorting(component, event, helper);
                } else {
                    //component.set("v.currencyMismatchError", resultdata.ErrorMsg);
                    helper.showToast("Error", "Error", resultdata.ErrorMsg);
                }
            }
            if (pickselected == '') {
                component.set('v.records', uniqueRecords);
                //subham
                    console.log('subham records--> 319 :: ', uniqueRecords);
            }

            else if (state === "ERROR") {
                component.set("v.isLoad", false);
                var errors = response.getError();
                console.error(errors);
            }
        });
        $A.enqueueAction(action);

    },



    onClickHandleChange: function (component, event, helper) {

        var headers = component.get('v.headers');
        var fullSet = component.get('v.fullSet');

        let isSpareselected = false;
        let allChk = 0;
        for (var header of headers) {

            if (header.Name === 'SPARE' && header.isSelected === true) {
                if (fullSet === false) {
                    isSpareselected = true;
                    var errMsg = $A.get("$Label.c.No_Spare_W_O_Full_Set");
                    header.isSelected = false;
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: 'Cannot Select Spare',
                        message: errMsg,
                        duration: ' 5000',
                        key: 'info_alt',
                        type: 'error',
                        mode: 'dismissible'
                    });
                    toastEvent.fire();
                }
            }

            if (header.isSelected === false) {
                header.value = 0;
            } else {
              
                if (header.value <= 1 || header.value === undefined)
                    header.value = 1;
                allChk++;
            }
        }

       

        if (headers.length === allChk) {
            // component.set("v.fullSet", true);
        } else {
            component.set("v.fullSet", false);
            for (var header of headers) {
                if (header.Name === 'SPARE') {
                    header.value = 0;
                    header.isSelected = false;
                }
            }
        }
        component.set('v.headers', headers);
        if (isSpareselected === false) {
            helper.caluculateLevel2CustomQuantity(component, event, helper, true);
            window.setTimeout(function () {
                helper.applySorting(component, event, helper);
            }, 100);
        }
    },

    handleOnChange: function (component, event, helper) {
        let headerList = component.get("v.headers");
        var value = event.currentTarget.value;
        var header = event.currentTarget.dataset.header;
        var index = event.currentTarget.dataset.index;
        headerList[index].value = value;

        helper.calculateRecordCustomQuantity(component, event, helper, value, header, true);
    },


    onFullSetCheckBox: function (component, event, helper) {
        helper.onChangeFullSet(component, event, helper, true);
        window.setTimeout(function () {
            helper.applySorting(component, event, helper);
        }, 100);
    },

    onCheckFullSet: function (component, event, helper) {
        helper.onChangeFullSet(component, event, helper, false);
    },

    onChange: function (component, event, helper) {
        window.setTimeout(function () {
            helper.changeCustomQty(component, event, helper)
        }, 1500)
    },

    onChangeMargin: function (component, event, helper) {
        helper.onMarginChange(component, event, helper);
    },

    onChangeDiscount: function (component, event, helper) {
        helper.onDiscountChange(component, event, helper);
    },

    onChangeMarginAll: function (component, event, helper) {
        helper.allMarginChange(component, event, helper);
    },

    onChangeDiscountAll: function (component, event, helper) {
        helper.allDiscountChange(component, event, helper);
    },

    showSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.addClass(spinner, "slds-hide");
    },

    handleConfirmDialogNo: function (component, event, helper) {
        component.set("v.showConfirmDialog", false);
    },

    //    validate : function(component, event, helper){
    //     let totalSalesPrice =  component.get("v.totalSalesPrice");
    //     let totalBTPPrice =  component.get("v.totalBTPPrice");
    //     let totalSalesPer = component.get("v.totalSalesPer");
    //     let discount = (parseFloat(totalSalesPrice)/parseFloat(totalBTPPrice))*100;
    //     console.log('discount-->>',discount);
    //     let percent = 100 - discount;
    //     console.log('percent-->>',percent);
    //     if(percent > 1){
    //         console.log('inside discount if-->>',discount);
    //         component.set("v.showConfirmDialog", true);
    //         //console.log('inside If-Else-->>',discount);
    //         //helper.createOffer(component, event, helper);
    //     }
    //    else
    //    {
    //         console.log('inside Else-->>',discount);
    //         helper.createOffer(component, event, helper);
    //     }
    // }, 

    validate: function (component, event, helper) {

        
        let totalSalesPrice = component.get("v.totalSalesPrice");
        let totalBTPPrice = component.get("v.totalBTPPrice");
        let totalSalesPer = component.get("v.totalSalesPer");
        let discount = (parseFloat(totalSalesPrice) / parseFloat(totalBTPPrice)) * 100;
        let percent = 100 - discount;

        if (percent > 1) {
            component.set("v.showConfirmDialog", true);
        }
        else {
            helper.createOffer(component, event, helper, true); // ✅ Save & Close
        }
    },

    saveOnly: function (component, event, helper) {

        
        let totalSalesPrice = component.get("v.totalSalesPrice");
        let totalBTPPrice = component.get("v.totalBTPPrice");
        let totalSalesPer = component.get("v.totalSalesPer");
        let discount = (parseFloat(totalSalesPrice) / parseFloat(totalBTPPrice)) * 100;
        let percent = 100 - discount;

        if (percent > 1) {
            component.set("v.showConfirmDialog", true);
        }
        else {
            helper.createOffer(component, event, helper, false); // ✅ Save only, don’t close
        }
    },


    offerLinesave: function (component, event, helper) {
       
        helper.createOffer(component, event, helper);
    },

    handleExit: function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    //Reeta

    handleSorting: function (component, event, helper) {

        var currentSortBy = component.get('v.sortBy');
        var currentSortOrder = component.get('v.sortOrder');

      

        // Toggle sort order for Product Name
        if (currentSortBy === 'Product_L3__r.Name') {
            if (currentSortOrder === 'asc') {
                component.set('v.sortOrder', 'desc');
            } else {
                component.set('v.sortOrder', 'asc');
            }
        } else {
            // Start sorting by Product Name with default order
            component.set('v.sortBy', 'Product_L3__r.Name');
            component.set('v.sortOrder', 'asc');
        }


        // Apply sorting to current records
        helper.applySorting(component, event, helper);

    },

})