import { LightningElement, api, wire } from "lwc";
import getFinancialYears from "@salesforce/apex/DetailedMISDataController.getFinancialYears";
import getData from "@salesforce/apex/DetailedMISDataController.getData";
import getPicklistValuesLwc from "@salesforce/apex/DcBudgetLWCController.getPicklistValuesLwc";
import getDCBudgetAndChildItems from "@salesforce/apex/TegaCustomReportController.getDCBudgetAndChildItems";
import getDatedConversionRate from "@salesforce/apex/TegaCustomReportController.getDatedConversionRate";
import getAllForm4E4DRecords from "@salesforce/apex/TegaCustomReportController.getAllForm4E4DRecords";
import getDCBudgetRecordTypes from "@salesforce/apex/TegaCustomReportController.getDCBudgetRecordTypes";
import {
    YTD_MONTH_OPTIONS,
    YTD_QUARTER_OPTIONS,
    QUARTER_MONTHS,
    LEVEL1_OPTIONS,
    LEVEL2_OPTIONS,
    currentMonthName,
    reverseFormat,
    filterYtdData,
    buildYtdMatrix,
    exportUrl
} from "./ytdReport";

const FISCAL_MONTHS = ["Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"];
const MONTH_NAMES = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const QUARTERS = [
    { value: "Q1", label: "Q1 (Apr–Jun)", months: ["Apr", "May", "Jun"] },
    { value: "Q2", label: "Q2 (Jul–Sep)", months: ["Jul", "Aug", "Sep"] },
    { value: "Q3", label: "Q3 (Oct–Dec)", months: ["Oct", "Nov", "Dec"] },
    { value: "Q4", label: "Q4 (Jan–Mar)", months: ["Jan", "Feb", "Mar"] }
];
const BUDGET_TYPES = [
    { value: "both", label: "Budget + Outside" },
    { value: "budget", label: "Budget" },
    { value: "outside", label: "Outside" }
];
const ORDER_TYPE_LABELS = { "C-Conversion": "Conversion", "E-Spares": "Spares", "P-Project": "Project", "S-Service": "Service" };
const FIGURES = [
    { value: "1", label: "Rupees" },
    { value: "1000", label: "Thousand" },
    { value: "100000", label: "Lakh" },
    { value: "1000000", label: "Million" },
    { value: "10000000", label: "Crore" }
];
const DECIMALS = [
    { value: "0", label: "0" },
    { value: "1", label: "1" },
    { value: "2", label: "2" }
];
const PAGE_SIZES = [
    { value: "50", label: "50 / page" },
    { value: "100", label: "100 / page" },
    { value: "250", label: "250 / page" },
    { value: "500", label: "500 / page" }
];
const GROUP_BY = [
    { value: "region", label: "Region" },
    { value: "country", label: "Country" },
    { value: "branch", label: "Branch" },
    { value: "owner", label: "Budget Owner" },
    { value: "customer", label: "Customer" },
    { value: "pmg", label: "PMG" },
    { value: "productGroup", label: "Product Group" },
    { value: "orderTypeLabel", label: "Order Type" },
    { value: "reportLabel", label: "Report Month" },
    { value: "submittedBy", label: "Submitted By" }
];
const COLUMNS = [
    { field: "reportKey", label: "Report Month" },
    { field: "branch", label: "Branch" },
    { field: "customer", label: "Customer" },
    { field: "pmg", label: "PMG" },
    { field: "productGroup", label: "Product Group" },
    { field: "description", label: "Description / Part List" },
    { field: "orderTypeLabel", label: "Order Type" },
    { field: "typeLabel", label: "Type" },
    { field: "slotIndex", label: "Budget Month" },
    { field: "budgetAmountInr", label: "Budget Amt", numeric: true },
    { field: "stageIndex", label: "Stage" },
    { field: "expectedMonth", label: "Exp. Month" },
    { field: "expectedValueInr", label: "Exp. Value", numeric: true },
    { field: "remarks", label: "Remarks" },
    { field: "submittedBy", label: "Submitted By" },
    { field: "submittedOnTime", label: "Submitted On" }
];
const ALL = "";
const SEARCH_DELAY_MS = 300;
const WON = "Order";
const LOST = "Lost";
const IDLE = "No work done";

const distinctSorted = (values) => [...new Set(values.filter(Boolean))].sort((a, b) => a.localeCompare(b));
const withAll = (values, allLabel = "All") => [{ value: ALL, label: allLabel }, ...values.map((value) => ({ value, label: value }))];
const reportLabel = (key) => {
    if (!key) {
        return "";
    }
    const [year, month] = key.split("-");
    return `${MONTH_NAMES[Number(month) - 1]}-${year.slice(-2)}`;
};
const csvCell = (value) => {
    const text = value === null || value === undefined ? "" : String(value);
    return /[",\n\r]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
};
// Resolves after LWC has patched the DOM and the browser has painted it.
// eslint-disable-next-line @lwc/lwc/no-async-operation
const nextPaint = () => new Promise((resolve) => setTimeout(() => requestAnimationFrame(() => requestAnimationFrame(resolve)), 0));

export default class DetailedMISdata extends LightningElement {
    // Optional budget Ids (e.g. from a Flow); limits the YTD Report to those budgets, as in tegaBudgetYtdReport.
    @api budgetIds = "";

    financialYears = [];
    selectedYear = "";
    stageOrder = [];
    allRows = [];

    // Filters.
    budgetType = "both";
    budgetStatus = ALL;
    region = ALL;
    country = ALL;
    branch = ALL;
    owner = ALL;
    pmg = ALL;
    productGroup = ALL;
    orderType = ALL;
    submittedBy = ALL;
    expectedMonth = ALL;
    searchText = "";
    selectedStages = [];
    selectedReportMonths = [];
    selectedQuarters = [];
    latestOnly = true;
    remarksOnly = false;

    // Display.
    figures = "100000";
    decimals = "2";
    view = "table";
    groupBy = "region";
    sortField = "budgetAmountInr";
    sortDirection = "desc";
    pageSize = "100";
    pageIndex = 0;

    // Derived, recomputed by refresh().
    filteredRows = [];
    pageRows = [];
    kpis = [];
    stageBars = [];
    groupRows = [];

    // YTD Report (PMG matrix), loaded the first time its view is opened and on year change.
    ytdLoadedYear = null;
    ytdBudgetData = [];
    ytdRates = [];
    ytdForms = [];
    ytdOutsideRecordTypeId;
    ytdQuarter = "";
    ytdMonth = currentMonthName();
    ytdOrderType = "";
    ytdLevel1 = "None";
    ytdLevel2 = "";
    ytdOrderTypeOptions = [{ label: "None", value: "" }];
    ytdRows = [];
    ytdTotals = {};
    ytdRequest = 0;

    historyKey = null;
    isLoading = true;
    errorMessage = "";
    latestRequest = 0;
    searchTimer;

    @wire(getPicklistValuesLwc, { ObjectApi_name: "DC_Budget_Line_Items__c", Field_name: "Order_Type__c" })
    wiredYtdOrderTypes({ data, error }) {
        if (data) {
            this.ytdOrderTypeOptions = [{ label: "None", value: "" }, ...data.map((option) => ({ label: option.label, value: option.value }))];
        } else if (error) {
            console.error("Error reading the order types", error);
        }
    }

    async connectedCallback() {
        try {
            this.financialYears = await getFinancialYears();
            this.selectedYear = this.defaultYear(this.financialYears);
            await this.load();
        } catch (error) {
            this.showError(error);
            this.isLoading = false;
        }
    }

    disconnectedCallback() {
        clearTimeout(this.searchTimer);
    }

    defaultYear(years) {
        const today = new Date();
        const startYear = today.getMonth() >= 3 ? today.getFullYear() : today.getFullYear() - 1;
        const current = `${startYear}-${String(startYear + 1).slice(-2)}`;
        return years.includes(current) ? current : years[years.length - 1];
    }

    // ---------- Loading ----------

    async load() {
        const request = ++this.latestRequest;
        this.isLoading = true;
        this.errorMessage = "";
        try {
            const payload = await getData({ financialYear: this.selectedYear });
            if (request !== this.latestRequest) {
                return;
            }
            this.stageOrder = payload.stages || [];
            this.allRows = this.buildRows(payload);
            this.resetLineFilters();
            this.refresh();
            await nextPaint();
        } catch (error) {
            if (request === this.latestRequest) {
                this.allRows = [];
                this.refresh();
                this.showError(error);
            }
        } finally {
            if (request === this.latestRequest) {
                this.isLoading = false;
            }
        }
    }

    buildRows(payload) {
        const lines = new Map((payload.lines || []).map((line) => [line.id, line]));
        const startSuffix = this.selectedYear.slice(2, 4);
        const endSuffix = this.selectedYear.slice(-2);
        const stageIndex = new Map(this.stageOrder.map((stage, index) => [stage, index]));
        return (payload.entries || [])
            .filter((entry) => lines.has(entry.lineId))
            .map((entry) => {
                const line = lines.get(entry.lineId);
                const slotIndex = FISCAL_MONTHS.indexOf(entry.slot);
                const budgetAmount = line.budgetInr?.[entry.slot];
                const submittedOn = entry.submittedOn ? new Date(entry.submittedOn) : null;
                const row = {
                    key: `${entry.misId}-${entry.slot}`,
                    misId: entry.misId,
                    misName: entry.misName,
                    lineId: entry.lineId,
                    lineName: line.name,
                    slot: entry.slot,
                    slotKey: `${entry.lineId}-${entry.slot}`,
                    slotIndex,
                    quarter: QUARTERS.find((quarter) => quarter.months.includes(entry.slot))?.value,
                    budgetMonthLabel: `${entry.slot.toUpperCase()}-${slotIndex < 9 ? startSuffix : endSuffix}`,
                    reportKey: entry.reportKey,
                    reportLabel: reportLabel(entry.reportKey),
                    stage: entry.stage || "",
                    stageIndex: entry.stage && stageIndex.has(entry.stage) ? stageIndex.get(entry.stage) : 999,
                    expectedMonth: entry.expectedMonth || "",
                    expectedValueInr: entry.expectedValueInr === null || entry.expectedValueInr === undefined ? null : Number(entry.expectedValueInr),
                    remarks: entry.remarks || "",
                    submittedBy: entry.submittedBy || "",
                    submittedOnTime: submittedOn ? submittedOn.getTime() : 0,
                    submittedOnLabel: submittedOn
                        ? submittedOn.toLocaleString("en-IN", { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" })
                        : "",
                    isActive: entry.isActive,
                    isOutside: line.isOutside,
                    typeLabel: line.isOutside ? "Outside" : "Budget",
                    budgetStatus: line.budgetStatus || "",
                    owner: line.owner || "",
                    region: line.region || "",
                    country: line.country || "",
                    branch: line.branch || "",
                    customer: line.customer || "",
                    pmg: line.pmg || "",
                    productGroup: line.productGroup || "",
                    partList: line.partList || "",
                    description: line.description || "",
                    orderType: line.orderType || "",
                    orderTypeLabel: ORDER_TYPE_LABELS[line.orderType] || line.orderType || "",
                    budgetAmountInr: budgetAmount === null || budgetAmount === undefined ? null : Number(budgetAmount)
                };
                row.searchText = [row.customer, row.description, row.partList, row.lineName, row.misName, row.remarks, row.branch, row.pmg, row.productGroup]
                    .join(" ")
                    .toLowerCase();
                return row;
            });
    }

    /** Drop selections that do not exist in the newly loaded year. */
    resetLineFilters() {
        const has = (field, value) => !value || this.allRows.some((row) => row[field] === value);
        ["budgetStatus", "region", "country", "branch", "owner", "pmg", "productGroup", "orderType", "submittedBy", "expectedMonth"].forEach((field) => {
            if (!has(field, this[field])) {
                this[field] = ALL;
            }
        });
        const months = new Set(this.allRows.map((row) => row.reportKey));
        this.selectedReportMonths = this.selectedReportMonths.filter((month) => months.has(month));
        this.historyKey = null;
    }

    showError(error) {
        this.errorMessage = error?.body?.message || error?.message || "Something went wrong.";
    }

    // ---------- Filtering and summaries ----------

    refresh(keepPage = false) {
        const search = this.searchText.trim().toLowerCase();
        const stages = new Set(this.selectedStages);
        const months = new Set(this.selectedReportMonths);
        const quarters = new Set(this.selectedQuarters);

        let rows = this.allRows.filter(
            (row) =>
                (this.budgetType === "both" || row.isOutside === (this.budgetType === "outside")) &&
                (!this.budgetStatus || row.budgetStatus === this.budgetStatus) &&
                (!this.region || row.region === this.region) &&
                (!this.country || row.country === this.country) &&
                (!this.branch || row.branch === this.branch) &&
                (!this.owner || row.owner === this.owner) &&
                (!this.pmg || row.pmg === this.pmg) &&
                (!this.productGroup || row.productGroup === this.productGroup) &&
                (!this.orderType || row.orderType === this.orderType) &&
                (!this.submittedBy || row.submittedBy === this.submittedBy) &&
                (!this.expectedMonth || row.expectedMonth === this.expectedMonth) &&
                (months.size === 0 || months.has(row.reportKey)) &&
                (quarters.size === 0 || quarters.has(row.quarter)) &&
                (!this.remarksOnly || row.remarks) &&
                (!search || row.searchText.includes(search))
        );
        if (this.latestOnly) {
            rows = this.latestPerSlot(rows);
        }
        // Stage is applied after "latest" so it means "currently at this stage".
        const beforeStage = rows;
        if (stages.size) {
            rows = rows.filter((row) => stages.has(row.stage));
        }

        this.filteredRows = this.sortRows(rows);
        if (!keepPage) {
            this.pageIndex = 0;
        }
        this.pageIndex = Math.min(this.pageIndex, this.pageCount - 1);
        this.renderPage();
        this.kpis = this.buildKpis(rows);
        this.stageBars = this.buildStageBars(this.latestPerSlot(beforeStage));
        this.groupRows = this.buildGroups(rows);
    }

    /** The most recent report for each budget line and budgeted month. */
    latestPerSlot(rows) {
        const latest = new Map();
        rows.forEach((row) => {
            const current = latest.get(row.slotKey);
            if (
                !current ||
                row.reportKey > current.reportKey ||
                (row.reportKey === current.reportKey && row.submittedOnTime > current.submittedOnTime)
            ) {
                latest.set(row.slotKey, row);
            }
        });
        return [...latest.values()];
    }

    sortRows(rows) {
        const field = this.sortField;
        const direction = this.sortDirection === "asc" ? 1 : -1;
        return [...rows].sort((a, b) => {
            const x = a[field];
            const y = b[field];
            const xEmpty = x === null || x === undefined || x === "";
            const yEmpty = y === null || y === undefined || y === "";
            if (xEmpty || yEmpty) {
                // Blanks always last.
                return xEmpty === yEmpty ? 0 : xEmpty ? 1 : -1;
            }
            const result = typeof x === "number" && typeof y === "number" ? x - y : String(x).localeCompare(String(y));
            return result * direction;
        });
    }

    renderPage() {
        const size = Number(this.pageSize);
        const start = this.pageIndex * size;
        this.pageRows = this.filteredRows.slice(start, start + size).map((row, index) => this.toDisplayRow(row, start + index));
    }

    toDisplayRow(row, index) {
        return {
            ...row,
            serial: index + 1,
            rowClass: row.isOutside ? "mis-data-row mis-outside-row" : "mis-data-row",
            typeClass: row.isOutside ? "mis-badge mis-badge-outside" : "mis-badge mis-badge-budget",
            stageClass: this.stageClass(row.stage),
            budgetAmount: this.formatAmount(row.budgetAmountInr),
            expectedValue: this.formatAmount(row.expectedValueInr),
            detail: [row.description, row.partList].filter(Boolean).join(" · "),
            hasRemarks: Boolean(row.remarks)
        };
    }

    /** Amounts are summed once per line and budgeted month, so history mode does not double count. */
    buildKpis(rows) {
        const latest = this.latestPerSlot(rows);
        const sum = (list, field) => list.reduce((total, row) => total + (row[field] || 0), 0);
        const won = latest.filter((row) => row.stage === WON);
        const lost = latest.filter((row) => row.stage === LOST);
        const open = latest.filter((row) => row.stage && row.stage !== WON && row.stage !== LOST && row.stage !== IDLE);
        const closed = won.length + lost.length;
        const lines = new Set(rows.map((row) => row.lineId)).size;
        const customers = new Set(rows.map((row) => row.customer).filter(Boolean)).size;
        return [
            { key: "entries", label: "MIS Entries", value: this.formatCount(rows.length), hint: `${this.formatCount(lines)} lines · ${this.formatCount(customers)} customers`, className: "mis-kpi" },
            { key: "budget", label: "Budget Amount", value: this.formatAmount(sum(latest, "budgetAmountInr")), hint: this.figuresLabel, className: "mis-kpi" },
            { key: "expected", label: "Expected Order Value", value: this.formatAmount(sum(latest, "expectedValueInr")), hint: this.figuresLabel, className: "mis-kpi" },
            { key: "open", label: "In Progress", value: this.formatCount(open.length), hint: `${this.formatAmount(sum(open, "budgetAmountInr"))} budget`, className: "mis-kpi mis-kpi-open" },
            { key: "mis-won", label: "Won (Order)", value: this.formatCount(won.length), hint: `${this.formatAmount(sum(won, "budgetAmountInr"))} budget`, className: "mis-kpi mis-kpi-won" },
            { key: "mis-lost", label: "Lost", value: this.formatCount(lost.length), hint: `${this.formatAmount(sum(lost, "budgetAmountInr"))} budget`, className: "mis-kpi mis-kpi-lost" },
            {
                key: "rate",
                label: "Win Rate",
                value: closed ? `${Math.round((won.length / closed) * 100)}%` : "–",
                hint: `${this.formatCount(closed)} closed`,
                className: "mis-kpi"
            }
        ];
    }

    buildStageBars(latest) {
        const counts = new Map();
        latest.forEach((row) => {
            const stage = row.stage || "(No stage)";
            const item = counts.get(stage) || { count: 0, amount: 0 };
            item.count += 1;
            item.amount += row.budgetAmountInr || 0;
            counts.set(stage, item);
        });
        const order = [...this.stageOrder, "(No stage)"];
        const max = Math.max(1, ...[...counts.values()].map((item) => item.count));
        const total = latest.length || 1;
        const selected = new Set(this.selectedStages);
        return order
            .filter((stage) => counts.has(stage))
            .map((stage) => {
                const item = counts.get(stage);
                return {
                    stage,
                    count: this.formatCount(item.count),
                    share: `${Math.round((item.count / total) * 100)}%`,
                    amount: this.formatAmount(item.amount),
                    barStyle: `width: ${Math.max(2, (item.count / max) * 100)}%`,
                    barClass: `mis-bar-fill ${this.stageClass(stage === "(No stage)" ? "" : stage)}`,
                    itemClass: selected.has(stage) ? "mis-stage-bar mis-stage-bar-selected" : "mis-stage-bar",
                    // Kept as text: a boolean data attribute renders as "" or is dropped.
                    isSelectable: stage !== "(No stage)" ? "true" : "false"
                };
            });
    }

    buildGroups(rows) {
        const field = this.groupBy;
        const groups = new Map();
        rows.forEach((row) => {
            const name = row[field] || "(Blank)";
            if (!groups.has(name)) {
                groups.set(name, []);
            }
            groups.get(name).push(row);
        });
        const sum = (list, key) => list.reduce((total, row) => total + (row[key] || 0), 0);
        const result = [...groups.entries()].map(([name, list]) => {
            const latest = this.latestPerSlot(list);
            const won = latest.filter((row) => row.stage === WON).length;
            const lost = latest.filter((row) => row.stage === LOST).length;
            const budget = sum(latest, "budgetAmountInr");
            return {
                name,
                entries: this.formatCount(list.length),
                lines: this.formatCount(new Set(list.map((row) => row.lineId)).size),
                budgetValue: budget,
                budget: this.formatAmount(budget),
                expected: this.formatAmount(sum(latest, "expectedValueInr")),
                won: this.formatCount(won),
                lost: this.formatCount(lost),
                open: this.formatCount(latest.length - won - lost),
                winRate: won + lost ? `${Math.round((won / (won + lost)) * 100)}%` : "–"
            };
        });
        return result.sort((a, b) => b.budgetValue - a.budgetValue);
    }

    stageClass(stage) {
        if (!stage) {
            return "mis-stage mis-stage-none";
        }
        if (stage === WON) {
            return "mis-stage mis-stage-won";
        }
        if (stage === LOST) {
            return "mis-stage mis-stage-lost";
        }
        if (stage === IDLE) {
            return "mis-stage mis-stage-idle";
        }
        // Early, middle and late pipeline stages get progressively stronger colours.
        const index = this.stageOrder.indexOf(stage);
        const position = index < 0 ? 0 : index / Math.max(1, this.stageOrder.length - 1);
        return position < 0.34 ? "mis-stage mis-stage-early" : position < 0.67 ? "mis-stage mis-stage-mid" : "mis-stage mis-stage-late";
    }

    formatAmount(value) {
        if (value === null || value === undefined) {
            return "";
        }
        const decimals = Number(this.decimals);
        return (value / Number(this.figures)).toLocaleString("en-IN", { minimumFractionDigits: decimals, maximumFractionDigits: decimals });
    }

    formatCount(value) {
        return Number(value).toLocaleString("en-IN");
    }

    // ---------- Options ----------

    get yearOptions() {
        return this.financialYears.map((year) => ({ value: year, label: `FY ${year}` }));
    }

    get budgetTypeOptions() {
        return BUDGET_TYPES;
    }

    rowsFor(predicate) {
        return predicate ? this.allRows.filter(predicate) : this.allRows;
    }

    get statusOptions() {
        return withAll(distinctSorted(this.allRows.map((row) => row.budgetStatus)));
    }

    get regionOptions() {
        return withAll(distinctSorted(this.allRows.map((row) => row.region)));
    }

    get countryOptions() {
        return withAll(distinctSorted(this.rowsFor(this.region && ((row) => row.region === this.region)).map((row) => row.country)));
    }

    get branchOptions() {
        return withAll(
            distinctSorted(
                this.rowsFor((row) => (!this.region || row.region === this.region) && (!this.country || row.country === this.country)).map((row) => row.branch)
            )
        );
    }

    get ownerOptions() {
        return withAll(distinctSorted(this.allRows.map((row) => row.owner)));
    }

    get pmgOptions() {
        return withAll(distinctSorted(this.allRows.map((row) => row.pmg)));
    }

    get productGroupOptions() {
        return withAll(distinctSorted(this.rowsFor(this.pmg && ((row) => row.pmg === this.pmg)).map((row) => row.productGroup)));
    }

    get orderTypeOptions() {
        return [
            { value: ALL, label: "All" },
            ...distinctSorted(this.allRows.map((row) => row.orderType)).map((value) => ({ value, label: ORDER_TYPE_LABELS[value] || value }))
        ];
    }

    get submittedByOptions() {
        return withAll(distinctSorted(this.allRows.map((row) => row.submittedBy)));
    }

    get expectedMonthOptions() {
        const keyOf = (label) => {
            const [month, year] = label.split("-");
            return `${year}-${String(MONTH_NAMES.indexOf(month) + 1).padStart(2, "0")}`;
        };
        const labels = [...new Set(this.allRows.map((row) => row.expectedMonth).filter(Boolean))].sort((a, b) => keyOf(a).localeCompare(keyOf(b)));
        return withAll(labels);
    }

    get reportMonthChips() {
        const selected = new Set(this.selectedReportMonths);
        const counts = new Map();
        this.allRows.forEach((row) => counts.set(row.reportKey, (counts.get(row.reportKey) || 0) + 1));
        return [...counts.keys()].sort().map((key) => ({
            value: key,
            label: reportLabel(key),
            count: this.formatCount(counts.get(key)),
            className: selected.has(key) ? "mis-chip mis-chip-selected" : "mis-chip",
            pressed: selected.has(key) ? "true" : "false"
        }));
    }

    get quarterChips() {
        const selected = new Set(this.selectedQuarters);
        return QUARTERS.map((quarter) => ({
            ...quarter,
            className: selected.has(quarter.value) ? "mis-chip mis-chip-selected" : "mis-chip",
            pressed: selected.has(quarter.value) ? "true" : "false"
        }));
    }

    get stageChips() {
        const selected = new Set(this.selectedStages);
        const present = new Set(this.allRows.map((row) => row.stage).filter(Boolean));
        return this.stageOrder
            .filter((stage) => present.has(stage))
            .map((stage) => ({
                value: stage,
                label: stage,
                className: selected.has(stage) ? `mis-chip mis-chip-selected ${this.stageClass(stage)}` : "mis-chip",
                pressed: selected.has(stage) ? "true" : "false"
            }));
    }

    get figuresOptions() {
        return FIGURES;
    }

    get decimalOptions() {
        return DECIMALS;
    }

    get pageSizeOptions() {
        return PAGE_SIZES;
    }

    get groupByOptions() {
        return GROUP_BY;
    }

    get figuresLabel() {
        return `INR in ${FIGURES.find((option) => option.value === this.figures)?.label || ""}`;
    }

    get columns() {
        return COLUMNS.map((column) => {
            const active = column.field === this.sortField;
            return {
                ...column,
                className: `${column.numeric ? "mis-num" : ""} mis-sortable ${active ? "mis-sorted" : ""}`.trim(),
                sortIcon: active ? (this.sortDirection === "asc" ? "▲" : "▼") : "",
                ariaSort: active ? (this.sortDirection === "asc" ? "ascending" : "descending") : "none"
            };
        });
    }

    // ---------- View state ----------

    get hasData() {
        return this.allRows.length > 0;
    }

    get hasRows() {
        return this.filteredRows.length > 0;
    }

    get showEmpty() {
        return !this.isLoading && !this.errorMessage && !this.hasRows;
    }

    get emptyMessage() {
        return this.hasData ? "No MIS entries match these filters." : `No MIS has been submitted for FY ${this.selectedYear} yet.`;
    }

    get isTableView() {
        return this.view === "table";
    }

    get isSummaryView() {
        return this.view === "summary";
    }

    get tableVariant() {
        return this.isTableView ? "brand" : "neutral";
    }

    get summaryVariant() {
        return this.isSummaryView ? "brand" : "neutral";
    }

    get activeFilterCount() {
        return (
            ["budgetStatus", "region", "country", "branch", "owner", "pmg", "productGroup", "orderType", "submittedBy", "expectedMonth"].filter((field) => this[field])
                .length +
            (this.budgetType !== "both" ? 1 : 0) +
            (this.searchText ? 1 : 0) +
            this.selectedStages.length +
            this.selectedReportMonths.length +
            this.selectedQuarters.length +
            (this.remarksOnly ? 1 : 0)
        );
    }

    get activeFilterLabel() {
        const count = this.activeFilterCount;
        return count ? `${count} filter${count === 1 ? "" : "s"} applied` : "No filters applied";
    }

    get modeLabel() {
        return this.latestOnly
            ? "Latest report per line & budget month"
            : "Full history: every monthly report";
    }

    get pageCount() {
        return Math.max(1, Math.ceil(this.filteredRows.length / Number(this.pageSize)));
    }

    get rowsMessage() {
        const size = Number(this.pageSize);
        const start = this.pageIndex * size;
        const end = start + this.pageRows.length;
        const total = this.formatCount(this.filteredRows.length);
        return this.pageIndex === 0
            ? `Showing the first ${this.formatCount(end)} of ${total} rows.`
            : `Showing rows ${this.formatCount(start + 1)}–${this.formatCount(end)} of ${total}.`;
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

    // ---------- History modal ----------

    get showHistory() {
        return Boolean(this.historyKey) && this.historyLine !== null;
    }

    get historyRows() {
        if (!this.historyKey) {
            return [];
        }
        return this.allRows
            .filter((row) => row.slotKey === this.historyKey)
            .sort((a, b) => a.reportKey.localeCompare(b.reportKey) || a.submittedOnTime - b.submittedOnTime)
            .map((row) => ({
                ...row,
                stageClass: this.stageClass(row.stage),
                expectedValue: this.formatAmount(row.expectedValueInr),
                budgetAmount: this.formatAmount(row.budgetAmountInr)
            }));
    }

    get historyLine() {
        const rows = this.historyRows;
        if (!rows.length) {
            return null;
        }
        const row = rows[rows.length - 1];
        return {
            title: `${row.customer || row.lineName} · ${row.budgetMonthLabel}`,
            subtitle: [row.lineName, row.typeLabel, row.orderTypeLabel, row.branch].filter(Boolean).join(" · "),
            details: [
                { label: "PMG", value: row.pmg },
                { label: "Product Group", value: row.productGroup },
                { label: "Description", value: row.description },
                { label: "Part List", value: row.partList },
                { label: "Budget Owner", value: row.owner },
                { label: "Budget Amount", value: `${this.formatAmount(row.budgetAmountInr)} (${this.figuresLabel})` },
                { label: "Current Stage", value: row.stage || "–" }
            ]
        };
    }

    // ---------- Handlers ----------

    handleYearChange(event) {
        this.selectedYear = event.detail.value;
        this.load();
        if (this.isYtdView) {
            this.loadYtd();
        }
    }

    handleFilterChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.detail.value;
        if (field === "region") {
            this.country = ALL;
            this.branch = ALL;
        }
        if (field === "country") {
            this.branch = ALL;
            // Picking a country with no region chosen fills in that country's region.
            if (this.country && !this.region) {
                const regions = distinctSorted(this.allRows.filter((row) => row.country === this.country).map((row) => row.region));
                if (regions.length === 1) {
                    this.region = regions[0];
                }
            }
        }
        if (field === "pmg") {
            this.productGroup = ALL;
        }
        this.refresh();
    }

    handleSearch(event) {
        const value = event.target.value || "";
        clearTimeout(this.searchTimer);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.searchTimer = setTimeout(() => {
            this.searchText = value;
            this.refresh();
        }, SEARCH_DELAY_MS);
    }

    handleToggle(event) {
        this[event.target.dataset.field] = event.target.checked;
        this.refresh();
    }

    handleChipToggle(event) {
        const { list, value } = event.currentTarget.dataset;
        const current = this[list];
        this[list] = current.includes(value) ? current.filter((item) => item !== value) : [...current, value];
        this.refresh();
    }

    handleStageBarClick(event) {
        const { stage, selectable } = event.currentTarget.dataset;
        if (selectable !== "true") {
            return;
        }
        this.selectedStages = this.selectedStages.includes(stage) ? this.selectedStages.filter((item) => item !== stage) : [...this.selectedStages, stage];
        this.refresh();
    }

    handleClearChips(event) {
        this[event.currentTarget.dataset.list] = [];
        this.refresh();
    }

    handleClearAll() {
        ["budgetStatus", "region", "country", "branch", "owner", "pmg", "productGroup", "orderType", "submittedBy", "expectedMonth"].forEach((field) => {
            this[field] = ALL;
        });
        this.budgetType = "both";
        this.searchText = "";
        const search = this.template.querySelector("lightning-input[data-id='search']");
        if (search) {
            search.value = "";
        }
        this.selectedStages = [];
        this.selectedReportMonths = [];
        this.selectedQuarters = [];
        this.remarksOnly = false;
        this.latestOnly = true;
        this.refresh();
    }

    handleDisplayChange(event) {
        this[event.target.dataset.field] = event.detail.value;
        // Formatting or grouping changes keep the current page.
        this.refresh(true);
    }

    handlePageSizeChange(event) {
        this.pageSize = event.detail.value;
        this.refresh();
    }

    handleSort(event) {
        const field = event.currentTarget.dataset.field;
        if (this.sortField === field) {
            this.sortDirection = this.sortDirection === "asc" ? "desc" : "asc";
        } else {
            this.sortField = field;
            const numeric = COLUMNS.find((column) => column.field === field)?.numeric || field === "submittedOnTime" || field === "reportKey";
            this.sortDirection = numeric ? "desc" : "asc";
        }
        this.filteredRows = this.sortRows(this.filteredRows);
        this.pageIndex = 0;
        this.renderPage();
    }

    handleViewTable() {
        this.view = "table";
    }

    handleViewSummary() {
        this.view = "summary";
    }

    handleViewYtd() {
        this.view = "ytd";
        if (this.ytdLoadedYear !== this.selectedYear) {
            this.loadYtd();
        }
    }

    // ---------- YTD Report ----------

    budgetIdList() {
        if (!this.budgetIds) {
            return [];
        }
        const cleaned = Array.isArray(this.budgetIds) ? this.budgetIds.join(",") : String(this.budgetIds).replace(/[[\]]/g, "");
        return cleaned
            .split(",")
            .map((id) => id.trim().replace(/;$/, ""))
            .filter((id) => id !== "");
    }

    async loadYtd() {
        const request = ++this.ytdRequest;
        const year = this.selectedYear;
        this.isLoading = true;
        this.errorMessage = "";
        try {
            const [rates, budgets, recordTypes, forms] = await Promise.all([
                getDatedConversionRate({ SelectedFy: year }),
                getDCBudgetAndChildItems({ selectedFY: year, budgetIds: this.budgetIdList() }),
                getDCBudgetRecordTypes(),
                getAllForm4E4DRecords({ selectedFY: year })
            ]);
            if (request !== this.ytdRequest) {
                return;
            }
            this.ytdRates = rates || [];
            this.ytdBudgetData = budgets || [];
            this.ytdOutsideRecordTypeId = recordTypes?.Development_Budget;
            this.ytdForms = forms || [];
            this.ytdLoadedYear = year;
            this.computeYtd();
            await nextPaint();
        } catch (error) {
            if (request === this.ytdRequest) {
                this.ytdRows = [];
                this.ytdTotals = {};
                this.showError(error);
            }
        } finally {
            if (request === this.ytdRequest) {
                this.isLoading = false;
            }
        }
    }

    computeYtd() {
        const { budgets, forms } = filterYtdData(this.ytdBudgetData, this.ytdForms, {
            fy: this.ytdLoadedYear,
            orderType: this.ytdOrderType,
            level1: this.ytdLevel1,
            level2: this.ytdLevel2
        });
        // As in the original report: no matching budget means "No Details Found".
        if (budgets.length === 0) {
            this.ytdRows = [];
            this.ytdTotals = {};
            return;
        }
        const { rows, totals } = buildYtdMatrix(budgets, forms, {
            fy: this.ytdLoadedYear,
            month: this.ytdMonth,
            quarter: this.ytdQuarter,
            rates: this.ytdRates,
            outsideRecordTypeId: this.ytdOutsideRecordTypeId
        });
        const percentClass = (text) => {
            const value = parseFloat(text);
            return value >= 100 ? "mis-pct mis-pct-good" : value >= 75 ? "mis-pct mis-pct-warn" : "mis-pct mis-pct-bad";
        };
        this.ytdRows = rows.map((row) => ({
            ...row,
            achievementClass: percentClass(row.achievement),
            ytdAchievementClass: percentClass(row.ytdAchievement),
            ytdBarStyle: `width: ${Math.min(100, Math.max(0, parseFloat(row.ytdAchievement) || 0))}%`
        }));
        this.ytdTotals = {
            ...totals,
            achievementClass: percentClass(totals.achievement),
            ytdAchievementClass: percentClass(totals.ytdAchievement)
        };
    }

    handleYtdMonthChange(event) {
        this.ytdMonth = event.detail.value;
        // Picking a month clears the quarter, as in the original report.
        this.ytdQuarter = "";
        this.computeYtd();
    }

    handleYtdQuarterChange(event) {
        this.ytdQuarter = event.detail.value;
        // A quarter reports its months and sets YTD to the quarter's last month.
        this.ytdMonth = this.ytdQuarter ? QUARTER_MONTHS[this.ytdQuarter].slice(-1)[0] : currentMonthName();
        this.computeYtd();
    }

    handleYtdOrderTypeChange(event) {
        this.ytdOrderType = event.detail.value;
        this.computeYtd();
    }

    handleYtdLevel1Change(event) {
        this.ytdLevel1 = event.detail.value;
        this.ytdLevel2 = "";
        this.computeYtd();
    }

    handleYtdLevel2Change(event) {
        this.ytdLevel2 = event.detail.value;
        this.computeYtd();
    }

    handleYtdReset() {
        this.ytdQuarter = "";
        this.ytdMonth = currentMonthName();
        this.ytdOrderType = "";
        this.ytdLevel1 = "None";
        this.ytdLevel2 = "";
        this.computeYtd();
    }

    ytdExportParams() {
        return {
            rows: this.ytdRows,
            totals: this.ytdTotals,
            fy: this.ytdLoadedYear,
            orderType: this.ytdOrderType,
            month: this.ytdMonth,
            quarter: this.ytdQuarter,
            level1: this.ytdLevel1,
            level2: this.ytdLevel2,
            currency: "USD"
        };
    }

    handleYtdExportExcel() {
        window.open(exportUrl("MonthlyMatrixExport2", this.ytdExportParams()), "_blank");
    }

    handleYtdExportPdf() {
        window.open(exportUrl("MonthlyMatrixPDFExport", this.ytdExportParams()), "_blank");
    }

    get isYtdView() {
        return this.view === "ytd";
    }

    get isMisView() {
        return this.view !== "ytd";
    }

    get ytdVariant() {
        return this.isYtdView ? "brand" : "neutral";
    }

    get ytdQuarterOptions() {
        return YTD_QUARTER_OPTIONS;
    }

    get ytdMonthOptions() {
        return YTD_MONTH_OPTIONS;
    }

    get ytdLevel1Options() {
        return LEVEL1_OPTIONS;
    }

    get showYtdLevel2() {
        return Boolean(LEVEL2_OPTIONS[this.ytdLevel1]);
    }

    get ytdLevel2Options() {
        return (LEVEL2_OPTIONS[this.ytdLevel1] || []).map((value) => ({ label: value, value }));
    }

    get ytdMonthlyHeader() {
        return this.ytdQuarter ? YTD_QUARTER_OPTIONS.find((option) => option.value === this.ytdQuarter)?.label : this.ytdMonth;
    }

    get hasYtdRows() {
        return this.ytdRows.length > 0;
    }

    get showYtdEmpty() {
        return !this.isLoading && !this.hasYtdRows && this.ytdLoadedYear !== null;
    }

    get ytdKpis() {
        const totals = this.ytdTotals;
        if (!totals.budgetedOrder) {
            return [];
        }
        return [
            { key: "m", label: `${this.ytdMonthlyHeader} Achievement`, value: totals.achievement, hint: `USD ${totals.monthlyReceived} of ${totals.budgetedOrder}`, className: "mis-kpi" },
            { key: "y", label: "YTD Achievement", value: totals.ytdAchievement, hint: `USD ${totals.ytdActual} of ${totals.ytdBudget}`, className: "mis-kpi mis-kpi-won" },
            { key: "f", label: "Forecast Next 3 Months", value: `USD ${totals.forecastMIS2}`, hint: `Budget USD ${totals.forecastBudget}`, className: "mis-kpi mis-kpi-open" },
            { key: "b", label: "Full Year Budget", value: `USD ${totals.fullYearBudget}`, hint: "Budget lines only", className: "mis-kpi" },
            {
                key: "fy",
                label: "Full Year Forecast",
                value: `USD ${totals.fullYearForecast}`,
                hint: reverseFormat(totals.fullYearBudget)
                    ? `${((reverseFormat(totals.fullYearForecast) / reverseFormat(totals.fullYearBudget)) * 100).toFixed(1)} % of budget`
                    : "YTD actual + forecast + remaining budget",
                className: "mis-kpi"
            }
        ];
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
        await nextPaint();
        this.pageIndex = pageIndex;
        this.renderPage();
        await nextPaint();
        const sheet = this.template.querySelector(".mis-table-scroll");
        if (sheet) {
            sheet.scrollTop = 0;
        }
        this.isLoading = false;
    }

    handleOpenHistory(event) {
        this.historyKey = event.currentTarget.dataset.key;
    }

    handleCloseHistory() {
        this.historyKey = null;
    }

    handleModalKeydown(event) {
        if (event.key === "Escape") {
            this.handleCloseHistory();
        }
    }

    handleReload() {
        this.load();
    }

    handleExport() {
        const header = [
            "Report Month", "Region", "Country", "Branch", "Budget Owner", "Customer", "PMG", "Product Group", "Description", "Part List",
            "Order Type", "Type", "Budget Status", "Budget Line", "MIS", "Budget Month", `Budget Amount (${this.figuresLabel})`, "Stage",
            "Expected Month", `Expected Value (${this.figuresLabel})`, "Remarks", "Submitted By", "Submitted On"
        ];
        const lines = this.filteredRows.map((row) =>
            [
                row.reportLabel, row.region, row.country, row.branch, row.owner, row.customer, row.pmg, row.productGroup, row.description, row.partList,
                row.orderTypeLabel, row.typeLabel, row.budgetStatus, row.lineName, row.misName, row.budgetMonthLabel, this.formatAmount(row.budgetAmountInr),
                row.stage, row.expectedMonth, this.formatAmount(row.expectedValueInr), row.remarks, row.submittedBy, row.submittedOnLabel
            ]
                .map(csvCell)
                .join(",")
        );
        const csv = "﻿" + [header.map(csvCell).join(","), ...lines].join("\r\n");
        const link = document.createElement("a");
        link.href = `data:text/csv;charset=utf-8,${encodeURIComponent(csv)}`;
        link.download = `Detailed_MIS_${this.selectedYear}.csv`;
        link.style.display = "none";
        this.template.querySelector(".export-anchor").appendChild(link);
        link.click();
        link.remove();
    }
}