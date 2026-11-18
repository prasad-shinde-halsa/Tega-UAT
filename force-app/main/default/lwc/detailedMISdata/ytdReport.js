/**
 * YTD Report (PMG matrix), ported from the tegaBudgetYtdReport LWC so both give the same figures.
 * Data comes from TegaCustomReportController: approved budgets with active lines, their MIS and
 * Proposal Forms; closed Form 4E/4D records as actual orders; dated exchange rates.
 * Values are reported in USD millions ("0.00 M"), exactly as the original report shows them.
 */

export const PMG_CATEGORIES = ["Mill", "Screen", "Wear Component", "Conveyor Component", "Hydrocyclone", "Trommel"];

export const FISCAL_MONTH_NAMES = [
    "April", "May", "June", "July", "August", "September",
    "October", "November", "December", "January", "February", "March"
];

export const YTD_MONTH_OPTIONS = FISCAL_MONTH_NAMES.map((month) => ({ label: month, value: month }));

export const YTD_QUARTER_OPTIONS = [
    { label: "All Quarters", value: "" },
    { label: "Q1 (April - June)", value: "Q1" },
    { label: "Q2 (July - September)", value: "Q2" },
    { label: "Q3 (October - December)", value: "Q3" },
    { label: "Q4 (January - March)", value: "Q4" }
];

export const QUARTER_MONTHS = {
    Q1: ["April", "May", "June"],
    Q2: ["July", "August", "September"],
    Q3: ["October", "November", "December"],
    Q4: ["January", "February", "March"]
};

export const LEVEL1_OPTIONS = [
    { label: "All", value: "None" },
    { label: "ASIA", value: "ASIA" },
    { label: "Australia", value: "Australia" },
    { label: "Europe", value: "Europe" },
    { label: "LATAM", value: "LATAM" },
    { label: "North America", value: "North America" },
    { label: "Russia", value: "Russia" },
    { label: "South Africa", value: "South Africa" },
    { label: "West Africa", value: "West Africa" }
];

export const LEVEL2_OPTIONS = {
    ASIA: ["INDIA", "MEA"],
    LATAM: ["BRAZIL", "CHILE", "PERU"],
    "North America": ["CANADA", "USA", "MEXICO"]
};

const ORDER_TYPE_MAPPING = {
    "E-Spares": ["Spare", "Spare + Modification"],
    "P-Project": ["Project"],
    "C-Conversion": ["Competitor Conversion", "Steel Conversion"],
    "S-Service": []
};

const SHORT = {
    April: "Apr", May: "May", June: "Jun", July: "Jul", August: "Aug", September: "Sep",
    October: "Oct", November: "Nov", December: "Dec", January: "Jan", February: "Feb", March: "Mar"
};
const FISCAL_SHORT = ["Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"];
const CALENDAR_NUMBER = {
    January: 1, February: 2, March: 3, April: 4, May: 5, June: 6,
    July: 7, August: 8, September: 9, October: 10, November: 11, December: 12
};
const EXPECTED_VALUE_FIELDS = {
    Apr: "Expected_Order_Value_April__c", May: "Expected_Order_Value_May__c", Jun: "Expected_Order_Value_June__c",
    Jul: "Expected_Order_Value_Jul__c", Aug: "Expected_Order_Value_Aug__c", Sep: "Expected_Order_Value_Sep__c",
    Oct: "Expected_Order_Value_Oct__c", Nov: "Expected_Order_Value_Nov__c", Dec: "Expected_Order_Value_Dec__c",
    Jan: "Expected_Order_Value_Jan__c", Feb: "Expected_Order_Value_Feb__c", Mar: "Expected_Order_Value_Mar__c"
};

const BRANCH_REGION_MAP = {
    BHL: { level1: "ASIA", level2: "INDIA" }, RKL: { level1: "ASIA", level2: "INDIA" }, BDSH: { level1: "ASIA", level2: "INDIA" },
    BOK: { level1: "ASIA", level2: "INDIA" }, DGP: { level1: "ASIA", level2: "INDIA" }, SING: { level1: "ASIA", level2: "INDIA" },
    BRL: { level1: "ASIA", level2: "INDIA" }, CTC: { level1: "ASIA", level2: "INDIA" }, JSR: { level1: "ASIA", level2: "INDIA" },
    HO: { level1: "ASIA", level2: "INDIA" }, BLR: { level1: "ASIA", level2: "INDIA" }, CHN: { level1: "ASIA", level2: "INDIA" },
    GOA: { level1: "ASIA", level2: "INDIA" }, HSP: { level1: "ASIA", level2: "INDIA" }, HYD: { level1: "ASIA", level2: "INDIA" },
    MUM: { level1: "ASIA", level2: "INDIA" }, VZG: { level1: "ASIA", level2: "INDIA" }, AHM: { level1: "ASIA", level2: "INDIA" },
    DLI: { level1: "ASIA", level2: "INDIA" }, UDR: { level1: "ASIA", level2: "INDIA" }, MEA: { level1: "ASIA", level2: "MEA" },
    AUA: { level1: "Australia" }, A1: { level1: "Australia" }, A2: { level1: "Australia" }, A3: { level1: "Australia" },
    A4: { level1: "Australia" }, A5: { level1: "Australia" }, A6: { level1: "Australia" }, A7: { level1: "Australia" },
    A8: { level1: "Australia" }, A9: { level1: "Australia" }, A10: { level1: "Australia" }, A11: { level1: "Australia" },
    A12: { level1: "Australia" }, A13: { level1: "Australia" }, A14: { level1: "Australia" }, A15: { level1: "Australia" },
    A16: { level1: "Australia" }, A17: { level1: "Australia" }, TAP: { level1: "Australia" },
    ATK: { level1: "Europe" }, BEL: { level1: "Europe" }, FIN: { level1: "Europe" }, FRE: { level1: "Europe" },
    IRE: { level1: "Europe" }, NLD: { level1: "Europe" }, PORT: { level1: "Europe" }, SPN: { level1: "Europe" },
    SWD: { level1: "Europe" }, UK: { level1: "Europe" },
    BRA: { level1: "LATAM", level2: "BRAZIL" }, CAF: { level1: "LATAM", level2: "CHILE" }, ARG: { level1: "LATAM", level2: "CHILE" },
    CBV: { level1: "LATAM", level2: "CHILE" }, CCA: { level1: "LATAM", level2: "CHILE" }, CHIL: { level1: "LATAM", level2: "CHILE" },
    CCM: { level1: "LATAM", level2: "CHILE" }, CCO: { level1: "LATAM", level2: "CHILE" }, CCQ: { level1: "LATAM", level2: "CHILE" },
    CIQ: { level1: "LATAM", level2: "CHILE" }, CSG: { level1: "LATAM", level2: "CHILE" }, CSA: { level1: "LATAM", level2: "CHILE" },
    PER: { level1: "LATAM", level2: "PERU" },
    CND: { level1: "North America", level2: "CANADA" }, MEX: { level1: "North America", level2: "MEXICO" },
    USA: { level1: "North America", level2: "USA" },
    RUS: { level1: "Russia" },
    BOT: { level1: "South Africa" }, DRC: { level1: "South Africa" }, GAU: { level1: "South Africa" }, KZN: { level1: "South Africa" },
    LIS: { level1: "South Africa" }, MMM: { level1: "South Africa" }, NAM: { level1: "South Africa" }, NAF: { level1: "South Africa" },
    NCF: { level1: "South Africa" }, NWM: { level1: "South Africa" }, PLK: { level1: "South Africa" }, RST: { level1: "South Africa" },
    SAF: { level1: "South Africa" }, STP: { level1: "South Africa" }, TAN: { level1: "South Africa" }, SAHO: { level1: "South Africa" },
    ZAM: { level1: "South Africa" }, ZIM: { level1: "South Africa" },
    EGY: { level1: "West Africa" }, GHN: { level1: "West Africa" }, GUI: { level1: "West Africa" }, MALI: { level1: "West Africa" },
    MOR: { level1: "West Africa" }
};

export const currentMonthName = () =>
    ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][new Date().getMonth()];

/** Same as the original: value is in thousands, shown as millions. */
export const formatMillions = (value) => `${((value * 1000) / 1000000).toFixed(2)} M`;

export const reverseFormat = (value) => {
    if (!value || typeof value !== "string") {
        return 0;
    }
    const num = parseFloat(value.replace(/[^\d.-]/g, ""));
    if (isNaN(num)) {
        return 0;
    }
    const upper = value.toUpperCase();
    if (upper.includes("T")) return num * 1e12;
    if (upper.includes("B")) return num * 1e9;
    if (upper.includes("M")) return num * 1e6;
    if (upper.includes("K")) return num * 1e3;
    return num;
};

const achievement = (actualText, budgetText) => {
    const actual = reverseFormat(actualText);
    const budget = reverseFormat(budgetText);
    if (!budget || budget === 0) {
        return "0.00 %";
    }
    return `${((actual / budget) * 100).toFixed(2)} %`;
};

/** Rate that converts an amount in `currency` to USD, from the dated rates (INR is the corporate currency). */
const toUsdRate = (currency, rates) => {
    if (currency === "USD") {
        return 1;
    }
    const recordRate = rates.find((item) => item.IsoCode === currency)?.ConversionRate || 1;
    const usdRate = rates.find((item) => item.IsoCode === "USD")?.ConversionRate || 1;
    return usdRate / recordRate;
};

/** Months from April up to the selected month (fiscal order), as short names. */
const ytdShortMonths = (selectedMonth) => FISCAL_SHORT.slice(0, FISCAL_SHORT.indexOf(SHORT[selectedMonth]) + 1);

/** Calendar month numbers from April up to the selected month. */
const ytdMonthNumbers = (selectedMonth) => {
    const selected = CALENDAR_NUMBER[selectedMonth];
    const numbers = [];
    for (let month = 4; month <= selected; month++) {
        numbers.push(month);
    }
    if (selected <= 3) {
        for (let month = 4; month <= 12; month++) {
            numbers.push(month);
        }
        for (let month = 1; month <= selected; month++) {
            numbers.push(month);
        }
    }
    return numbers;
};

/** Up to three months after the selected one, never past March (end of the FY). */
export const nextThreeMonths = (selectedMonth) => {
    const index = FISCAL_MONTH_NAMES.indexOf(selectedMonth);
    const next = [];
    if (FISCAL_MONTH_NAMES[index] === "March") {
        return next;
    }
    for (let i = 1; i <= 3; i++) {
        const nextIndex = (index + i) % 12;
        if (index < 11 && nextIndex > 11) {
            break;
        }
        next.push(FISCAL_MONTH_NAMES[nextIndex]);
        if (FISCAL_MONTH_NAMES[nextIndex] === "March") {
            break;
        }
    }
    return next;
};

const matchesRegion = (branchCode, level1, level2) => {
    const level1Selected = level1 && level1 !== "None";
    const level2Selected = level2 && level2 !== "None";
    if (!level1Selected) {
        return true;
    }
    const region = BRANCH_REGION_MAP[branchCode];
    return level2Selected ? region?.level2 === level2 : region?.level1 === level1;
};

/** Filters budgets and Form 4E/4D records by FY, order type and region, as the original report does. */
export function filterYtdData(budgetData, formData, filters) {
    const { fy, orderType, level1, level2 } = filters;
    const budgets = [];
    (budgetData || []).forEach((budget) => {
        const branchCode = budget.Branch__r?.Branch_Code__c;
        const lines = (budget.Budget_Line_Items__r || []).filter(
            (line) =>
                (!orderType || line.Order_Type__c === orderType) &&
                (!fy || line.Budget_FN_Year__c === fy) &&
                matchesRegion(branchCode, level1, level2)
        );
        if (lines.length > 0) {
            budgets.push({ ...budget, Budget_Line_Items__r: lines });
        }
    });

    let forms = formData || [];
    if (orderType && forms.length > 0) {
        forms = forms.filter((record) => {
            if (orderType === "S-Service") {
                return false;
            }
            // The mapping lists Order_Category__c values. The original report compared them with
            // Order_Type__c (Shutdown / Stock, not queried), so any order type zeroed the actuals.
            const mapped = ORDER_TYPE_MAPPING[orderType];
            return mapped && mapped.length > 0 ? mapped.includes(record.Order_Category__c) : record.Order_Category__c === orderType;
        });
    }
    forms = forms.filter((record) => PMG_CATEGORIES.includes(record.PMG__c === "Trommel" ? "Screen" : record.PMG__c));
    forms = forms.filter((record) => matchesRegion(record.SF_Offer__r?.Branch__r?.Branch_Code__c, level1, level2));
    return { budgets, forms };
}

/** Builds the PMG matrix and the TOTAL row. */
export function buildYtdMatrix(budgets, forms, { fy, month, quarter, rates, outsideRecordTypeId }) {
    const ytdMonths = ytdShortMonths(month);
    const ytdNumbers = ytdMonthNumbers(month);
    const forecastMonths = nextThreeMonths(month);
    const forecastShortMonths = forecastMonths.map((name) => SHORT[name]);
    const startYear = fy ? parseInt(fy.split("-")[0], 10) : new Date().getFullYear();
    const selectedIsQ4 = ["January", "February", "March"].includes(month);
    const forecastMonthTexts = forecastMonths.map((name) => {
        const inNextCalendarYear = selectedIsQ4 && !["January", "February", "March"].includes(name);
        return `${SHORT[name]}, ${inNextCalendarYear ? startYear + 1 : startYear}`;
    });
    const monthsToAggregate = quarter ? QUARTER_MONTHS[quarter] : [month];
    const aggregateNumbers = monthsToAggregate.map((name) => CALENDAR_NUMBER[name] || 1);

    const rows = PMG_CATEGORIES.map((pmg) => {
        let monthlyActual = 0;
        let monthlyBudget = 0;
        let ytdActual = 0;
        let ytdBudget = 0;
        let forecastMIS = 0;
        let forecastMIS2 = 0;
        let forecastBudget = 0;
        let fullYearBudget = 0;

        // Actual orders: closed Form 4E/4D by created month. Trommel counts as Screen.
        (forms || []).forEach((record) => {
            if (!record.CreatedDate) {
                return;
            }
            const recordPmg = record.PMG__c === "Trommel" ? "Screen" : record.PMG__c;
            if (recordPmg !== pmg) {
                return;
            }
            const createdMonth = new Date(record.CreatedDate).getMonth() + 1;
            const value = (record.End_Customer_PO_Value__c / 1000 || 0) * toUsdRate(record.CurrencyIsoCode || "INR", rates);
            if (aggregateNumbers.includes(createdMonth)) {
                monthlyActual += value;
            }
            if (ytdNumbers.includes(createdMonth)) {
                ytdActual += value;
            }
        });

        (budgets || []).forEach((budget) => {
            const rate = toUsdRate(budget.CurrencyIsoCode || "INR", rates);
            const isOutside = budget.RecordTypeId === outsideRecordTypeId;
            (budget.Budget_Line_Items__r || []).forEach((line) => {
                if (line.PMG_Name__c !== pmg) {
                    return;
                }
                // Budget columns count Budget lines only, never Outside Budget lines.
                if (!isOutside) {
                    monthsToAggregate.forEach((name) => {
                        monthlyBudget += (line[`${SHORT[name]}_Order__c`] || 0) * rate;
                    });
                    ytdMonths.forEach((short) => {
                        ytdBudget += (line[`${short}_Order__c`] || 0) * rate;
                    });
                    FISCAL_SHORT.forEach((short) => {
                        fullYearBudget += (line[`${short}_Order__c`] || 0) * rate;
                    });
                    forecastMonths.forEach((name) => {
                        forecastBudget += (line[`${SHORT[name]}_Order__c`] || 0) * rate;
                    });
                }
                // MIS forecast (kept for parity; the report shows the Proposal Form forecast).
                (line.MIS_Budgets__r || []).forEach((mis) => {
                    FISCAL_SHORT.forEach((short) => {
                        const expected = mis[`Order_Expected_Month_${short}__c`]?.trim();
                        if (forecastMonthTexts.includes(expected)) {
                            forecastMIS += (mis[EXPECTED_VALUE_FIELDS[short]] || 0) * rate;
                        }
                    });
                });
                // Forecast next 3 months: Proposal Forms whose expected month falls in that window.
                (line.Proposal_Form__r || []).forEach((proposal) => {
                    if (forecastShortMonths.includes(proposal.Order_Expected_Month__c?.trim())) {
                        forecastMIS2 += (proposal.Total_Price_Quoted__c / 1000 || 0) * rate;
                    }
                });
            });
        });

        const remainingBudget = fullYearBudget - ytdBudget;
        const fullYearForecast = ytdActual + forecastMIS2 + (remainingBudget > 0 ? remainingBudget : 0);
        const row = {
            pmg,
            budgetedOrder: formatMillions(monthlyBudget),
            monthlyReceived: formatMillions(monthlyActual),
            ytdBudget: formatMillions(ytdBudget),
            ytdActual: formatMillions(ytdActual),
            forecastMIS: formatMillions(forecastMIS),
            forecastMIS2: formatMillions(forecastMIS2),
            fullYearBudget: formatMillions(fullYearBudget),
            fullYearForecast: formatMillions(fullYearForecast),
            forecastBudget: formatMillions(forecastBudget),
            raw: { monthlyBudget, monthlyActual, ytdBudget, ytdActual }
        };
        row.achievement = achievement(row.monthlyReceived, row.budgetedOrder);
        row.ytdAchievement = achievement(row.ytdActual, row.ytdBudget);
        return row;
    });

    const totals = {};
    ["budgetedOrder", "monthlyReceived", "ytdBudget", "ytdActual", "forecastMIS", "forecastMIS2", "fullYearBudget", "fullYearForecast", "forecastBudget"].forEach(
        (field) => {
            totals[field] = formatMillions(rows.reduce((sum, row) => sum + reverseFormat(row[field]), 0) / 1000);
        }
    );
    const percent = (actual, budget) => (budget > 0 ? `${((actual / budget) * 100).toFixed(2)} %` : "0.00 %");
    totals.achievement = percent(reverseFormat(totals.monthlyReceived), reverseFormat(totals.budgetedOrder));
    totals.ytdAchievement = percent(reverseFormat(totals.ytdActual), reverseFormat(totals.ytdBudget));
    return { rows, totals };
}

/** Same payload as the original report's Excel / PDF Visualforce exports. */
export function exportUrl(page, { rows, totals, fy, orderType, month, quarter, level1, level2, currency }) {
    const exportRows = rows.map((row) => ({
        pmg: row.pmg || "",
        budgetedOrder: row.budgetedOrder || "0.00 M",
        monthlyReceived: row.monthlyReceived || "0.00 M",
        achievement: row.achievement || "0.00 %",
        ytdBudget: row.ytdBudget || "0.00 M",
        ytdActual: row.ytdActual || "0.00 M",
        ytdAchievement: row.ytdAchievement || "0.00 %",
        forecastBudget: row.forecastBudget || "0.00 M",
        forecastMIS: row.forecastMIS2 || "0.00 M",
        fullYearForecast: row.fullYearForecast || "0.00 M"
    }));
    const totalsData = {
        budgetedOrder: totals.budgetedOrder || "0.00 M",
        monthlyReceived: totals.monthlyReceived || "0.00 M",
        achievement: totals.achievement || "0.00",
        ytdBudget: totals.ytdBudget || "0.00 M",
        ytdActual: totals.ytdActual || "0.00 M",
        ytdAchievement: totals.ytdAchievement || "0.00",
        forecastBudget: totals.forecastBudget || "0.00 M",
        forecastMIS: totals.forecastMIS2 || "0.00 M",
        fullYearForecast: totals.fullYearForecast || "0.00 M"
    };
    const params = new URLSearchParams({
        fy: fy || "All",
        orderType: orderType || "All",
        month: month || "All",
        quarter: quarter || "All",
        level1: level1 === "None" ? "All" : level1 || "All",
        level2: level2 === "None" ? "All" : level2 || "All",
        currency: currency || "USD",
        jsonData: encodeURIComponent(JSON.stringify(exportRows)),
        totalsData: encodeURIComponent(JSON.stringify(totalsData))
    });
    return `/apex/${page}?${params.toString()}`;
}