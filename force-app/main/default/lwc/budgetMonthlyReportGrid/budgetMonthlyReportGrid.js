import { LightningElement, api } from "lwc";
import getBudgetRows from "@salesforce/apex/BudgetMonthlyReportController.getBudgetRows";
import getReportRows from "@salesforce/apex/BudgetMonthlyReportController.getReportRows";

const FISCAL_MONTHS = ["Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"];

const column = (key, label, type = "") => ({ key, label, type });

const REPORT_COLUMNS = [
    column("budgetId", "Budget ID"),
    column("rev", "rev", "number"),
    column("misMonth", "MIS_Month"),
    column("currencyCode", "currency_code"),
    column("slNo", "sl_no", "number"),
    column("buName", "bu_name"),
    column("pgName", "pg_name"),
    column("descr", "descr", "long"),
    column("customerCode", "customer_code"),
    column("customerName", "customer_name", "long"),
    column("annualPotential", "annual_potential", "number"),
    column("budgetMonth", "budget_month"),
    column("conStage", "con_stage"),
    column("orderType", "order_type"),
    column("orderReceived", "order_received", "number"),
    column("remarks", "remarks", "long")
];

const BUDGET_COLUMNS = [
    column("budgetId", "Budget ID"),
    column("rev", "rev", "number"),
    column("currencyCode", "currency_code"),
    column("slNo", "sl_no", "number"),
    column("buName", "bu_name"),
    column("pgName", "pg_name"),
    column("descr", "descr", "long"),
    column("customerCode", "customer_code"),
    column("customerName", "customer_name", "long"),
    column("annualPotential", "annual_potential", "number"),
    column("orderType", "order_type"),
    ...FISCAL_MONTHS.map((month) => column(month, month, "number")),
    column("total", "total", "number")
];

export default class BudgetMonthlyReportGrid extends LightningElement {
    @api mode;
    @api budgetIds;
    @api financialYear;
    @api month;
    @api title;

    rawRows = [];
    isLoading = true;
    errorMessage = "";

    async connectedCallback() {
        try {
            this.rawRows =
                this.mode === "report"
                    ? await getReportRows({
                          budgetIds: this.budgetIds,
                          financialYear: this.financialYear,
                          month: this.month
                      })
                    : await getBudgetRows({ budgetIds: this.budgetIds });
        } catch (error) {
            this.errorMessage = error?.body?.message || error?.message || "Something went wrong.";
        } finally {
            this.isLoading = false;
        }
    }

    get columns() {
        return this.mode === "report" ? REPORT_COLUMNS : BUDGET_COLUMNS;
    }

    get rows() {
        return this.rawRows.map((row) => ({
            key: row.key,
            cells: this.columns.map((col) => ({
                key: col.key,
                value: this.format(row[col.key]),
                className: col.type
            }))
        }));
    }

    get showNoRows() {
        return !this.isLoading && !this.errorMessage && this.rawRows.length === 0;
    }

    format(value) {
        if (value === null || value === undefined) {
            return "";
        }
        return typeof value === "number" ? Math.round(value * 100) / 100 : value;
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent("back"));
    }
}