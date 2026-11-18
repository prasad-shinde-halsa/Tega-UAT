/**
 * Read-only data for the detailedMISdata LWC: every monthly report (MIS) entry of a financial year,
 * one entry per MIS record and budgeted month that carries a stage, expected month, expected value
 * or remark. Budget line details are sent once per line and referenced by the entries.
 * Runs in user mode, so each viewer only sees the budgets and fields they have access to.
 */
public with sharing class DetailedMISDataController {
    // "Development Outside Budget" on DC_Budget__c.
    private static final String OUTSIDE_RECORD_TYPE = 'Development_Budget';
    private static final List<String> FISCAL_MONTHS = new List<String>{
        'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'
    };
    // Expected Order Value fields do not all follow the month pattern.
    private static final Map<String, String> EXPECTED_VALUE_FIELDS = new Map<String, String>{
        'Apr' => 'Expected_Order_Value_April__c',
        'Jun' => 'Expected_Order_Value_June__c'
    };
    // Mis_Monthly_Report__c is trusted only this close to CreatedDate (same rule as the stage tracker).
    private static final Integer MAX_STAMP_DRIFT_DAYS = 45;
    // Budget and expected values are entered in thousands of the record's currency.
    private static final Decimal VALUE_UNIT = 1000;

    public class LineInfo {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean isOutside;
        @AuraEnabled public String budgetStatus;
        @AuraEnabled public String owner;
        @AuraEnabled public String region;
        @AuraEnabled public String country;
        @AuraEnabled public String branch;
        @AuraEnabled public String customer;
        @AuraEnabled public String pmg;
        @AuraEnabled public String productGroup;
        @AuraEnabled public String partList;
        @AuraEnabled public String description;
        @AuraEnabled public String orderType;
        @AuraEnabled public String currencyCode;
        // Budgeted order value per fiscal month, whole INR. Null when the currency has no rate.
        @AuraEnabled public Map<String, Decimal> budgetInr = new Map<String, Decimal>();
    }

    public class Entry {
        @AuraEnabled public String misId;
        @AuraEnabled public String misName;
        @AuraEnabled public String lineId;
        @AuraEnabled public String slot;
        // First day of the month the MIS reports on, as yyyy-MM.
        @AuraEnabled public String reportKey;
        @AuraEnabled public String stage;
        @AuraEnabled public String expectedMonth;
        @AuraEnabled public Decimal expectedValueInr;
        @AuraEnabled public String remarks;
        @AuraEnabled public String submittedBy;
        @AuraEnabled public Datetime submittedOn;
        @AuraEnabled public Boolean isActive;
    }

    public class Payload {
        @AuraEnabled public List<LineInfo> lines = new List<LineInfo>();
        @AuraEnabled public List<Entry> entries = new List<Entry>();
        // Stage picklist values in their configured order.
        @AuraEnabled public List<String> stages = new List<String>();
    }

    @AuraEnabled
    public static List<String> getFinancialYears() {
        return BudgetStageTrackerController.getFinancialYears();
    }

    @AuraEnabled
    public static Payload getData(String financialYear) {
        if (String.isBlank(financialYear) || !financialYear.left(4).isNumeric()) {
            throw new AuraHandledException('Select a valid financial year.');
        }
        Date yearStart = Date.newInstance(Integer.valueOf(financialYear.left(4)), 4, 1);
        Map<String, Decimal> rates = exchangeRates(yearStart);
        Map<Id, Id> nextVersions = nextVersions(financialYear);

        Payload payload = new Payload();
        payload.stages = stageValues();

        Set<Id> lineIds = new Set<Id>();
        List<MIS_Budget__c> reports = Database.queryWithBinds(misQuery(), new Map<String, Object>{ 'fy' => financialYear }, AccessLevel.USER_MODE);
        for (MIS_Budget__c mis : reports) {
            // Editing a line creates a new version, while its older MIS stays on the old one.
            Id lineId = mis.Budget_Line_Items__c;
            while (nextVersions.containsKey(lineId)) {
                lineId = nextVersions.get(lineId);
            }
            String reportKey = reportMonth(mis);
            for (String slot : FISCAL_MONTHS) {
                String stage = (String) mis.get('Order_Expected_Stage_' + slot + '__c');
                String expected = (String) mis.get('Order_Expected_Month_' + slot + '__c');
                String remarks = (String) mis.get('Remarks_' + slot + '__c');
                Decimal value = (Decimal) mis.get(expectedValueField(slot));
                if (String.isBlank(stage) && String.isBlank(expected) && String.isBlank(remarks) && (value == null || value == 0)) {
                    continue;
                }
                Entry entry = new Entry();
                entry.misId = mis.Id;
                entry.misName = mis.Name;
                entry.lineId = lineId;
                entry.slot = slot;
                entry.reportKey = reportKey;
                entry.stage = stage;
                entry.expectedMonth = String.isBlank(expected) ? null : expectedMonthLabel(expected);
                entry.expectedValueInr = (value == null || value == 0) ? null : toInr(value, mis.CurrencyIsoCode, rates);
                entry.remarks = remarks;
                entry.submittedBy = mis.CreatedBy?.Name;
                entry.submittedOn = mis.CreatedDate;
                entry.isActive = mis.IsActive__c;
                payload.entries.add(entry);
                lineIds.add(lineId);
            }
        }

        for (DC_Budget_Line_Items__c line : [
            SELECT Id, Name, CurrencyIsoCode, Customer_Name__c, PMG_Name__c, Product_Group_Name__c, Description__c,
                Part_List_Name__c, Order_Type__c, Budget__r.RecordType.DeveloperName, Budget__r.Status__c,
                Budget__r.Owner_Name__c, Budget__r.Branch_Name__c, Budget__r.Branch__r.Branch_Code__c,
                Budget__r.Branch__r.Sales_Region__r.Name, Budget__r.Branch__r.Sales_Country__r.Name,
                Budget__r.Company__r.Company_Code__c,
                Apr_Order__c, May_Order__c, Jun_Order__c, Jul_Order__c, Aug_Order__c, Sep_Order__c,
                Oct_Order__c, Nov_Order__c, Dec_Order__c, Jan_Order__c, Feb_Order__c, Mar_Order__c
            FROM DC_Budget_Line_Items__c
            WHERE Id IN :lineIds
            WITH USER_MODE
        ]) {
            payload.lines.add(toLineInfo(line, rates));
        }
        return payload;
    }

    private static String misQuery() {
        List<String> fields = new List<String>{
            'Id', 'Name', 'Budget_Line_Items__c', 'CreatedDate', 'CreatedBy.Name', 'Mis_Monthly_Report__c',
            'IsActive__c', 'CurrencyIsoCode'
        };
        for (String slot : FISCAL_MONTHS) {
            fields.add('Order_Expected_Stage_' + slot + '__c');
            fields.add('Order_Expected_Month_' + slot + '__c');
            fields.add('Remarks_' + slot + '__c');
            fields.add(expectedValueField(slot));
        }
        return 'SELECT ' + String.join(fields, ', ') +
            ' FROM MIS_Budget__c WHERE Budget_Line_Items__r.Budget__r.Financial_Year__c = :fy ORDER BY CreatedDate ASC';
    }

    @TestVisible
    private static String expectedValueField(String slot) {
        return EXPECTED_VALUE_FIELDS.containsKey(slot) ? EXPECTED_VALUE_FIELDS.get(slot) : 'Expected_Order_Value_' + slot + '__c';
    }

    private static LineInfo toLineInfo(DC_Budget_Line_Items__c line, Map<String, Decimal> rates) {
        LineInfo info = new LineInfo();
        info.id = line.Id;
        info.name = line.Name;
        info.isOutside = line.Budget__r.RecordType.DeveloperName == OUTSIDE_RECORD_TYPE;
        info.budgetStatus = line.Budget__r.Status__c;
        info.owner = line.Budget__r.Owner_Name__c;
        info.region = line.Budget__r.Branch__r?.Sales_Region__r?.Name;
        info.country = line.Budget__r.Branch__r?.Sales_Country__r?.Name;
        info.branch = branchLabel(line);
        info.customer = line.Customer_Name__c;
        info.pmg = line.PMG_Name__c;
        info.productGroup = line.Product_Group_Name__c;
        info.partList = line.Part_List_Name__c;
        info.description = line.Description__c;
        info.orderType = line.Order_Type__c;
        info.currencyCode = line.CurrencyIsoCode;
        for (String slot : FISCAL_MONTHS) {
            Decimal value = (Decimal) line.get(slot + '_Order__c');
            if (value != null && value != 0) {
                info.budgetInr.put(slot, toInr(value, line.CurrencyIsoCode, rates));
            }
        }
        return info;
    }

    private static List<String> stageValues() {
        List<String> stages = new List<String>();
        for (Schema.PicklistEntry entry : MIS_Budget__c.Order_Expected_Stage_Jan__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                stages.add(entry.getValue());
            }
        }
        return stages;
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
        return (value * VALUE_UNIT / rate).setScale(2);
    }

    private static String branchLabel(DC_Budget_Line_Items__c line) {
        String branchCode = line.Budget__r.Branch__r?.Branch_Code__c;
        String companyCode = line.Budget__r.Company__r?.Company_Code__c;
        if (branchCode == null && companyCode == null) {
            return line.Budget__r.Branch_Name__c;
        }
        return line.Budget__r.Branch_Name__c + ' (' + branchCode + ' - ' + companyCode + ')';
    }

    /** Stored as "Aug, 2026"; shown as "Aug-26". */
    @TestVisible
    private static String expectedMonthLabel(String expected) {
        List<String> parts = expected.split(',');
        return parts.size() == 2 ? parts[0].trim() + '-' + parts[1].trim().right(2) : expected;
    }

    /** The calendar month a MIS record reports on, as yyyy-MM. */
    @TestVisible
    private static String reportMonth(MIS_Budget__c mis) {
        Date created = mis.CreatedDate.date();
        Date stamped = mis.Mis_Monthly_Report__c;
        Date month = (stamped != null && Math.abs(stamped.daysBetween(created)) <= MAX_STAMP_DRIFT_DAYS)
            ? stamped
            : created;
        return month.year() + '-' + String.valueOf(month.month()).leftPad(2, '0');
    }
}