import { LightningElement } from "lwc";
import getFilterOptions from "@salesforce/apex/BudgetMonthlyReportController.getFilterOptions";
import getBranches from "@salesforce/apex/BudgetMonthlyReportController.getBranches";
import getStatusRows from "@salesforce/apex/BudgetMonthlyReportController.getStatusRows";
import getAttachments from "@salesforce/apex/BudgetMonthlyReportController.getAttachments";

const FISCAL_MONTHS = ["Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"];
const ALL = "";

export default class BudgetMonthlyReportStatus extends LightningElement {
    financialYears = [];
    companies = [];
    branches = [];
    selectedYear = "";
    selectedMonth = "";
    selectedCompany = ALL;
    selectedBranch = ALL;

    rows = [];
    attachments = [];
    showAttachments = false;
    grid = null;
    isLoading = true;
    errorMessage = "";
    latestRequest = 0;

    async connectedCallback() {
        try {
            const options = await getFilterOptions();
            this.financialYears = options.financialYears;
            this.companies = options.companies;
            this.selectedYear = this.defaultYear(options.financialYears);
            this.selectedMonth = FISCAL_MONTHS[(new Date().getMonth() + 9) % 12];
            this.branches = await getBranches({ companyId: null });
            await this.loadRows();
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

    async loadRows() {
        // Ignore a slow response if the user has changed a filter since asking for it.
        const request = ++this.latestRequest;
        this.isLoading = true;
        this.errorMessage = "";
        this.showAttachments = false;
        try {
            const rows = await getStatusRows({
                financialYear: this.selectedYear,
                month: this.selectedMonth,
                companyId: this.selectedCompany || null,
                branchId: this.selectedBranch || null
            });
            if (request === this.latestRequest) {
                this.rows = rows.map((row, index) => ({
                    ...row,
                    serial: index + 1,
                    mrBranchName: row.mrBranchName || "-",
                    mrEmployeeName: row.mrEmployeeName || "-"
                }));
            }
        } catch (error) {
            if (request === this.latestRequest) {
                this.rows = [];
                this.showError(error);
            }
        } finally {
            if (request === this.latestRequest) {
                this.isLoading = false;
            }
        }
    }

    showError(error) {
        this.errorMessage = error?.body?.message || error?.message || "Something went wrong.";
    }

    get isListView() {
        return !this.grid;
    }

    get showNoRows() {
        return !this.isLoading && !this.errorMessage && this.rows.length === 0;
    }

    get hasAttachments() {
        return this.attachments.length > 0;
    }

    get yearOptions() {
        return this.financialYears.map((year) => ({
            value: year,
            label: `${year.slice(0, 4)} - ${year.slice(0, 2)}${year.slice(-2)}`,
            selected: year === this.selectedYear
        }));
    }

    get monthOptions() {
        return FISCAL_MONTHS.map((month) => ({ value: month, label: month, selected: month === this.selectedMonth }));
    }

    get companyOptions() {
        return this.withAll(this.companies, this.selectedCompany);
    }

    get branchOptions() {
        return this.withAll(this.branches, this.selectedBranch);
    }

    withAll(options, selected) {
        return [
            { value: ALL, label: "ALL", selected: selected === ALL },
            ...options.map((option) => ({ ...option, selected: option.value === selected }))
        ];
    }

    handleYearChange(event) {
        this.selectedYear = event.target.value;
        this.loadRows();
    }

    handleMonthChange(event) {
        this.selectedMonth = event.target.value;
        this.loadRows();
    }

    async handleCompanyChange(event) {
        this.selectedCompany = event.target.value;
        this.selectedBranch = ALL;
        try {
            this.branches = await getBranches({ companyId: this.selectedCompany || null });
        } catch (error) {
            this.showError(error);
        }
        this.loadRows();
    }

    handleBranchChange(event) {
        this.selectedBranch = event.target.value;
        this.loadRows();
    }

    async handleAttachmentsClick() {
        if (this.showAttachments) {
            this.showAttachments = false;
            return;
        }
        this.isLoading = true;
        try {
            const budgetIds = this.rows.flatMap((row) => row.budgetIds);
            const files = await getAttachments({ budgetIds });
            this.attachments = files.map((file) => ({
                ...file,
                url: `/lightning/r/ContentDocument/${file.documentId}/view`,
                name: file.extension ? `${file.title}.${file.extension}` : file.title
            }));
            this.showAttachments = true;
        } catch (error) {
            this.showError(error);
        } finally {
            this.isLoading = false;
        }
    }

    handleViewBudget(event) {
        const row = this.rows[event.target.dataset.index];
        this.grid = {
            mode: "budget",
            budgetIds: row.budgetIds,
            title: `Budget: ${row.employeeName}, ${row.branchName} (${this.selectedYear})`
        };
    }

    handleViewReport(event) {
        const row = this.rows[event.target.dataset.index];
        this.grid = {
            mode: "report",
            budgetIds: row.budgetIds,
            title: `Monthly Report: ${row.employeeName}, ${row.branchName} (${this.selectedMonth}, ${this.selectedYear})`
        };
    }

    handleBack() {
        this.grid = null;
    }
}