import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

// Apex Methods
import searchPartList from '@salesforce/apex/CreateOfferLineController.searchPartList';
import getl2l3Products from '@salesforce/apex/CreateOfferLineController.getl2l3Products';
import saveOffer from '@salesforce/apex/CreateOfferLineController.saveOffer';
import getQuoteStatus from '@salesforce/apex/CreateOfferLineController.getQuoteStatus';
import getProductSortingOrder from '@salesforce/apex/CreateOfferLineController.getProductSortingOrder';
import productPriceUpdate from '@salesforce/apex/CreateOfferLineController.productPriceUpdate';
import getBTPPrice from '@salesforce/apex/CreateOfferLineController.getBTPPrice';

export default class OfferProductManager extends LightningElement {
    @api recordId;

    // Track variables
    @track records = [];
    @track headers = [];
    @track searchKeyword = '';
    @track picksel = '';
    @track fullSet = false;
    @track fullSetQuantity = 0;
    @track marginAllVal = 0;
    @track totalBTPPrice = 0;
    @track totalSalesPrice = 0;
    @track totalSalesPer = 0;
    @track isLoading = false;
    @track showConfirmDialog = false;
    @track partlistnumber = true;
    @track isButtonDisabled = false;
    @track currencyMismatchError = '';
    @track zeroBTPError = '';

    // Internal variables
    offCurrency = '';
    partId = '';
    sOrgId = '';
    wos = false;
    BTPMap = {};
    L3ProductQty = {};
    L2ProductMap = {};
    sapCodeSortOrder = {};
    derivedSOfactor = 0;
    directCustomer = false;
    fixedPriceMap = {};
    isUpdate = false;

    // Product type options
    get productTypeOptions() {
        return [
            { label: 'ALL', value: '' },
            { label: 'Hardware', value: 'Hardware' },
            { label: 'Non-Hardware', value: 'Non-Hardware' }
        ];
    }

    // Computed properties
    get disableFullSetQty() {
        return !this.fullSet;
    }

    get disableHeader() {
        return this.fullSet;
    }

    get formattedTotalBTP() {
        return this.formatCurrency(this.totalBTPPrice);
    }

    get formattedTotalSales() {
        return this.formatCurrency(this.totalSalesPrice);
    }

    get formattedTotalSalesPercent() {
        return this.totalSalesPer.toFixed(2);
    }

    // Lifecycle Hooks
    connectedCallback() {
        this.initializeComponent();
    }

    async initializeComponent() {
        this.isLoading = true;
        
        try {
            // Check quote status
            await this.checkQuoteStatus();
            
            // Check product price update
            const isPriceUpdated = await productPriceUpdate();
            if (isPriceUpdated) {
                this.showToast('Error', 'The product prices are Updated. Please contact your Admin.', 'error');
                this.closeAction();
                return;
            }

            // Get sorting order
            await this.loadSortingOrder();
            
            // Load products
            await this.loadProducts();
            
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

    async checkQuoteStatus() {
        try {
            const result = await getQuoteStatus({ offerId: this.recordId });
            const isAllowed = (result.status === 'PD' && result.approvalStatus === 'Draft');
            this.isButtonDisabled = !isAllowed;
            
            if (result.approvalStatus === 'Price Rejected') {
                this.isButtonDisabled = false;
            }
        } catch (error) {
            console.error('Error checking quote status:', error);
            this.isButtonDisabled = true;
        }
    }

    async loadSortingOrder() {
        try {
            this.sapCodeSortOrder = await getProductSortingOrder();
        } catch (error) {
            console.error('Error loading sorting order:', error);
        }
    }

    async loadProducts() {
        try {
            const result = await getl2l3Products({ offerId: this.recordId });
            
            if (!result || !result.data) {
                return;
            }

            this.processProductData(result);
            
        } catch (error) {
            this.handleError(error);
        }
    }

    processProductData(resultdata) {
        const obj = resultdata.data;
        
        // Set component variables
        this.BTPMap = resultdata.BTP;
        this.partId = resultdata.partListId;
        this.offCurrency = resultdata.offerCurrency;
        this.totalBTPPrice = resultdata.totalBTPPrice;
        this.totalSalesPrice = resultdata.totalSalesPrice;
        this.totalSalesPer = resultdata.totalSalesPer;
        this.fullSet = resultdata.isFullSet;
        this.fullSetQuantity = resultdata.fullSetQty;
        this.wos = resultdata.isWos;
        this.derivedSOfactor = resultdata.SOFactor;
        this.directCustomer = resultdata.isDirectCustomer;
        this.sOrgId = resultdata.sOrgId;
        this.L3ProductQty = resultdata.L3ProdQtyMap;
        this.fixedPriceMap = obj.fixedPriceMap;

        // Process products
        this.processProducts(obj, resultdata);
        
        // Process headers
        this.processHeaders(resultdata);
        
        // Apply sorting
        this.applySorting();
        
        // Calculate fresh BTP
        this.calculateFreshBTPForAllProducts();
    }

    processProducts(obj, resultdata) {
        const result = obj.products;
        const sapPriceMap = obj.sapPriceMap;
        const sapDateMap = obj.sapDateMap;
        const fixedPrice = obj.fixedPriceMap;
        const wrp = resultdata.wrp;
        const l1l2 = resultdata.l1l2;
        const sapPriceMap2 = resultdata.originalSapPriceMap;

        let recordsFromServer = JSON.parse(JSON.stringify(result));
        let productHeaders = new Set();
        let quantityMap = new Map();
        let l2Mapupdate = new Map();

        // First pass: build maps
        for (let record of recordsFromServer) {
            const prodName = record.Product_L2__r.Name.split('-');
            record.ProductL2Name = prodName[3];
            productHeaders.add(prodName[3]);

            let mapRow = quantityMap.get(record.Product_L3__r.Name) || new Map();
            mapRow.set(record.ProductL2Name, record.Quantity__c);
            quantityMap.set(record.Product_L3__r.Name, mapRow);

            // Build L2L3 map
            const text = record.Product_L2__r.Name;
            const myArray = text.split("-");
            const l2Level = myArray[3];
            const mapKey = record.Product_L3__c + "-" + l2Level;
            l2Mapupdate.set(mapKey, record.Id);
        }

        this.L2ProductMap = Object.fromEntries(l2Mapupdate);

        // Second pass: build unique records
        let uniqueL3 = new Set();
        let uniqueRecords = [];

        for (let record of recordsFromServer) {
            if (uniqueL3.has(record.Product_L3__r.Name)) {
                continue;
            }
            uniqueL3.add(record.Product_L3__r.Name);

            const quantityMapRecord = quantityMap.get(record.Product_L3__r.Name);
            const columnsString = [];
            let total = 0;

            // Build quantity columns
            for (let headerName of productHeaders) {
                const value = quantityMapRecord.get(headerName) || 0;
                columnsString.push(`<div class="slds-truncate">${value}</div>`);
                total += value;
            }

            record.product2Quantities = columnsString;
            record.productquantities = total;
            record.quantityMapRecord = quantityMapRecord;
            record.inputDisable = total > 0 ? false : true;
            record.level2customQuantity = 0;
            record.customQuantity = 0;
            record.isLLP = false;
            record.isDirectCustomer = this.directCustomer;
            record.isWos = this.wos;

            // Initialize BTP fields
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

            // Fixed BTP
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

            // Get setting value from existing quote lines
            let getSettingValue = '';

            // Process wrapped products
            for (let key in wrp) {
                if (key === record.Product_L3__r.Name) {
                    const wrpprds = wrp[key];
                    record.QuotelineId = wrpprds.QuotelineId;
                    record.customQuantity = wrpprds.customQuantity;

                    if (record.customQuantity > 0) {
                        record.inputDisable = false;
                    }

                    getSettingValue = wrpprds.setType;

                    const ProType = record.Product_L3__r.Product_Type__c;
                    const isFG = ProType && ProType.slice(0, 2) === 'FG';

                    if (wrpprds.btpPrice === 0) {
                        record.btpPrice = isFG ? Math.ceil(wrpprds.L2btpPrice) : wrpprds.L2btpPrice;
                    } else {
                        record.btpPrice = isFG ? Math.ceil(wrpprds.btpPrice) : wrpprds.btpPrice;
                    }

                    record.cusBtpPrice = wrpprds.cusBtpPrice;
                    record.L2btpPrice = wrpprds.L2btpPrice;
                    record.margin = wrpprds.margin;
                    record.discount = wrpprds.discount;

                    if (wrpprds.salesPrice === 0) {
                        record.mySalesPrice = isFG ? Math.ceil(wrpprds.L2btpPrice) : wrpprds.L2btpPrice;
                    } else if (record.isFixedBTP && fixedPrice[record.Product_L3__c]) {
                        record.mySalesPrice = isFG ? Math.ceil(fixedPrice[record.Product_L3__c]) : fixedPrice[record.Product_L3__c];
                    } else {
                        record.mySalesPrice = isFG ? Math.ceil(wrpprds.salesPrice) : wrpprds.salesPrice;
                    }

                    record.level2customQuantity = wrpprds.level2customQuantity;
                }
            }

            // Set full set state
            if (getSettingValue === 'fullset') {
                this.fullSet = true;
            }

            // Process SAP prices
            let lastSPrice = 0;
            let lastSPrice2 = 0;

            if (sapPriceMap[record.Product_L3__c]) {
                lastSPrice = sapPriceMap[record.Product_L3__c];
                lastSPrice2 = sapPriceMap2[record.Product_L3__c];
                record.isLLP = true;
            }

            if (sapDateMap[record.Product_L3__c]) {
                record.SAP_Date = sapDateMap[record.Product_L3__c];
            }

            const ProType2 = record.Product_L3__r.Product_Type__c;
            const isFG2 = ProType2 && ProType2.slice(0, 2) === 'FG';

            record.SAP_Price_Incremented = isFG2 ? Math.ceil(lastSPrice) : lastSPrice;

            // Handle WOS calculation
            let displaySapPrice = lastSPrice2;
            if (record.isWos && !record.isDirectCustomer && displaySapPrice > 0) {
                displaySapPrice = displaySapPrice / 0.75;
            }

            // Set SAP prices
            if (!record.QuotelineId) {
                record.SAP_Price = isFG2 ? Math.ceil(displaySapPrice) : displaySapPrice;
                if (!record.isFixedBTP && record.SAP_Price_Incremented > 0) {
                    record.mySalesPrice = isFG2 ? Math.ceil(record.SAP_Price_Incremented) : record.SAP_Price_Incremented;
                }
            } else {
                record.SAP_Price = isFG2 ? Math.ceil(displaySapPrice) : displaySapPrice;
            }

            // Initialize BTP if zero
            if ((record.btpPrice === 0 || record.btpPrice === undefined) && record.SAP_Price > 0) {
                const isFG3 = ProType2 && ProType2.slice(0, 2) === 'FG';
                record.btpPrice = isFG3 ? Math.ceil(record.SAP_Price) : record.SAP_Price;
                record.mySalesPrice = isFG3 ? Math.ceil(record.SAP_Price) : record.SAP_Price;
            }

            record.SAP_PriceOld = Math.ceil(sapPriceMap[record.Product_L3__c]);
            record.customQuantityValues = new Map(Object.entries(JSON.parse(JSON.stringify(quantityMapRecord))));
            record.level2CustomQuantityValues = new Map(Object.entries(JSON.parse(JSON.stringify(quantityMapRecord))));

            uniqueRecords.push(record);
        }

        // Add row numbers
        uniqueRecords.forEach((record, index) => {
            record.rowNumber = index + 1;
        });

        this.records = uniqueRecords;
        this.partlistnumber = uniqueRecords.length === 0;
    }

    processHeaders(resultdata) {
        const l1l2 = resultdata.l1l2;
        const productHeaders = new Set();
        
        // Extract headers from records
        this.records.forEach(record => {
            const prodName = record.Product_L2__r.Name.split('-');
            productHeaders.add(prodName[3]);
        });

        const headers = [];
        const settingState = this.getSettingState();

        for (let headerName of productHeaders) {
            const header = {
                Name: headerName,
                isSelected: false,
                value: 0
            };

            // Set selected state based on setting
            if (settingState === 'fullset') {
                header.isSelected = true;
            } else if (settingState.includes(headerName)) {
                header.isSelected = true;
            }

            // Set quantity from L1L2 records
            for (let l1l2Record of l1l2) {
                if (l1l2Record.Product_Description__c && l1l2Record.Product_Description__c.includes(headerName)) {
                    header.value = l1l2Record.Quantity__c;
                }
            }

            headers.push(header);
        }

        this.headers = headers;
    }

    getSettingState() {
        // Extract setting state from first record with QuotelineId
        for (let record of this.records) {
            if (record.QuotelineId) {
                // Implement logic to extract setting type
                return ''; // Replace with actual logic
            }
        }
        return '';
    }

    // Event Handlers
    handleSearchKeywordChange(event) {
        this.searchKeyword = event.target.value;
    }

    handleProductTypeChange(event) {
        this.picksel = event.detail.value;
    }

    async handleSearch() {
        this.isLoading = true;
        
        try {
            const result = await searchPartList({
                offerId: this.recordId,
                SearchProducts: this.searchKeyword,
                picklistProductType: this.picksel
            });

            if (result.isErr) {
                this.showToast('Error', result.ErrorMsg, 'error');
                return;
            }

            this.processSearchResults(result);
            
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

    processSearchResults(resultdata) {
        const obj = resultdata.data;
        
        this.BTPMap = resultdata.BTP;
        this.offCurrency = resultdata.offerCurrency;
        this.derivedSOfactor = resultdata.SOFactor;
        this.sOrgId = resultdata.sOrgId;
        this.wos = resultdata.isWos;
        this.directCustomer = resultdata.isDirectCustomer;
        this.partId = obj.partListId;
        this.L3ProductQty = resultdata.L3ProdQtyMap;

        // Process products similar to loadProducts
        this.processProducts(obj, resultdata);
        this.applySorting();
    }

    handleFullSetChange(event) {
        this.fullSet = event.target.checked;
        this.onChangeFullSet(true);
    }

    handleFullSetQtyChange(event) {
        this.fullSetQuantity = event.target.value;
        this.onChangeFullSet(false);
    }

    onChangeFullSet(isFromCheckBox) {
        const quantity = isFromCheckBox ? 1 : this.fullSetQuantity;
        this.fullSetQuantity = quantity;

        const headers = this.headers.map(header => {
            if (this.fullSet) {
                return {
                    ...header,
                    value: quantity,
                    isSelected: true
                };
            } else {
                return {
                    ...header,
                    value: 0,
                    isSelected: false
                };
            }
        });

        this.headers = headers;

        if (this.fullSet) {
            let iterations = headers.length;
            headers.forEach(header => {
                const isLast = (--iterations) === 0;
                this.calculateRecordCustomQuantity(quantity, header.Name, isLast);
            });
        } else {
            this.clearFullSet();
        }
    }

    clearFullSet() {
        this.records = this.records.map(record => ({
            ...record,
            L2btpPrice: 0,
            cusBtpPrice: 0,
            level2customQuantity: 0,
            customQuantity: 0,
            productquantities: 0
        }));
    }

    handleHeaderCheckboxChange(event) {
        const headerName = event.target.dataset.name;
        const isChecked = event.target.checked;

        // Check for SPARE without Full Set
        if (headerName === 'SPARE' && isChecked && !this.fullSet) {
            this.showToast('Error', 'Cannot select SPARE without Full Set', 'error');
            event.target.checked = false;
            return;
        }

        this.headers = this.headers.map(header => {
            if (header.Name === headerName) {
                return {
                    ...header,
                    isSelected: isChecked,
                    value: isChecked ? (header.value || 1) : 0
                };
            }
            return header;
        });

        // Check if all headers selected
        const allSelected = this.headers.every(h => h.isSelected);
        if (!allSelected) {
            this.fullSet = false;
            this.headers = this.headers.map(header => {
                if (header.Name === 'SPARE') {
                    return { ...header, value: 0, isSelected: false };
                }
                return header;
            });
        }

        this.calculateLevel2CustomQuantity(true);
        setTimeout(() => this.applySorting(), 100);
    }

    handleHeaderQtyChange(event) {
        const headerName = event.target.dataset.name;
        const value = parseFloat(event.target.value) || 0;

        this.headers = this.headers.map(header => {
            if (header.Name === headerName) {
                return { ...header, value };
            }
            return header;
        });

        this.calculateRecordCustomQuantity(value, headerName, true);
    }

    calculateRecordCustomQuantity(value, headerName, isLast) {
        const L3ProdQtyMap = this.L3ProductQty;

        this.records = this.records.map(record => {
            const key = record.Product_L3__c + headerName;
            const pQty = L3ProdQtyMap[key];
            
            if (pQty) {
                const valueToupdate = pQty * value;
                record.level2CustomQuantityValues.set(headerName, valueToupdate);
                record.level2customQuantity = valueToupdate;
            }
            
            return record;
        });

        this.calculateLevel2CustomQuantity(isLast);
    }

    calculateLevel2CustomQuantity(isLast) {
        const L3ProdQtyMap = this.L3ProductQty;
        let productQuantity = {};

        this.records = this.records.map(record => {
            let total = 0;

            this.headers.forEach(header => {
                if (header.isSelected) {
                    const key = record.Product_L3__c + header.Name;
                    const pQty = L3ProdQtyMap[key];
                    
                    if (pQty) {
                        total += header.value * pQty;
                    }
                }
            });

            record.level2customQuantity = total > 0 ? total : 0;
            productQuantity[record.Product_L3__c] = Number(total) + Number(record.customQuantity);

            return record;
        });

        if (isLast) {
            this.fetchBTPForAllRecords(productQuantity);
        }
    }

    async fetchBTPForAllRecords(productQuantity) {
        let count = 0;
        
        for (let record of this.records) {
            const total = Number(record.level2customQuantity) + Number(record.customQuantity);
            
            if (total > 0) {
                await this.fetchBTPPrice(count, record.level2customQuantity, false, true, productQuantity);
            } else {
                this.records[count].L2btpPrice = 0;
            }
            
            count++;
        }

        this.priceRecalculation();
        setTimeout(() => this.applySorting(), 200);
    }

    handleCustomQtyChange(event) {
        const index = parseInt(event.target.dataset.index);
        const value = parseFloat(event.target.value) || 0;

        this.records[index].customQuantity = value;
        
        // Debounce BTP calculation
        clearTimeout(this.customQtyTimeout);
        this.customQtyTimeout = setTimeout(() => {
            this.changeCustomQty(index);
        }, 1500);
    }

    changeCustomQty(selectedIndx) {
        const records = this.records;
        let productQuantity = {};

        records.forEach(record => {
            const l2Quan = Number(record.level2customQuantity) || 0;
            const custQuan = Number(record.customQuantity) || 0;
            productQuantity[record.Product_L3__c] = l2Quan + custQuan;
        });

        this.totalBTPCalculate();
        this.totalSalesPriceCalculate();
    }

    handleMarginChange(event) {
        const index = parseInt(event.target.dataset.index);
        const margin = parseFloat(event.target.value) || 0;

        this.records[index].margin = margin;
        
        const record = this.records[index];
        const btpPrice = parseFloat(record.btpPrice) || 0;
        const sapPrice = parseFloat(record.SAP_Price) || 0;

        let basePrice = 0;
        if (record.isFixedBTP) {
            basePrice = sapPrice;
        } else {
            basePrice = (sapPrice > 0 && sapPrice > btpPrice) ? sapPrice : btpPrice;
        }

        const ProType = record.Product_L3__r.Product_Type__c;
        const isFG = ProType && ProType.slice(0, 2) === 'FG';

        const marginAmount = (basePrice * margin) / 100;
        const salesPrice = basePrice + marginAmount;
        
        this.records[index].mySalesPrice = isNaN(salesPrice) ? 0 : (isFG ? Math.ceil(salesPrice) : salesPrice);

        this.totalBTPCalculate();
        this.totalSalesPriceCalculate();
        this.applySorting();
    }

    handleMarginAllChange(event) {
        this.isLoading = true;
        
        let marginAllVal = parseFloat(event.target.value) || 0;
        this.marginAllVal = marginAllVal;

        this.records = this.records.map(record => {
            const ProType = record.Product_L3__r.Product_Type__c;
            const isFG = ProType && ProType.slice(0, 2) === 'FG';

            let basePrice = 0;
            if (record.isFixedBTP) {
                basePrice = parseFloat(record.SAP_Price) || 0;
            } else {
                const btp = parseFloat(record.btpPrice) || 0;
                const sap = parseFloat(record.SAP_Price) || 0;
                basePrice = (sap > 0 && sap > btp) ? sap : btp;
            }

            if (basePrice > 0) {
                record.margin = marginAllVal;
                const marginAmount = (basePrice * marginAllVal) / 100;
                const finalSalesPrice = basePrice + marginAmount;
                record.mySalesPrice = isNaN(finalSalesPrice) ? 0 : (isFG ? Math.ceil(finalSalesPrice) : parseFloat(finalSalesPrice.toFixed(2)));
            }

            return record;
        });

        this.totalSalesPriceCalculate();
        this.totalBTPCalculate();
        this.isLoading = false;
    }

    // BTP Calculation
    async fetchBTPPrice(index, qty, isCustom, isL2, productQuantity) {
        if (qty <= 0 && !true) { // Note: "|| true" makes this always fetch
            this.records[index].error = '';
            if (isCustom) {
                this.records[index].customQuantity = 0;
                this.records[index].cusBtpPrice = 0;
            }
            if (isL2) {
                this.records[index].level2customQuantity = 0;
                this.records[index].L2btpPrice = 0;
            }
            return;
        }

        this.isLoading = true;

        try {
            const record = this.records[index];
            const result = await getBTPPrice({
                offerId: this.recordId,
                productId: record.Product_L3__c,
                itemQty: qty,
                productQuantity: productQuantity,
                btpMap: this.BTPMap
            });

            const btpFromApex = result.btpPrice;
            const ProType = record.Product_L3__r.Product_Type__c;
            const isFG = ProType && ProType.slice(0, 2) === 'FG';

            if (!record.isFixedBTP) {
                this.records[index].error = result.errMsg;

                // Set BTP component fields
                this.records[index].RMCCost = result.RMCCost;
                this.records[index].branchRateOfInterest = result.branchRateOfInterest;
                this.records[index].offerpayment = result.offerpayment;
                this.records[index].branchHedging = result.branchHedging;
                this.records[index].basicPrice = result.basicPrice;
                this.records[index].costPackingForwarding = result.costPackingForwarding;
                this.records[index].CostFreight = result.CostFreight;
                this.records[index].costInsurance = result.costInsurance;
                this.records[index].costInterest = result.costInterest;
                this.records[index].costHedging = result.costHedging;
                this.records[index].exchangeRate = result.exchangeRate;

                if (!result.errMsg) {
                    if (this.records[index].customQuantity > 0) {
                        this.records[index].cusBtpPrice = isFG ? Math.ceil(btpFromApex) : btpFromApex;
                    }

                    if (this.records[index].level2customQuantity > 0) {
                        this.records[index].L2btpPrice = btpFromApex;
                    }

                    this.records[index].btpPrice = isFG ? Math.ceil(btpFromApex) : btpFromApex;

                    const isUpdate = this.isUpdate;
                    if (isUpdate && this.records[index].QuotelineId) {
                        const savedMargin = this.records[index].margin || 0;
                        const btp = parseFloat(this.records[index].btpPrice) || 0;
                        const sap = parseFloat(this.records[index].SAP_Price) || 0;
                        const baseForMargin = (sap > 0 && sap > btp) ? sap : btp;

                        const marginAmt = (baseForMargin * savedMargin) / 100;
                        const recalcSalesPrice = baseForMargin + marginAmt;
                        this.records[index].mySalesPrice = isFG ? Math.ceil(recalcSalesPrice) : recalcSalesPrice;
                    } else {
                        const btp = parseFloat(this.records[index].btpPrice) || 0;
                        const sap = parseFloat(this.records[index].SAP_Price) || 0;
                        const basePrice = (sap > 0 && sap > btp) ? sap : btp;
                        this.records[index].mySalesPrice = isFG ? Math.ceil(basePrice) : basePrice;
                    }

                    if (result.btpPrice > 0) {
                        this.records[index].inputDisable = false;
                        if (!isUpdate) {
                            this.records[index].margin = 0;
                            this.records[index].discount = 0;
                        }
                    }
                }
            } else {
                // Fixed BTP
                this.records[index].RMCCost = result.RMCCost;
                this.records[index].branchRateOfInterest = result.branchRateOfInterest;
                this.records[index].offerpayment = result.offerpayment;
                this.records[index].branchHedging = result.branchHedging;
                this.records[index].basicPrice = result.basicPrice;
                this.records[index].costPackingForwarding = result.costPackingForwarding;
                this.records[index].CostFreight = result.CostFreight;
                this.records[index].costInsurance = result.costInsurance;
                this.records[index].costInterest = result.costInterest;
                this.records[index].costHedging = result.costHedging;
                this.records[index].exchangeRate = result.exchangeRate;

                this.records[index].btpPrice = isFG ? Math.ceil(btpFromApex) : btpFromApex;

                const fixedPriceMap = this.fixedPriceMap;
                const prodId = this.records[index].Product_L3__c;

                if (fixedPriceMap[prodId]) {
                    const fPrice = fixedPriceMap[prodId];
                    this.records[index].mySalesPrice = isFG ? Math.ceil(fPrice) : fPrice;
                } else {
                    this.records[index].mySalesPrice = isFG ? Math.ceil(btpFromApex) : btpFromApex;
                }
            }

        } catch (error) {
            console.error('Error fetching BTP:', error);
        } finally {
            this.isLoading = false;
        }
    }

    async calculateFreshBTPForAllProducts() {
        let productQuantity = {};
        
        this.records.forEach(record => {
            const l2Quan = Number(record.level2customQuantity) || 0;
            const custQuan = Number(record.customQuantity) || 0;
            productQuantity[record.Product_L3__c] = l2Quan + custQuan;
        });

        const fetchPromises = [];

        this.records.forEach((record, index) => {
            const total = (Number(record.level2customQuantity) || 0) + (Number(record.customQuantity) || 0);
            
            if (total > 0 || true) { // Always fetch for display
                const promise = this.fetchBTPPrice(index, total, false, false, productQuantity);
                fetchPromises.push(promise);
            }
        });

        try {
            await Promise.all(fetchPromises);
            
            // Mark zero-BTP records
            this.records = this.records.map(rec => {
                if (!(parseFloat(rec.btpPrice) > 0)) {
                    rec.error = "BTP is zero. Please resolve before saving.";
                } else {
                    rec.error = '';
                }
                return rec;
            });

            // Set banner error
            const zeroBTPProducts = this.records
                .filter(rec => !(parseFloat(rec.btpPrice) > 0))
                .map(rec => rec.Product_L3__r.Name);

            if (zeroBTPProducts.length > 0) {
                this.zeroBTPError = `BTP is zero for: ${zeroBTPProducts.join(", ")}. Please contact PMG.`;
            } else {
                this.zeroBTPError = '';
            }

            this.totalBTPCalculate();
            this.totalSalesPriceCalculate();
            this.applySorting();

        } catch (error) {
            console.error('Error calculating BTP:', error);
            this.showToast('Error', 'Failed to calculate BTP prices', 'error');
        }
    }

    priceRecalculation() {
        this.records = this.records.map(record => {
            let tBtp = 0;

            if (record.customQuantity > 0 && record.SAP_Price >= record.cusBtpPrice) {
                record.btpPrice = record.SAP_Price;
                tBtp = record.SAP_Price;
            } else if (record.customQuantity > 0) {
                record.btpPrice = record.cusBtpPrice;
                tBtp = record.cusBtpPrice;
            } else {
                if (!record.isLLP) {
                    record.SAP_Price = 0;
                }
            }

            const margin = (tBtp * record.margin) / 100;
            record.mySalesPrice = parseFloat(tBtp) + parseFloat(margin);

            return record;
        });

        this.totalBTPCalculate();
        this.totalSalesPriceCalculate();
        this.applySorting();
    }

    totalBTPCalculate() {
        let totalBtpPrice = 0;

        this.records.forEach(record => {
            if (parseFloat(record.btpPrice) > 0) {
                let totalQty = 0;
                
                if (record.level2customQuantity) {
                    totalQty += parseFloat(record.level2customQuantity);
                }
                if (record.customQuantity) {
                    totalQty += parseFloat(record.customQuantity);
                }

                if (record.isFixedBTP) {
                    totalBtpPrice += parseFloat(record.SAP_Price) * totalQty;
                } else {
                    totalBtpPrice += parseFloat(record.btpPrice) * totalQty;
                }
            }
        });

        this.totalBTPPrice = parseFloat(totalBtpPrice.toFixed(2));
    }

    totalSalesPriceCalculate() {
        let totalSalesPrice = 0;
        let totalBaseForPercentage = 0;

        this.records.forEach(record => {
            let totalQty = 0;

            if (record.level2customQuantity) {
                totalQty += parseFloat(record.level2customQuantity);
            }
            if (record.customQuantity) {
                totalQty += parseFloat(record.customQuantity);
            }

            if (parseFloat(record.mySalesPrice) > 0) {
                totalSalesPrice += parseFloat(record.mySalesPrice) * totalQty;
            }

            // Calculate base for percentage
            const ProType = record.Product_L3__r ? record.Product_L3__r.Product_Type__c : '';
            const isFG = ProType && ProType.slice(0, 2) === 'FG';

            let basePrice = 0;
            if (record.isFixedBTP) {
                basePrice = parseFloat(record.SAP_Price) || 0;
            } else {
                const btp = parseFloat(record.btpPrice) || 0;
                const sap = parseFloat(record.SAP_Price) || 0;
                basePrice = (sap > 0 && sap > btp) ? sap : btp;
            }

            const mySalesPriceAtZeroMargin = isFG ? Math.ceil(basePrice) : basePrice;
            totalBaseForPercentage += mySalesPriceAtZeroMargin * totalQty;
        });

        this.totalSalesPrice = parseFloat(totalSalesPrice.toFixed(2));

        if (totalBaseForPercentage > 0) {
            this.totalSalesPer = parseFloat((totalSalesPrice / totalBaseForPercentage) * 100);
        } else {
            this.totalSalesPer = 0;
        }
    }

    // Sorting
    applySorting() {
        if (!this.records || this.records.length === 0 || !this.sapCodeSortOrder || Object.keys(this.sapCodeSortOrder).length === 0) {
            return;
        }

        const sortedRecords = [...this.records];

        sortedRecords.sort((a, b) => {
            const productNameA = a.Product_L3__r.Name;
            const productNameB = b.Product_L3__r.Name;

            const prefixA = this.findBestMatchingPrefix(productNameA);
            const prefixB = this.findBestMatchingPrefix(productNameB);

            const orderA = this.sapCodeSortOrder[prefixA] !== undefined ? this.sapCodeSortOrder[prefixA] : 999;
            const orderB = this.sapCodeSortOrder[prefixB] !== undefined ? this.sapCodeSortOrder[prefixB] : 999;

            if (orderA === orderB) {
                return productNameA.localeCompare(productNameB);
            }

            return orderA - orderB;
        });

        this.records = sortedRecords;
    }

    findBestMatchingPrefix(productName) {
        const sortingKeys = Object.keys(this.sapCodeSortOrder);

        // Try exact match
        if (this.sapCodeSortOrder[productName] !== undefined) {
            return productName;
        }

        // Try prefix matching
        let bestMatch = '';
        let bestMatchLength = 0;

        for (let prefix of sortingKeys) {
            if (productName.startsWith(prefix) && prefix.length > bestMatchLength) {
                bestMatch = prefix;
                bestMatchLength = prefix.length;
            }
        }

        if (bestMatchLength > 0) {
            return bestMatch;
        }

        // Pattern matching
        const patterns = [
            /^([A-Z]+-?\d+)/,
            /^(\d+)/,
            /^(\d+-\d+)/
        ];

        for (let pattern of patterns) {
            const match = productName.match(pattern);
            if (match && match[1] && this.sapCodeSortOrder[match[1]] !== undefined) {
                return match[1];
            }
        }

        return productName;
    }

    // Save Operations
    handleSave() {
        this.saveOffer(false); // Save only, don't close
    }

    handleSaveAndClose() {
        const totalSalesPrice = this.totalSalesPrice;
        const totalBTPPrice = this.totalBTPPrice;
        const discount = (totalSalesPrice / totalBTPPrice) * 100;
        const percent = 100 - discount;

        if (percent > 1) {
            this.showConfirmDialog = true;
        } else {
            this.saveOffer(true); // Save and close
        }
    }

    handleConfirmNo() {
        this.showConfirmDialog = false;
    }

    handleConfirmYes() {
        this.saveOffer(true);
    }

    async saveOffer(shouldClose = true) {
        this.isLoading = true;
        this.showConfirmDialog = false;

        try {
            // Validate zero BTP
            const offerLine = [];
            const zeroBTPProducts = [];

            for (let record of this.records) {
                if (record.customQuantity > 0 || record.level2customQuantity > 0) {
                    const ProType = record.Product_L3__r.Product_Type__c;
                    const isFG = ProType && ProType.slice(0, 2) === 'FG';

                    // Build L2 header map
                    const result = this.buildL2HeaderString(record);

                    const recordObj = {
                        discount: record.discount,
                        margin: record.margin,
                        salesPrice: record.mySalesPrice,
                        OriginalBTP: record.L2btpPrice,
                        btpPrice: record.btpPrice,
                        l3ProductId: record.Product_L3__c,
                        l2ProductId: record.Product_L2__c,
                        customQuantity: record.customQuantity,
                        level2customQuantity: record.level2customQuantity,
                        isFG: isFG,
                        RMCCost: record.RMCCost,
                        branchRateOfInterest: record.branchRateOfInterest,
                        offerpayment: record.offerpayment,
                        branchHedging: record.branchHedging,
                        basicPrice: record.basicPrice,
                        costPackingForwarding: record.costPackingForwarding,
                        CostFreight: record.CostFreight,
                        costInsurance: record.costInsurance,
                        costInterest: record.costInterest,
                        costHedging: record.costHedging,
                        exchangeRate: record.exchangeRate,
                        quantityL2Wise: result,
                        setType: this.getSetType()
                    };

                    offerLine.push(recordObj);

                    // Check for zero BTP
                    const totalQty = (parseFloat(recordObj.customQuantity) || 0) + (parseFloat(recordObj.level2customQuantity) || 0);
                    if (totalQty > 0 && !(parseFloat(recordObj.btpPrice) > 0)) {
                        zeroBTPProducts.push(record.Product_L3__r.Name);
                    }
                }
            }

            if (zeroBTPProducts.length > 0) {
                this.showToast('Error', `BTP is zero for: ${zeroBTPProducts.join(", ")}. Please contact PMG.`, 'error');
                this.isLoading = false;
                return;
            }

            if (offerLine.length === 0) {
                this.showToast('Error', 'BTP/Sales price are missing', 'error');
                this.isLoading = false;
                return;
            }

            const fSetQty = this.fullSet ? this.fullSetQuantity : 0;

            await saveOffer({
                offerId: this.recordId,
                currCode: this.offCurrency,
                partListId: this.partId,
                recordStr: JSON.stringify(offerLine),
                l2l3MapStr: JSON.stringify(this.L2ProductMap),
                btpMap: this.BTPMap,
                fullSetQty: fSetQty,
                sOrgId: this.sOrgId,
                isWOS: this.wos,
                headerStr: JSON.stringify(this.headers),
                percent: 0
            });

            this.showToast('Success', 'Offer Products are created successfully.', 'success');

            if (shouldClose) {
                this.closeAction();
            }

        } catch (error) {
            this.handleError(error);
            this.showConfirmDialog = false;
        } finally {
            this.isLoading = false;
        }
    }

    buildL2HeaderString(record) {
        let result = "";
        
        this.headers.forEach(header => {
            if (header.isSelected) {
                const qty = record.quantityMapRecord.get(header.Name) || 0;
                result += `${header.Name}-${qty};`;
            }
        });

        return result;
    }

    getSetType() {
        if (this.fullSet) {
            return 'fullset';
        }

        let setType = '';
        this.headers.forEach(header => {
            if (header.isSelected) {
                setType = setType ? `${setType};${header.Name}` : header.Name;
            }
        });

        return setType;
    }

    handleCancel() {
        this.closeAction();
    }

    // Utility Methods
    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value || 0);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }

    handleError(error) {
        console.error('Error:', error);
        const message = error.body ? error.body.message : error.message;
        this.showToast('Error', message || 'An error occurred', 'error');
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}