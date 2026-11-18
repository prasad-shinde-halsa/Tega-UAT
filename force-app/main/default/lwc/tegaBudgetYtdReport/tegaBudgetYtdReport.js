import { LightningElement, track, wire, api } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
const FIELDS = ['User.Profile.Name', 'User.DefaultCurrencyIsoCode', 'User.Name', 'User.CurrencyIsoCode'];
import getPicklistValuesLwc from '@salesforce/apex/DcBudgetLWCController.getPicklistValuesLwc';
import getDCBudgetAndChildItems from '@salesforce/apex/TegaCustomReportController.getDCBudgetAndChildItems';
import getDatedConversionRate from '@salesforce/apex/TegaCustomReportController.getDatedConversionRate';
import getAllForm4E4DRecords from '@salesforce/apex/TegaCustomReportController.getAllForm4E4DRecords';
import getDCBudgetRecordTypes from '@salesforce/apex/TegaCustomReportController.getDCBudgetRecordTypes';
import getFinancialYears from '@salesforce/apex/TegaCustomReportController.getFinancialYears';
import getVisitReportUrl from '@salesforce/apex/TegaCustomReportController.getVisitReportUrl';

export default class TegaBudgetYtdReport extends LightningElement {

    @api budgetIds = '';
    @track soqlReadyList = []
    userId = USER_ID;
    profileName;
    @track isLoading = false;
    @track selectedFY;
    @track financialYearOptions = [];
    @track selectedOrderType = '';
    @track OrderTypeOptions = [];
    @track form4E4DData = [];
    @track selectedMonth = '';
    @track selectedQuarter = '';
    recordTypes = [];
    developmentOutsideBudgetRecordTypeId
    @track selectedLevel1 = '';
    @track showCurrecy = ''
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
    @track visitReportUrl = '';

    @track quarterOptions = [
        { label: 'All Quarters', value: '' },
        { label: 'Q1 (April - June)', value: 'Q1' },
        { label: 'Q2 (July - September)', value: 'Q2' },
        { label: 'Q3 (October - December)', value: 'Q3' },
        { label: 'Q4 (January - March)', value: 'Q4' }
    ];

    quarterMonthsMap = {
        'Q1': ['April', 'May', 'June'],
        'Q2': ['July', 'August', 'September'],
        'Q3': ['October', 'November', 'December'],
        'Q4': ['January', 'February', 'March']
    };

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

    @track budgetData = [];
    @track ConversionRateData = [];
    @track hasMultipleCurrencies = false;
    @track currencyCode = ''
    @track showTable = true;

    PMG_CATEGORIES = [
        'Mill',
        'Screen',
        'Wear Component',
        'Conveyor Component',
        'Hydrocyclone',
        'Trommel'
    ];

    @track visibleMatrix = [];

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

    months = [
        "April", "May", "June", "July", "August", "September",
        "October", "November", "December", "January", "February", "March"
    ];

    orderTypeMapping = {
        'E-Spares': ['Spare', 'Spare + Modification'],
        'P-Project': ['Project'],
        'C-Conversion': ['Competitor Conversion', 'Steel Conversion'],
        'S-Service': []
    };

    @track pmgForecastData = [];
    @track totalsRow = {};

    @wire(getRecord, { recordId: USER_ID, fields: FIELDS })
    userRecord({ error, data }) {
        if (data) {
            this.profileName = data.fields.Profile.displayValue || data.fields.Profile.value.fields.Name.value;
            this.currencyCode = data.fields.DefaultCurrencyIsoCode.value || 'USD';
            this.showCurrecy = 'USD'
        } else if (error) {
            console.error('Error fetching profile:', error);
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

    get showLevel2() {
        return ['ASIA', 'LATAM', 'North America'].includes(this.selectedLevel1);
    }

    get getColClass() {
        return this.showLevel2
            ? 'slds-col slds-size_1-of-1 slds-medium-size_1-of-6 slds-p-horizontal_small'
            : 'slds-col slds-size_1-of-1 slds-medium-size_1-of-5 slds-p-horizontal_small';
    }

    get monthlyHeaderLabel() {
        if (this.selectedQuarter) {
            const quarterLabels = {
                'Q1': 'Q1 (April - June)',
                'Q2': 'Q2 (July - September)',
                'Q3': 'Q3 (October - December)',
                'Q4': 'Q4 (January - March)'
            };
            return quarterLabels[this.selectedQuarter] || 'Monthly';
        }
        return this.selectedMonth || 'Monthly';
    }

    connectedCallback() {
        this.generateFinancialYears();
        this.loadVisitReportUrl();
    }

    loadVisitReportUrl() {
        getVisitReportUrl()
            .then(result => {
                this.visitReportUrl = result;
                console.log('URL = ', result);
            })
            .catch(error => {
                console.error(error);
            });
    }

    handleVisitReports() {
        if (this.visitReportUrl) {
            window.open(this.visitReportUrl, '_blank');
        } else {
            alert('Visit Report URL not configured.');
        }
    }

    generateFinancialYears() {
        this.isLoading = true;

        getFinancialYears()
            .then(data => {
                if (data && data.length > 0) {
                    this.financialYearOptions = data.map(fy => ({
                        label: fy,
                        value: fy
                    }));

                    const today = new Date();
                    const month = today.getMonth() + 1;
                    const year = today.getFullYear();

                    const fyStart = month >= 4 ? year : year - 1;
                    const fyEnd = (fyStart + 1).toString().slice(-2);
                    const currentFY = `${fyStart}-${fyEnd}`;

                    if (data.includes(currentFY)) {
                        this.selectedFY = currentFY;
                    } else {
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
        this.isLoading = true;

        if (this.budgetIds) {
            let cleaned;
            if (Array.isArray(this.budgetIds)) {
                cleaned = this.budgetIds.join(',');
            } else {
                cleaned = this.budgetIds.replace(/[\[\]]/g, '');
            }

            this.soqlReadyList = cleaned
                .split(',')
                .map(id => id.trim().replace(/;$/, ''))
                .filter(id => id !== '');
        } else {
            this.soqlReadyList = [];
        }

        Promise.all([
            getDatedConversionRate({ SelectedFy: this.selectedFY }),
            getDCBudgetAndChildItems({ selectedFY: this.selectedFY, budgetIds: this.soqlReadyList }),
            getDCBudgetRecordTypes(),
            getAllForm4E4DRecords({ selectedFY: this.selectedFY })
        ])
            .then(([conversionRateResult, budgetResult, recordtypeResult, formRecordsResult]) => {
                this.ConversionRateData = conversionRateResult;
                this.recordTypes = recordtypeResult;
                this.developmentOutsideBudgetRecordTypeId = recordtypeResult.Development_Budget;
                this.form4E4DData = formRecordsResult;
                this.budgetData = budgetResult;
                this.applyFiltersAndSummarize();
            })
            .catch(error => {
                console.error('Error fetching data:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    calculateAchievement(actual, budget) {
        console.log('Calculating achievement with actual:', actual, 'and budget:', budget);
        const actualNum = this.reverseFormat(actual);
        const budgetNum = this.reverseFormat(budget);
        if (!budgetNum || budgetNum === 0) return '0.00 %';
        const pct = (actualNum / budgetNum) * 100;
        return pct.toFixed(2) + ' %';
    }

    calculateFullYearForecast(ytdActualRaw, forecastMISRaw, ytdBudgetRaw, fullYearBudgetRaw) {
        const ytdActual = ytdActualRaw;
        const forecastMIS = forecastMISRaw;
        const ytdBudget = ytdBudgetRaw;
        const fullYearBudget = fullYearBudgetRaw;
        const remainingBudget = fullYearBudget - ytdBudget;
        const fullYearForecast = ytdActual + forecastMIS + (remainingBudget > 0 ? remainingBudget : 0);
        return fullYearForecast;
    }

    processPMGRows(data, formData) {
        if (!data || data.length === 0) {
            this.visibleMatrix = [];
            this.showTable = false;
            return;
        }

        this.isLoading = true;
        const matrix = [];

        const ytdMonths = this.getYTDMonths();
        const forecastMonths = this.getNext3Months(this.selectedMonth);
        const selectedYear = this.selectedFY ? this.selectedFY.split('-')[0] : new Date().getFullYear();

        // Determine which months to aggregate for "Monthly" columns
        let monthsToAggregate = [this.selectedMonth];
        if (this.selectedQuarter) {
            monthsToAggregate = this.quarterMonthsMap[this.selectedQuarter];
        }

        const monthFieldMap = {
            'April': 'Apr', 'May': 'May', 'June': 'Jun', 'July': 'Jul',
            'August': 'Aug', 'September': 'Sep', 'October': 'Oct', 'November': 'Nov',
            'December': 'Dec', 'January': 'Jan', 'February': 'Feb', 'March': 'Mar'
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

        const forecastShortMonthTexts = forecastMonths.map(m => {
            const short = monthFieldMap[m];
            let year = parseInt(selectedYear);
            const selectedMonthIsQ4 = ['January', 'February', 'March'].includes(this.selectedMonth);
            const monthIsInNextFY = ['April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'].includes(m);
            if (selectedMonthIsQ4 && monthIsInNextFY) {
                year += 1;
            }
            return `${short}, ${year}`;
        });

        // NEW: short month codes only (no year) — for Proposal_Form__c picklist matching
        const forecastShortMonthsOnly = forecastMonths.map(m => monthFieldMap[m]);

        const allFiscalMonthPrefixes = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'];

        for (const pmg of this.PMG_CATEGORIES) {
            let monthlyActual = 0;
            let monthlyBudget = 0;
            let ytdActual = 0;
            let ytdBudget = 0;
            let forecastMIS = 0;
            let forecastMIS2 = 0;
            let forecastBudget = 0;
            let fullYearBudget = 0;

            const ytdMonthNumbers = this.getYTDMonthNumbers();

            // Get month numbers for all months to aggregate (quarter or single month)
            const monthNumbersToAggregate = monthsToAggregate.map(m => this.getMonthNumber(m));

            // PROCESS FORM 4E/4D RECORDS FOR ACTUALS
            if (formData && formData.length > 0) {
                formData.forEach(record => {
                    if (record.CreatedDate) {
                        const recordPMG = record.PMG__c;
                        const normalizedPMG = (recordPMG === 'Trommel') ? 'Screen' : recordPMG;
                        if (normalizedPMG !== pmg) return;

                        const createdDate = new Date(record.CreatedDate);
                        const createdMonth = createdDate.getMonth() + 1;

                        const currency = record.CurrencyIsoCode || 'INR';
                        let conversionRate = 1;

                        if (currency !== 'USD') {
                            const recordCurrencyRateObj = this.ConversionRateData.find(item => item.IsoCode === currency);
                            const usdRateObj = this.ConversionRateData.find(item => item.IsoCode === 'USD');
                            const recordToCorporateRate = recordCurrencyRateObj?.ConversionRate || 1;
                            const usdToCorporateRate = usdRateObj?.ConversionRate || 1;
                            conversionRate = usdToCorporateRate / recordToCorporateRate;
                        }

                        const poValue = record.End_Customer_PO_Value__c / 1000 || 0;
                        const convertedValue = poValue * conversionRate;

                        // Check if month is in the aggregation list (quarter months or single month)
                        if (monthNumbersToAggregate.includes(createdMonth)) {
                            monthlyActual += convertedValue;
                        }

                        if (ytdMonthNumbers.includes(createdMonth)) {
                            ytdActual += convertedValue;
                        }
                    }
                });
            }

            // PROCESS BUDGET DATA
            data.forEach(budgetRecord => {
                const currency = budgetRecord.CurrencyIsoCode || 'INR';
                const lineItems = budgetRecord.Budget_Line_Items__r || [];
                let conversionRate = 1;

                if (currency !== 'USD') {
                    const budgetCurrencyRateObj = this.ConversionRateData.find(item => item.IsoCode === currency);
                    const usdRateObj = this.ConversionRateData.find(item => item.IsoCode === 'USD');
                    const budgetToCorporateRate = budgetCurrencyRateObj?.ConversionRate || 1;
                    const usdToCorporateRate = usdRateObj?.ConversionRate || 1;
                    conversionRate = usdToCorporateRate / budgetToCorporateRate;
                }

                const isDevelopmentBudget = budgetRecord.RecordTypeId === this.developmentOutsideBudgetRecordTypeId;

                lineItems.forEach(line => {
                    if (line.PMG_Name__c !== pmg) return;

                    if (!isDevelopmentBudget) {
                        // Aggregate budget for all months in quarter (or just selected month)
                        monthsToAggregate.forEach(month => {
                            const budgetField = this.monthMap[month]?.[1];
                            if (budgetField) {
                                const budget = line[budgetField] || 0;
                                monthlyBudget += budget * conversionRate;
                            }
                        });

                        ytdMonths.forEach(m => {
                            ytdBudget += (line[`${m}_Order__c`] || 0) * conversionRate;
                        });

                        // Full Year Budget - sum all 12 months
                        allFiscalMonthPrefixes.forEach(m => {
                            fullYearBudget += (line[`${m}_Order__c`] || 0) * conversionRate;
                        });

                        forecastMonths.forEach(nextMonth => {
                            const forecastBudgetField = this.monthMap[nextMonth]?.[1];
                            if (forecastBudgetField) {
                                forecastBudget += (line[forecastBudgetField] || 0) * conversionRate;
                            }
                        });
                    }

                    // FORECAST MIS

                    
                    const misList = line.MIS_Budgets__r || [];

                    if (pmg === 'Mill') {  // limit noise — just log for one PMG while debugging
        console.log('FY:', this.selectedFY, '| Looking for:', forecastShortMonthTexts);
        misList.forEach(mis => {
            console.log('Jul field raw value:', JSON.stringify(mis.Order_Expected_Month_Jul__c));
            console.log('Aug field raw value:', JSON.stringify(mis.Order_Expected_Month_Aug__c));
            console.log('Sep field raw value:', JSON.stringify(mis.Order_Expected_Month_Sep__c));
        });
    }
                    misList.forEach(mis => {
                        Object.entries(expectedMonthFields).forEach(([short, expectedMonthField]) => {
                            const expectedText = mis[expectedMonthField]?.trim();
                            if (forecastShortMonthTexts.includes(expectedText)) {
                                const value = mis[expectedValueFields[short]] || 0;
                                forecastMIS += value * conversionRate;
                            }
                        });
                    });


                    // NEW: Forecast - Next 3 months (MIS)-2, from Proposal_Form__c
                    const proposalList = line.Proposal_Form__r || [];
                                        
                    if (pmg === 'Mill' && proposalList.length > 0) {
                        console.log('Proposal list for line', line.Id, JSON.stringify(proposalList));
                        console.log('Looking for months:', forecastShortMonthsOnly);
                    }
                    proposalList.forEach(proposal => {
                        const expectedMonth = proposal.Order_Expected_Month__c?.trim();
                        if (forecastShortMonthsOnly.includes(expectedMonth)) {
                            const value = proposal.Total_Price_Quoted__c/1000 || 0;
                            forecastMIS2 += value * conversionRate;
                        }
                    });
                   
                });
            });

            // Calculate derived columns
            const achievementPct = (monthlyBudget > 0) ? ((monthlyActual / monthlyBudget) * 100).toFixed(2) + ' %' : '0.00 %';
            //const achievementPct = (monthlyBudget > 0) ? ((this.formatToDisplay(monthlyActual) / this.formatToDisplay(monthlyBudget)) * 100).toFixed(2) + ' %' : '0.00 %';
            const ytdAchievementPct = (ytdBudget > 0) ? ((ytdActual / ytdBudget) * 100).toFixed(2) + ' %' : '0.00 %';

            // Full Year Forecast = YTD Actual + Forecast MIS + Remaining Budget
            const remainingBudget = fullYearBudget - ytdBudget;
            //const fullYearForecastRaw = ytdActual + forecastMIS + (remainingBudget > 0 ? remainingBudget : 0);
            const fullYearForecastRaw = ytdActual + forecastMIS2 + (remainingBudget > 0 ? remainingBudget : 0);

            console.log('PMG RAW VALUES =>', {
                pmg: pmg,
                monthlyBudget: monthlyBudget,
                monthlyActual: monthlyActual,
                achievementPct: monthlyBudget > 0 ? ((monthlyActual / monthlyBudget) * 100) : 0,

                ytdBudget: ytdBudget,
                ytdActual: ytdActual,
                ytdAchievementPct: ytdBudget > 0 ? ((ytdActual / ytdBudget) * 100) : 0,

                forecastBudget: forecastBudget,
                forecastMIS: forecastMIS,
                forecastMIS2: forecastMIS2,
                fullYearBudget: fullYearBudget,
                remainingBudget: fullYearBudget - ytdBudget,
                fullYearForecast:
                    ytdActual + forecastMIS2 + ((fullYearBudget - ytdBudget) > 0 ? (fullYearBudget - ytdBudget) : 0)
            });

            matrix.push({
                pmg,
                budgetedOrder: this.formatToDisplay(monthlyBudget),
                monthlyReceived: this.formatToDisplay(monthlyActual),
                //achievement: achievementPct, // logic is to display percent based on raw values
                achievement: this.calculateAchievement(
                    this.formatToDisplay(monthlyActual),
                    this.formatToDisplay(monthlyBudget)
                ),  // this i am using to show actual value after formated 
                ytdBudget: this.formatToDisplay(ytdBudget),
                ytdActual: this.formatToDisplay(ytdActual),
                //ytdAchievement: ytdAchievementPct,
                ytdAchievement: this.calculateAchievement(
                    this.formatToDisplay(ytdActual),
                    this.formatToDisplay(ytdBudget)
                ),
                forecastMIS: this.formatToDisplay(forecastMIS),
                forecastMIS2: this.formatToDisplay(forecastMIS2),
                fullYearBudget: this.formatToDisplay(fullYearBudget),
                fullYearForecast: this.formatToDisplay(fullYearForecastRaw),
                forecastBudget: this.formatToDisplay(forecastBudget)
            });
        }

        this.visibleMatrix = matrix;


        const sumFields = ['budgetedOrder', 'monthlyReceived', 'ytdBudget', 'ytdActual', 'forecastMIS','forecastMIS2', 'fullYearBudget','fullYearForecast', 'forecastBudget'];
        let totals = {};


        sumFields.forEach(field => {
            const sum = matrix.reduce((acc, row) => acc + this.reverseFormat(row[field]), 0);
            totals[field] = this.formatToDisplay(sum / 1000);
        });

        //added
        const totalBudgetRaw = this.reverseFormat(totals.budgetedOrder);
        const totalActualRaw = this.reverseFormat(totals.monthlyReceived);
        totals.achievement = totalBudgetRaw > 0
            ? ((totalActualRaw / totalBudgetRaw) * 100).toFixed(2) + ' %'
            : '0.00 %';

        const totalYtdBudgetRaw = this.reverseFormat(totals.ytdBudget);
        const totalYtdActualRaw = this.reverseFormat(totals.ytdActual);
        totals.ytdAchievement = totalYtdBudgetRaw > 0
            ? ((totalYtdActualRaw / totalYtdBudgetRaw) * 100).toFixed(2) + ' %'
            : '0.00 %';

        this.totalsRow = totals;
        // today end


        // const totalAchievement = matrix.reduce((acc, row) => {
        //     const percentValue = parseFloat(row.achievement.replace('%', '').trim()) || 0;
        //     return acc + percentValue;
        // }, 0);
        // totals.achievement = totalAchievement.toFixed(2);

        // const totalYtdAchievement = matrix.reduce((acc, row) => {
        //     const percentValue = parseFloat(row.ytdAchievement.replace('%', '').trim()) || 0;
        //     return acc + percentValue;
        // }, 0);
        // totals.ytdAchievement = totalYtdAchievement.toFixed(2);

        // this.totalsRow = totals;

        this.showTable = true;
        this.isLoading = false;
        console.log(' processPMGRows complete. Matrix:', JSON.stringify(this.visibleMatrix, null, 2));
    }

    formatToDisplay(value) {
        const scaledValue = value * 1000;
        return (scaledValue / 1_000_000).toFixed(2) + ' M';
    }

    getMonthNumber(monthName) {
        const monthMap = {
            'January': 1, 'February': 2, 'March': 3,
            'April': 4, 'May': 5, 'June': 6,
            'July': 7, 'August': 8, 'September': 9,
            'October': 10, 'November': 11, 'December': 12
        };
        return monthMap[monthName] || 1;
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

        for (let month = 4; month <= selectedMonthNumber; month++) {
            ytdMonthNumbers.push(month);
        }

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

    getNext3Months(selectedMonth) {
        const idx = this.months.indexOf(selectedMonth);
        const fiscalYearEnd = 11;

        let next3 = [];
        for (let i = 1; i <= 3; i++) {
            const nextIdx = (idx + i) % 12;

            if (idx < fiscalYearEnd && nextIdx > fiscalYearEnd) {
                break;
            }

            if (this.months[idx] === 'March') {
                break;
            }
            next3.push(this.months[nextIdx]);


            if (this.months[nextIdx] === 'March') {
                break;
            }
        }

        return next3;
    }

    getYTDMonths() {
        const fiscalMonthMap = {
            'April': 'Apr', 'May': 'May', 'June': 'Jun', 'July': 'Jul',
            'August': 'Aug', 'September': 'Sep', 'October': 'Oct', 'November': 'Nov',
            'December': 'Dec', 'January': 'Jan', 'February': 'Feb', 'March': 'Mar'
        };

        const fiscalOrder = [
            'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep',
            'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'
        ];

        const selectedPrefix = fiscalMonthMap[this.selectedMonth];
        const index = fiscalOrder.findIndex(m => m === selectedPrefix);
        return fiscalOrder.slice(0, index + 1);
    }

    applyFiltersAndSummarize() {
        if (!this.budgetData || !this.selectedMonth) return;

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
            'AUA': { level1: 'Australia' },
            'A2': { level1: 'Australia' }, 'A6': { level1: 'Australia' }, 'A17': { level1: 'Australia' },
            'A1': { level1: 'Australia' }, 'A15': { level1: 'Australia' }, 'A9': { level1: 'Australia' },
            'A13': { level1: 'Australia' }, 'A8': { level1: 'Australia' }, 'A4': { level1: 'Australia' },
            'A14': { level1: 'Australia' }, 'A5': { level1: 'Australia' }, 'A7': { level1: 'Australia' },
            'A10': { level1: 'Australia' }, 'A16': { level1: 'Australia' }, 'A3': { level1: 'Australia' },
            'A12': { level1: 'Australia' }, 'TAP': { level1: 'Australia' }, 'A11': { level1: 'Australia' },
            'ATK': { level1: 'Europe' }, 'BEL': { level1: 'Europe' }, 'FIN': { level1: 'Europe' },
            'FRE': { level1: 'Europe' }, 'IRE': { level1: 'Europe' }, 'NLD': { level1: 'Europe' },
            'PORT': { level1: 'Europe' }, 'SPN': { level1: 'Europe' }, 'SWD': { level1: 'Europe' },
            'UK': { level1: 'Europe' },
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
            'CND': { level1: 'North America', level2: 'CANADA' },
            'MEX': { level1: 'North America', level2: 'MEXICO' },
            'USA': { level1: 'North America', level2: 'USA' },
            'RUS': { level1: 'Russia' },
            'BOT': { level1: 'South Africa' }, 'DRC': { level1: 'South Africa' },
            'GAU': { level1: 'South Africa' }, 'KZN': { level1: 'South Africa' },
            'LIS': { level1: 'South Africa' }, 'MMM': { level1: 'South Africa' },
            'NAM': { level1: 'South Africa' }, 'NAF': { level1: 'South Africa' },
            'NCF': { level1: 'South Africa' }, 'NWM': { level1: 'South Africa' },
            'PLK': { level1: 'South Africa' }, 'RST': { level1: 'South Africa' },
            'SAF': { level1: 'South Africa' }, 'STP': { level1: 'South Africa' },
            'TAN': { level1: 'South Africa' }, 'SAHO': { level1: 'South Africa' },
            'ZAM': { level1: 'South Africa' }, 'ZIM': { level1: 'South Africa' },
            'EGY': { level1: 'West Africa' }, 'GHN': { level1: 'West Africa' },
            'GUI': { level1: 'West Africa' }, 'MALI': { level1: 'West Africa' },
            'MOR': { level1: 'West Africa' }
        };

        let filteredData = [];
        const [actualField, budgetField] = this.monthMap[this.selectedMonth] || [];

        const level1Selected = this.selectedLevel1 && this.selectedLevel1 !== 'None';
        const level2Selected = this.selectedLevel2 && this.selectedLevel2 !== 'None';

        this.isLoading = true;

        // FILTER BUDGET DATA
        this.budgetData.forEach(budgetRecord => {
            const branchCode = budgetRecord.Branch__r?.Branch_Code__c;
            const regionInfo = branchRegionMap[branchCode];

            const filteredLineItems = (budgetRecord.Budget_Line_Items__r || []).filter(line => {
                const matchOrderType = !this.selectedOrderType || line.Order_Type__c === this.selectedOrderType;
                const matchFY = !this.selectedFY || line.Budget_FN_Year__c === this.selectedFY;

                const hasActual = actualField in line && line[actualField] !== undefined;
                const hasBudget = budgetField in line && line[budgetField] !== undefined;
                const matchMonth = hasActual || hasBudget;

                let matchRegion = true;
                if (level1Selected) {
                    if (level2Selected) {
                        matchRegion = regionInfo?.level2 === this.selectedLevel2;
                    } else {
                        matchRegion = regionInfo?.level1 === this.selectedLevel1;
                    }
                }

                return matchOrderType && matchFY && matchRegion;
            });

            if (filteredLineItems.length > 0) {
                filteredData.push({
                    ...budgetRecord,
                    Budget_Line_Items__r: filteredLineItems
                });
            }
        });

        // FILTER FORM 4E/4D DATA
        let filteredFormData = this.form4E4DData || [];

        if (this.selectedOrderType && filteredFormData.length > 0) {
            filteredFormData = filteredFormData.filter(record => {
                const recordOrderType = record.Order_Type__c;
                const mappedOrderTypes = this.orderTypeMapping[this.selectedOrderType];

                if (this.selectedOrderType === 'S-Service') {
                    return false;
                } else if (mappedOrderTypes && mappedOrderTypes.length > 0) {
                    return mappedOrderTypes.includes(recordOrderType);
                } else {
                    return recordOrderType === this.selectedOrderType;
                }
            });
        }

        if (filteredFormData.length > 0) {
            filteredFormData = filteredFormData.filter(record => {
                const recordPMG = record.PMG__c;
                const normalizedPMG = (recordPMG === 'Trommel') ? 'Screen' : recordPMG;
                return this.PMG_CATEGORIES.includes(normalizedPMG);
            });
        }

        // REGION Filter for Form 4E/4D Data
        if ((level1Selected || level2Selected) && filteredFormData.length > 0) {
            filteredFormData = filteredFormData.filter(record => {
                const branchCode = record.SF_Offer__r?.Branch__r?.Branch_Code__c;
                const regionInfo = branchRegionMap[branchCode];

                let matchRegion = true;
                if (level1Selected) {
                    if (level2Selected) {
                        matchRegion = regionInfo?.level2 === this.selectedLevel2;
                    } else {
                        matchRegion = regionInfo?.level1 === this.selectedLevel1;
                    }
                }

                return matchRegion;
            });
        }

        this.isLoading = false;
        this.processPMGRows(filteredData, filteredFormData);
    }

    handleFYChange(event) {
        this.selectedFY = event.detail.value;
        this.budgetData = [];
        this.ConversionRateData = [];
        this.form4E4DRecords = [];
        this.isLoading = true;

        getDCBudgetAndChildItems({ selectedFY: this.selectedFY })
            .then(budgetResult => {
                this.budgetData = budgetResult;
                return getDatedConversionRate({ SelectedFy: this.selectedFY });
            })
            .then(rateResult => {
                this.ConversionRateData = rateResult;
                return getAllForm4E4DRecords({ selectedFY: this.selectedFY });
            })
            .then(formResult => {
                this.form4E4DData = formResult;
                this.applyFiltersAndSummarize();
            })
            .catch(error => {
                console.error('Error while fetching FY data chain:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleMonthChange(event) {
        this.selectedMonth = event.detail.value;
        // Clear quarter when manually selecting month
        this.selectedQuarter = '';
        this.applyFiltersAndSummarize();
    }

    handleQuarterChange(event) {
        this.selectedQuarter = event.detail.value;
        if (this.selectedQuarter) {
            const quarterMonths = this.quarterMonthsMap[this.selectedQuarter];
            if (quarterMonths && quarterMonths.length > 0) {
                // Set to last month of quarter for YTD calculation
                this.selectedMonth = quarterMonths[quarterMonths.length - 1];
            }
        } else {
            // If "All Quarters" selected, reset to current month
            this.setDefaultSelectedMonth();
        }
        this.applyFiltersAndSummarize();
    }

    handleOrderTypeChange(event) {
        this.selectedOrderType = event.detail.value;
        this.applyFiltersAndSummarize();
    }

    handleLevel1Change(event) {
        this.selectedLevel1 = event.detail.value;
        if (this.selectedLevel1 === 'None') {
            this.selectedLevel2 = '';
        }
        this.selectedLevel2 = '';

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
        this.applyFiltersAndSummarize();
    }

    handleLevel2Change(event) {
        this.selectedLevel2 = event.detail.value;
        this.applyFiltersAndSummarize();
    }

    exportToExcel() {
        const baseUrl = '/apex/MonthlyMatrixExport2';

        const exportData = this.visibleMatrix.map(row => ({
            pmg: row.pmg || '',
            budgetedOrder: row.budgetedOrder || '0.00 M',
            monthlyReceived: row.monthlyReceived || '0.00 M',
            achievement: row.achievement || '0.00 %',
            ytdBudget: row.ytdBudget || '0.00 M',
            ytdActual: row.ytdActual || '0.00 M',
            ytdAchievement: row.ytdAchievement || '0.00 %',
            forecastBudget: row.forecastBudget || '0.00 M',
            forecastMIS: row.forecastMIS || '0.00 M',
            fullYearForecast: row.fullYearForecast || '0.00 M'
        }));

        const totalsData = {
            budgetedOrder: this.totalsRow.budgetedOrder || '0.00 M',
            monthlyReceived: this.totalsRow.monthlyReceived || '0.00 M',
            achievement: this.totalsRow.achievement || '0.00', 
            ytdBudget: this.totalsRow.ytdBudget || '0.00 M',
            ytdActual: this.totalsRow.ytdActual || '0.00 M',
            ytdAchievement: this.totalsRow.ytdAchievement || '0.00',
            forecastBudget: this.totalsRow.forecastBudget || '0.00 M',
            forecastMIS: this.totalsRow.forecastMIS || '0.00 M',
            fullYearForecast: this.totalsRow.fullYearForecast || '0.00 M'
        };

        const params = new URLSearchParams({
            fy: this.selectedFY || 'All',
            orderType: this.selectedOrderType || 'All',
            month: this.selectedMonth || 'All',
            quarter: this.selectedQuarter || 'All',
            level1: this.selectedLevel1 === 'None' ? 'All' : (this.selectedLevel1 || 'All'),
            level2: this.selectedLevel2 === 'None' ? 'All' : (this.selectedLevel2 || 'All'),
            currency: this.currencyCode || 'USD',
            jsonData: encodeURIComponent(JSON.stringify(exportData)),
            totalsData: encodeURIComponent(JSON.stringify(totalsData))
        });

        const fullUrl = `${baseUrl}?${params.toString()}`;
        window.open(fullUrl, '_blank');
    }

    exportToPDF() {
        const baseUrl = '/apex/MonthlyMatrixPDFExport';

        const exportData = this.visibleMatrix.map(row => ({
            pmg: row.pmg || '',
            budgetedOrder: row.budgetedOrder || '0.00 M',
            monthlyReceived: row.monthlyReceived || '0.00 M',
            achievement: row.achievement || '0.00 %',
            ytdBudget: row.ytdBudget || '0.00 M',
            ytdActual: row.ytdActual || '0.00 M',
            ytdAchievement: row.ytdAchievement || '0.00 %',
            forecastBudget: row.forecastBudget || '0.00 M',
            forecastMIS: row.forecastMIS || '0.00 M',
            fullYearForecast: row.fullYearForecast || '0.00 M'
        }));

        const totalsData = {
            budgetedOrder: this.totalsRow.budgetedOrder || '0.00 M',
            monthlyReceived: this.totalsRow.monthlyReceived || '0.00 M',
            achievement: this.totalsRow.achievement || '0.00',
            ytdBudget: this.totalsRow.ytdBudget || '0.00 M',
            ytdActual: this.totalsRow.ytdActual || '0.00 M',
            ytdAchievement: this.totalsRow.ytdAchievement || '0.00',
            forecastBudget: this.totalsRow.forecastBudget || '0.00 M',
            forecastMIS: this.totalsRow.forecastMIS || '0.00 M',
            fullYearForecast: this.totalsRow.fullYearForecast || '0.00 M'
        };

        const params = new URLSearchParams({
            fy: this.selectedFY || 'All',
            orderType: this.selectedOrderType || 'All',
            month: this.selectedMonth || 'All',
            quarter: this.selectedQuarter || 'All',
            level1: this.selectedLevel1 === 'None' ? 'All' : (this.selectedLevel1 || 'All'),
            level2: this.selectedLevel2 === 'None' ? 'All' : (this.selectedLevel2 || 'All'),
            currency: this.currencyCode || 'USD',
            jsonData: encodeURIComponent(JSON.stringify(exportData)),
            totalsData: encodeURIComponent(JSON.stringify(totalsData))
        });

        const fullUrl = `${baseUrl}?${params.toString()}`;
        window.open(fullUrl, '_blank');
    }

    reverseFormat(value) {
        if (!value || typeof value !== 'string') return 0;
        const cleaned = value.replace(/[^\d.-]/g, '');
        const num = parseFloat(cleaned);
        if (isNaN(num)) return 0;
        const upper = value.toUpperCase();
        if (upper.includes('T')) return num * 1_000_000_000_000;
        if (upper.includes('B')) return num * 1_000_000_000;
        if (upper.includes('M')) return num * 1_000_000;
        if (upper.includes('K')) return num * 1_000;
        return num;
    }
}