/**
 * Read-only data for the budgetStageTracker LWC: one row per budget line and budgeted month,
 * with the stage reported in each monthly report (MIS). Outside Budget rows are flagged.
 * Runs in user mode, so each viewer only sees the budgets and fields they have access to.
 */
public with sharing class BudgetStageTrackerController {
    private static final String APPROVED_STATUS = '4th Level Approved';
    // "Development Outside Budget" on DC_Budget__c.
    private static final String OUTSIDE_RECORD_TYPE = 'Development_Budget';
    private static final List<String> FISCAL_MONTHS = new List<String>{
        'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'
    };
    // Mis_Monthly_Report__c is trusted only this close to CreatedDate. MIS windows run about
    // 5 weeks, while many records carry a date stamp from a window long closed.
    private static final Integer MAX_STAMP_DRIFT_DAYS = 45;
    // Budget values are entered in thousands of the line's currency.
    private static final Decimal VALUE_UNIT = 1000;

    public class TrackerRow {
        @AuraEnabled public String key;
        @AuraEnabled public Boolean isOutside;
        @AuraEnabled public String region;
        @AuraEnabled public String country;
        @AuraEnabled public String branch;
        @AuraEnabled public String customer;
        @AuraEnabled public String address;
        @AuraEnabled public String pmg;
        @AuraEnabled public String productGroup;
        @AuraEnabled public String description;
        @AuraEnabled public String partList;
        @AuraEnabled public String orderType;
        @AuraEnabled public String budgetMonth;
        @AuraEnabled public String budgetMonthLabel;
        @AuraEnabled public String expectedMonth;
        // Whole INR. Null when the line's currency has no exchange rate.
        @AuraEnabled public Decimal amountInr;
        @AuraEnabled public Map<String, String> stages = new Map<String, String>();
    }

    private class SlotHistory {
        Map<String, String> stages = new Map<String, String>();
        String expectedMonth;
    }

    @AuraEnabled
    public static List<String> getFinancialYears() {
        List<String> years = new List<String>();
        for (Financial_Year_Option_For_Custom_Reports__mdt config : [
            SELECT Financial_Year_Values_For_MIS_Report__c
            FROM Financial_Year_Option_For_Custom_Reports__mdt
        ]) {
            if (String.isNotBlank(config.Financial_Year_Values_For_MIS_Report__c)) {
                for (String year : config.Financial_Year_Values_For_MIS_Report__c.split(',')) {
                    if (!years.contains(year.trim())) {
                        years.add(year.trim());
                    }
                }
            }
        }
        return years;
    }

    /** All approved Budget and Outside rows for the year, with stages up to the selected month. */
    @AuraEnabled
    public static List<TrackerRow> getRows(String financialYear, String forMonth) {
        Date yearStart = monthStart(financialYear, 'Apr');
        Date cutoff = monthStart(financialYear, forMonth).addMonths(1);
        Map<Id, Map<String, SlotHistory>> history = loadHistory(financialYear, yearStart, cutoff);
        Map<String, Decimal> rates = exchangeRates(yearStart);
        String startYearSuffix = String.valueOf(yearStart.year()).right(2);
        String endYearSuffix = String.valueOf(yearStart.year() + 1).right(2);

        List<TrackerRow> rows = new List<TrackerRow>();
        for (DC_Budget_Line_Items__c line : [
            SELECT Id, CurrencyIsoCode, Customer_Name__c, Address__c, PMG_Name__c, Product_Group_Name__c, Description__c,
                Part_List_Name__c, Order_Type__c, Budget__r.RecordType.DeveloperName, Budget__r.Branch_Name__c,
                Budget__r.Branch__r.Branch_Code__c, Budget__r.Branch__r.Sales_Region__r.Name,
                Budget__r.Branch__r.Sales_Country__r.Name, Budget__r.Company__r.Company_Code__c,
                Apr_Order__c, May_Order__c, Jun_Order__c, Jul_Order__c, Aug_Order__c, Sep_Order__c,
                Oct_Order__c, Nov_Order__c, Dec_Order__c, Jan_Order__c, Feb_Order__c, Mar_Order__c
            FROM DC_Budget_Line_Items__c
            WHERE Active_Status__c = TRUE AND Budget__r.Financial_Year__c = :financialYear AND Budget__r.Status__c = :APPROVED_STATUS
            WITH USER_MODE
        ]) {
            Map<String, SlotHistory> slots = history.get(line.Id);
            for (Integer i = 0; i < FISCAL_MONTHS.size(); i++) {
                String slot = FISCAL_MONTHS[i];
                Decimal value = (Decimal) line.get(slot + '_Order__c');
                SlotHistory slotHistory = slots?.get(slot);
                // Outside lines can have a zero value, so a reported stage also earns a row.
                if ((value == null || value == 0) && slotHistory == null) {
                    continue;
                }
                TrackerRow row = new TrackerRow();
                row.key = line.Id + '-' + slot;
                row.isOutside = line.Budget__r.RecordType.DeveloperName == OUTSIDE_RECORD_TYPE;
                row.region = line.Budget__r.Branch__r?.Sales_Region__r?.Name;
                row.country = line.Budget__r.Branch__r?.Sales_Country__r?.Name;
                row.branch = branchLabel(line);
                row.customer = line.Customer_Name__c;
                row.address = addressLabel(line.Address__c);
                row.pmg = line.PMG_Name__c;
                row.productGroup = line.Product_Group_Name__c;
                row.description = line.Description__c;
                row.partList = line.Part_List_Name__c;
                row.orderType = line.Order_Type__c;
                row.budgetMonth = slot;
                // Jan to Mar (index 9 onward) fall in the second calendar year of the FY.
                row.budgetMonthLabel = slot.toUpperCase() + '-' + (i < 9 ? startYearSuffix : endYearSuffix);
                row.amountInr = toInr(value, line.CurrencyIsoCode, rates);
                if (slotHistory != null) {
                    row.expectedMonth = slotHistory.expectedMonth;
                    row.stages = slotHistory.stages;
                }
                rows.add(row);
            }
        }
        return rows;
    }

    /** For each active line and budgeted month: the stage per report month, oldest MIS first so the latest wins. */
    private static Map<Id, Map<String, SlotHistory>> loadHistory(String financialYear, Date yearStart, Date cutoff) {
        Map<Id, Id> nextVersions = nextVersions(financialYear);
        Datetime windowStart = Datetime.newInstance(yearStart.addDays(-(MAX_STAMP_DRIFT_DAYS + 1)), Time.newInstance(0, 0, 0, 0));
        Datetime windowEnd = Datetime.newInstance(cutoff.addDays(MAX_STAMP_DRIFT_DAYS + 1), Time.newInstance(0, 0, 0, 0));

        Map<Id, Map<String, SlotHistory>> history = new Map<Id, Map<String, SlotHistory>>();
        for (MIS_Budget__c mis : [
            SELECT Budget_Line_Items__c, CreatedDate, Mis_Monthly_Report__c,
                Order_Expected_Stage_Apr__c, Order_Expected_Stage_May__c, Order_Expected_Stage_Jun__c,
                Order_Expected_Stage_Jul__c, Order_Expected_Stage_Aug__c, Order_Expected_Stage_Sep__c,
                Order_Expected_Stage_Oct__c, Order_Expected_Stage_Nov__c, Order_Expected_Stage_Dec__c,
                Order_Expected_Stage_Jan__c, Order_Expected_Stage_Feb__c, Order_Expected_Stage_Mar__c,
                Order_Expected_Month_Apr__c, Order_Expected_Month_May__c, Order_Expected_Month_Jun__c,
                Order_Expected_Month_Jul__c, Order_Expected_Month_Aug__c, Order_Expected_Month_Sep__c,
                Order_Expected_Month_Oct__c, Order_Expected_Month_Nov__c, Order_Expected_Month_Dec__c,
                Order_Expected_Month_Jan__c, Order_Expected_Month_Feb__c, Order_Expected_Month_Mar__c
            FROM MIS_Budget__c
            WHERE Budget_Line_Items__r.Budget__r.Financial_Year__c = :financialYear
                AND CreatedDate >= :windowStart AND CreatedDate < :windowEnd
            WITH USER_MODE
            ORDER BY CreatedDate ASC
        ]) {
            Date reported = reportMonth(mis);
            if (reported < yearStart || reported >= cutoff) {
                continue;
            }
            String column = FISCAL_MONTHS[Math.mod(reported.month() + 8, 12)];
            // Editing a line creates a new version, while its older MIS stays on the old one.
            Id lineId = mis.Budget_Line_Items__c;
            while (nextVersions.containsKey(lineId)) {
                lineId = nextVersions.get(lineId);
            }
            for (String slot : FISCAL_MONTHS) {
                String stage = (String) mis.get('Order_Expected_Stage_' + slot + '__c');
                String expected = (String) mis.get('Order_Expected_Month_' + slot + '__c');
                if (String.isBlank(stage) && String.isBlank(expected)) {
                    continue;
                }
                if (!history.containsKey(lineId)) {
                    history.put(lineId, new Map<String, SlotHistory>());
                }
                Map<String, SlotHistory> slots = history.get(lineId);
                if (!slots.containsKey(slot)) {
                    slots.put(slot, new SlotHistory());
                }
                if (String.isNotBlank(stage)) {
                    slots.get(slot).stages.put(column, stage);
                }
                if (String.isNotBlank(expected)) {
                    slots.get(slot).expectedMonth = expectedMonthLabel(expected);
                }
            }
        }
        return history;
    }

    /** Maps each superseded line to the version that replaced it. */
    private static Map<Id, Id> nextVersions(String financialYear) {
        Map<Id, Id> nextVersions = new Map<Id, Id>();
        for (DC_Budget_Line_Items__c line : [
            SELECT Id, Previous_Version__c
            FROM DC_Budget_Line_Items__c
            WHERE Budget__r.Financial_Year__c = :financialYear AND Previous_Version__c != NULL
            WITH USER_MODE
        ]) {
            nextVersions.put(line.Previous_Version__c, line.Id);
        }
        return nextVersions;
    }

    /** Units of each currency per 1 INR (the corporate currency), as dated at the start of the FY. */
    private static Map<String, Decimal> exchangeRates(Date yearStart) {
        Map<String, Decimal> rates = new Map<String, Decimal>();
        for (CurrencyType currencyType : [SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsActive = TRUE]) {
            rates.put(currencyType.IsoCode, currencyType.ConversionRate);
        }
        for (DatedConversionRate dated : [
            SELECT IsoCode, ConversionRate
            FROM DatedConversionRate
            WHERE StartDate <= :yearStart AND NextStartDate > :yearStart
        ]) {
            rates.put(dated.IsoCode, dated.ConversionRate);
        }
        return rates;
    }

    private static Decimal toInr(Decimal value, String currencyCode, Map<String, Decimal> rates) {
        Decimal rate = rates.get(currencyCode);
        if (rate == null || rate == 0) {
            return null;
        }
        return ((value == null ? 0 : value) * VALUE_UNIT / rate).setScale(2);
    }

    /** The formula field holds HTML line breaks, escaped characters and empty address parts. */
    @TestVisible
    private static String addressLabel(String address) {
        if (String.isBlank(address)) {
            return null;
        }
        return address.replace('<br>', ', ').unescapeHtml4().replaceAll('\\s*,(\\s*,)+', ',').replaceAll('^[\\s,]+|[\\s,]+$', '');
    }

    private static String branchLabel(DC_Budget_Line_Items__c line) {
        String branchCode = line.Budget__r.Branch__r?.Branch_Code__c;
        String companyCode = line.Budget__r.Company__r?.Company_Code__c;
        if (branchCode == null && companyCode == null) {
            return line.Budget__r.Branch_Name__c;
        }
        return line.Budget__r.Branch_Name__c + ' (' + branchCode + ' - ' + companyCode + ')';
    }

    /** Stored as "Aug, 2026"; the report shows "Aug-26". */
    private static String expectedMonthLabel(String expected) {
        List<String> parts = expected.split(',');
        return parts.size() == 2 ? parts[0].trim() + '-' + parts[1].trim().right(2) : expected;
    }

    /** The calendar month a MIS record reports on, as the first day of that month. */
    private static Date reportMonth(MIS_Budget__c mis) {
        Date created = mis.CreatedDate.date();
        Date stamped = mis.Mis_Monthly_Report__c;
        if (stamped != null && Math.abs(stamped.daysBetween(created)) <= MAX_STAMP_DRIFT_DAYS) {
            return stamped.toStartOfMonth();
        }
        return created.toStartOfMonth();
    }

    private static Date monthStart(String financialYear, String month) {
        Integer fiscalIndex = FISCAL_MONTHS.indexOf(month);
        if (fiscalIndex < 0 || String.isBlank(financialYear) || !financialYear.left(4).isNumeric()) {
            throw new AuraHandledException('Select a valid financial year and month.');
        }
        Integer startYear = Integer.valueOf(financialYear.left(4));
        return fiscalIndex < 9
            ? Date.newInstance(startYear, fiscalIndex + 4, 1)
            : Date.newInstance(startYear + 1, fiscalIndex - 8, 1);
    }
}