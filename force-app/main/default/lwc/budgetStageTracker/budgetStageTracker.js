import { LightningElement } from "lwc";
import getFinancialYears from "@salesforce/apex/BudgetStageTrackerController.getFinancialYears";
import getRows from "@salesforce/apex/BudgetStageTrackerController.getRows";

const FISCAL_MONTHS = ["Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"];
const QUARTERS = [
    { value: "Q1", label: "Quarter 1", months: ["Apr", "May", "Jun"] },
    { value: "Q2", label: "Quarter 2", months: ["Jul", "Aug", "Sep"] },
    { value: "Q3", label: "Quarter 3", months: ["Oct", "Nov", "Dec"] },
    { value: "Q4", label: "Quarter 4", months: ["Jan", "Feb", "Mar"] }
];
const BUDGET_TYPES = [
    { value: "budget", label: "Budget" },
    { value: "outside", label: "Outside" },
    { value: "both", label: "Budget+Outside" }
];
const FIGURES = [
    { value: "1000", label: "Thousand" },
    { value: "100000", label: "Lakh" },
    { value: "1000000", label: "Million" },
    { value: "10000000", label: "Crore" }
];
const ORDER_TYPES = [
    { value: "", label: "All" },
    { value: "C-Conversion", label: "Conversion" },
    { value: "E-Spares", label: "Spares" },
    { value: "P-Project", label: "Project" },
    { value: "S-Service", label: "Service" }
];
const TOP_PERCENTS = ["100", "95", "90", "85", "80", "70", "50"];
const DECIMALS = ["0", "1", "2"];
const ALL = "";
const ALL_PMG = "All";
// Rows are shown a page at a time so a wide filter cannot freeze the browser.
const PAGE_SIZE = 1000;
const formatCount = (count) => count.toLocaleString("en-IN");

const markSelected = (options, selected) => options.map((option) => ({ ...option, selected: option.value === selected }));
const asOptions = (values) => values.map((value) => ({ value, label: value }));
const distinctSorted = (values) => [...new Set(values.filter(Boolean))].sort((a, b) => a.localeCompare(b));
// Lightning's global CSS reaches into this component and defines .stage, so that name cannot be used here.
const MONTH_CELL = "month-cell";
// Resolves after LWC has patched the DOM and the browser has painted it.
// eslint-disable-next-line @lwc/lwc/no-async-operation
const nextPaint = () => new Promise((resolve) => setTimeout(() => requestAnimationFrame(() => requestAnimationFrame(resolve)), 0));
const stageClass = (stage) => `${MONTH_CELL} status-${stage.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")}`;

export default class BudgetStageTracker extends LightningElement {
    financialYears = [];
    selectedYear = "";
    selectedMonth = FISCAL_MONTHS[(new Date().getMonth() + 9) % 12];
    selectedRegion = ALL;
    selectedCountry = ALL;
    selectedCustomer = ALL;
    budgetType = "both";
    selectedFigures = "1000000";
    selectedDecimals = "1";
    selectedOrderType = ALL;
    selectedTop = "85";
    selectedQuarters = QUARTERS.map((quarter) => quarter.value);
    selectedPmgs = [ALL_PMG];
    selectedGroups = [];

    allRows = [];
    rankedRows = [];
    visibleRows = [];
    totalMatched = 0;
    pageIndex = 0;
    isLoading = true;
    hasShown = false;
    errorMessage = "";
    latestRequest = 0;

    monthColumns = FISCAL_MONTHS;

    async connectedCallback() {
        try {
            this.financialYears = await getFinancialYears();
            this.selectedYear = this.defaultYear(this.financialYears);
            await this.loadAndShow();
        } catch (error) {
            this.showError(error);
            this.isLoading = false;
        }
    }

    defaultYear(years) {
        const today = new Date();
        const startYear = today.getMonth() >= 3 ? today.getFullYear() : today.getFullYear() - 1;
        const current = `${startYear}-${String(startYear + 1).slice(-2)}`;
        return years.includes(current) ? current : years[years.length - 1];
    }

    async loadAndShow() {
        // Ignore a slow response if the user has asked again since.
        const request = ++this.latestRequest;
        this.isLoading = true;
        this.errorMessage = "";
        try {
            const rows = await getRows({ financialYear: this.selectedYear, forMonth: this.selectedMonth });
            if (request === this.latestRequest) {
                // High-precision Apex decimals can arrive as text, which would break the totals.
                this.allRows = rows.map((row) => ({
                    ...row,
                    amountInr: row.amountInr === null || row.amountInr === undefined ? null : Number(row.amountInr)
                }));
                this.dropMissingSelections();
                this.applyFilters();
                // Keep the loader up until the table has rendered and painted; up to
                // 1000 rows take a moment to draw after the data arrives.
                await nextPaint();
            }
        } catch (error) {
            if (request === this.latestRequest) {
                this.allRows = [];
                this.rankedRows = [];
                this.visibleRows = [];
                this.totalMatched = 0;
                this.pageIndex = 0;
                this.showError(error);
            }
        } finally {
            if (request === this.latestRequest) {
                this.isLoading = false;
                this.hasShown = true;
            }
        }
    }

    /**
     * After a reload (e.g. another financial year), a selected region, country, PMG or product
     * group may no longer exist. Its dropdown can't show it, yet it would still filter every row
     * out, so fall back to "All" for anything that is gone.
     */
    dropMissingSelections() {
        const has = (field, value) => this.allRows.some((row) => row[field] === value);
        if (this.selectedRegion && !has("region", this.selectedRegion)) {
            this.selectedRegion = ALL;
        }
        if (
            this.selectedCountry &&
            !this.allRows.some((row) => row.region === this.selectedRegion && row.country === this.selectedCountry)
        ) {
            this.selectedCountry = ALL;
        }
        if (this.selectedCustomer && !has("customer", this.selectedCustomer)) {
            this.selectedCustomer = ALL;
        }
        if (!this.selectedPmgs.includes(ALL_PMG)) {
            const pmgs = this.selectedPmgs.filter((pmg) => has("pmg", pmg));
            this.selectedPmgs = pmgs.length ? pmgs : [ALL_PMG];
        }
        this.selectedGroups = this.selectedPmgs.includes(ALL_PMG)
            ? []
            : this.selectedGroups.filter((group) =>
                  this.allRows.some((row) => row.productGroup === group && this.selectedPmgs.includes(row.pmg))
              );
    }

    showError(error) {
        this.errorMessage = error?.body?.message || error?.message || "Something went wrong.";
    }

    applyFilters() {
        const months = QUARTERS.filter((quarter) => this.selectedQuarters.includes(quarter.value)).flatMap((quarter) => quarter.months);
        const allPmgs = this.selectedPmgs.includes(ALL_PMG);
        const matched = this.allRows.filter(
            (row) =>
                (this.budgetType === "both" || row.isOutside === (this.budgetType === "outside")) &&
                (!this.selectedRegion || row.region === this.selectedRegion) &&
                (!this.selectedCountry || row.country === this.selectedCountry) &&
                (!this.selectedCustomer || row.customer === this.selectedCustomer) &&
                (!this.selectedOrderType || row.orderType === this.selectedOrderType) &&
                months.includes(row.budgetMonth) &&
                (allPmgs || this.selectedPmgs.includes(row.pmg)) &&
                (this.selectedGroups.length === 0 || this.selectedGroups.includes(row.productGroup))
        );
        // Top customers are ranked within Budget and within Outside separately, so that
        // Budget+Outside is exactly the Budget rows plus the Outside rows. Ranking them in one
        // pool lets a few large Outside values push every Budget customer out of the top share.
        const keepTop = (rows) => {
            const top = this.topCustomers(rows);
            return rows.filter((row) => top.has(row.customer));
        };
        const kept =
            this.budgetType === "both"
                ? [...keepTop(matched.filter((row) => !row.isOutside)), ...keepTop(matched.filter((row) => row.isOutside))]
                : keepTop(matched);
        const ranked = kept.sort((a, b) => (b.amountInr || 0) - (a.amountInr || 0));
        this.rankedRows = ranked;
        this.totalMatched = ranked.length;
        this.pageIndex = 0;
        this.renderPage();
    }

    /** Shows the current page; serial numbers continue across pages. */
    renderPage() {
        const start = this.pageIndex * PAGE_SIZE;
        this.visibleRows = this.rankedRows
            .slice(start, start + PAGE_SIZE)
            .map((row, index) => this.toDisplayRow(row, start + index));
    }

    /** The largest customers that together reach the selected share of the total budget amount. */
    topCustomers(rows) {
        const totals = new Map();
        rows.forEach((row) => totals.set(row.customer, (totals.get(row.customer) || 0) + (row.amountInr || 0)));
        const share = Number(this.selectedTop) / 100;
        const grandTotal = [...totals.values()].reduce((sum, total) => sum + total, 0);
        if (share >= 1 || grandTotal === 0) {
            return new Set(totals.keys());
        }
        const top = new Set();
        let running = 0;
        [...totals.entries()]
            .sort((a, b) => b[1] - a[1])
            .some(([customer, total]) => {
                top.add(customer);
                running += total;
                return running >= grandTotal * share;
            });
        return top;
    }

    toDisplayRow(row, index) {
        return {
            key: row.key,
            serialLabel: row.isOutside ? `${index + 1}*` : `${index + 1}`,
            serialClass: row.isOutside ? "serial outside" : "serial",
            branch: row.branch,
            customerLabel: row.address ? `${row.customer} [${row.address}]` : row.customer,
            pmg: row.pmg,
            productGroup: row.productGroup,
            description: row.description,
            partList: row.partList,
            budgetMonthLabel: row.budgetMonthLabel,
            expectedMonth: row.expectedMonth || "-",
            amount: this.formatAmount(row.amountInr),
            cells: FISCAL_MONTHS.map((month) => {
                const stage = row.stages?.[month];
                return { month, stage, className: stage ? stageClass(stage) : MONTH_CELL };
            })
        };
    }

    formatAmount(amountInr) {
        if (amountInr === null || amountInr === undefined) {
            return "";
        }
        return (amountInr / Number(this.selectedFigures)).toLocaleString("en-IN", {
            minimumFractionDigits: Number(this.selectedDecimals),
            maximumFractionDigits: Number(this.selectedDecimals)
        });
    }

    get yearOptions() {
        return markSelected(
            this.financialYears.map((year) => ({
                value: year,
                label: `${year.slice(0, 4)} - ${year.slice(0, 2)}${year.slice(-2)}`
            })),
            this.selectedYear
        );
    }

    get monthOptions() {
        return markSelected(
            FISCAL_MONTHS.map((month) => ({ value: month, label: month.toUpperCase() })),
            this.selectedMonth
        );
    }

    get regionOptions() {
        return markSelected(
            [{ value: ALL, label: "All" }, ...asOptions(distinctSorted(this.allRows.map((row) => row.region)))],
            this.selectedRegion
        );
    }

    get countryOptions() {
        const rows = this.allRows.filter((row) => row.region === this.selectedRegion);
        return markSelected(
            [{ value: ALL, label: "All" }, ...asOptions(distinctSorted(rows.map((row) => row.country)))],
            this.selectedCountry
        );
    }

    get isCountryDisabled() {
        return !this.selectedRegion;
    }

    get customerOptions() {
        return markSelected(
            [{ value: ALL, label: "" }, ...asOptions(distinctSorted(this.allRows.map((row) => row.customer)))],
            this.selectedCustomer
        );
    }

    get budgetTypeOptions() {
        return BUDGET_TYPES.map((type) => ({ ...type, checked: type.value === this.budgetType }));
    }

    get figuresOptions() {
        return markSelected(FIGURES, this.selectedFigures);
    }

    get decimalOptions() {
        return markSelected(asOptions(DECIMALS), this.selectedDecimals);
    }

    get orderTypeOptions() {
        return markSelected(ORDER_TYPES, this.selectedOrderType);
    }

    get topOptions() {
        return markSelected(
            TOP_PERCENTS.map((value) => ({ value, label: `${value}%` })),
            this.selectedTop
        );
    }

    get quarterOptions() {
        return QUARTERS.map((quarter) => ({ ...quarter, checked: this.selectedQuarters.includes(quarter.value) }));
    }

    get pmgOptions() {
        const pmgs = distinctSorted(this.allRows.map((row) => row.pmg));
        return [ALL_PMG, ...pmgs].map((value) => ({ value, label: value, checked: this.selectedPmgs.includes(value) }));
    }

    /** Stays empty until a specific PMG is ticked, as in the existing report. */
    get groupOptions() {
        if (this.selectedPmgs.includes(ALL_PMG)) {
            return [];
        }
        const groups = distinctSorted(
            this.allRows.filter((row) => this.selectedPmgs.includes(row.pmg)).map((row) => row.productGroup)
        );
        return groups.map((value) => ({ value, label: value, checked: this.selectedGroups.includes(value) }));
    }

    get showNoRows() {
        return this.hasShown && !this.isLoading && !this.errorMessage && this.visibleRows.length === 0;
    }

    get hasRows() {
        return this.totalMatched > 0;
    }

    get pageCount() {
        return Math.max(1, Math.ceil(this.totalMatched / PAGE_SIZE));
    }

    get rowsMessage() {
        const start = this.pageIndex * PAGE_SIZE;
        const end = start + this.visibleRows.length;
        const total = formatCount(this.totalMatched);
        return this.pageIndex === 0
            ? `Showing the first ${formatCount(end)} of ${total} rows.`
            : `Showing rows ${formatCount(start + 1)}–${formatCount(end)} of ${total}.`;
    }

    get pageLabel() {
        return `Page ${this.pageIndex + 1} of ${this.pageCount}`;
    }

    get isBackDisabled() {
        return this.isLoading || this.pageIndex === 0;
    }

    get isNextDisabled() {
        return this.isLoading || this.pageIndex >= this.pageCount - 1;
    }

    handleBack() {
        this.goToPage(this.pageIndex - 1);
    }

    handleNext() {
        this.goToPage(this.pageIndex + 1);
    }

    async goToPage(pageIndex) {
        if (pageIndex < 0 || pageIndex >= this.pageCount || this.isLoading) {
            return;
        }
        this.isLoading = true;
        // Let the loader paint before the heavy re-render of up to a full page of rows.
        await nextPaint();
        this.pageIndex = pageIndex;
        this.renderPage();
        await nextPaint();
        const sheet = this.template.querySelector(".sheet");
        if (sheet) {
            sheet.scrollTop = 0;
        }
        this.isLoading = false;
    }

    handleYearChange(event) {
        this.selectedYear = event.target.value;
        this.selectedCustomer = ALL;
        this.loadAndShow();
    }

    handleMonthChange(event) {
        this.selectedMonth = event.target.value;
    }

    handleRegionChange(event) {
        this.selectedRegion = event.target.value;
        this.selectedCountry = ALL;
    }

    handleCountryChange(event) {
        this.selectedCountry = event.target.value;
    }

    handleCustomerChange(event) {
        this.selectedCustomer = event.target.value;
    }

    handleBudgetTypeChange(event) {
        this.budgetType = event.target.value;
    }

    handleFiguresChange(event) {
        this.selectedFigures = event.target.value;
    }

    handleDecimalsChange(event) {
        this.selectedDecimals = event.target.value;
    }

    handleOrderTypeChange(event) {
        this.selectedOrderType = event.target.value;
    }

    handleTopChange(event) {
        this.selectedTop = event.target.value;
    }

    handleQuarterChange(event) {
        const { value, checked } = event.target;
        this.selectedQuarters = checked
            ? [...this.selectedQuarters, value]
            : this.selectedQuarters.filter((quarter) => quarter !== value);
    }

    handlePmgChange(event) {
        const { value, checked } = event.target;
        this.selectedGroups = [];
        if (value === ALL_PMG || (!checked && this.selectedPmgs.length === 1)) {
            // "All" is exclusive, and clearing the last PMG falls back to it.
            this.selectedPmgs = [ALL_PMG];
            return;
        }
        const specific = this.selectedPmgs.filter((pmg) => pmg !== ALL_PMG);
        this.selectedPmgs = checked ? [...specific, value] : specific.filter((pmg) => pmg !== value);
    }

    handleGroupChange(event) {
        const { value, checked } = event.target;
        this.selectedGroups = checked
            ? [...this.selectedGroups, value]
            : this.selectedGroups.filter((group) => group !== value);
    }

    handleShow() {
        this.loadAndShow();
    }
}