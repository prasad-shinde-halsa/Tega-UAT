({
    getProductType: function (component, event, helper) {
        var action = component.get("c.getProductType");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultdata = response.getReturnValue();
                var prodTypelist = [];
                for (var key in resultdata.keySet()) {
                    prodTypelist.push({
                        key: key,
                        value: resultdata[key]
                    });
                }
                component.set("v.selectKeyword", prodTypelist);
                var obj = prodTypelist.data;

                console.log(JSON.stringify(resultdata));
            } else if (state === "ERROR") {
                var errors = response.getError();
            }
        });
        $A.enqueueAction(action);
    },

    //working fine but BTP not loaded in decimal 
    //   getl2l3products: function (component, event, helper) {
    //       var pickselected ="";
    //       component.set("v.isLoad", true);
    //       var offerId = component.get("v.recordId");
    //       var action = component.get("c.getl2l3Products");
    //       var l2Mapupdate = new Map();
    //       action.setParams({
    //           offerId: offerId
    //       });
    //       action.setCallback(this, function (response) {
    //           var state = response.getState();
    //           console.log('update state--->>' +state);
    //           if (state === "SUCCESS") {
    //               //component.set("v.isLoad", false);
    //               component.set("v.isUpdate",true);
    //               var resultdata = response.getReturnValue();
    //               console.log('resultdata' + JSON.stringify(resultdata));
    //               var obj = resultdata.data;
    //               console.log('obj------'+obj)
    //                console.log('resultdata.BTP------'+JSON.stringify(resultdata.BTP))
    //               if(obj == undefined){
    //                   return;
    //               }
    //               var wrp = resultdata.wrp;
    //               console.log('--wrp--',wrp);
    //               var l1l2 = resultdata.l1l2;
    //               console.log('l1l2========'+JSON.stringify(l1l2));
    //               let parListId = resultdata.partListId;
    //               component.set("v.BTPMap", resultdata.BTP);
    //               console.log(' resultdata.BTP==========='+ JSON.stringify(resultdata.BTP))
    //               component.set("v.partId", parListId);
    //               component.set("v.offCurrency", resultdata.offerCurrency);
    //               component.set("v.totalBTPPrice", resultdata.totalBTPPrice);
    //               component.set("v.totalBTPPricev2", resultdata.totalBTPPricev2);
    //               console.log('resultdata.totalBTPPrice--------'+JSON.stringify(resultdata.totalBTPPrice))
    //               component.set("v.totalSalesPrice", resultdata.totalSalesPrice);
    //               console.log('resultdata.totalSalesPrice--------'+JSON.stringify(resultdata.totalSalesPrice))
    //               // SK - 211122 : Adding the Overall Percentage calculation
    //               component.set("v.totalSalesPer",resultdata.totalSalesPer);
    //               console.log('resultdata.totalSalesPer ----'+JSON.stringify(resultdata.totalSalesPer))


    //               component.set("v.fullSet", resultdata.isFullSet);
    //               component.set("v.fullSetQuantity", resultdata.fullSetQty);
    //               component.set("v.wos", resultdata.isWos);
    //               component.set("v.derivedSOfactor", resultdata.SOFactor);

    //               // AK 02/12/22 Changes
    //               component.set("v.directCustomer", resultdata.isDirectCustomer);

    //               console.log("AK AK salesOrgId=>",resultdata.sOrgId);
    //               component.set("v.sOrgId", resultdata.sOrgId);
    //               console.log('L3ProdQtyMap load');
    //               console.log(resultdata.L3ProdQtyMap);
    //               component.set("v.L3ProductQty", resultdata.L3ProdQtyMap);

    //               // console.log('========'+JSON.stringify(wrp));
    //               // console.log('l1l2========'+JSON.stringify(l1l2));

    //               // console.log('obje sales price---------',obj);
    //               var result = obj.products;
    //               console.log('obj'+obj.products)
    //               var sapPriceMap = obj.sapPriceMap;
    //               var salesprice = sapPriceMap;
    //               var sapDateMap = obj.sapDateMap;
    //               let fixedPrice = obj.fixedPriceMap;
    //               component.set('v.fixedPriceMap', fixedPrice);
    //               // console.log('salesprice-------'+salesprice)
    //               console.log('recordsFromServer-->>'+JSON.stringify(result));
    //               console.log(recordsFromServer);
    //                var recordsFromServer = JSON.parse(JSON.stringify(result));
    //                if (recordsFromServer != '' || recordsFromServer.length > 0) {
    //                   component.set('v.partlistnumber', false);
    //                   component.set('v.searchTable', false);
    //               }
    //               var productHeaders = new Set();
    //               // console.log('productHeaders'+productHeaders)
    //               var records = [];
    //               var quantityMap = new Map();
    //               for (var key in recordsFromServer) {
    //                   console.log('key-->>'+key);
    //                   var record = recordsFromServer[key];
    //                   console.log(record.Product_L2__r.Name);
    //                   var prodName = record.Product_L2__r.Name.split('-');
    //                   recordsFromServer[key].ProductL2Name = prodName[3];
    //                   productHeaders.add(prodName[3]);
    //                   var mapRow = new Map();
    //                   if (quantityMap.has(record.Product_L3__r.Name)) {
    //                       mapRow = quantityMap.get(record.Product_L3__r.Name);
    //                   }
    //                   mapRow.set(record.ProductL2Name, record.Quantity__c);
    //                   console.log('record.ProductL2Name' + record.ProductL2Name)
    //                   console.log('record.ProductL2Name qty' + record.Quantity__c)
    //                   quantityMap.set(record.Product_L3__r.Name, mapRow);
    //                   console.log('record.Product_L3__r.Name' + record.Product_L3__r.Name)
    //                   console.log('AK prodName[3] =>',prodName[3]);

    //                   // AK 09/12/22 Changes
    //                   /*if (!l2Mapupdate.has(prodName[3])) {
    //                       l2Mapupdate.set(prodName[3], record.Id);
    //                   }*/

    //                   //AK Fixes 13/12/22
    //                   let text = record.Product_L2__r.Name;
    //                   const myArray = text.split("-");
    //                   let l2Level = myArray[3];
    //                   let result = record.Product_L3__c + "-" + l2Level;

    //                   //AK Fixes 08/12/22 => L2Map has now all L2L3 Records from that PartList along with header name like FEH as key
    //                   l2Mapupdate.set(result, record.Id);
    //               }
    //               console.log('AK l2Mapupdate =>',JSON.stringify(l2Mapupdate));
    //               console.log('AK 07/12/22 Headers')
    //               console.log(productHeaders);
    //               console.log(quantityMap);
    //               console.log(recordsFromServer.length);
    //               var uniqueL3 = new Set();
    //               var uniqueRecords = new Array();

    //               for (var key in recordsFromServer) {
    //                   var record = recordsFromServer[key];
    //                   var quantityMapRecord = quantityMap.get(record.Product_L3__r.Name);
    //                   var columnsString = [];
    //                   var TotalQuantity = [];
    //                   var level2CustomQuantityValues = new Map();
    //                   var customQuantityValues = new Map();
    //                   const iterator1 = productHeaders.values();
    //                   var total = 0;
    //                   for (var i = 0; i < productHeaders.size; i++) {
    //                       var headerVal = iterator1.next().value;
    //                       var value = quantityMapRecord.get(headerVal) ? quantityMapRecord.get(headerVal) : 0;
    //                       var column = '<div class="slds-truncate">' + value + '</div>';
    //                       var total = total + value;
    //                       columnsString.push(column);
    //                       TotalQuantity.push(total);
    //                   }
    //                   console.log('total =>',total);

    //                   /*  
    //                       var columnsString = [];
    //                       var L2Customqty =[];
    //                       const iteratorl2 = productHeaders.values();
    //                       var customqtyl2 =0;
    //                       for (var i=0 ; i < productHeaders.size ; i++) {
    //                           var headerVal = iteratorl2.next().value;
    //                           var value = quantityMapRecord.get(headerVal) ? quantityMapRecord.get(headerVal) : 0;
    //                           var column = '<div class="slds-truncate">' + value  + '</div>';
    //                           var l2customqtty = customqtyl2 + value;
    //                           columnsString.push(column);
    //                           L2Customqty.push(l2customqtty);
    //                       }*/

    //                   console.log('product l3 name----' + record.Product_L3__r.Name);

    //                   record.product2Quantities = columnsString;
    //                   record.productquantities = total;
    //                   record.quantityMapRecord = quantityMapRecord;

    //                   console.log("productquantities => ",record.productquantities);
    //                   console.log(record);
    //                   if(total > 0){
    //                       record.inputDisable = false;
    //                   }else{
    //                       record.inputDisable = true;
    //                   }

    //                   record.headers = headers;
    //                   //console.log('header nikhjil==========' + headers);
    //                   record.level2customQuantity = component.get("v.l2values");
    //                   record.customQuantity = 0;
    //                   var prodName = record.Product_L2__r.Name.split('-');
    //                   record.partCode = prodName[3];
    //                   record.isLLP = false;

    //                   console.log('AK 2 Dec inside init');
    //                   record.isDirectCustomer = component.get("v.directCustomer");
    //                   console.log('record.isDirectCustomer=>'+record.isDirectCustomer);
    //                   record.isWos = component.get("v.wos");
    //                     record.RMCCost = 0;
    //                     record.branchRateOfInterest = 0;
    //                     record.offerpayment = 0;
    //                     record.branchHedging = 0;
    //                     record.basicPrice = 0;
    //                     record.costPackingForwarding = 0;
    //                     record.CostFreight = 0;
    //                     record.costInsurance = 0;
    //                     record.costInterest = 0;
    //                     record.costHedging = 0;
    //                     record.exchangeRate = 0;

    //                   if(fixedPrice[record.Product_L3__c]){
    //                       record.isFixedBTP = true;
    //                       record.isLLP = true;
    //                   }else{
    //                       record.isFixedBTP = false;
    //                   }
    //                   record.L2btpPrice = 0;
    //                   record.cusBtpPrice = 0;
    //                   record.margin = 0;
    //                   record.discount = 0;
    //                   for (var key in wrp) {
    //                       //console.log('wrp key-->>'+key);
    //                       if (key == record.Product_L3__r.Name) {
    //                           var wrpprds = wrp[key];


    //                           console.log('record till here',record);
    //                           record.QuotelineId = wrpprds.QuotelineId;
    //                           console.log("AK customQuantity",wrpprds.customQuantity);
    //                           record.customQuantity = wrpprds.customQuantity;

    //                           // AK 19/12/22 Changes
    //                           if(record.customQuantity > 0){
    //                               record.inputDisable = false;
    //                           }

    //                           console.log("AK btpPrice",wrpprds.btpPrice);


    //                           let ProType = record.Product_L3__r.Product_Type__c;
    //                             let isFG = false;
    //                             if(ProType && ProType.slice(0,2) == 'FG'){
    //                                 isFG = true;
    //                                 console.log('FG Product detected:', record.Product_L3__r.Name);
    //                             }
    //                           //RJ 
    //                         //   if (wrpprds.btpPrice==0){
    //                         //     record.btpPrice=Math.ceil(wrpprds.L2btpPrice);
    //                         //   }
    //                         //   else{                              
    //                         //     record.btpPrice = Math.ceil(wrpprds.btpPrice);
    //                         //     }

    //                         if (wrpprds.btpPrice==0){
    //                                 record.btpPrice = isFG ? Math.ceil(wrpprds.L2btpPrice) : wrpprds.L2btpPrice;
    //                             } else {                              
    //                                 record.btpPrice = isFG ? Math.ceil(wrpprds.btpPrice) : wrpprds.btpPrice;
    //                             }
    //                           record.cusBtpPrice = wrpprds.cusBtpPrice;
    //                           record.L2btpPrice = wrpprds.L2btpPrice; 
    //                           record.margin = wrpprds.margin;
    //                           record.discount = wrpprds.discount;
    //                         //   if (wrpprds.salesPrice==0){
    //                         //     record.mySalesPrice= Math.ceil(wrpprds.L2btpPrice);
    //                         //   }

    //                         if (wrpprds.salesPrice==0){
    //                                 record.mySalesPrice = isFG ? Math.ceil(wrpprds.L2btpPrice) : wrpprds.L2btpPrice;
    //                             }
    //                         //   if (record.isFixedBTP && fixedPrice[record.Product_L3__c]) {
    //                         //         record.mySalesPrice = Math.ceil(fixedPrice[record.Product_L3__c]);
    //                         //         //record.btpPrice = fixedPrice[record.Product_L3__c];
    //                         //     }

    //                         //   else{
    //                         //     record.mySalesPrice = Math.ceil(wrpprds.salesPrice);
    //                         //   }

    //                         if (record.isFixedBTP && fixedPrice[record.Product_L3__c]) {
    //                                 record.mySalesPrice = isFG ? Math.ceil(fixedPrice[record.Product_L3__c]) : fixedPrice[record.Product_L3__c];
    //                             } else {
    //                                 record.mySalesPrice = isFG ? Math.ceil(wrpprds.salesPrice) : wrpprds.salesPrice;
    //                             }

    //                           record.level2customQuantity = wrpprds.level2customQuantity;


    //                           console.log('record till here2',record);
    //                       }
    //                   }
    //                   // record.level2customQuantity =total*;
    //                   let lastSPrice = 0
    //                   if(sapPriceMap[record.Product_L3__c]){
    //                       //lastSPrice = (sapPriceMap[record.Product_L3__c] * obj.conversionRate).toFixed(5);
    //                       lastSPrice = (sapPriceMap[record.Product_L3__c] );
    //                       record.isLLP = true;
    //                   }/* AK 07/12/22 Changes else{
    //                       if(!isNaN(record.

    //                       ) ){
    //                           lastSPrice = record.btpPrice;
    //                       }                        
    //                   }*/
    //                   console.log('AK 07/12/22 lastSPrice-->>'+lastSPrice);

    //                   if(sapDateMap[record.Product_L3__c]){
    //                     	record.SAP_Date = sapDateMap[record.Product_L3__c];
    //                   }  

    //                   let ProType2 = record.Product_L3__r.Product_Type__c;
    //                     if(ProType2 && ProType2.slice(0,2) == 'FG'){
    //                         record.SAP_Price = Math.ceil(lastSPrice);
    //                     } else {
    //                         record.SAP_Price = lastSPrice;
    //                     }

    //                   //record.SAP_Price = Math.ceil(lastSPrice);
    //                   record.SAP_PriceOld = Math.ceil(sapPriceMap[record.Product_L3__c]);
    //                   record.customQuantityValues = new Map(Object.entries(JSON.parse(JSON.stringify(quantityMapRecord)))); //customQuantityValues ;
    //                   record.level2CustomQuantityValues = new Map(Object.entries(JSON.parse(JSON.stringify(quantityMapRecord)))); //customQuantityValues ;


    //                   //CODE ADDED Ranjeet 
    //                                         // Set initial BTP from SAP_Price if no other BTP exists
    //                     // if(record.btpPrice === 0 || record.btpPrice === undefined) {
    //                     //     if(record.SAP_Price > 0) {
    //                     //         record.btpPrice = record.SAP_Price;
    //                     //         record.mySalesPrice = record.SAP_Price;
    //                     //         console.log('Setting initial BTP from SAP_Price: ' + record.SAP_Price);
    //                     //     }
    //                     // }
    //                     if(record.btpPrice === 0 || record.btpPrice === undefined) {
    //                         if(record.SAP_Price > 0) {
    //                             // ✅ Check if FG product for rounding
    //                             let ProType = record.Product_L3__r.Product_Type__c;
    //                             let isFG = (ProType && ProType.slice(0,2) == 'FG');

    //                             if(isFG) {
    //                                 record.btpPrice = Math.ceil(record.SAP_Price);
    //                                 record.mySalesPrice = Math.ceil(record.SAP_Price);
    //                                 console.log('Setting initial BTP from SAP_Price (FG rounded): ' + record.SAP_Price);
    //                             } else {
    //                                 record.btpPrice = record.SAP_Price;
    //                                 record.mySalesPrice = record.SAP_Price;
    //                                 console.log('Setting initial BTP from SAP_Price (non-FG): ' + record.SAP_Price);
    //                             }
    //                         }
    //                     }
    //                 // CODE ADDED BY Ranjeet

    //                   let ProType = record.Product_L3__r.Product_Type__c;
    //                   if(ProType && ProType.slice(0,2) == 'FG'){
    //                       record.SAP_Price = Math.ceil(lastSPrice);
    //                   }
    //                   else {
    //                         record.SAP_Price = lastSPrice;
    //                     }
    //                    if(uniqueL3.has(record.Product_L3__r.Name))
    //                       {
    //                           continue;
    //                       }
    //                       else{
    //                       uniqueL3.add(record.Product_L3__r.Name);
    //                       uniqueRecords.push(record);    
    //                       }  

    //               }
    //               console.log("unique rec => ",uniqueRecords);
    //               component.set('v.record', total);
    //               var headers = [];
    //               const iterator1 = productHeaders.values();
    //               let isFSet = component.get("v.fullSet");
    //               console.log('productHeaders.size => '+productHeaders.size);
    //               for (var i = 0; i < productHeaders.size; i++) {
    //                   var header = new Object();
    //                   header.Name = iterator1.next().value;
    //                   header.isSelected = false;
    //                  // if(isFSet === true){
    //                   //	header.isSelected = true;
    //                     //  header.value =  l1l2[i].Quantity__c;
    //                   //}
    //                   for (var j = 0; j < l1l2.length; j++) {
    //                       if (l1l2[j].Product_Description__c != undefined && l1l2[j].Product_Description__c.includes(header.Name)) {
    //                           header.value = l1l2[j].Quantity__c;
    //                           header.isSelected = true;
    //                           console.log('header.value========' + header.value);
    //                           // break;
    //                       }
    //                       console.log('l1l2.----------' + l1l2[j]);
    //                   }
    //                   headers.push(header);

    //               }
    //               console.log('headers======', headers);
    //              // component.set("v.recordspartlist",record.level2customQuantity);
    //               component.set('v.headers', headers);
    //               console.log('recordsFromServer======', recordsFromServer);
    //               component.set('v.recordspartlist', recordsFromServer);
    //             // component.set('v.records', recordsFromServer);
    //              component.set('v.records', uniqueRecords);
    //               //console.log('recordsFromServer-----121' + JrecordsFromServer));
    //               helper.applySorting(component, event, helper);
    //               console.log('productHeaders>' + productHeaders);
    //               component.set('v.headersName', productHeaders);
    //               // component.set('v.updateL2ProductMap', l2Mapupdate);
    //               component.set('v.L2ProductMap', l2Mapupdate);

    //                helper.totalBTPCalculate(component, event, helper);
    //                helper.totalSalesPriceCalculate(component, event, helper);

    //                helper.calculateFreshBTPForAllProducts(component, event, helper);
    //                component.set("v.isLoad", false);

    //               if (recordsFromServer != '') {
    //                   component.set('v.partlistnumber', false);
    //                   component.set('v.searchTable', false);
    //               }

    //           }else if (state === "ERROR") {
    //               component.set("v.isLoad", false);
    //               var errors = response.getError();
    //               console.error(errors);
    //           }

    //           if (pickselected == '') {
    //               //component.set("v.isLoad", false); 
    //              // component.set('v.recordspartlist', recordsFromServer);
    //                              component.set('v.recordspartlist', uniqueRecords);

    //           } 
    //           /*else if (state === "ERROR") {
    //               component.set("v.isLoad", false);
    //               var errors = response.getError();
    //               console.error(errors);
    //           }*/
    //       });
    //       $A.enqueueAction(action);
    //   },

    getl2l3products: function (component, event, helper) {
        var pickselected = "";
        component.set("v.isLoad", true);

        // Clear existing records to prevent showing old data
        component.set('v.records', []);
        component.set('v.recordspartlist', []);

        var offerId = component.get("v.recordId");
        var action = component.get("c.getl2l3Products");
        var l2Mapupdate = new Map();
        action.setParams({
            offerId: offerId
        });
        action.setCallback(this, function (response) {
            console.log('Final Response--->>' + response);
            var state = response.getState();
            console.log('update state--->>' + state);
            if (state === "SUCCESS") {
                component.set("v.isUpdate", true);
                var resultdata = response.getReturnValue();
                console.log('resultdata' + JSON.stringify(resultdata));

                // code added by Ranjeet for debugging SAP Price issues:


                if (resultdata && resultdata.data) {

                }
                console.log('============ SAP PRICE DEBUG END ============');
                //  END DEBUG STATEMENTS

                // old code for error before currency check //

                var obj = resultdata.data;

                if (obj == undefined) {
                    component.set("v.isLoad", false);
                    return;
                }

                // // Currency mismatch check
                // if (resultdata.isErr === true) {
                //     component.set("v.isLoad", false);
                //     component.set("v.currencyMismatchError", resultdata.ErrorMsg);
                //     helper.showToast("Error", "Error", resultdata.ErrorMsg);
                //     return;
                // }
                // component.set("v.currencyMismatchError", ""); // clear error if no mismatch
                // var obj = resultdata.data;
                // console.log('obj------' + obj)
                // console.log('resultdata.BTP------' + JSON.stringify(resultdata.BTP))
                // if (obj == undefined) {
                //     component.set("v.isLoad", false);
                //     return;
                // }




                var wrp = resultdata.wrp;

                var l1l2 = resultdata.l1l2;

                let parListId = resultdata.partListId;
                component.set("v.BTPMap", resultdata.BTP);

                component.set("v.partId", parListId);
                component.set("v.offCurrency", resultdata.offerCurrency);

                // // Compare part list currency with offer currency
                // var partListCurrency = resultdata.partListCurrency;
                // var offerCurrency = resultdata.offerCurrency;
                // console.log('partListCurrency => ', partListCurrency);
                // console.log('offerCurrency => ', offerCurrency);
                // var isSapCurrencyMismatch = false;
                // if (partListCurrency && offerCurrency && partListCurrency !== offerCurrency) {
                //     isSapCurrencyMismatch = true;
                // }
                // console.log('isSapCurrencyMismatch => ', isSapCurrencyMismatch);
                // component.set("v.isSapCurrencyMismatch", isSapCurrencyMismatch);
                // // // Compare part list currency with offer currency end 

                component.set("v.totalBTPPrice", resultdata.totalBTPPrice);
                component.set("v.totalBTPPricev2", resultdata.totalBTPPricev2);

                component.set("v.totalSalesPrice", resultdata.totalSalesPrice);

                // SK - 211122 : Adding the Overall Percentage calculation
                component.set("v.totalSalesPer", resultdata.totalSalesPer);

                //Subham below line
                // component.set("v.fullSet", resultdata.isFullSet);
                component.set("v.fullSetQuantity", resultdata.fullSetQty);
                component.set("v.wos", resultdata.isWos);
                component.set("v.derivedSOfactor", resultdata.SOFactor);

                // AK 02/12/22 Changes
                component.set("v.directCustomer", resultdata.isDirectCustomer);


                component.set("v.sOrgId", resultdata.sOrgId);

                component.set("v.L3ProductQty", resultdata.L3ProdQtyMap);

                var result = obj.products;

                var sapPriceMap = obj.sapPriceMap;

                var sapPriceMap2 = resultdata.originalSapPriceMap;

                var salesprice = sapPriceMap;
                var sapDateMap = obj.sapDateMap;
                let fixedPrice = obj.fixedPriceMap;
                component.set('v.fixedPriceMap', fixedPrice);

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


                    let text = record.Product_L2__r.Name;
                    const myArray = text.split("-");
                    let l2Level = myArray[3];
                    let result = record.Product_L3__c + "-" + l2Level;

                    l2Mapupdate.set(result, record.Id);
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


                    if (total > 0) {
                        record.inputDisable = false;
                    } else {
                        record.inputDisable = true;
                    }

                    record.headers = headers;
                    record.level2customQuantity = component.get("v.l2values");
                    record.customQuantity = 0;
                    var prodName = record.Product_L2__r.Name.split('-');
                    record.partCode = prodName[3];
                    record.isLLP = false;


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

                    if (fixedPrice[record.Product_L3__c]) {
                        record.isFixedBTP = true;
                        record.isLLP = true;
                    } else {
                        record.isFixedBTP = false;
                    }
                    record.L2btpPrice = 0;
                    record.cusBtpPrice = 0;
                    record.margin = 0;
                    record.discount = 0;

                    let getSettingValue = '';

                    for (var key in wrp) {
                        if (key == record.Product_L3__r.Name) {
                            var wrpprds = wrp[key];

                            console.log('record till here', record);
                            record.QuotelineId = wrpprds.QuotelineId;
                            console.log("AK customQuantity", wrpprds.customQuantity);
                            record.customQuantity = wrpprds.customQuantity;

                            // AK 19/12/22 Changes
                            if (record.customQuantity > 0) {
                                record.inputDisable = false;
                            }

                            getSettingValue = wrpprds.setType;

                            let ProType = record.Product_L3__r.Product_Type__c;
                            let isFG = false;
                            if (ProType && ProType.slice(0, 2) == 'FG') {
                                isFG = true;

                            }

                            if (wrpprds.btpPrice == 0) {
                                record.btpPrice = isFG ? Math.ceil(wrpprds.L2btpPrice) : wrpprds.L2btpPrice;
                            } else {
                                record.btpPrice = isFG ? Math.ceil(wrpprds.btpPrice) : wrpprds.btpPrice;
                            }
                            record.cusBtpPrice = wrpprds.cusBtpPrice;
                            record.L2btpPrice = wrpprds.L2btpPrice;
                            record.margin = wrpprds.margin;
                            record.discount = wrpprds.discount;
                            console.log('subham lastsales price::: ', record.mySalesPrice)
                            if (wrpprds.salesPrice == 0) {
                                record.mySalesPrice = isFG ? Math.ceil(wrpprds.L2btpPrice) : wrpprds.L2btpPrice;

                                console.log('subham lastsales price in if::: ', record.mySalesPrice)
                            }

                            if (record.isFixedBTP && fixedPrice[record.Product_L3__c]) {
                                record.mySalesPrice = isFG ? Math.ceil(fixedPrice[record.Product_L3__c]) : fixedPrice[record.Product_L3__c];

                                console.log('subham lastsales price in iffixed BTP::: ', record.mySalesPrice)

                            } else {
                                record.mySalesPrice = isFG ? Math.ceil(wrpprds.salesPrice) : wrpprds.salesPrice;

                                console.log('subham lastsales price in else::: ', record.mySalesPrice)
                            }

                            record.level2customQuantity = wrpprds.level2customQuantity;

                            console.log('record till here2', record);
                        }
                    }

                    //subham -- check id already full set
                    if (getSettingValue == 'fullset') {
                        component.set('v.fullSet', true)

                    }
                    component.set('v.settingState', getSettingValue)

                    console.log('getSettingValue111::: ', getSettingValue)

                    let lastSPrice = 0
                    let lastSPrice2 = 0
                    if (sapPriceMap[record.Product_L3__c]) {
                        lastSPrice = (sapPriceMap[record.Product_L3__c]);      // INCREMENTED VALUE
                        lastSPrice2 = (sapPriceMap2[record.Product_L3__c]);      //ORIGINAL VALUE
                        //lastSPriceNew = (sapPriceMap[record.Product_L3__c] );
                        record.isLLP = true;


                    }


                    if (sapDateMap[record.Product_L3__c]) {
                        record.SAP_Date = sapDateMap[record.Product_L3__c];
                    }

                    let ProType2 = record.Product_L3__r.Product_Type__c;
                    if (ProType2 && ProType2.slice(0, 2) == 'FG') {
                        record.SAP_Price = Math.ceil(lastSPrice);
                        record.SAP_Price2 = Math.ceil(lastSPrice2);
                    } else {
                        record.SAP_Price = lastSPrice;
                        record.SAP_Price2 = lastSPrice2;
                    }

                    record.SAP_Price_Incremented = lastSPrice;  // Store incremented value
                    if (ProType2 && ProType2.slice(0, 2) == 'FG') {
                        record.SAP_Price_Incremented = Math.ceil(lastSPrice);
                    }


                    // Apply WOS factor to SAP_Price_Incremented same as displaySapPrice
                    // let incrementedSapPrice = lastSPrice;
                    // if (record.isWos && record.isDirectCustomer !== true && incrementedSapPrice > 0) {
                    //     incrementedSapPrice = incrementedSapPrice / 0.75;
                    // }
                    // if (ProType2 && ProType2.slice(0, 2) == 'FG') {
                    //     record.SAP_Price_Incremented = Math.ceil(incrementedSapPrice);
                    // } else {
                    //     record.SAP_Price_Incremented = incrementedSapPrice;
                    // }

                    /// end logic for WOS factor on incremented SAP price

                    record.SAP_PriceOld = Math.ceil(sapPriceMap[record.Product_L3__c]);
                    record.customQuantityValues = new Map(Object.entries(JSON.parse(JSON.stringify(quantityMapRecord))));
                    record.level2CustomQuantityValues = new Map(Object.entries(JSON.parse(JSON.stringify(quantityMapRecord))));

                    if (record.btpPrice == 0 || record.btpPrice == undefined) {
                        if (record.SAP_Price > 0) {
                            let ProType = record.Product_L3__r.Product_Type__c;
                            let isFG = (ProType && ProType.slice(0, 2) == 'FG');


                            console.log('btp under first 1')

                            if (isFG) {
                                console.log('subham isFG:: btp before', record.btpPrice)
                                record.btpPrice = Math.ceil(record.SAP_Price);
                                console.log('subham isFG:: btp after', record.btpPrice)

                                record.mySalesPrice = Math.ceil(record.SAP_Price);

                                console.log('line 774:: ', record.mySalesPrice)
                                //record.mySalesPrice = isSapCurrencyMismatch ? 0 : Math.ceil(record.SAP_Price); //new 


                                // if(!record.isFixedBTP) { // product is NOT fixed price
                                //     if(record.SAP_Price > record.btpPrice) {
                                //         console.log('SAP Override Applied for: ' + record.Product_L3__r.Name);
                                //         // FG → round SAP price | Non-FG → keep value
                                //         record.mySalesPrice = Math.ceil(record.SAP_Price) ;
                                //     }
                                // }
                                console.log('Setting initial BTP from SAP_Price (FG rounded): ' + record.SAP_Price);
                            } else {
                                console.log('subham isNotFG:: btp before', record.btpPrice)
                                record.btpPrice = record.SAP_Price;
                                console.log('subham isNotFG:: btp before', record.btpPrice)
                                record.mySalesPrice = record.SAP_Price;
                                //record.mySalesPrice = isSapCurrencyMismatch ? 0 : record.SAP_Price;
                                // if(!record.isFixedBTP) { // product is NOT fixed price
                                //     if(record.SAP_Price > record.btpPrice) {
                                //         console.log('SAP Override Applied for: ' + record.Product_L3__r.Name);
                                //         // FG → round SAP price | Non-FG → keep value
                                //         record.mySalesPrice =  record.SAP_Price;
                                //     }
                                // }
                                console.log('Setting initial BTP from SAP_Price (non-FG): ' + record.SAP_Price);
                            }
                        }
                    }

                    //new logic added by ranjeet for btp>last sap price

                    // if(!record.isFixedBTP) { // product is NOT fixed price
                    //     if(record.SAP_Price > record.btpPrice) {
                    //         console.log('SAP Override Applied for: ' + record.Product_L3__r.Name);

                    //         let ProTypeSAP = record.Product_L3__r.Product_Type__c;
                    //         let isFGSAP = (ProTypeSAP && ProTypeSAP.slice(0,2) == 'FG');

                    //         // FG → round SAP price | Non-FG → keep value
                    //         record.mySalesPrice = isFGSAP ? Math.ceil(record.SAP_Price) : record.SAP_Price;
                    //     }
                    // }
                    //end here


                    // let ProType = record.Product_L3__r.Product_Type__c;
                    // if(ProType && ProType.slice(0,2) == 'FG'){
                    //     record.SAP_Price = Math.ceil(lastSPrice2);
                    // }
                    // else {
                    //     record.SAP_Price = lastSPrice2;
                    // }

                    // Code for Wos //

                    let displaySapPrice = lastSPrice2;
                    if (record.isWos && record.isDirectCustomer !== true && displaySapPrice > 0) {
                        displaySapPrice = displaySapPrice / 0.75;
                    }
                    // CODE ADDED FOR ISWOS 

                    // code backup
                    let ProType = record.Product_L3__r.Product_Type__c;
                    if(ProType && ProType.slice(0,2) == 'FG'){
                       // record.SAP_Price = Math.ceil(lastSPrice2);  // Set to ORIGINAL value // BEFORE ISWOS 
                       record.SAP_Price = Math.ceil(displaySapPrice);
                        // Update mySalesPrice with INCREMENTED value if not fixed BTP
                        if(!record.isFixedBTP && record.SAP_Price_Incremented > 0) {
                            record.mySalesPrice = Math.ceil(record.SAP_Price_Incremented);
                        }
                    } else {
                        //record.SAP_Price = lastSPrice2;  // Set to ORIGINAL value // BEFORE ISWOS 
                        record.SAP_Price = displaySapPrice;
                        // Update mySalesPrice with INCREMENTED value if not fixed BTP
                        if(!record.isFixedBTP && record.SAP_Price_Incremented > 0) {
                            record.mySalesPrice = record.SAP_Price_Incremented;
                        }
                    }
                    // code backup end

                    //NEW
                    // let ProType = record.Product_L3__r.Product_Type__c;

                    // console.log('displayprice--::: --> ', displaySapPrice, ' -- ', record.mySalesPrice)

                    // if (!record.QuotelineId) {
                    //     if (ProType && ProType.slice(0, 2) == 'FG') {
                    //         record.SAP_Price = Math.ceil(displaySapPrice);
                    //         if (!record.isFixedBTP && record.SAP_Price_Incremented > 0) {
                    //             record.mySalesPrice = Math.ceil(record.SAP_Price_Incremented) / 0.75;
                    //         }
                    //     } else {
                    //         record.SAP_Price = displaySapPrice;
                    //         if (!record.isFixedBTP && record.SAP_Price_Incremented > 0) {
                    //             record.mySalesPrice = record.SAP_Price_Incremented / 0.75;
                    //         }
                    //     }
                    // } else {
                    //     if (ProType && ProType.slice(0, 2) == 'FG') {
                    //         record.SAP_Price = Math.ceil(displaySapPrice);
                    //     } else {
                    //         record.SAP_Price = displaySapPrice;
                    //     }
                    // }

                    // console.log('displayprice2--::: --> ', displaySapPrice, ' -- ', record.mySalesPrice)

                    //NEW END
                    console.log('record.SAP_Price::: --> ', record.SAP_Price, ' -- ', record.mySalesPrice)
                    console.log('record record.SAP_Price_Incremented--> ', record.SAP_Price_Incremented);



                    console.log('top record::: ', record, "  -- ", record.mySalesPrice)


                    if (uniqueL3.has(record.Product_L3__r.Name)) {
                        continue;
                        console.log('if record::: ', record)
                    }
                    else {
                        console.log('else record::: ', record)
                        uniqueL3.add(record.Product_L3__r.Name);
                        console.log('else record::: ', record)
                        uniqueRecords.push(record);
                    }
                }

                console.log("unique rec => ", uniqueRecords);
                component.set('v.record', total);
                var headers = [];
                const iterator1 = productHeaders.values();
                let isFSet = component.get("v.fullSet");
                console.log('productHeaders.size => ' + productHeaders.size);


                let settingState = component.get('v.settingState')
                console.log('getSettingValue222::: ', settingState)

                for (var i = 0; i < productHeaders.size; i++) {
                    var header = new Object();
                    header.Name = iterator1.next().value;
                    header.isSelected = false;

                    if (settingState == 'fullset') {
                        header.isSelected = true;
                    }
                    else if (settingState.includes(header.Name)) {
                        header.isSelected = true;
                    }

                    for (var j = 0; j < l1l2.length; j++) {
                        if (l1l2[j].Product_Description__c != undefined && l1l2[j].Product_Description__c.includes(header.Name)) {
                            header.value = l1l2[j].Quantity__c;
                            // header.isSelected = true;

                        }

                    }
                    headers.push(header);
                }


                component.set('v.headers', headers);


                // Set records so calculateFreshBTPForAllProducts can access them
                component.set('v.recordspartlist', recordsFromServer);

                console.log('subham records: ---> ', uniqueRecords);
                component.set('v.records', uniqueRecords);

                helper.applySorting(component, event, helper);


                component.set('v.headersName', productHeaders);
                component.set('v.L2ProductMap', l2Mapupdate);

                if (recordsFromServer != '' || recordsFromServer.length > 0) {
                    component.set('v.partlistnumber', false);
                    component.set('v.searchTable', false);
                }



                // DON'T calculate totals here - let calculateFreshBTPForAllProducts do it
                // DON'T hide spinner here - let calculateFreshBTPForAllProducts do it

                // This function will:
                // 1. Fetch fresh BTP for all products
                // 2. Calculate totals (totalBTPCalculate, totalSalesPriceCalculate)
                // 3. Apply sorting
                // 4. Hide the spinner when done

                component.set("v.firstTimeBoot", true);
                

                helper.calculateFreshBTPForAllProducts(component, event, helper);

                
//  component.set("v.isLoad", false);

                // Everything below this point is handled by calculateFreshBTPForAllProducts

            } else if (state === "ERROR") {
                component.set("v.isLoad", false);
                var errors = response.getError();
                console.error(errors);
            }
        });
        $A.enqueueAction(action);
    },
    //old working code
    calculateFreshBTPForAllProducts: function (component, event, helper) {


        var records = component.get("v.records");

        // Build productQuantity map for ALL products
        var productQuantity = {};
        for (var record of records) {
            let total = 0;
            let l2Quan = 0;
            let custQuan = 0;

            if (!isNaN(record.level2customQuantity))
                l2Quan = Number(record.level2customQuantity);
            if (!isNaN(record.customQuantity))
                custQuan = Number(record.customQuantity);

            total = l2Quan + custQuan;
            productQuantity[record.Product_L3__c] = total;
        }


        // Array to hold all BTP fetch promises
        var fetchPromises = [];

        // Loop through all records and fetch BTP for those with quantity > 0
        for (var i = 0; i < records.length; i++) {
            let total = 0;

            if (!isNaN(records[i].level2customQuantity))
                total += Number(records[i].level2customQuantity);
            if (!isNaN(records[i].customQuantity))
                total += Number(records[i].customQuantity);

            //subham 
            if (total > 0 || true) {


                // Call fetchBTPPrice for this record
                var promise = helper.fetchBTPPrice(
                    component,
                    i,
                    total,  // Use total quantity (L2 + custom)
                    false,  // Not custom-only
                    false,  // Not L2-only
                    productQuantity
                );

                fetchPromises.push(promise);
            }
        }

        // Wait for all BTP calculations to complete
        //     Promise.all(fetchPromises).then(function (results) {
        //         console.log('✅ All BTP calculations completed');

        //         // Recalculate totals
        //         helper.totalBTPCalculate(component, event, helper);
        //         helper.totalSalesPriceCalculate(component, event, helper);



        //         // Apply sorting
        //         helper.applySorting(component, event, helper);

        //         // Hide spinner
        //         component.set("v.isLoad", false);

        //     }).catch(function (error) {
        //         console.error('❌ Error calculating BTP:', error);
        //         component.set("v.isLoad", false);
        //         helper.showToast("Error", "Error", "Failed to calculate BTP prices");
        //     });
        // },

        Promise.all(fetchPromises).then(function (results) {
            console.log('✅ All BTP calculations completed');

            // ── NEW: Mark zero-BTP records with inline error + banner ──────
            var records = component.get("v.records");
            var zeroBTPProducts = [];

            for (var i = 0; i < records.length; i++) {
                var rec = records[i];

                if (!(parseFloat(rec.btpPrice) > 0)) {
                    records[i].error = "BTP is zero. Please resolve before saving.";
                    zeroBTPProducts.push(rec.Product_L3__r.Name);
                } else {
                    records[i].error = '';
                }
            }

            component.set("v.records", records);

            // Set or clear the banner message
            if (zeroBTPProducts.length > 0) {
                component.set("v.zeroBTPError",
                    "BTP is zero for: " + zeroBTPProducts.join(", ") + ". Please contact PMG."
                );
            } else {
                component.set("v.zeroBTPError", "");
            }
            // ── END NEW ──────────────────────────────────────────────────

            // Recalculate totals
            helper.totalBTPCalculate(component, event, helper);


            console.log('before freshBtp -->', component.get("v.totalSalesPrice"))

            let isfirstboot = component.get("v.firstTimeBoot");
            console.log('isfirstboot--> ', isfirstboot)
            if(isfirstboot == false){
                helper.totalSalesPriceCalculate(component, event, helper);
            }
            console.log('after freshBtp -->>', component.get("v.totalSalesPrice"))
component.set("v.firstTimeBoot", false);
            // Apply sorting
            helper.applySorting(component, event, helper);

            // Hide spinner
            component.set("v.isLoad", false);

        }).catch(function (error) {
            console.error('❌ Error calculating BTP:', error);
            component.set("v.isLoad", false);
            helper.showToast("Error", "Error", "Failed to calculate BTP prices");
        });
    },

    /* caluculateCustomQuantity: function (component, event, helper) {
         var records = component.get('v.records');
         let i = 0;
         for (var record of records) {
             let total = 0;
             for (var key of record.customQuantityValues.keys()) {
                 total += record.customQuantityValues.get(key) ? record.customQuantityValues.get(key) : 0;
             }
             record.customQuantity = total;
             //helper.fetchBTPPrice(component, i);
             helper.fetchBTPPrice(component, i, total, true, false).then(function (result) {
                 helper.totalBTPCalculate(component, event, helper);
                 helper.totalSalesPriceCalculate(component, event, helper);
             }).catch(err => {
                 console.log('err-->>' + err);
                 helper.showToast("Error", "Error", "Something went wrong. Contact your adim.");
             });
             i++;
         }
         component.set('v.records', records);
 
     },*/

    caluculateLevel2CustomQuantity: function (component, event, helper, isLast) {
        console.log('caluculateLevel2CustomQuantity is method calling')
        var records = component.get('v.records');
        console.log('records**', JSON.stringify(records));
        let i = 0;
        let L3ProdQtyMap = component.get("v.L3ProductQty");
        console.log('L3ProdQty');
        console.log(JSON.stringify(L3ProdQtyMap));
        var productQuantity = {};
        for (var record of records) {
            console.log('Check- i->>>' + i);
            let total = 0;

            var headers = component.get("v.headers");
            console.log('headers', headers);

            for (var header of headers) {
                if (header.isSelected === true) {
                    let key = record.Product_L3__c + header.Name;
                    console.log('key-->' + key);
                    console.log('qty MAP-->' + L3ProdQtyMap[key]);
                    let pQty = L3ProdQtyMap[key];
                    console.log('pQty-->>' + pQty);
                    if (pQty != undefined && pQty != '') {
                        console.log('--headervalue---' + header.value);
                        total += header.value * pQty;
                    }

                }
            }
            if (total > 0) {
                records[i].level2customQuantity = total;
            }
            else {
                records[i].level2customQuantity = 0;
            }
            productQuantity[records[i].Product_L3__c] = Number(total) + Number(records[i].customQuantity);
            i++;
        }

        console.log('before last v.records ', JSON.stringify(records));
        component.set("v.records", records);

        if (isLast) {
            console.log(productQuantity);
            console.log(' above product quantity');
            var records = component.get('v.records');
            let count = 0;
            for (var record of records) {
                let total = 0;

                total = total + Number(record.level2customQuantity) + Number(record.customQuantity);
                console.log('----total--quantity' + total);
                if (total > 0) {
                    // Added by Kuhinoor
                    helper.fetchBTPPrice(component, count, record.level2customQuantity, false, true, productQuantity).then(function (result) {
                        helper.totalBTPCalculate(component, event, helper);

                        console.log('before level 2 --', component.get("v.totalSalesPrice"))

                        helper.totalSalesPriceCalculate(component, event, helper);

                        console.log('after freshBtp --', component.get("v.totalSalesPrice"))

                        // console.log('before freshBtp --', component.get("v.totalSalesPrice"))


                    }).catch(err => {
                        console.log('err-->>' + err);
                        helper.showToast("Error", "Error", "Something went wrong. Contact your adim.");
                    });

                } else {
                    records[count].L2btpPrice = 0;
                    console.log('customQuantity-->>>' + records[count].customQuantity);
                    /*if(parseFloat(records[count].customQuantity) === 0){
                        records[count].SAP_Price = 0;
                        records[count].mySalesPrice = 0;
                    }*/
                    helper.priceRecalculation(component, event, helper);
                }
                //END Here...
                count++;
            }
            console.log('caluculateLevel2CustomQuantity method records ', records);
            component.set("v.records", records);
            window.setTimeout(function () {
                helper.applySorting(component, event, helper);
            }, 200);
        }


    },

    priceRecalculation: function (component, event, helper) {

        var records = component.get('v.records');
        for (var record of records) {
            let tBtp = 0;

            //if(record.customQuantity > 0 && record.SAP_Price >= record.cusBtpPrice){

            if (record.customQuantity > 0 && record.SAP_Price >= record.cusBtpPrice) {
                record.btpPrice = record.SAP_Price;
                tBtp = record.SAP_Price;
            } else if (record.customQuantity > 0) {
                record.btpPrice = record.cusBtpPrice;
                tBtp = record.cusBtpPrice;
            } else {
                //record.btpPrice = 0;
                if (record.isLLP === false) {
                    record.SAP_Price = 0;
                }
            }

            /*
            if(record.SAP_Price > record.cusBtpPrice){
                record.btpPrice = record.SAP_Price;
                tBtp =  record.SAP_Price;
            }
            else
            {
                record.btpPrice = record.cusBtpPrice;
                tBtp =  record.cusBtpPrice;
            } */

            let discount = 0;
            let margin = 0;
            margin = (tBtp * record.margin) / 100;
            if (record.discount > 0) {
                discount = (tBtp * record.discount) / 100;
            }

            // AK Fix 5 sep 2022
            record.mySalesPrice = parseFloat(tBtp) + parseFloat(margin);

            // record.mySalesPrice = record.mySalesPrice - discount;




        }
        component.set("v.records", records);
        helper.totalBTPCalculate(component, event, helper);

        console.log('before freshRecal --', component.get("v.totalSalesPrice"))
        helper.totalSalesPriceCalculate(component, event, helper);
        console.log('after freshRecal --', component.get("v.totalSalesPrice"))
        helper.applySorting(component, event, helper);
    },


    onChangeFullSet: function (component, event, helper, isFromCheckBox) {
        var fullset = component.get('v.fullSet');
        let isLast = false;
        //       var quantity = event.target.checked ? component.get('v.fullSetQuantity') : 0;//isFromCheckBox !== undefined && !isFromCheckBox ?  0 : 1;
        var quantity = isFromCheckBox !== undefined && !isFromCheckBox ? event.currentTarget.value : 1;

        component.set('v.fullSetQuantity', quantity);
        var records = component.get('v.records');
        console.log('fullset' + fullset);
        var headers = component.get('v.headers');
        //  var value = event.currentTarget.value;
        //var header = event.currentTarget.dataset.header;
        let iterations = headers.length;
        for (var record of headers) {
            //if (record.isSelected == fullset) {
            if (fullset === true) {
                record.value = quantity;
                record.isSelected = true;
                component.set('v.isButtonActive', true);
            } else {
                record.value = 0;
                record.isSelected = false;
                component.set('v.fullSetQuantity', 0);
                component.set('v.isButtonActive', false);

            }
            if (fullset === true) {
                if (!(--iterations)) {
                    isLast = true;
                }
                console.log('===is Last 3' + isLast);
                helper.calculateRecordCustomQuantity(component, event, helper, quantity, record.Name, isLast);

            } else {
                console.log('INSIDE ELSE FULLSET')
                helper.clearFullSet(component, event, helper);
            }


        }
        component.set('v.headers', headers);

    },




    clearFullSet: function (component, event, helper) {
        var records = component.get('v.records');
        let i = 0;
        for (let key of records) {
            records[i].L2btpPrice = 0;
            //records[i].btpPrice = 0;
            records[i].cusBtpPrice = 0;
            records[i].level2customQuantity = 0
            records[i].customQuantity = 0
            //records[i].mySalesPrice = 0;
            records[i].productquantities = 0;

            i++;
        }
        component.set('v.records', records);
    },

    calculateRecordCustomQuantity: function (component, event, helper, value, header, isLast, quantity) {
        console.log('is method caling calculateRecordCustomQuantity')
        var records = component.get('v.records');

        console.log('REcords :', records);
        console.log(header);
        console.log(value);
        //console.log(quantity);
        for (var record of records) {
            let valueToupdate = record.quantityMapRecord.has(header) ? record.quantityMapRecord.get(header) * value : 0;
            console.log('value to update', valueToupdate);
            record.level2CustomQuantityValues.set(header, valueToupdate);
            record.level2customQuantity = valueToupdate;
        }
        // helper.caluculateLevel2CustomQuantity(component, event, helper, records);
        helper.caluculateLevel2CustomQuantity(component, event, helper, isLast);
        console.log("expected last l2 change records ", records);

    },

    changeCustomQty: function (component, event, helper) {
        var selectedIndx = event.target.dataset.index;
        console.log('selectedIndx---' + selectedIndx)
        var records = component.get("v.records");
        console.log('changeCustomQty rec ', records);

        console.log('records after changing quantity => ', JSON.stringify(records, null, 2));

        // commented by Kuhnoor b/c this func. changes...we have to keep header if there are custom qty aslo
        // so no need to disable header on the input of custom qty.
        // var headers = component.get("v.headers");
        // for(var header of headers){
        //     header.isSelected = false;
        // }
        //component.set("v.headers", headers);
        console.log('record index---' + records[selectedIndx]);
        let qty = records[selectedIndx].customQuantity;
        console.log('qty-------' + qty)
        console.log('---' + records[selectedIndx].level2customQuantity)
        //component.set("v.records", records);
        var records = component.get('v.records');
        console.log("records at cstm qty change", records);
        var productQuantity = {};
        for (var record of records) {
            let total = 0;
            let count = 0;
            let l2Quan = 0;
            let custQuan = 0;
            if (!isNaN(record.level2customQuantity))
                l2Quan = Number(record.level2customQuantity);
            if (!isNaN(record.customQuantity))
                custQuan = Number(record.customQuantity);
            total = total + l2Quan + custQuan;
            productQuantity[record.Product_L3__c] = total;
        }
        console.log(productQuantity);
        console.log(' above product quantity');
        // helper.fetchBTPPrice(component, selectedIndx, qty, true, false, productQuantity).then(function (result) {
        //     helper.totalBTPCalculate(component, event, helper);
        //     helper.totalSalesPriceCalculate(component, event, helper);
        //     helper.applySorting(component, event, helper);
        // });
        helper.totalBTPCalculate(component, event, helper);
        console.log('before custom quantity --', component.get("v.totalSalesPrice"))
        helper.totalSalesPriceCalculate(component, event, helper);
        console.log('after quantity --', component.get("v.totalSalesPrice"))
        // component.set("v.records", records);


    },
    //new
    fetchBTPPrice: function (component, i, qty, isCustom, isL2, productQuantity) {
        component.set("v.isLoad", true);
        var offerId = component.get("v.recordId");
        var records = component.get("v.records");
        console.log('AK 1 Dec inside fetchPrice');
        console.log(JSON.stringify(records[i]));

        let isWos = component.get("v.wos");
        let prodId = records[i].Product_L3__c;
        let isFG = false;
        let ProType = records[i].Product_L3__r.Product_Type__c;
        if (ProType && ProType.slice(0, 2) == 'FG') {
            isFG = true;
        }
        let isfixBTP = records[i].isFixedBTP;
        let l2BTPPriceMap = new Map();

        console.log('Subham 1319 btp')
        //Subham true
        if (qty > 0 || true) {
            return new Promise(
                $A.getCallback(function (resolve, reject) {
                    var action = component.get("c.getBTPPrice");
                    console.log('subham action 1339::: ', action)
                    action.setParams({
                        offerId: offerId,
                        productId: prodId,
                        itemQty: qty,
                        productQuantity: productQuantity,
                        btpMap: component.get("v.BTPMap")
                    });
                    action.setCallback(this, function (response) {
                        var result = response.getReturnValue();
                        var state = response.getState();

                        if (state === "SUCCESS") {
                            var btpFromApex = result.btpPrice;
                            console.log('subham btpFromApex 1339::: ', btpFromApex)
                            // USE THE BTP VALUE DIRECTLY FROM APEX - NO OVERRIDES
                            if (isfixBTP === false) {
                                component.set("v.isLoad", false);

                                records[i].error = result.errMsg;

                                // AK 02/12/22 Changes
                                records[i].RMCCost = result.RMCCost;
                                records[i].branchRateOfInterest = result.branchRateOfInterest;
                                records[i].offerpayment = result.offerpayment;
                                records[i].branchHedging = result.branchHedging;
                                records[i].basicPrice = result.basicPrice;
                                records[i].costPackingForwarding = result.costPackingForwarding;
                                records[i].CostFreight = result.CostFreight;
                                records[i].costInsurance = result.costInsurance;
                                records[i].costInterest = result.costInterest;
                                records[i].costHedging = result.costHedging;
                                records[i].exchangeRate = result.exchangeRate;

                                if (result.errMsg === '' || result.errMsg == undefined) {
                                    if (records[i].customQuantity > 0) {
                                        // Round up ONLY for FG products
                                        records[i].cusBtpPrice = isFG ? Math.ceil(btpFromApex) : btpFromApex;
                                    }

                                    if (records[i].level2customQuantity > 0) {
                                        if (!l2BTPPriceMap.has(prodId)) {
                                            l2BTPPriceMap.set(prodId, btpFromApex);
                                        } else {
                                            let fPrice = l2BTPPriceMap.get(prodId) + btpFromApex;
                                            l2BTPPriceMap.set(prodId, fPrice);
                                        }
                                        records[i].L2btpPrice = l2BTPPriceMap.get(prodId);
                                    }

                                    // Round up ONLY for FG products
                                    // records[i].btpPrice = isFG ? Math.ceil(btpFromApex) : btpFromApex;
                                    // records[i].mySalesPrice = isFG ? Math.ceil(btpFromApex) : btpFromApex;

                                    // // Ranjeet:Check if SAP Price > BTP, then use SAP_Price for Fixed BTP False product 
                                    // if(records[i].SAP_Price > 0 && records[i].SAP_Price > records[i].btpPrice) {
                                    //     console.log('SAP Override in fetchBTP for: ' + records[i].Product_L3__r.Name);
                                    //     records[i].mySalesPrice = isFG ? Math.ceil(records[i].SAP_Price) : records[i].SAP_Price;
                                    // }

                                    // Round up ONLY for FG products
                                    // NEW
                                    // records[i].btpPrice = isFG ? Math.ceil(btpFromApex) : btpFromApex;

                                    // var isUpdate = component.get("v.isUpdate");
                                    // if (isUpdate === true && records[i].QuotelineId) {
                                    //     // Saved record — recalculate mySalesPrice using stored margin
                                    //     var savedMargin = records[i].margin || 0;
                                    //     var baseForMargin = parseFloat(records[i].btpPrice) || 0;
                                    //     var marginAmt = (baseForMargin * parseFloat(savedMargin)) / 100;
                                    //     var recalcSalesPrice = baseForMargin + marginAmt;
                                    //     records[i].mySalesPrice = isFG ? Math.ceil(recalcSalesPrice) : recalcSalesPrice;
                                    // } else {
                                    //     // Fresh/new record — set mySalesPrice from BTP
                                    //     records[i].mySalesPrice = isFG ? Math.ceil(btpFromApex) : btpFromApex;

                                    //     // Check if SAP Price > BTP, then use SAP_Price
                                    //     if(records[i].SAP_Price > 0 && records[i].SAP_Price > records[i].btpPrice) {
                                    //         console.log('SAP Override in fetchBTP for: ' + records[i].Product_L3__r.Name);
                                    //         records[i].mySalesPrice = isFG ? Math.ceil(records[i].SAP_Price) : records[i].SAP_Price;
                                    //     }
                                    // }


                                    records[i].btpPrice = isFG ? Math.ceil(btpFromApex) : btpFromApex;

                                    var isUpdate = component.get("v.isUpdate");
                                    if (isUpdate === true && records[i].QuotelineId) {

                                        var savedMargin = records[i].margin || 0;


                                        var btp = parseFloat(records[i].btpPrice) || 0;
                                        var sap = parseFloat(records[i].SAP_Price) || 0;
                                        var baseForMargin = (sap > 0 && sap > btp) ? sap : btp;

                                        var marginAmt = (baseForMargin * parseFloat(savedMargin)) / 100;
                                        var recalcSalesPrice = baseForMargin + marginAmt;
                                        records[i].mySalesPrice = isFG ? Math.ceil(recalcSalesPrice) : recalcSalesPrice;



                                    } else {

                                        var btp = parseFloat(records[i].btpPrice) || 0;
                                        var sap = parseFloat(records[i].SAP_Price) || 0;


                                        var basePrice = (sap > 0 && sap > btp) ? sap : btp;
                                        records[i].mySalesPrice = isFG ? Math.ceil(basePrice) : basePrice;

                                       
                                    }




                                    //OLD MARGIN LOGIC
                                    // if (result.btpPrice > 0) {
                                    //     records[i].inputDisable = false;
                                    //     records[i].margin = 0;
                                    //     records[i].discount = 0;
                                    //     component.set("v.allMarginDisc", false);
                                    // }
                                    //OLD Margin LOGIC END

                                    // New Margin Logic
                                    if (result.btpPrice > 0) {
                                        records[i].inputDisable = false;
                                        // Only reset margin and discount if they are not already set
                                        // (i.e. this is a fresh load, not an update load)
                                        var isUpdate = component.get("v.isUpdate");
                                        if (isUpdate !== true) {
                                            records[i].margin = 0;
                                            records[i].discount = 0;
                                        }
                                        component.set("v.allMarginDisc", false);
                                    }
                                    //new margin logic end
                                }

                            } else if (isfixBTP === true) {

                                // For fixed BTP, still use the calculated value
                                records[i].RMCCost = result.RMCCost;
                                records[i].branchRateOfInterest = result.branchRateOfInterest;
                                records[i].offerpayment = result.offerpayment;
                                records[i].branchHedging = result.branchHedging;
                                records[i].basicPrice = result.basicPrice;
                                records[i].costPackingForwarding = result.costPackingForwarding;
                                records[i].CostFreight = result.CostFreight;
                                records[i].costInsurance = result.costInsurance;
                                records[i].costInterest = result.costInterest;
                                records[i].costHedging = result.costHedging;
                                records[i].exchangeRate = result.exchangeRate;

                                // Round up ONLY for FG products
                                records[i].btpPrice = isFG ? Math.ceil(btpFromApex) : btpFromApex;

                                let fixedPriceMap = component.get("v.fixedPriceMap");
                                console.log('Fixed price in Fetch BTP', JSON.stringify(fixedPriceMap));
                                let prodId = records[i].Product_L3__c;

                                if (fixedPriceMap[prodId]) {
                                    let fPrice = fixedPriceMap[prodId];
                                    // Round up ONLY for FG products
                                    records[i].mySalesPrice = isFG ? Math.ceil(fPrice) : fPrice;
                                    console.log("Fixed Price Applied:", records[i].Product_L3__r.Name, "=>", fPrice);
                                } else {
                                    // fallback if not found in map
                                    // Round up ONLY for FG products
                                    records[i].mySalesPrice = isFG ? Math.ceil(btpFromApex) : btpFromApex;
                                }
                            }

                            component.set("v.records", records);
                            component.set("v.isLoad", false);

                            resolve(result);
                        } else if (state === "ERROR") {
                            component.set("v.isLoad", false);
                            var errors = response.getError();
                            console.error(errors);
                        }
                    });
                    $A.enqueueAction(action);
                })
            );
        } else {
            return new Promise(
                $A.getCallback(function (resolve, reject) {
                    records[i].error = '';
                    if (isCustom === true) {
                        records[i].customQuantity = 0;
                        records[i].cusBtpPrice = 0;
                    }
                    if (isL2 === true) {
                        records[i].level2customQuantity = 0;
                        records[i].L2btpPrice = 0;
                    }

                    component.set("v.records", records);
                    component.set("v.isLoad", false);
                    var result = {};
                    resolve(result);
                })
            );
        }
    },

    //old backup
    //     fetchBTPPrice: function (component, i, qty, isCustom, isL2, productQuantity) {
    //     component.set("v.isLoad", true);
    //     var offerId = component.get("v.recordId");
    //     var records = component.get("v.records");
    //     console.log('AK 1 Dec inside fetchPrice');
    //     console.log(JSON.stringify(records[i]));

    //     let isWos = component.get("v.wos");
    //     let prodId = records[i].Product_L3__c;
    //     let isFG = false;
    //     let ProType = records[i].Product_L3__r.Product_Type__c;
    //     if(ProType && ProType.slice(0,2) == 'FG'){
    //         isFG = true;
    //     }
    //     let isfixBTP = records[i].isFixedBTP;
    //     let l2BTPPriceMap = new Map();

    //     if (qty > 0) {
    //         return new Promise(
    //             $A.getCallback(function (resolve, reject) {
    //                 var action = component.get("c.getBTPPrice");
    //                 action.setParams({
    //                     offerId: offerId,
    //                     productId: prodId,
    //                     itemQty: qty,
    //                     productQuantity: productQuantity,
    //                     btpMap: component.get("v.BTPMap")                            
    //                 });
    //                 action.setCallback(this, function (response) {
    //                     var result = response.getReturnValue();
    //                     var state = response.getState();

    //                     if (state === "SUCCESS") {
    //                         var btpFromApex = result.btpPrice;

    //                         // USE THE BTP VALUE DIRECTLY FROM APEX - NO OVERRIDES
    //                         if(isfixBTP === false){
    //                             component.set("v.isLoad", false);
    //                             records[i].error = result.errMsg;

    //                             // AK 02/12/22 Changes
    //                             records[i].RMCCost = result.RMCCost;
    //                             records[i].branchRateOfInterest = result.branchRateOfInterest;
    //                             records[i].offerpayment = result.offerpayment;
    //                             records[i].branchHedging = result.branchHedging;
    //                             records[i].basicPrice = result.basicPrice;
    //                             records[i].costPackingForwarding = result.costPackingForwarding;
    //                             records[i].CostFreight = result.CostFreight;
    //                             records[i].costInsurance = result.costInsurance;
    //                             records[i].costInterest = result.costInterest;
    //                             records[i].costHedging = result.costHedging;
    //                             records[i].exchangeRate = result.exchangeRate;

    //                             if (result.errMsg === '' || result.errMsg == undefined) {
    //                                 if (records[i].customQuantity > 0) {
    //                                     records[i].cusBtpPrice = Math.ceil(btpFromApex);
    //                                 }

    //                                 if(records[i].level2customQuantity > 0){
    //                                     if(!l2BTPPriceMap.has(prodId)){
    //                                         l2BTPPriceMap.set(prodId, btpFromApex);
    //                                     } else {
    //                                         let fPrice = l2BTPPriceMap.get(prodId) + btpFromApex;
    //                                         l2BTPPriceMap.set(prodId, fPrice);
    //                                     }     
    //                                     records[i].L2btpPrice = l2BTPPriceMap.get(prodId);
    //                                 }

    //                                 // USE BTP FROM APEX DIRECTLY - NO OVERRIDES
    //                                 records[i].btpPrice = Math.ceil(btpFromApex);
    //                                 records[i].mySalesPrice = Math.ceil(btpFromApex);

    //                                 if (result.btpPrice > 0) {
    //                                     records[i].inputDisable = false;
    //                                     records[i].margin = 0;
    //                                     records[i].discount = 0;
    //                                     component.set("v.allMarginDisc", false);
    //                                 }
    //                             }

    //                         } else if(isfixBTP === true){
    //                             // For fixed BTP, still use the calculated value
    //                             records[i].RMCCost = result.RMCCost;
    //                             records[i].branchRateOfInterest = result.branchRateOfInterest;
    //                             records[i].offerpayment = result.offerpayment;
    //                             records[i].branchHedging = result.branchHedging;
    //                             records[i].basicPrice = result.basicPrice;
    //                             records[i].costPackingForwarding = result.costPackingForwarding;
    //                             records[i].CostFreight = result.CostFreight;
    //                             records[i].costInsurance = result.costInsurance;
    //                             records[i].costInterest = result.costInterest;
    //                             records[i].costHedging = result.costHedging;
    //                             records[i].exchangeRate = result.exchangeRate;

    //                             // Use BTP from Apex for fixed BTP as well
    //                             records[i].btpPrice = Math.ceil(btpFromApex);
    //                             //records[i].mySalesPrice = btpFromApex;

    //                             let fixedPriceMap = component.get("v.fixedPriceMap");
    //                             console.log('Fixed price in Fetch BTP',JSON.stringify(fixedPriceMap));
    //                             let prodId = records[i].Product_L3__c;



    //                             if (fixedPriceMap[prodId]) {
    //                                 let fPrice = fixedPriceMap[prodId];
    //                                 //records[i].btpPrice = fPrice;
    //                                 records[i].mySalesPrice = Math.ceil(fPrice);
    //                                 console.log("Fixed Price Applied:", records[i].Product_L3__r.Name, "=>", fPrice);
    //                             } else {
    //                                 // fallback if not found in map
    //                                 //records[i].btpPrice = btpFromApex;
    //                                 records[i].mySalesPrice = Math.ceil(btpFromApex);
    //                             }
    //                         }

    //                         component.set("v.records", records);
    //                         component.set("v.isLoad", false);
    //                         resolve(result);
    //                     } else if (state === "ERROR") {
    //                         component.set("v.isLoad", false);
    //                         var errors = response.getError();
    //                         console.error(errors);
    //                     }
    //                 });
    //                 $A.enqueueAction(action);
    //             })
    //         );
    //     } else {
    //         return new Promise(
    //             $A.getCallback(function (resolve, reject) {
    //                 records[i].error = '';
    //                 if (isCustom === true) {
    //                     records[i].customQuantity = 0;
    //                     records[i].cusBtpPrice = 0;
    //                 }
    //                 if (isL2 === true) {
    //                     records[i].level2customQuantity = 0;
    //                     records[i].L2btpPrice = 0;
    //                 }               

    //                 // records[i].btpPrice = 0;
    //                 // records[i].mySalesPrice = 0;
    //                 // records[i].margin = 0;
    //                 // records[i].discount = 0;

    //                 component.set("v.records", records);
    //                 component.set("v.isLoad", false);
    //                 var result = {};
    //                 resolve(result);
    //             })
    //         );
    //     }
    // },
    onMarginChange: function (component, event, helper) {
        var selectedIndx = event.target.dataset.index;
        var records = component.get("v.records");

        let margin = records[selectedIndx].margin;
        if (margin == '') margin = 0;
        let btpPrice = records[selectedIndx].btpPrice;
        let SAP_Price = records[selectedIndx].SAP_Price;
        console.log("SAP_Price in onMarginChange:", SAP_Price);

        // Check if FG product
        let ProType = records[selectedIndx].Product_L3__r.Product_Type__c;
        let isFG = false;
        if (ProType && ProType.slice(0, 2) == 'FG') {
            isFG = true;
        }

        // Determine base price for margin calculation
        var btp = parseFloat(btpPrice) || 0;
        var sap = parseFloat(SAP_Price) || 0;
        var basePrice = 0;

        if (records[selectedIndx].isFixedBTP === true) {
            basePrice = sap; // Fixed BTP always uses SAP_Price
        } else {
            basePrice = (sap > 0 && sap > btp) ? sap : btp; // use whichever is higher
        }

        let marginAmount = (basePrice * parseFloat(margin)) / 100;
        let salesPrice = basePrice + marginAmount;
        records[selectedIndx].mySalesPrice = isNaN(salesPrice) ? 0 : (isFG ? Math.ceil(salesPrice) : salesPrice);

        component.set("v.records", records);
        helper.totalBTPCalculate(component, event, helper);
        console.log('before MarginChnages --', component.get("v.totalSalesPrice"))
        helper.totalSalesPriceCalculate(component, event, helper);
        console.log('after MarginChnages --', component.get("v.totalSalesPrice"))
        helper.applySorting(component, event, helper);
        console.log('--rc1---' + component.get("v.totalSalesPrice"));
        console.log('--rc2---' + component.get("v.totalBTPPrice"));
    },
    onDiscountChange: function (component, event, helper) {
        component.set("v.isLoad", true);
        var selectedIndx = event.target.dataset.index;
        var records = component.get("v.records");
        let margin = records[selectedIndx].margin;
        let discount = records[selectedIndx].discount;
        if (discount == '') discount = 0;
        let btpPrice = records[selectedIndx].btpPrice;
        let marginAmount = (parseFloat(btpPrice) * parseFloat(margin)) / 100;
        let salesPrice = parseFloat(btpPrice) + parseInt(marginAmount);

        console.log('btpPrice-->>' + btpPrice);
        console.log('marginAmount-->>' + marginAmount);
        console.log('salesPrice-->>' + salesPrice);
        let discountedPrice = parseFloat(btpPrice) * parseFloat(discount) / 100;
        console.log('discountedPrice-->>' + discountedPrice);

        // Check if FG product
        let ProType = records[selectedIndx].Product_L3__r.Product_Type__c;
        let isFG = false;
        if (ProType && ProType.slice(0, 2) == 'FG') {
            isFG = true;
        }

        let finalPrice = salesPrice - discountedPrice;
        // Round up ONLY for FG products
        records[selectedIndx].mySalesPrice = isFG ? Math.ceil(finalPrice) : finalPrice.toFixed(2);

        component.set("v.records", records);
        console.log('before onDiscount --', component.get("v.totalSalesPrice"))
        helper.totalSalesPriceCalculate(component, event, helper);
        console.log('after onDiscount --', component.get("v.totalSalesPrice"))
        helper.applySorting(component, event, helper);
        component.set("v.isLoad", false);

    },




    //   allMarginChange: function (component, event, helper) {
    //       component.set("v.isLoad", true);
    //       let marginAllVal = component.get("v.marginAllVal");
    //       let records = component.get("v.records");
    //       console.log("records in allMarginChange ",records);
    //       for (let ele of records) {
    //           let ProType = ele.Product_L3__r.Product_Type__c;
    //           let isFG = false;
    //           if(ProType && ProType.slice(0,2) == 'FG'){
    //               isFG = true;
    //           }
    //           if (ele.btpPrice > 0) {
    //               if (ele.isFixedBTP == true){
    //                     ele.margin = marginAllVal != '' ? marginAllVal : 0;
    //                     let marginAmount = (parseFloat(ele.SAP_Price) * parseFloat(marginAllVal)) / 100;
    //                     let salesPrice = parseFloat(ele.SAP_Price) + parseFloat(marginAmount);
    //                     let discountPrice = salesPrice * parseFloat(ele.discount) / 100
    //                     let finalSalesPrice = salesPrice - discountPrice;
    //                     console.log('finalSalesPrice-->>' + finalSalesPrice);
    //                     // Round up ONLY for FG products
    //                     ele.mySalesPrice = isNaN(finalSalesPrice) ? 0 : (isFG ? Math.ceil(finalSalesPrice) : finalSalesPrice.toFixed(2));
    //               }
    //               else{
    //                     ele.margin = marginAllVal != '' ? marginAllVal : 0;
    //                     let marginAmount = (parseFloat(ele.btpPrice) * parseFloat(marginAllVal)) / 100;
    //                     let salesPrice = parseFloat(ele.btpPrice) + parseFloat(marginAmount);
    //                     let discountPrice = salesPrice * parseFloat(ele.discount) / 100
    //                     let finalSalesPrice = salesPrice - discountPrice;
    //                     console.log('finalSalesPrice-->>' + finalSalesPrice);
    //                     // Round up ONLY for FG products
    //                     ele.mySalesPrice = isNaN(finalSalesPrice) ? 0 : (isFG ? Math.ceil(finalSalesPrice) : finalSalesPrice.toFixed(2));
    //           }
    //         }
    //       }
    //       component.set("v.records", records);
    //       helper.totalSalesPriceCalculate(component, event, helper);
    //       helper.applySorting(component, event, helper);
    //       component.set("v.isLoad", false);
    //   },

    //     allMarginChange: function (component, event, helper) {
    //     component.set("v.isLoad", true);
    //     let marginAllVal = component.get("v.marginAllVal");
    //     if(marginAllVal == '' || marginAllVal == null || marginAllVal == undefined){
    //         marginAllVal = 0;
    //     }
    //     marginAllVal = parseFloat(marginAllVal);
    //     let records = component.get("v.records");
    //     //var isSapCurrMismatch = component.get("v.isSapCurrencyMismatch");
    //     console.log("marginAllVal in allMarginChange => ", marginAllVal);
    //     console.log("isSapCurrMismatch in allMarginChange => ", isSapCurrMismatch);

    //     for (var idx = 0; idx < records.length; idx++) {

    //         let ProType = records[idx].Product_L3__r.Product_Type__c;
    //         let isFG = false;
    //         if(ProType && ProType.slice(0,2) == 'FG'){
    //             isFG = true;
    //         }

    //         // Always use btpPrice as base for margin calculation
    //         // because btpPrice is the original base price before any margin
    //         let basePrice = 0;
    //         if(records[idx].isFixedBTP == true){
    //             basePrice = parseFloat(records[idx].SAP_Price) || 0;
    //         } else {
    //             basePrice = parseFloat(records[idx].btpPrice) || 0;
    //         }

    //         console.log('basePrice for ' + records[idx].Product_L3__r.Name + ' => ' + basePrice);

    //         if(basePrice > 0){
    //             // Directly update margin on existing record object
    //             records[idx].margin = marginAllVal;

    //             if(isSapCurrMismatch){
    //                 console.log('Currency mismatch - keeping mySalesPrice blank for: ' + records[idx].Product_L3__r.Name);
    //                 records[idx].mySalesPrice = 0;
    //             } else {
    //                 let marginAmount = (basePrice * marginAllVal) / 100;
    //                 let finalSalesPrice = basePrice + marginAmount;
    //                 console.log('finalSalesPrice for ' + records[idx].Product_L3__r.Name + ' => ' + finalSalesPrice);
    //                 records[idx].mySalesPrice = isNaN(finalSalesPrice) ? 0 : (isFG ? Math.ceil(finalSalesPrice) : parseFloat(finalSalesPrice.toFixed(2)));
    //             }
    //         }
    //     }

    //     // Force Aura to re-render by setting records again
    //     component.set("v.records", []);
    //     window.setTimeout($A.getCallback(function() {
    //         component.set("v.records", records);
    //         helper.totalSalesPriceCalculate(component, event, helper);
    //         helper.totalBTPCalculate(component, event, helper);
    //         component.set("v.isLoad", false);
    //     }), 50);
    // },

    // REPLACE THE ENTIRE allMarginChange FUNCTION WITH THIS:

    allMarginChange: function (component, event, helper) {
        component.set("v.isLoad", true);

        var marginAllVal = component.get("v.marginAllVal");
        if (marginAllVal === '' || marginAllVal === null || marginAllVal === undefined) {
            marginAllVal = 0;
        }
        marginAllVal = parseFloat(marginAllVal);
        if (isNaN(marginAllVal)) {
            marginAllVal = 0;
        }

        // ── FIX: read isSapCurrencyMismatch properly ──────────────────
        var isSapCurrMismatch = component.get("v.isSapCurrencyMismatch") || false;
        // ─────────────────────────────────────────────────────────────

        var records = component.get("v.records");

        if (!records || records.length === 0) {
            component.set("v.isLoad", false);
            return;
        }

        for (var idx = 0; idx < records.length; idx++) {
            var rec = records[idx];

            if (!rec.Product_L3__r) {
                continue;
            }

            var ProType = rec.Product_L3__r.Product_Type__c;
            var isFG = (ProType && ProType.slice(0, 2) === 'FG');

            // var basePrice = 0;
            // if (rec.isFixedBTP === true) {
            //     basePrice = parseFloat(rec.SAP_Price) || 0;
            // } else {
            //     basePrice = parseFloat(rec.btpPrice) || 0;
            // }

            var basePrice = 0;
            if (rec.isFixedBTP === true) {
                basePrice = parseFloat(rec.SAP_Price) || 0;
            } else {
                var btp = parseFloat(rec.btpPrice) || 0;
                var sap = parseFloat(rec.SAP_Price) || 0;
                basePrice = (sap > 0 && sap > btp) ? sap : btp; //  use whichever is higher
            }

            console.log('allMarginChange | product:', rec.Product_L3__r.Name,
                '| basePrice:', basePrice, '| margin:', marginAllVal);

            if (basePrice > 0) {
                records[idx].margin = marginAllVal;

                if (isSapCurrMismatch) {
                    records[idx].mySalesPrice = 0;
                } else {
                    var marginAmount = (basePrice * marginAllVal) / 100;
                    var finalSalesPrice = basePrice + marginAmount;
                    records[idx].mySalesPrice = isNaN(finalSalesPrice)
                        ? 0
                        : (isFG ? Math.ceil(finalSalesPrice) : parseFloat(finalSalesPrice.toFixed(2)));
                }
            }
        }

        // Single clean set — no wipe, no setTimeout
        component.set("v.records", records);
        console.log('before margin --', component.get("v.totalSalesPrice"))
        helper.totalSalesPriceCalculate(component, event, helper);
        console.log('after margin --', component.get("v.totalSalesPrice"))
        helper.totalBTPCalculate(component, event, helper);
        component.set("v.isLoad", false);
    },
    totalBTPCalculate: function (component, event, helper) {
        let records = component.get("v.records");
        console.log('records totalBTPCalculate method => ', JSON.stringify(records, null, 2));

        let totalBtpPrice = 0;
        for (let ele of records) {
            if (parseFloat(ele.btpPrice) > 0) {
                let totalQty = 0;
                if (ele.level2customQuantity != '' && ele.level2customQuantity != undefined) {
                    totalQty += parseFloat(ele.level2customQuantity);
                }
                if (ele.customQuantity != '' && ele.customQuantity != undefined) {
                    //console.log("AK CUST QTY =>",ele.customQuantity);
                    totalQty += parseFloat(ele.customQuantity);
                    //console.log("AK TOTAL QTY =>",totalQty);
                }
                console.log("AK BEF Total BTP =>", totalBtpPrice);
                console.log("AK Bef Total Qty =>", totalQty);
                if (ele.isFixedBTP == true) {
                    totalBtpPrice += parseFloat(ele.SAP_Price) * totalQty;
                }
                else {
                    totalBtpPrice += parseFloat(ele.btpPrice) * totalQty;
                    console.log("AK AFT Total BTP =>", totalBtpPrice);
                }
            }
        }
        component.set("v.totalBTPPrice", totalBtpPrice.toFixed(2));
    },
    //Ranjeet -- logic working for percentage 
    // totalSalesPriceCalculate: function (component, event, helper) {
    //     let records = component.get("v.records");
    //     console.log('records totalSalesPriceCalculate method => ', records);
    //     let totalSalesPrice = 0;
    //     var totalSalesPert = 0;

    //     for (let ele of records) {

    //         let totalQty = 0;
    //         //========= For All marin update issue and header 
    //         //   let isUpdateCheck = component.get("v.isUpdate");
    //         //     console.log("isUpdateCheck => ",isUpdateCheck);
    //         //     console.log("ele => ",JSON.stringify(ele));
    //         //     if(isUpdateCheck == true && ele.level2customQuantity != '' && ele.level2customQuantity != undefined){
    //         //         console.log('inside 1052 isUpdateCheck');
    //         //         totalQty += parseFloat(ele.level2customQuantity);
    //         //     }
    //         //   if(isUpdateCheck == true && ele.productquantities != '' && ele.productquantities != undefined){
    //         //       totalQty += parseFloat(ele.productquantities);
    //         //   }
    //         //========= For All marin update issue and header end 

    //         if (ele.level2customQuantity != '' && ele.level2customQuantity != undefined) {
    //             totalQty += parseFloat(ele.level2customQuantity);
    //         }
    //         if (ele.customQuantity != '' && ele.customQuantity != undefined) {
    //             console.log('inside 1018 and outside isUpdateCheck');
    //             totalQty += parseFloat(ele.customQuantity);
    //         }

    //         if (parseFloat(ele.mySalesPrice) > 0) {
    //             /*let marginPrice = 0;
    //             if(ele.margin > 0){
    //                 console.log('marginPrice++++');
    //                 let percentPrice = parseFloat(ele.margin).toFixed(2) * parseFloat(ele.mySalesPrice).toFixed(2);
    //                 percentPrice = percentPrice/100;
    //                 percentPrice = percentPrice.toFixed(2);
    //                 marginPrice = parseFloat(ele.mySalesPrice).toFixed(2) + percentPrice;

    //             }else if(ele.margin < 0){
    //                 console.log('marginPrice----');
    //                 let percentPrice = parseFloat(ele.margin).toFixed(2) * parseFloat(ele.mySalesPrice).toFixed(2);
    //                 percentPrice = percentPrice/100;
    //                 percentPrice = percentPrice.toFixed(2) * -1;
    //                 marginPrice = parseFloat(ele.mySalesPrice).toFixed(2) - percentPrice;
    //             }
    //             console.log('marginPrice=>',marginPrice);*/
    //             console.log('totalQty in totalSalesPriceCalculate =>', totalQty);
    //             //totalSalesPrice += parseFloat(marginPrice) * totalQty;

    //             if (ele.isFixedBTP == true) {
    //                 totalSalesPrice += parseFloat(ele.mySalesPrice) * totalQty;
    //             }
    //             else {
    //                 totalSalesPrice += parseFloat(ele.mySalesPrice) * totalQty;
    //             }
    //             console.log('totalSalesPrice =>', totalSalesPrice);
    //         }
    //     }
    //     let totalBtpPrice = 0;
    //     totalBtpPrice = component.get("v.totalBTPPrice");
    //     console.log('--tc--' + totalBtpPrice);


    //     totalSalesPert = parseFloat(totalSalesPrice / totalBtpPrice) * 100;
    //     //totalSalesPert =parseFloat ((totalBtpPrice+totalSalesPrice)/totalBtpPrice)*100; 
    //     console.log('--tc1--' + totalSalesPert);
    //     component.set("v.totalSalesPrice", totalSalesPrice.toFixed(2));
    //     component.set("v.totalSalesPer", totalSalesPert.toFixed(2));
    //     console.log("Total sales percent => ", totalSalesPert.toFixed(2));



    // },

    //Ranjeet -- new logic for percent 
    totalSalesPriceCalculate: function (component, event, helper) {
        let records = component.get("v.records");
        console.log('records totalSalesPriceCalculate method => ', records);
        let totalSalesPrice = 0;
        var totalSalesPert = 0;
        let totalBaseForPercentage = 0; // NEW

        for (let ele of records) {

            console.log('ele record:::: ', JSON.stringify(ele));

            let totalQty = 0;

            if (ele.level2customQuantity != '' && ele.level2customQuantity != undefined) {
                totalQty += parseFloat(ele.level2customQuantity);
            }
            if (ele.customQuantity != '' && ele.customQuantity != undefined) {
                console.log('inside 1018 and outside isUpdateCheck');
                totalQty += parseFloat(ele.customQuantity);
            }

            if (parseFloat(ele.mySalesPrice) > 0) {
                if (ele.isFixedBTP == true) {
                    totalSalesPrice += parseFloat(ele.mySalesPrice) * totalQty;
                }
                else {
                    totalSalesPrice += parseFloat(ele.mySalesPrice) * totalQty;
                }
                console.log('totalSalesPrice =>', totalSalesPrice);
            }

            // NEW: calculate what mySalesPrice would be if margin were 0
            let ProType = ele.Product_L3__r ? ele.Product_L3__r.Product_Type__c : '';
            let isFG = (ProType && ProType.slice(0, 2) === 'FG');

            let basePrice = 0;
            if (ele.isFixedBTP == true) {
                basePrice = parseFloat(ele.SAP_Price) || 0;
            } else {
                let btp = parseFloat(ele.btpPrice) || 0;
                let sap = parseFloat(ele.SAP_Price) || 0;
                console.log(' sap btp ', sap, ' -- ', btp)
                basePrice = (sap > 0 && sap > btp) ? sap : btp;
            }

            // margin = 0 → mySalesPrice = basePrice itself
            console.log('isFG basePrice:: ', basePrice)
            let mySalesPriceAtZeroMargin = isFG ? Math.ceil(basePrice) : basePrice;

            console.log('=== Zero Margin Base Calculation ===');
            console.log('Product:', ele.Product_L3__r ? ele.Product_L3__r.Name : 'N/A');
            console.log('Actual Margin:', ele.margin);
            console.log('btpPrice:', ele.btpPrice);
            console.log('SAP_Price:', ele.SAP_Price);
            console.log('isFixedBTP:', ele.isFixedBTP);
            console.log('isFG:', isFG);
            console.log('basePrice used:', basePrice);
            console.log('mySalesPrice at zero margin:', mySalesPriceAtZeroMargin);
            console.log('totalQty:', totalQty);
            console.log('contribution to base:', mySalesPriceAtZeroMargin * totalQty);
            console.log('====================================');

            totalBaseForPercentage += mySalesPriceAtZeroMargin * totalQty;
        }

        // ORIGINAL: these two lines replaced with new logic below
        // let totalBtpPrice = component.get("v.totalBTPPrice");
        // totalSalesPert = parseFloat(totalSalesPrice / totalBtpPrice) * 100;

        // NEW: percentage over mySalesPrice at zero margin
        console.log('=== TOTAL SUMMARY ===');
        console.log('totalSalesPrice:', totalSalesPrice);
        console.log('totalBaseForPercentage (all products at zero margin):', totalBaseForPercentage);

        if (totalBaseForPercentage > 0) {
            totalSalesPert = parseFloat(totalSalesPrice / totalBaseForPercentage) * 100;
        } else {
            totalSalesPert = 0;
        }

        console.log('totalSalesPer (%):', totalSalesPert.toFixed(2));
        console.log('=====================');

        component.set("v.totalSalesPrice", totalSalesPrice.toFixed(2));
        component.set("v.totalSalesPer", totalSalesPert.toFixed(2));
        console.log("Total sales percent => ", totalSalesPert.toFixed(2));
    },

    //SK - 211122 : Overall Sales percentage over the BTP.

    totalSalesPerCalculate: function (component, event, helper) {
        let records = component.get("v.records");
        let totalSalesPer = 0;
        for (let ele of records) {
            let totalBtpPrice = 0;
            let totalSalesPrice = 0;

            if (totalSalesPrice != '') {
                totalSalesPrice += parseFloat(totalSalesPrice);
            }
            if (totalBtpPrice != '') {
                totalBtpPrice += parseFloat(totalBtpPrice);
            }
            if ((parseFloat(totalSalesPrice) > 0) && (parseFloat(totalBtpPrice) > 0)) {
                //   totalSalesPer += parseFloat (totalSalesPrice / totalBtpPrice)*100;
                totalSalesPer += parseFloat((totalBtpPrice + totalSalesPrice) / totalBtpPrice) * 100; //modified

            }
        }

        component.set("v.totalSalesPer", totalSalesPer.toFixed(2));
    },





    createOffer: function (component, event, helper, shouldClose) {
        // Default to true for backward compatibility (old Save & Close)
        shouldClose = (shouldClose === undefined) ? true : shouldClose;


        component.set("v.isLoad", true);
        component.set("v.showConfirmDialog", false);
        console.log('Called....');
        let offerId = component.get("v.recordId");
        var records = component.get("v.records");
        console.log('Helper records before save => ', records);

        let l2Map = component.get("v.L2ProductMap");
        let headers = component.get("v.headers");
        var l2l3obj = Object.fromEntries(l2Map);
        console.log(l2l3obj);

        let offerLine = [];

        //checking the setType
        let isflSet = component.get("v.fullSet");
        let setType = '';
        if (isflSet == true) {
            setType = 'fullset'
        }
        else {
            setType = ''
            for (var hd of headers) {
                if (hd.isSelected) {
                    setType = setType != '' ? (setType + ';' + hd.Name) : hd.Name;
                };
            }
        }

        component.set('v.settingState', setType)


        for (let ele of records) {
            if (ele.customQuantity > 0 || ele.level2customQuantity > 0) {
                let ProType = ele.Product_L3__r.Product_Type__c;
                let isFG = (ProType && ProType.slice(0, 2) === 'FG');

                let l2Map = new Map();
                for (let obj of headers) {
                    if (obj.isSelected) {
                        l2Map.set(obj.Name, obj.value);
                    }
                }

                let l2HeadersMap = ele.quantityMapRecord;
                let result = "";
                l2Map.forEach(function (value, key) {
                    result = result + key.concat("-", l2HeadersMap.get(key)) + ";";
                });

                let recordObj = {
                    "discount": ele.discount,
                    "margin": ele.margin,
                    "salesPrice": ele.mySalesPrice,
                    "OriginalBTP": ele.L2btpPrice,
                    "btpPrice": ele.btpPrice,
                    "l3ProductId": ele.Product_L3__c,
                    "l2ProductId": ele.Product_L2__c,
                    "customQuantity": ele.customQuantity,
                    "level2customQuantity": ele.level2customQuantity,
                    "isFG": isFG,
                    "RMCCost": ele.RMCCost,
                    "branchRateOfInterest": ele.branchRateOfInterest,
                    "offerpayment": ele.offerpayment,
                    "branchHedging": ele.branchHedging,
                    "basicPrice": ele.basicPrice,
                    "costPackingForwarding": ele.costPackingForwarding,
                    "CostFreight": ele.CostFreight,
                    "costInsurance": ele.costInsurance,
                    "costInterest": ele.costInterest,
                    "costHedging": ele.costHedging,
                    "exchangeRate": ele.exchangeRate,
                    "quantityL2Wise": result,
                    "setType": setType
                };
                offerLine.push(recordObj);
            }
        }

        console.log("offerLine=> ", offerLine);
        // Validate: no record with quantity > 0 should have BTP = 0
        var zeroBTPProducts = [];
        for (var i = 0; i < offerLine.length; i++) {
            var line = offerLine[i];
            var totalQty = (parseFloat(line.customQuantity) || 0) + (parseFloat(line.level2customQuantity) || 0);
            if (totalQty > 0 && !(parseFloat(line.btpPrice) > 0)) {
                for (var r = 0; r < records.length; r++) {
                    if (records[r].Product_L3__c === line.l3ProductId) {
                        zeroBTPProducts.push(records[r].Product_L3__r.Name);
                        break;
                    }
                }
            }
        }
        if (zeroBTPProducts.length > 0) {
            helper.showToast("Error", "Error", "BTP is zero for the following product(s): " + zeroBTPProducts.join(", ") + ". Please contact PMG.");
            component.set("v.isLoad", false);
            component.set("v.showConfirmDialog", false);
            return;
        }


        if (offerLine.length > 0) {
            var action = component.get("c.saveOffer");
            let fSetQty = component.get("v.fullSetQuantity");
            let isFullSet = component.get("v.fullSet");
            let sOrgId = component.get("v.sOrgId");
            let isWos = component.get("v.wos");

            if (isFullSet === false) fSetQty = 0;

            let offCurrencyCode = component.get("v.offCurrency");
            let prtId = component.get("v.partId");

            action.setParams({
                offerId: offerId,
                currCode: offCurrencyCode,
                partListId: prtId,
                recordStr: JSON.stringify(offerLine),
                l2l3MapStr: JSON.stringify(l2l3obj),
                btpMap: component.get("v.BTPMap"),
                fullSetQty: fSetQty,
                sOrgId: sOrgId,
                isWOS: isWos,
                headerStr: JSON.stringify(headers)
            });

            action.setCallback(this, function (response) {
                var state = response.getState();
                console.log("state=> ", state);
                component.set("v.isLoad", false);

                if (state === "SUCCESS") {
                    helper.showToast("Success", "Success", "Offer Products are created successfully.");

                    // ✅ Only close when shouldClose = true
                    if (shouldClose) {
                        $A.get("e.force:closeQuickAction").fire();
                    }
                } else {
                    component.set("v.showConfirmDialog", false);
                    helper.showToast("Error", "Error", "Something went wrong while saving.");
                }
            });

            $A.enqueueAction(action);
        } else {
            helper.showToast("Error", "Error", "BTP/Sales price are missing");
            component.set("v.isLoad", false);
        }
    },



    showToast: function (title, type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },

    showToast2: function (title, type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'sticky',
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },

    // Enhanced applySorting method
    // applySorting: function(component, event, helper) {
    //     var records = component.get("v.records");
    //     var sortBy = component.get("v.sortBy");
    //     var sortOrder = component.get("v.sortOrder");
    //     var sapCodeSortOrder = component.get("v.sapCodeSortOrder");

    //     // Don't apply sorting if no records or no sorting map loaded yet
    //     if (!records || records.length === 0 || !sapCodeSortOrder || Object.keys(sapCodeSortOrder).length === 0) {
    //         console.log('Skipping sorting - no records or sorting map');
    //         return;
    //     }

    //     console.log('Applying enhanced sorting to', records.length, 'records');
    //     console.log('Sort by:', sortBy, 'Order:', sortOrder);
    //     console.log('Sorting map has', Object.keys(sapCodeSortOrder).length, 'entries');

    //     if (sortBy === 'Product_L3__r.Name' && records.length > 0) {
    //         // Create a copy of records to avoid mutation issues
    //         var sortedRecords = records.slice();

    //         sortedRecords.sort(function(a, b) {
    //             var productNameA = a.Product_L3__r.Name;
    //             var productNameB = b.Product_L3__r.Name;

    //             // Find the best matching prefix for both products
    //             var prefixA = helper.findBestMatchingPrefix(component, productNameA);
    //             var prefixB = helper.findBestMatchingPrefix(component, productNameB);

    //             // Get sort order from custom metadata
    //             var orderA = sapCodeSortOrder[prefixA] || 999;
    //             var orderB = sapCodeSortOrder[prefixB] || 999;

    //             // If same order group, sort alphabetically within the group
    //             if (orderA === orderB) {
    //                 if (sortOrder === 'asc') {
    //                     return productNameA.localeCompare(productNameB);
    //                 } else {
    //                     return productNameB.localeCompare(productNameA);
    //                 }
    //             }

    //             // Otherwise sort by the order from metadata
    //             if (sortOrder === 'asc') {
    //                 return orderA - orderB;
    //             } else {
    //                 return orderB - orderA;
    //             }
    //         });

    //         console.log('Sorting completed - setting sorted records');
    //         component.set("v.records", sortedRecords);
    //     }
    // },

    // Find best matching prefix method
    // findBestMatchingPrefix: function(component, productName) {
    //     var sapCodeSortOrder = component.get("v.sapCodeSortOrder");
    //     var sortingKeys = Object.keys(sapCodeSortOrder);

    //     // Try exact match first
    //     if (sapCodeSortOrder[productName] !== undefined) {
    //         return productName;
    //     }

    //     // Try prefix matching - find the longest matching prefix
    //     var bestMatch = '';
    //     var bestMatchLength = 0;

    //     for (var i = 0; i < sortingKeys.length; i++) {
    //         var prefix = sortingKeys[i];

    //         // Check if product name starts with this prefix
    //         if (productName.startsWith(prefix)) {
    //             // Prefer longer matches for better accuracy
    //             if (prefix.length > bestMatchLength) {
    //                 bestMatch = prefix;
    //                 bestMatchLength = prefix.length;
    //             }
    //         }
    //     }

    //     // If we found a prefix match, return it
    //     if (bestMatchLength > 0) {
    //         return bestMatch;
    //     }

    //     // If no match found, try to extract the base code (like M33 from M33-01515O000-0102)
    //     var baseCodeMatch = productName.match(/^([A-Za-z]+-?\d+)/);
    //     if (baseCodeMatch && baseCodeMatch[1]) {
    //         var baseCode = baseCodeMatch[1];
    //         // Check if base code exists in sorting map
    //         if (sapCodeSortOrder[baseCode] !== undefined) {
    //             return baseCode;
    //         }
    //     }

    //     // Return the original product name if no prefix found
    //     return productName;
    // },

    applySorting: function (component, event, helper) {
        var records = component.get("v.records");
        var sapCodeSortOrder = component.get("v.sapCodeSortOrder");

        if (!records || records.length === 0 || !sapCodeSortOrder || Object.keys(sapCodeSortOrder).length === 0) {
            console.log('Skipping sorting - no records or sorting map');
            return;
        }

        console.log('Applying sorting to', records.length, 'records');

        var sortedRecords = records.slice();

        sortedRecords.sort(function (a, b) {
            var productNameA = a.Product_L3__r.Name;
            var productNameB = b.Product_L3__r.Name;

            var prefixA = helper.findBestMatchingPrefix(component, productNameA);
            var prefixB = helper.findBestMatchingPrefix(component, productNameB);

            var orderA = sapCodeSortOrder[prefixA] !== undefined ? sapCodeSortOrder[prefixA] : 999;
            var orderB = sapCodeSortOrder[prefixB] !== undefined ? sapCodeSortOrder[prefixB] : 999;

            if (orderA === orderB) {
                return productNameA.localeCompare(productNameB);
            }

            return orderA - orderB;
        });

        console.log('Sorting completed - setting sorted records');
        component.set("v.records", sortedRecords);
    },

    findBestMatchingPrefix: function (component, productName) {
        var sapCodeSortOrder = component.get("v.sapCodeSortOrder");
        var sortingKeys = Object.keys(sapCodeSortOrder);

        // Try exact match first
        if (sapCodeSortOrder[productName] !== undefined) {
            return productName;
        }

        // Try prefix matching - find the longest matching prefix
        var bestMatch = '';
        var bestMatchLength = 0;

        for (var i = 0; i < sortingKeys.length; i++) {
            var prefix = sortingKeys[i];

            if (productName.startsWith(prefix)) {
                if (prefix.length > bestMatchLength) {
                    bestMatch = prefix;
                    bestMatchLength = prefix.length;
                }
            }
        }

        if (bestMatchLength > 0) {
            return bestMatch;
        }

        // Pattern matching
        var baseCodeMatch1 = productName.match(/^([A-Z]+-?\d+)/);
        if (baseCodeMatch1 && baseCodeMatch1[1]) {
            var baseCode = baseCodeMatch1[1];
            if (sapCodeSortOrder[baseCode] !== undefined) {
                return baseCode;
            }
        }

        var numberMatch = productName.match(/^(\d+)/);
        if (numberMatch && numberMatch[1]) {
            var numberCode = numberMatch[1];
            if (sapCodeSortOrder[numberCode] !== undefined) {
                return numberCode;
            }
        }

        var fullCodeMatch = productName.match(/^(\d+-\d+)/);
        if (fullCodeMatch && fullCodeMatch[1]) {
            var fullCode = fullCodeMatch[1];
            if (sapCodeSortOrder[fullCode] !== undefined) {
                return fullCode;
            }
        }

        return productName;
    }

})