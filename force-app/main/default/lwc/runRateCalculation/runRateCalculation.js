import { LightningElement, track, wire } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
const FIELDS = ['User.Profile.Name', 'User.DefaultCurrencyIsoCode', 'User.Name', 'User.CurrencyIsoCode'];
import getDCBudgetAndChildItems from '@salesforce/apex/RunRateCalculationController.getDCBudgetAndChildItems';
import getDatedConversionRate from '@salesforce/apex/TegaCustomReportController.getDatedConversionRate';
import getDCBudgetRecordTypes from '@salesforce/apex/RunRateCalculationController.getDCBudgetRecordTypes';
import getPicklistValuesLwc from '@salesforce/apex/DcBudgetLWCController.getPicklistValuesLwc';
import getAllForm4E4DRecords from '@salesforce/apex/RunRateCalculationController.getAllForm4E4DRecords';
import getFinancialYears from '@salesforce/apex/RunRateCalculationController.getFinancialYears';

export default class RunRateCalculation extends LightningElement {

    userId = USER_ID;
    profileName;
    @track selectedOrderType = '';
    @track OrderTypeOptions = [];
    @track searchTermPMG = ''
    @track isLoading = false;
    @track selectedFY;
    @track financialYearOptions = [];
    @track ConversionRateData = [];
    @track selectedMonth = '';
    recordTypes = []
    developmentOutsideBudgetRecordTypeId
    @track form4E4DData = []; // NEW: Store all Form 4E/4D records
    @track showCurrecy = ''
    totalDays
    endDate
     @track selectedLevel1 = '';
     @track Level1Options = [
        { label: 'All', value: 'None' },
        { label: 'ASIA', value: 'ASIA' },
        { label: 'Australia', value: 'Australia' },
        { label: 'Europe', value: 'Europe' },
        { label: 'LATAM', value: 'LATAM' },
        { label: 'North America', value: 'North America' },
        { label: 'Russia', value: 'Russia' },
        { label: 'South Africa', value: 'South Africa' },
        { label: 'West Africa', value: 'West Africa' }

    ];
    @track selectedLevel2 = '';
    @track Level2Options = [];
    monthOptions = [
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
    @track showTable = true;

    @track budgetData = []
    @track AllbudgetData = [];

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
    @track hasMultipleCurrencies = false;
    @track currencyCode = ''
    @track processedRow = {
        budget: '0.00',
        month: 12,
        budgetRunRate: '0.00',
        actual: '0.00',
        actualRunRate: '0.00',
        requiredRunRate: '0.00'
    };

    // Add these mapping properties
    orderTypeMapping = {
        'E-Spares': ['Spare', 'Spare + Modification'],
        'P-Project': ['Project'],
        'C-Conversion': ['Competitor Conversion', 'Steel Conversion'],
        'S-Service': [] // No matching values
    };


    @wire(getRecord, { recordId: USER_ID, fields: FIELDS })
    userRecord({ error, data }) {
        if (data) {
            //console.log('⚙️ Raw user data:', JSON.stringify(data, null, 2));
            this.profileName = data.fields.Profile.displayValue || data.fields.Profile.value.fields.Name.value;
            this.currencyCode = data.fields.DefaultCurrencyIsoCode.value || 'INR'; // default to INR
            const userName = data.fields.Name.value
            this.showCurrecy = 'USD'
            //console.log('🔐 Logged-in Profile:', this.profileName);
            //console.log('🔐 Logged-in user currency:', this.currencyCode);
            //console.log('🔐 Logged-in user Name:',userName);
        } else if (error) {
            console.error('⚠️ Error fetching profile:', error);
        }
    }

    @wire(getPicklistValuesLwc, { ObjectApi_name: 'DC_Budget_Line_Items__c', Field_name: 'Order_Type__c' })
    handleOrderTypeOptions({ data, error }) {
        if (data) {
            this.OrderTypeOptions = [
                { label: 'None', value: '' },
                ...data.map(picklistValue => ({
                    label: picklistValue.label,
                    value: picklistValue.value
                }))
            ];
        } else if (error) {
            console.error(error);
        }
    }

    connectedCallback() {
        this.generateFinancialYears();
    }

    generateFinancialYears() {
        this.isLoading = true;
    
        getFinancialYears()
            .then(data => {
                if (data && data.length > 0) {
    
                    // Build combobox options
                    this.financialYearOptions = data.map(fy => ({
                        label: fy,
                        value: fy
                    }));
    
                    // --- Compute Current Financial Year ---
                    const today = new Date();
                    const month = today.getMonth() + 1; // April = 4
                    const year = today.getFullYear();
    
                    const fyStart = month >= 4 ? year : year - 1;   // FY starts in April
                    const fyEnd = (fyStart + 1).toString().slice(-2);
    
                    const currentFY = `${fyStart}-${fyEnd}`;
    
                    // --- Auto-select current FY if available ---
                    if (data.includes(currentFY)) {
                        this.selectedFY = currentFY;
                    } else {
                        // fallback: select last value from metadata
                        this.selectedFY = data[data.length - 1];
                    }
                    this.setDefaultSelectedMonth();
                    console.log('Selected FY', this.selectedFY);
                }
            })
            .catch(error => {
                console.error('Error fetching FY values: ', error);
            })
            .finally(() => {
                this.isLoading = false;
                this.getAllBudgetAndChildRecords();
            });
    }

    get showLevel2() {
        return ['ASIA', 'LATAM', 'North America'].includes(this.selectedLevel1);
    }

    get getColClass() {
        return this.showLevel2
            ? 'slds-col slds-size_1-of-1 slds-medium-size_1-of-4 slds-p-horizontal_small'
            : 'slds-col slds-size_1-of-1 slds-medium-size_1-of-4 slds-p-horizontal_small';
    }

    setDefaultSelectedMonth() {
        const today = new Date();
        const monthNames = [
            'January', 'February', 'March',
            'April', 'May', 'June',
            'July', 'August', 'September',
            'October', 'November', 'December'
        ];
        const currentMonthName = monthNames[today.getMonth()];
        this.selectedMonth = currentMonthName;
    }
    getAllBudgetAndChildRecords() {
        console.log('Selected FY ggg', this.selectedFY);
        this.isLoading = true;
        Promise.all([getDatedConversionRate( { SelectedFy: this.selectedFY } ), getDCBudgetAndChildItems({ selectedFY: this.selectedFY }) , getDCBudgetRecordTypes(), getAllForm4E4DRecords({ selectedFY: this.selectedFY })])
            .then(([conversionRateResult, budgetResult, recordtypeResult, formRecordsResult]) => {
                this.ConversionRateData = conversionRateResult;
                this.budgetData = budgetResult;
                this.AllbudgetData = budgetResult,
                this.recordTypes = recordtypeResult;
                this.developmentOutsideBudgetRecordTypeId = recordtypeResult.Development_Budget
                this.form4E4DData = formRecordsResult; // NEW: Store all form records
                //console.log('Record Types', JSON.stringify(this.recordTypes))
                //console.log('developmentOutsideBudgetRecordTypeId', this.developmentOutsideBudgetRecordTypeId)
                this.ProcessData(this.budgetData, this.form4E4DData);
                console.log('Budget Data', JSON.stringify(this.budgetData))
            })
            .catch(error => {
                console.error('❌ Error fetching data:', error);
                console.error('Error details:', JSON.stringify(error, null, 2));
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    //Commeting out this part temporary because of actual value source change
    /*ProcessData(data) {
    if (!data || data.length === 0) {
        this.showTable = false;
        return;
    }

    console.log('Data', JSON.stringify(data))
    this.isLoading = true;
    const ytdMonths = this.getYTDMonths();

    let totalBudget = 0;
    let ytdActual = 0;
    let ytdBudget = 0;

    // Calculate fiscal year dates
    const today = new Date();
    const fiscalStartYear = today.getMonth() >= 3 ? today.getFullYear() : today.getFullYear() - 1;
    const fiscalStartDate = new Date(fiscalStartYear, 3, 1); // April 1
    const fiscalEndDate = new Date(fiscalStartYear + 1, 2, 31); // March 31 next year
    const totalDaysInYear = Math.ceil((fiscalEndDate - fiscalStartDate) / (1000 * 60 * 60 * 24)) + 1;
    this.totalDays = totalDaysInYear;

    // Days elapsed till selected month (or today if current month)
    const monthMap = {
        'April': 3, 'May': 4, 'June': 5, 'July': 6, 'August': 7,
        'September': 8, 'October': 9, 'November': 10, 'December': 11,
        'January': 0, 'February': 1, 'March': 2
    };
    let endDateForCalculation;
    const selectedMonthIndex = monthMap[this.selectedMonth];

    if (selectedMonthIndex === today.getMonth() && today.getFullYear() === (selectedMonthIndex >= 3 ? fiscalStartYear : fiscalStartYear + 1)) {
        endDateForCalculation = today;
    } else {
        let yearOffset = selectedMonthIndex >= 3 ? fiscalStartYear : fiscalStartYear + 1;
        endDateForCalculation = new Date(yearOffset, selectedMonthIndex + 1, 0);
    }
    this.endDate = endDateForCalculation.toDateString();

    const daysElapsed = Math.ceil((endDateForCalculation - fiscalStartDate) / (1000 * 60 * 60 * 24));
    
    const daysRemaining = totalDaysInYear - daysElapsed;
    console.log('Days Elapsed', daysElapsed, 'Days Remaining', daysRemaining, )
    // Loop through records
    data.forEach(budgetRecord => {
        const currency = budgetRecord.CurrencyIsoCode || 'INR';
        const lineItems = budgetRecord.Budget_Line_Items__r || [];
        let conversionRate = 1;

        if (currency !== 'USD') {
                    const budgetCurrencyRateObj = this.ConversionRateData.find(item => item.IsoCode === currency);
                    const usdRateObj = this.ConversionRateData.find(item => item.IsoCode === 'USD');

                    const budgetToCorporateRate = budgetCurrencyRateObj?.ConversionRate || 1;
                    const usdToCorporateRate = usdRateObj?.ConversionRate || 1;

                    // CORRECT FORMULA: Convert budget currency → USD
                    conversionRate = usdToCorporateRate / budgetToCorporateRate;
                    console.log('budgetCurrencyRateObj', JSON.stringify(budgetCurrencyRateObj), 'usdRateObj', JSON.stringify(usdRateObj), 'budgetToCorporateRate', budgetToCorporateRate, 'usdToCorporateRate', usdToCorporateRate,)

                    console.log(`💰 1 ${currency} = ${1 / conversionRate} USD`); // For display
                    console.log(`🔄 Converting ${currency} → USD: rate = ${conversionRate.toFixed(6)}`);
                }

        lineItems.forEach(line => {
            // Full-year budget
            Object.keys(this.monthMap).forEach(month => {
                const field = this.monthMap[month][1]; // budget field (Order__c)
                totalBudget += (line[field] || 0) * conversionRate;
            });

            // YTD Budget (Order__c till selected month)
            ytdMonths.forEach(m => {
                const budgetField = `${m}_Order__c`;
                console.log('budgetField', budgetField)
                ytdBudget += (line[budgetField] || 0) * conversionRate;
            });

            // YTD Actual
            ytdMonths.forEach(m => {
                const actualField = `${m}_Order_Actual__c`;
                ytdActual += (line[actualField] || 0) * conversionRate;
            });
        });
    });

    // Run rates
    const yearlyRunRate = totalBudget / 12;
    const ytdRunRate = ytdBudget / ((daysElapsed / 365) * 12);
    const actualRunRate = ytdActual / ((daysElapsed / 365) * 12);
    const requiredRunRate = (totalBudget - ytdActual) / ((daysRemaining / 365) * 12);

    this.processedRow = {
        budget: this.formatToDisplay(totalBudget),
        yearlyRunRate: this.formatToDisplay(yearlyRunRate),
        ytdBudget: this.formatToDisplay(ytdBudget),
        ytdRunRate: this.formatToDisplay(ytdRunRate),
        actual: this.formatToDisplay(ytdActual),
        actualRunRate: this.formatToDisplay(actualRunRate),
        requiredRunRate: this.formatToDisplay(requiredRunRate)
    };

    this.showTable = true;
    this.isLoading = false;
}*/

ProcessData(budgetData, formData) {
    if ((!budgetData || budgetData.length === 0) && (!formData || formData.length === 0)) {
        this.showTable = false;
        return;
    }

let pmgDistribution = {};
let totalYtdByPMG = 0;
    //console.log('Budget Data', JSON.stringify(budgetData))
    //console.log('Form Data', JSON.stringify(formData))
    this.isLoading = true;
    const ytdMonths = this.getYTDMonths();

    let totalBudget = 0;
    let ytdActual = 0;
    let ytdBudget = 0;

    // Calculate fiscal year dates
    const today = new Date();
    const fiscalStartYear = today.getMonth() >= 3 ? today.getFullYear() : today.getFullYear() - 1;
    const fiscalStartDate = new Date(fiscalStartYear, 3, 1); // April 1
    const fiscalEndDate = new Date(fiscalStartYear + 1, 2, 31); // March 31 next year
    const totalDaysInYear = Math.ceil((fiscalEndDate - fiscalStartDate) / (1000 * 60 * 60 * 24)) + 1;
    this.totalDays = totalDaysInYear;

    // Days elapsed till selected month (or today if current month)
    const monthMap = {
        'April': 3, 'May': 4, 'June': 5, 'July': 6, 'August': 7,
        'September': 8, 'October': 9, 'November': 10, 'December': 11,
        'January': 0, 'February': 1, 'March': 2
    };
    let endDateForCalculation;
    const selectedMonthIndex = monthMap[this.selectedMonth];

    if (selectedMonthIndex === today.getMonth() && today.getFullYear() === (selectedMonthIndex >= 3 ? fiscalStartYear : fiscalStartYear + 1)) {
        endDateForCalculation = today;
    } else {
        let yearOffset = selectedMonthIndex >= 3 ? fiscalStartYear : fiscalStartYear + 1;
        endDateForCalculation = new Date(yearOffset, selectedMonthIndex + 1, 0);
    }
    this.endDate = endDateForCalculation.toDateString();

    const daysElapsed = Math.ceil((endDateForCalculation - fiscalStartDate) / (1000 * 60 * 60 * 24));
    const daysRemaining = totalDaysInYear - daysElapsed;
    
    //console.log('Days Elapsed', daysElapsed, 'Days Remaining', daysRemaining);

    // Get selected month number and YTD month numbers
    const ytdMonthNumbers = this.getYTDMonthNumbers();

    // Process BUDGET DATA if available
    if (budgetData && budgetData.length > 0) {
        budgetData.forEach(budgetRecord => {
            const currency = budgetRecord.CurrencyIsoCode || 'INR';
            const lineItems = budgetRecord.Budget_Line_Items__r || [];
            let conversionRate = 1;

            if (currency !== 'USD') {
                const budgetCurrencyRateObj = this.ConversionRateData.find(item => item.IsoCode === currency);
                const usdRateObj = this.ConversionRateData.find(item => item.IsoCode === 'USD');

                const budgetToCorporateRate = budgetCurrencyRateObj?.ConversionRate || 1;
                const usdToCorporateRate = usdRateObj?.ConversionRate || 1;

                conversionRate = usdToCorporateRate / budgetToCorporateRate;
                //console.log(`🔄 Converting ${currency} → USD: rate = ${conversionRate.toFixed(6)}`);
            }

            // Check if this is a development budget record
            const isDevelopmentBudget = budgetRecord.RecordTypeId === this.developmentOutsideBudgetRecordTypeId;
            const recordTypeId = budgetRecord.RecordTypeId;
           // console.log(`Budget Record: ${budgetRecord.Name},Budgeet RecordType Id : ${recordTypeId},development Outside Budget RecordType Id: ${this.developmentOutsideBudgetRecordTypeId} ,Is Development Budget: ${isDevelopmentBudget}`);

            // BUDGET CALCULATIONS: Process each line item
            lineItems.forEach(line => {
                // Skip if development budget
                if (!isDevelopmentBudget) {
                    // Full-year budget
                    Object.keys(this.monthMap).forEach(month => {
                        const field = this.monthMap[month][1]; // budget field (Order__c)
                        totalBudget += (line[field] || 0) * conversionRate;
                    });

                    // YTD Budget
                    ytdMonths.forEach(m => {
                        const budgetField = `${m}_Order__c`;
                        //console.log('budgetField', budgetField);
                        ytdBudget += (line[budgetField] || 0) * conversionRate;
                    });
                }
                
            });
        });
    }
   

    // Process FILTERED Form 4E/4D records for ACTUALS
    console.log(`Processing ${formData?.length || 0} Form 4E/4D records for actuals`);
    
    if (formData && formData.length > 0) {
        formData.forEach(record => {
            if (record.CreatedDate) {
                const createdDate = new Date(record.CreatedDate);
                const createdMonth = createdDate.getMonth() + 1; // 1-12
                const createdYear = createdDate.getFullYear();
                
                // Check if this record belongs to YTD months
                if (ytdMonthNumbers.includes(createdMonth)) {
                    const currency = record.CurrencyIsoCode || 'INR';
                    let conversionRate = 1;

                    // Currency conversion for form records
                    if (currency !== 'USD') {
                        const recordCurrencyRateObj = this.ConversionRateData.find(item => item.IsoCode === currency);
                        const usdRateObj = this.ConversionRateData.find(item => item.IsoCode === 'USD');

                        const recordToCorporateRate = recordCurrencyRateObj?.ConversionRate || 1;
                        const usdToCorporateRate = usdRateObj?.ConversionRate || 1;

                        conversionRate = usdToCorporateRate / recordToCorporateRate;
                    }

                    const poValue = record.End_Customer_PO_Value__c / 1000 || 0;
                    ytdActual += poValue * conversionRate;
                    
                    console.log(`✅ Added Form 4E/4D PO Value: ${poValue} for month ${createdMonth}, conversion rate: ${conversionRate}`);
                }
            }
        });
    }

    console.log(`📊 Final YTD Actual from FILTERED Form 4E/4D: ${ytdActual}`);
    console.log(`📊 Final Total Budget: ${totalBudget}`);
    console.log(`📊 Final YTD Budget: ${ytdBudget}`);

    // Run rates
    const yearlyRunRate = totalBudget / 12;
    const ytdRunRate = ytdBudget / ((daysElapsed / 365) * 12);
    const actualRunRate = ytdActual / ((daysElapsed / 365) * 12);
    const requiredRunRate = (totalBudget - ytdActual) / ((daysRemaining / 365) * 12);

    this.processedRow = {
        budget: this.formatToDisplay(totalBudget),
        yearlyRunRate: this.formatToDisplay(yearlyRunRate),
        ytdBudget: this.formatToDisplay(ytdBudget),
        ytdRunRate: this.formatToDisplay(ytdRunRate),
        actual: this.formatToDisplay(ytdActual),
        actualRunRate: this.formatToDisplay(actualRunRate),
        requiredRunRate: this.formatToDisplay(requiredRunRate)
    };

    this.showTable = true;
    this.isLoading = false;
}



getYTDMonthNumbers() {
    const fiscalMonthMap = {
        'April': 4, 'May': 5, 'June': 6, 'July': 7,
        'August': 8, 'September': 9, 'October': 10,
        'November': 11, 'December': 12, 'January': 1,
        'February': 2, 'March': 3
    };

    const selectedMonthNumber = fiscalMonthMap[this.selectedMonth];
    const ytdMonthNumbers = [];
    
    // Fiscal year starts with April (4)
    for (let month = 4; month <= selectedMonthNumber; month++) {
        ytdMonthNumbers.push(month);
    }
    
    // Handle January (1), February (2), March (3) - they come after December (12)
    if (selectedMonthNumber <= 3) {
        for (let month = 4; month <= 12; month++) {
            ytdMonthNumbers.push(month);
        }
        for (let month = 1; month <= selectedMonthNumber; month++) {
            ytdMonthNumbers.push(month);
        }
    }
    
    return ytdMonthNumbers;
}

    getYTDMonths() {
        const fiscalMonthMap = {
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

        const fiscalOrder = [
            'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep',
            'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'
        ];

        const selectedPrefix = fiscalMonthMap[this.selectedMonth];
        const index = fiscalOrder.findIndex(m => m === selectedPrefix);

        return fiscalOrder.slice(0, index + 1); // e.g. ['Apr', 'May', 'Jun'] for June
    }

    formatToDisplay(value) {
    const scaledValue = value * 1000;

    if (scaledValue >= 1_000_000) {
        return (scaledValue / 1_000_000).toFixed(2) + ' M';
    } else if (scaledValue >= 1_000) {
        return (scaledValue / 1_000).toFixed(2) + ' K';
    } else {
        return scaledValue.toFixed(2); // Less than 1K
    }
}



    handleMonthChange(event) {
        this.selectedMonth = event.detail.value;
        this.filterBudgetData();
        //this.ProcessData(this.budgetData);
    }
   
    handleFYChange(event) {
       this.selectedFY = event.detail.value;
       this.budgetData = [];
       this.ConversionRateData = [];
       this.form4E4DRecords = [];
       this.isLoading = true;
   
       console.log('Selected FY:', this.selectedFY);
   
       // Step 1: Fetch Budget + Child Records
       getDCBudgetAndChildItems({ selectedFY: this.selectedFY })
           .then(budgetResult => {
               this.budgetData = budgetResult;
               console.log('Budget Data:', JSON.stringify(this.budgetData));
   
               // Step 2: Fetch Conversion Rate
               return getDatedConversionRate({ SelectedFy: this.selectedFY });
           })
           .then(rateResult => {
               this.ConversionRateData = rateResult;
               console.log('Conversion Rates:', JSON.stringify(this.ConversionRateData));
   
               // Step 3: Fetch Form4/E4D Records
               return getAllForm4E4DRecords({ selectedFY: this.selectedFY });
           })
           .then(formResult => {
               this.form4E4DData = formResult;
               console.log('Form 4/E4D Data:', JSON.stringify(this.form4E4DData));
   
               // Step 4: Apply filters
               this.getAllBudgetAndChildRecords();
           })
           .catch(error => {
               console.error('Error while fetching FY data chain:', error);
           })
           .finally(() => {
               this.isLoading = false;
           });
   }
    handleOrderTypeChange(event) {
        this.selectedOrderType = event.target.value;
        this.filterBudgetData();
    }

    handleSearchPMG(event) {
        this.searchTermPMG = event.target.value;

        this.filterBudgetData();

    }
    handleLevel1Change(event) {
        this.selectedLevel1 = event.detail.value;
        if (this.selectedLevel1 === 'None') {
            this.selectedLevel2 = ''; // or 'None'
        }
        this.selectedLevel2 = ''; // Reset Level 2

        switch (this.selectedLevel1) {
            case 'ASIA':
                this.Level2Options = [
                    { label: 'INDIA', value: 'INDIA' },
                    { label: 'MEA', value: 'MEA' }
                ];
                break;
            case 'LATAM':
                this.Level2Options = [
                    { label: 'BRAZIL', value: 'BRAZIL' },
                    { label: 'CHILE', value: 'CHILE' },
                    { label: 'PERU', value: 'PERU' }
                ];
                break;
            case 'North America':
                this.Level2Options = [
                    { label: 'CANADA', value: 'CANADA' },
                    { label: 'USA', value: 'USA' },
                    { label: 'MEXICO', value: 'MEXICO' }
                ];
                break;
            default:
                this.Level2Options = [];
                break;
        }
        this.filterBudgetData();
    }

    handleLevel2Change(event) {
        this.selectedLevel2 = event.detail.value;
        this.filterBudgetData();
    }

    filterBudgetData() {

        if (!this.budgetData || this.budgetData.length === 0) {
            this.showTable = false;
            return;
        }

        const branchRegionMap = {
        'BHL': { level1: 'ASIA', level2: 'INDIA' },
        'RKL': { level1: 'ASIA', level2: 'INDIA' },
        'BDSH': { level1: 'ASIA', level2: 'INDIA' },
        'BOK': { level1: 'ASIA', level2: 'INDIA' },
        'DGP': { level1: 'ASIA', level2: 'INDIA' },
        'SING': { level1: 'ASIA', level2: 'INDIA' },
        'BRL': { level1: 'ASIA', level2: 'INDIA' },
        'CTC': { level1: 'ASIA', level2: 'INDIA' },
        'JSR': { level1: 'ASIA', level2: 'INDIA' },
        'HO': { level1: 'ASIA', level2: 'INDIA' },
        'BLR': { level1: 'ASIA', level2: 'INDIA' },
        'CHN': { level1: 'ASIA', level2: 'INDIA' },
        'GOA': { level1: 'ASIA', level2: 'INDIA' },
        'HSP': { level1: 'ASIA', level2: 'INDIA' },
        'HYD': { level1: 'ASIA', level2: 'INDIA' },
        'MUM': { level1: 'ASIA', level2: 'INDIA' },
        'VZG': { level1: 'ASIA', level2: 'INDIA' },
        'AHM': { level1: 'ASIA', level2: 'INDIA' },
        'DLI': { level1: 'ASIA', level2: 'INDIA' },
        'UDR': { level1: 'ASIA', level2: 'INDIA' },
        'MEA': { level1: 'ASIA', level2: 'MEA' },

        // Australia
        'AUA': { level1: 'Australia' },
        'A2': { level1: 'Australia' }, 'A6': { level1: 'Australia' }, 'A17': { level1: 'Australia' },
        'A1': { level1: 'Australia' }, 'A15': { level1: 'Australia' }, 'A9': { level1: 'Australia' },
        'A13': { level1: 'Australia' }, 'A8': { level1: 'Australia' }, 'A4': { level1: 'Australia' },
        'A14': { level1: 'Australia' }, 'A5': { level1: 'Australia' }, 'A7': { level1: 'Australia' },
        'A10': { level1: 'Australia' }, 'A16': { level1: 'Australia' }, 'A3': { level1: 'Australia' },
        'A12': { level1: 'Australia' }, 'TAP': { level1: 'Australia' }, 'A11': { level1: 'Australia' },

        // Europe
        'ATK': { level1: 'Europe' }, 'BEL': { level1: 'Europe' }, 'FIN': { level1: 'Europe' },
        'FRE': { level1: 'Europe' }, 'IRE': { level1: 'Europe' }, 'NLD': { level1: 'Europe' },
        'PORT': { level1: 'Europe' }, 'SPN': { level1: 'Europe' }, 'SWD': { level1: 'Europe' },
        'UK': { level1: 'Europe' },

        // LATAM
        'BRA': { level1: 'LATAM', level2: 'BRAZIL' },
        'CAF': { level1: 'LATAM', level2: 'CHILE' },
        'ARG': { level1: 'LATAM', level2: 'CHILE' },
        'CBV': { level1: 'LATAM', level2: 'CHILE' },
        'CCA': { level1: 'LATAM', level2: 'CHILE' },
        'CHIL': { level1: 'LATAM', level2: 'CHILE' },
        'CCM': { level1: 'LATAM', level2: 'CHILE' },
        'CCO': { level1: 'LATAM', level2: 'CHILE' },
        'CCQ': { level1: 'LATAM', level2: 'CHILE' },
        'CIQ': { level1: 'LATAM', level2: 'CHILE' },
        'CSG': { level1: 'LATAM', level2: 'CHILE' },
        'CSA': { level1: 'LATAM', level2: 'CHILE' },
        'PER': { level1: 'LATAM', level2: 'PERU' },

        // North America
        'CND': { level1: 'North America', level2: 'CANADA' },
        'MEX': { level1: 'North America', level2: 'MEXICO' },
        'USA': { level1: 'North America', level2: 'USA' },

        // Russia
        'RUS': { level1: 'Russia' },

        // South Africa
        'BOT': { level1: 'South Africa' }, 'DRC': { level1: 'South Africa' },
        'GAU': { level1: 'South Africa' }, 'KZN': { level1: 'South Africa' },
        'LIS': { level1: 'South Africa' }, 'MMM': { level1: 'South Africa' },
        'NAM': { level1: 'South Africa' }, 'NAF': { level1: 'South Africa' },
        'NCF': { level1: 'South Africa' }, 'NWM': { level1: 'South Africa' },
        'PLK': { level1: 'South Africa' }, 'RST': { level1: 'South Africa' },
        'SAF': { level1: 'South Africa' }, 'STP': { level1: 'South Africa' },
        'TAN': { level1: 'South Africa' }, 'SAHO': { level1: 'South Africa' },
        'ZAM': { level1: 'South Africa' }, 'ZIM': { level1: 'South Africa' },

        // West Africa
        'EGY': { level1: 'West Africa' }, 'GHN': { level1: 'West Africa' },
        'GUI': { level1: 'West Africa' }, 'MALI': { level1: 'West Africa' },
        'MOR': { level1: 'West Africa' }
        };


        const pmgSearch = this.searchTermPMG?.toLowerCase();
        //console.log('searchTermPMG', pmgSearch)
        const orderTypeFilter = this.selectedOrderType;

        const level1Selected = this.selectedLevel1 && this.selectedLevel1 !== 'None';
    const level2Selected = this.selectedLevel2 && this.selectedLevel2 !== 'None';

        const filtered = this.budgetData.filter(budget => {
            const lineItems = budget.Budget_Line_Items__r || [];
            //console.log('lineItems', JSON.stringify(lineItems));
            // Check if at least one line item matches both filters
            return lineItems.some(item => {
                const pmgMatch = pmgSearch
                    ? (item.PMG_Master__r?.Name || '').toLowerCase().includes(pmgSearch)
                    : true;

                const orderTypeMatch = orderTypeFilter
                    ? item.Order_Type__c === orderTypeFilter
                    : true;

                return pmgMatch && orderTypeMatch;
            });
        });

        // Filter Form 4E/4D Data
        const filteredFormData = this.filterForm4E4DData(this.form4E4DData, pmgSearch, orderTypeFilter);


        this.ProcessData(filtered ,filteredFormData);
    }

    filterForm4E4DData(formData, pmgSearch, orderTypeFilter) {
        console.log('formData', JSON.stringify(formData))
    if (!formData || formData.length === 0) return [];

    return formData.filter(record => {
        // PMG Filter Logic
        let pmgMatch = true;
        if (pmgSearch) {
            const recordPMG = record.PMG__c || '';
            const recordPMGLower = recordPMG.toLowerCase();
            const searchTermLower = pmgSearch.toLowerCase();

            // Special case: "Trommel/Screen" should match both "Trommel/Screen" and "Trommel/Screen" (same)
            if (searchTermLower.includes('trommel') || searchTermLower.includes('screen')) {
                pmgMatch = recordPMGLower.includes('trommel') || recordPMGLower.includes('screen');
            } else {
                // Exact match for other PMG values
                pmgMatch = recordPMGLower.includes(searchTermLower);
            }
        }

        // Order Type Filter Logic
        let orderTypeMatch = true;
        if (orderTypeFilter) {
            const recordOrderType = record.Order_Category__c;
            const mappedOrderTypes = this.orderTypeMapping[orderTypeFilter];
            console.log('mappedOrderTypes', JSON.stringify(mappedOrderTypes))
            
            if (orderTypeFilter === 'S-Service') {
                // S-Service has no matching values, so exclude all records
                orderTypeMatch = false;
            } else if (mappedOrderTypes && mappedOrderTypes.length > 0) {
                // Check if record's order type matches any of the mapped values
                orderTypeMatch = mappedOrderTypes.includes(recordOrderType);
            } else {
                // Direct match for other order types
                orderTypeMatch = recordOrderType === orderTypeFilter;
            }
        }

        return pmgMatch && orderTypeMatch;
    });
}
}