import { LightningElement, track, wire } from 'lwc';
import getPicklistValuesLwc from '@salesforce/apex/DcBudgetLWCController.getPicklistValuesLwc';
import getDCBudgetAndChildItems from '@salesforce/apex/TegaCustomReportController.getDCBudgetAndChildItems';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
const FIELDS = ['User.Profile.Name'];
import getDatedConversionRate from '@salesforce/apex/TegaCustomReportController.getDatedConversionRate';

export default class TegaCustomReport extends LightningElement {

    userId = USER_ID;
    profileName;
    @track isLoading = false;
    @track selectedFY;
    @track financialYearOptions = [];
    @track selectedOrderType = '';
    @track OrderTypeOptions = [];
    @track budgetData = [];
    @track ConversionRateData = [];
    @track showTable = false;
    @track monthlyMatrix = [];
    @track selectedMonth = 'April';
    @track forecastTotal = 0;
    @track searchTermPMG = ''
    @track showForcast = true
    @track hasMultipleCurrencies = false;
    @track currencyCode = ''
    @track visibleMatrix = [];

    monthOptions = [
        { label: 'All', value: 'All' },
        { label: 'April', value: 'April' },
        { label: 'May', value: 'May' },
        { label: 'June', value: 'June' },
        { label: 'July', value: 'July' },
        { label: 'August', value: 'August' },
        { label: 'September', value: 'September' },
        { label: 'October', value: 'October' },
        { label: 'November', value: 'November' },
        { label: 'December', value: 'December' },
        { label: 'January', value: 'January' },
        { label: 'February', value: 'February' },
        { label: 'March', value: 'March' }
    ];


    months = [
        "April", "May", "June", "July", "August", "September",
        "October", "November", "December", "January", "February", "March"
    ];

    monthMap = {
        April: ['Apr_Order_Actual__c', 'Apr_Order__c'],
        May: ['May_Order_Actual__c', 'May_Order__c'],
        June: ['Jun_Order_Actual__c', 'Jun_Order__c'],
        July: ['Jul_Order_Actual__c', 'Jul_Order__c'],
        August: ['Aug_Order_Actual__c', 'Aug_Order__c'],
        September: ['Sep_Order_Actual__c', 'Sep_Order__c'],
        October: ['Oct_Order_Actual__c', 'Oct_Order__c'],
        November: ['Nov_Order_Actual__c', 'Nov_Order__c'],
        December: ['Dec_Order_Actual__c', 'Dec_Order__c'],
        January: ['Jan_Order_Actual__c', 'Jan_Order__c'],
        February: ['Feb_Order_Actual__c', 'Feb_Order__c'],
        March: ['Mar_Order_Actual__c', 'Mar_Order__c']
    };

    // Used to determine the forecast months for each selected month
    forecastFieldSequence = [
        'April', 'May', 'June', 'July', 'August', 'September',
        'October', 'November', 'December', 'January', 'February', 'March'
    ];

    // Maps forecast fields to months
    forecastFieldMap = {
        'April': ['Expected_Order_Value_May__c', 'Expected_Order_Value_June__c', 'Expected_Order_Value_Jul__c'],
        'May': ['Expected_Order_Value_June__c', 'Expected_Order_Value_Jul__c', 'Expected_Order_Value_Aug__c'],
        'June': ['Expected_Order_Value_Jul__c', 'Expected_Order_Value_Aug__c', 'Expected_Order_Value_Sep__c'],
        'July': ['Expected_Order_Value_Aug__c', 'Expected_Order_Value_Sep__c', 'Expected_Order_Value_Oct__c'],
        'August': ['Expected_Order_Value_Sep__c', 'Expected_Order_Value_Oct__c', 'Expected_Order_Value_Nov__c'],
        'September': ['Expected_Order_Value_Oct__c', 'Expected_Order_Value_Nov__c', 'Expected_Order_Value_Dec__c'],
        'October': ['Expected_Order_Value_Nov__c', 'Expected_Order_Value_Dec__c', 'Expected_Order_Value_Jan__c'],
        'November': ['Expected_Order_Value_Dec__c', 'Expected_Order_Value_Jan__c', 'Expected_Order_Value_Feb__c'],
        'December': ['Expected_Order_Value_Jan__c', 'Expected_Order_Value_Feb__c', 'Expected_Order_Value_Mar__c'],
        'January': ['Expected_Order_Value_Feb__c', 'Expected_Order_Value_Mar__c', 'Expected_Order_Value_April__c'],
        'February': ['Expected_Order_Value_Mar__c', 'Expected_Order_Value_April__c', 'Expected_Order_Value_May__c'],
        'March': ['Expected_Order_Value_April__c', 'Expected_Order_Value_May__c', 'Expected_Order_Value_June__c']
    };

    @wire(getRecord, { recordId: USER_ID, fields: FIELDS })
    userRecord({ error, data }) {
        if (data) {
            this.profileName = data.fields.Profile.displayValue || data.fields.Profile.value.fields.Name.value;
            console.log('🔐 Logged-in Profile:', this.profileName);
        } else if (error) {
            console.error('⚠️ Error fetching profile:', error);
        }
    }

    @wire(getPicklistValuesLwc, {
        ObjectApi_name: 'DC_Budget_Line_Items__c',
        Field_name: 'Order_Type__c'
    })
    handleOrderTypeOptions({ data, error }) {
        if (data) {
            this.OrderTypeOptions = [
                { label: 'None', value: '' },
                ...data.map(p => ({ label: p.label, value: p.value }))
            ];
        } else if (error) {
            console.error(error);
        }
    }

    connectedCallback() {
        this.generateFinancialYears();
        this.getAllBudgetAndChildRecords();
    }

    generateFinancialYears() {
        this.isLoading = true;
        const today = new Date();
        const currentMonth = today.getMonth() + 1;
        const currentYear = today.getFullYear();
        const fyStartYear = currentMonth >= 4 ? currentYear : currentYear - 1;

        const firstFyStartYear = 2025;
        let options = [];

        for (let year = firstFyStartYear; year <= fyStartYear; year++) {
            const endYear = (year + 1).toString().slice(-2);
            options.push({ label: `${year}-${endYear}`, value: `${year}-${endYear}` });
        }

        this.financialYearOptions = options;
        this.selectedFY = `${fyStartYear}-${(fyStartYear + 1).toString().slice(-2)}`;
        this.isLoading = false;
    }

    getAllBudgetAndChildRecords() {
        this.isLoading = true;

        Promise.all([getDatedConversionRate(), getDCBudgetAndChildItems()])
            .then(([conversionRateResult, budgetResult]) => {
                this.ConversionRateData = conversionRateResult;
                console.log('Currency', JSON.stringify(this.ConversionRateData))

                this.budgetData = budgetResult;
                if (this.profileName === 'PMG' || this.profileName === 'Sales' || this.profileName === 'Regional Manager') {
                    let currencySet = new Set();

                    budgetResult.forEach(budgetRecord => {
                        const lineItems = budgetRecord.Budget_Line_Items__r || [];
                        lineItems.forEach(line => {
                            if (line.CurrencyIsoCode) {
                                currencySet.add(line.CurrencyIsoCode);
                            }
                        });
                    });

                    this.hasMultipleCurrencies = currencySet.size > 1;
                    if (this.hasMultipleCurrencies === true) {
                        this.currencyCode = 'INR';
                    } else {
                        // Get the only currency from the set
                        const [singleCurrency] = Array.from(currencySet);
                        this.currencyCode = singleCurrency || 'INR';
                    }
                    this.processMonthlySummary(budgetResult);
                    console.log('🔍 Has Multiple Currencies:', this.hasMultipleCurrencies);
                } else {
                    this.currencyCode = 'INR';
                    this.processMonthlySummary(budgetResult);
                }

            })
            .catch(error => {
                console.error('❌ Error fetching data:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }


    processMonthlySummary(data) {
        if(data.length == 0){
            this.showTable = false;
            return;
        }
    let matrix = [];
    let cumulativeActual = 0;
    let cumulativeBudget = 0;

    for (const month of this.months) {
        const [actualField, budgetField] = this.monthMap[month];
        let monthlyActual = 0;
        let monthlyBudget = 0;
        let pmgName = ''; // default

        data.forEach(budgetRecord => {
            const lineItems = budgetRecord.Budget_Line_Items__r || [];
            const currency = budgetRecord.CurrencyIsoCode || 'INR';
            let conversionRate = 1;

            // Currency logic
            if ((this.profileName === 'System Administrator' || this.profileName === 'Ex-Com Leadership' || this.profileName === 'Leadership') && currency !== 'INR') {
                const matched = this.ConversionRateData.find(item => item.IsoCode === currency);
                if (matched?.ConversionRate) {
                    conversionRate = 1 / matched.ConversionRate;
                }
            } else if (this.profileName === 'System Administrator' || this.profileName === 'Ex-Com Leadership' || this.profileName === 'Leadership') {
                if (this.hasMultipleCurrencies && currency !== 'INR') {
                    const matched = this.ConversionRateData.find(item => item.IsoCode === currency);
                    if (matched?.ConversionRate) {
                        conversionRate = 1 / matched.ConversionRate;
                    }
                } else if (currency !== this.currencyCode) {
                    const matched = this.ConversionRateData.find(item => item.IsoCode === this.currencyCode);
                    if (matched?.ConversionRate) {
                        conversionRate = 1 / matched.ConversionRate;
                    }
                }
            }

            lineItems.forEach(line => {
                const actual = line[actualField] || 0;
                const budget = line[budgetField] || 0;

                monthlyActual += actual * conversionRate;
                monthlyBudget += budget * conversionRate;

                if (!pmgName && line.PMG_Name__c) {
                    pmgName = line.PMG_Name__c;
                }
            });
        });

        cumulativeActual += monthlyActual;
        cumulativeBudget += monthlyBudget;

        matrix.push({
            month: month,
            PMG_Name__c: pmgName,
            actual: parseFloat(monthlyActual.toFixed(2)),
            budgeted: parseFloat(monthlyBudget.toFixed(2)),
            received: parseFloat(cumulativeActual.toFixed(2)),
            expected: parseFloat(cumulativeBudget.toFixed(2))
        });
    }

    this.monthlyMatrix = matrix;
    this.calculateForecast(data);
    this.showTable = true;
}

    // calculateForecast(budgetData) {
    //     this.isLoading = true;
    //     let forecastSum = 0;
    //     const forecastFields = this.forecastFieldMap[this.selectedMonth] || [];

    //     /*console.log(`🔍 Calculating forecast for selected month: ${this.selectedMonth}`);
    //     console.log(`📅 Forecast Fields to sum:`, forecastFields);
    //     console.log('📦 budgetData:', JSON.stringify(budgetData));*/

    //     budgetData.forEach((budgetRecord, recordIndex) => {
    //         const lineItems = budgetRecord.Budget_Line_Items__r || [];

    //         lineItems.forEach((line, lineIndex) => {
    //             const misList = line.MIS_Budgets__r || [];

    //             misList.forEach((mis, misIndex) => {
    //                 forecastFields.forEach(field => {
    //                     const val = mis[field] || 0;
    //                     forecastSum += val;
    //                     //console.log(`📘 Record #${recordIndex} → Line #${lineIndex} → MIS #${misIndex} → ${field}: ${val}`);
    //                 });
    //             });
    //         });
    //     });

    //     this.forecastTotal = forecastSum;
    //     //console.log(`✅ Forecast Total from ${this.selectedMonth}: ₹${this.forecastTotal}`);
    //     this.isLoading = false;
    // }

/*calculateForecast(budgetData) {
    this.isLoading = true;
    let forecastSum = 0;
    const forecastFields = this.forecastFieldMap[this.selectedMonth] || [];

    budgetData.forEach((budgetRecord) => {
        const lineItems = budgetRecord.Budget_Line_Items__r || [];
        const currency = budgetRecord.CurrencyIsoCode || 'INR';
        let conversionRate = 1;

        // Currency logic at budget level
        if ((this.profileName === 'System Administrator' || this.profileName === 'Ex-Com Leadership' || this.profileName === 'Leadership') && currency !== 'INR') {
            const matched = this.ConversionRateData.find(item => item.IsoCode === currency);
            if (matched && matched.ConversionRate) {
                conversionRate = 1 / matched.ConversionRate;
            }
        } else if (this.profileName === 'System Administrator' || this.profileName === 'Ex-Com Leadership' || this.profileName === 'Leadership') {
            if (this.hasMultipleCurrencies && currency !== 'INR') {
                const matched = this.ConversionRateData.find(item => item.IsoCode === currency);
                if (matched && matched.ConversionRate) {
                    conversionRate = 1 / matched.ConversionRate;
                }
            } else if (currency !== this.currencyCode) {
                const matched = this.ConversionRateData.find(item => item.IsoCode === this.currencyCode);
                if (matched && matched.ConversionRate) {
                    conversionRate = 1 / matched.ConversionRate;
                }
            }
        }

        lineItems.forEach((line) => {
            const misList = line.MIS_Budgets__r || [];

            misList.forEach((mis) => {
                forecastFields.forEach(field => {
                    const val = mis[field] || 0;
                    forecastSum += val * conversionRate;
                });
            });
        });
    });

    this.forecastTotal = parseFloat(forecastSum.toFixed(2));
    this.updateVisibleMatrix();
    this.isLoading = false;
}*/

calculateForecast(budgetData) {
    this.isLoading = true;
    let forecastSum = 0;

    const forecastMonths = this.getNext3Months(this.selectedMonth); // ['July', 'August', 'September']
    const selectedYear = this.selectedFY ? this.selectedFY.split('-')[0] : new Date().getFullYear();
    console.log('📆 Forecast Months:', forecastMonths);
    console.log('📅 Selected Year:', selectedYear);

    // Mapping of field suffixes
    const monthFieldMap = {
        'April': 'Apr',
        'May': 'May',
        'June': 'Jun',
        'July': 'Jul',
        'August': 'Aug',
        'September': 'Sep',
        'October': 'Oct',
        'November': 'Nov',
        'December': 'Dec',
        'January': 'Jan',
        'February': 'Feb',
        'March': 'Mar'
    };

    const expectedValueFields = {
        'Apr': 'Expected_Order_Value_April__c',
        'May': 'Expected_Order_Value_May__c',
        'Jun': 'Expected_Order_Value_June__c',
        'Jul': 'Expected_Order_Value_Jul__c',
        'Aug': 'Expected_Order_Value_Aug__c',
        'Sep': 'Expected_Order_Value_Sep__c',
        'Oct': 'Expected_Order_Value_Oct__c',
        'Nov': 'Expected_Order_Value_Nov__c',
        'Dec': 'Expected_Order_Value_Dec__c',
        'Jan': 'Expected_Order_Value_Jan__c',
        'Feb': 'Expected_Order_Value_Feb__c',
        'Mar': 'Expected_Order_Value_Mar__c'
    };

    const expectedMonthFields = {
        'Apr': 'Order_Expected_Month_Apr__c',
        'May': 'Order_Expected_Month_May__c',
        'Jun': 'Order_Expected_Month_Jun__c',
        'Jul': 'Order_Expected_Month_Jul__c',
        'Aug': 'Order_Expected_Month_Aug__c',
        'Sep': 'Order_Expected_Month_Sep__c',
        'Oct': 'Order_Expected_Month_Oct__c',
        'Nov': 'Order_Expected_Month_Nov__c',
        'Dec': 'Order_Expected_Month_Dec__c',
        'Jan': 'Order_Expected_Month_Jan__c',
        'Feb': 'Order_Expected_Month_Feb__c',
        'Mar': 'Order_Expected_Month_Mar__c'
    };

    const forecastShortMonthTexts = forecastMonths.map(m => `${monthFieldMap[m]}, ${selectedYear}`);

    budgetData.forEach((budgetRecord) => {
        const lineItems = budgetRecord.Budget_Line_Items__r || [];
        const currency = budgetRecord.CurrencyIsoCode || 'INR';
        let conversionRate = 1;

        if ((this.profileName === 'System Administrator' || this.profileName === 'Ex-Com Leadership' || this.profileName === 'Leadership') && currency !== 'INR') {
            const matched = this.ConversionRateData.find(item => item.IsoCode === currency);
            if (matched?.ConversionRate) conversionRate = 1 / matched.ConversionRate;
        } else if (this.hasMultipleCurrencies && currency !== 'INR') {
            const matched = this.ConversionRateData.find(item => item.IsoCode === this.currencyCode);
            if (matched?.ConversionRate) conversionRate = 1 / matched.ConversionRate;
        }

        lineItems.forEach(line => {
            const misList = line.MIS_Budgets__r || [];

            misList.forEach(mis => {
                Object.entries(expectedMonthFields).forEach(([short, expectedMonthField]) => {
                    const expectedValue = mis[expectedMonthField];
                    const expectedText = expectedValue ? expectedValue.trim() : '';

                    if (forecastShortMonthTexts.includes(expectedText)) {
                        const valueField = expectedValueFields[short];
                        const value = mis[valueField] || 0;
                        forecastSum += value * conversionRate;

                        console.log(`✅ MATCH: ${valueField} = ${value} for ${expectedText} via ${expectedMonthField}`);
                    } else if (forecastShortMonthTexts.includes(`${short}, ${selectedYear}`)) {
                        console.log(`⛔ Mismatch: ${expectedMonthField} = ${expectedText} | Expected one of: ${forecastShortMonthTexts}`);
                    }
                });
            });
        });
    });

    console.log('📊 Final Forecast Total:', forecastSum);
    this.forecastTotal = parseFloat(forecastSum.toFixed(2));
    this.updateVisibleMatrix();
    this.isLoading = false;
}


getNext3Months(selectedMonth) {
    const idx = this.months.indexOf(selectedMonth);
    return [
        this.months[(idx + 1) % 12],
        this.months[(idx + 2) % 12],
        this.months[(idx + 3) % 12]
    ];
}

    handleFYChange(event) {
        this.selectedFY = event.detail.value;
        this.applyFiltersAndSummarize();
    }

    handleOrderTypeChange(event) {
        this.selectedOrderType = event.detail.value;
        this.applyFiltersAndSummarize();
    }

    handleMonthChange(event) {
        this.selectedMonth = event.detail.value;
        this.applyFiltersAndSummarize(); // so summary + forecast both recalculate
        
    }

    handleSearchPMG(event) {
        this.searchTermPMG = event.target.value
        this.applyFiltersAndSummarize();
    }

    applyFiltersAndSummarize() {
    if (!this.budgetData) return;

    let filteredData = [];

    this.budgetData.forEach(budgetRecord => {
        const filteredLineItems = (budgetRecord.Budget_Line_Items__r || []).filter(line => {
            const matchOrderType = !this.selectedOrderType || line.Order_Type__c === this.selectedOrderType;
            const matchFY = !this.selectedFY || line.Budget_FN_Year__c === this.selectedFY;

            const matchPMG = !this.searchTermPMG ||
                (line.PMG_Name__c && line.PMG_Name__c.toLowerCase().includes(this.searchTermPMG.toLowerCase()));

            return matchOrderType && matchFY && matchPMG;
        });

        if (filteredLineItems.length > 0) {
            filteredData.push({
                ...budgetRecord,
                Budget_Line_Items__r: filteredLineItems
            });
        }
    });

   // console.log('🔍 Filtered Budget Data:', JSON.stringify(filteredData, null, 2));

    this.processMonthlySummary(filteredData);
}




/*updateVisibleMatrix() {
    if (this.selectedMonth === "All") {
        this.showForcast = false;
        this.visibleMatrix = this.monthlyMatrix;
        return;
    }

    this.showForcast = true;

    const selectedIndex = this.months.indexOf(this.selectedMonth);
    if (selectedIndex === -1) {
        this.visibleMatrix = [];
        return;
    }

    const visibleMonths = selectedIndex > 0
        ? [this.months[selectedIndex - 1], this.selectedMonth]
        : [this.selectedMonth];

    this.visibleMatrix = this.monthlyMatrix
        .filter(row => visibleMonths.includes(row.month))
        .map(row => ({
            ...row,
            showForecast: row.month === this.selectedMonth
        }));
}*/
updateVisibleMatrix() {
    if (this.selectedMonth === "All") {
        this.showForcast = false;
        this.visibleMatrix = this.monthlyMatrix;
        return;
    }

    this.showForcast = true;

    this.visibleMatrix = this.monthlyMatrix
        .filter(row => row.month === this.selectedMonth)
        .map(row => ({
            ...row,
            showForecast: true
        }));
}

    exportToCSV() {
        try {
            if (!this.visibleMatrix || this.visibleMatrix.length === 0) {
                console.warn('No data to export.');
                return;
            }

            let csvContent = 'Monthly Matrix Report\n';
            csvContent += `Filtered FY:,${this.selectedFY || 'All'}\n`;
            csvContent += `Filtered Order Type:,${this.selectedOrderType || 'All'}\n`;
            csvContent += `Filtered Month:,${this.selectedMonth || 'All'}\n`;
            csvContent += `Forecast (next 3 months from ${this.selectedMonth || 'N/A'}):,₹${this.forecastTotal || 0}\n\n`;

            csvContent += 'Month,Actual,Budgeted,Received,Expected\n';
            this.visibleMatrix.forEach(row => {
                csvContent += `${row.month},${row.actual},${row.budgeted},${row.received},${row.expected}\n`;
            });

            const blob = new Blob(["\uFEFF" + csvContent], {
                type: 'application/octet-stream' // for compatibility
            });

            const url = URL.createObjectURL(blob);
            const link = document.createElement("a");
            link.setAttribute("href", url);
            link.setAttribute("download", "Monthly_Matrix_Report.csv");
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        } catch (error) {
            console.error("CSV Export Failed:", error);
            alert("An error occurred while exporting the report.");
        }
    }

    exportToExcel() {
        const baseUrl = '/apex/MonthlyMatrixExport';
        const params = new URLSearchParams({
            fy: this.selectedFY || 'All',
            orderType: this.selectedOrderType || 'All',
            month: this.selectedMonth || 'All',
            forecastTotal: this.forecastTotal || 0,
            jsonData: encodeURIComponent(JSON.stringify(this.visibleMatrix))
        });

        const fullUrl = `${baseUrl}?${params.toString()}`;
        window.open(fullUrl, '_blank');
    }



}