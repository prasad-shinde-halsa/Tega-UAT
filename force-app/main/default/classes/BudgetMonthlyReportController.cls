/**
 * Read-only data for the budgetMonthlyReportStatus and budgetMonthlyReportGrid LWCs:
 * who has a budget, who filed a monthly report (MIS) for the month, and the Excel-style detail.
 * Runs in user mode, so each viewer only sees the budgets and fields they have access to.
 */
public with sharing class BudgetMonthlyReportController {
    private static final String APPROVED_STATUS = '4th Level Approved';
    // Fiscal order. A month before Apr falls in the second calendar year of the FY.
    private static final List<String> FISCAL_MONTHS = new List<String>{
        'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'
    };
    // The only two months whose MIS value field does not follow the short-name pattern.
    private static final Map<String, String> VALUE_FIELD_EXCEPTIONS = new Map<String, String>{
        'Apr' => 'Expected_Order_Value_April__c',
        'Jun' => 'Expected_Order_Value_June__c'
    };
    // Mis_Monthly_Report__c is trusted only this close to CreatedDate. MIS windows run about
    // 5 weeks, while many records carry a date stamp from a window long closed.
    private static final Integer MAX_STAMP_DRIFT_DAYS = 45;

    public class Option implements Comparable {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        Option(String label, String value) {
            this.label = label;
            this.value = value;
        }
        public Integer compareTo(Object other) {
            return label.compareTo(((Option) other).label);
        }
    }

    public class FilterOptions {
        @AuraEnabled public List<String> financialYears = new List<String>();
        @AuraEnabled public List<Option> companies = new List<Option>();
    }

    public class StatusRow implements Comparable {
        @AuraEnabled public String key;
        @AuraEnabled public String branchName;
        @AuraEnabled public String employeeName;
        @AuraEnabled public String mrBranchName;
        @AuraEnabled public String mrEmployeeName;
        @AuraEnabled public Boolean hasReport = false;
        @AuraEnabled public List<Id> budgetIds = new List<Id>();
        public Integer compareTo(Object other) {
            StatusRow that = (StatusRow) other;
            Integer byBranch = (branchName == null ? '' : branchName).compareTo(that.branchName == null ? '' : that.branchName);
            return byBranch != 0 ? byBranch : (employeeName == null ? '' : employeeName).compareTo(that.employeeName == null ? '' : that.employeeName);
        }
    }

    public class AttachmentRow {
        @AuraEnabled public Id documentId;
        @AuraEnabled public String title;
        @AuraEnabled public String extension;
        @AuraEnabled public Datetime createdDate;
    }

    @AuraEnabled
    public static FilterOptions getFilterOptions() {
        FilterOptions options = new FilterOptions();
        for (Financial_Year_Option_For_Custom_Reports__mdt config : [
            SELECT FY_Option_For_MIS_Status_Check__c
            FROM Financial_Year_Option_For_Custom_Reports__mdt
        ]) {
            if (String.isNotBlank(config.FY_Option_For_MIS_Status_Check__c)) {
                for (String year : config.FY_Option_For_MIS_Status_Check__c.split(',')) {
                    if (!options.financialYears.contains(year.trim())) {
                        options.financialYears.add(year.trim());
                    }
                }
            }
        }
        for (Company__c company : [SELECT Id, Name FROM Company__c WITH USER_MODE ORDER BY Name]) {
            options.companies.add(new Option(company.Name, company.Id));
        }
        return options;
    }

    /** Branches of one company, or of every company when companyId is blank. */
    @AuraEnabled
    public static List<Option> getBranches(Id companyId) {
        Map<Id, Option> branchesById = new Map<Id, Option>();
        for (Sales_Org_Branch_Relationship__c relationship : [
            SELECT Company__c, Branch__c, Branch__r.Name
            FROM Sales_Org_Branch_Relationship__c
            WITH USER_MODE
        ]) {
            if (companyId == null || relationship.Company__c == companyId) {
                branchesById.put(
                    relationship.Branch__c,
                    new Option(relationship.Branch__r.Name, relationship.Branch__c)
                );
            }
        }
        List<Option> branches = branchesById.values();
        branches.sort();
        return branches;
    }

    /** One row per branch and budget owner, merging that person's budget types and companies. */
    @AuraEnabled
    public static List<StatusRow> getStatusRows(String financialYear, String month, Id companyId, Id branchId) {
        Date monthStart = monthStart(financialYear, month);

        List<DC_Budget__c> budgets = [
            SELECT Id, Company__c, Branch__c, Branch_Name__c, OwnerId
            FROM DC_Budget__c
            WHERE Financial_Year__c = :financialYear AND Status__c = :APPROVED_STATUS
            WITH USER_MODE
        ];
        // Owner.Name is polymorphic and comes back empty in user mode, so read the User directly.
        Set<Id> ownerIds = new Set<Id>();
        for (DC_Budget__c budget : budgets) {
            ownerIds.add(budget.OwnerId);
        }
        Map<Id, User> owners = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :ownerIds WITH USER_MODE]);

        Map<String, StatusRow> rowsByKey = new Map<String, StatusRow>();
        Map<Id, StatusRow> rowsByBudget = new Map<Id, StatusRow>();
        for (DC_Budget__c budget : budgets) {
            if ((companyId != null && budget.Company__c != companyId) || (branchId != null && budget.Branch__c != branchId)) {
                continue;
            }
            String key = budget.Branch__c + '|' + budget.OwnerId;
            StatusRow row = rowsByKey.get(key);
            if (row == null) {
                row = new StatusRow();
                row.key = key;
                row.branchName = budget.Branch_Name__c;
                row.employeeName = owners.containsKey(budget.OwnerId) ? owners.get(budget.OwnerId).Name : null;
                rowsByKey.put(key, row);
            }
            row.budgetIds.add(budget.Id);
            rowsByBudget.put(budget.Id, row);
        }

        Set<Id> budgetIds = rowsByBudget.keySet();
        Datetime windowStart = windowStart(monthStart);
        Datetime windowEnd = windowEnd(monthStart);
        Map<String, Map<String, Integer>> reportersByKey = new Map<String, Map<String, Integer>>();
        for (MIS_Budget__c mis : [
            SELECT Budget_Line_Items__r.Budget__c, CreatedBy.Name, CreatedDate, Mis_Monthly_Report__c
            FROM MIS_Budget__c
            WHERE Budget_Line_Items__r.Budget__c IN :budgetIds AND CreatedDate >= :windowStart AND CreatedDate < :windowEnd
            WITH USER_MODE
        ]) {
            if (reportMonth(mis) != monthStart) {
                continue;
            }
            StatusRow row = rowsByBudget.get(mis.Budget_Line_Items__r.Budget__c);
            row.hasReport = true;
            row.mrBranchName = row.branchName;
            if (!reportersByKey.containsKey(row.key)) {
                reportersByKey.put(row.key, new Map<String, Integer>());
            }
            Map<String, Integer> reporters = reportersByKey.get(row.key);
            String reporter = mis.CreatedBy.Name;
            reporters.put(reporter, reporters.containsKey(reporter) ? reporters.get(reporter) + 1 : 1);
        }

        // A row can have several creators, so show whoever filed the most lines.
        for (String key : reportersByKey.keySet()) {
            Map<String, Integer> reporters = reportersByKey.get(key);
            Integer highest = 0;
            for (String reporter : reporters.keySet()) {
                if (reporters.get(reporter) > highest) {
                    highest = reporters.get(reporter);
                    rowsByKey.get(key).mrEmployeeName = reporter;
                }
            }
        }
        List<StatusRow> rows = rowsByKey.values();
        rows.sort();
        return rows;
    }

    /** Budget screen: one row per active line with the 12 planned monthly order values. */
    @AuraEnabled
    public static List<Map<String, Object>> getBudgetRows(List<Id> budgetIds) {
        Map<Id, Id> previousVersions = previousVersions(budgetIds);
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        Id currentBudget;
        Integer serial = 0;
        for (DC_Budget_Line_Items__c line : [
            SELECT Id, Budget__c, Budget__r.Name, CurrencyIsoCode, PMG_Name__c, Product_Group_Name__c, Description__c,
                Customer_Code__c, Customer_Name__c, Annual_Potential__c, Order_Type__c, Total_Order__c,
                Apr_Order__c, May_Order__c, Jun_Order__c, Jul_Order__c, Aug_Order__c, Sep_Order__c,
                Oct_Order__c, Nov_Order__c, Dec_Order__c, Jan_Order__c, Feb_Order__c, Mar_Order__c
            FROM DC_Budget_Line_Items__c
            WHERE Budget__c IN :budgetIds AND Active_Status__c = TRUE
            WITH USER_MODE
            ORDER BY Budget__r.Name, Name
        ]) {
            serial = (line.Budget__c == currentBudget) ? serial + 1 : 1;
            currentBudget = line.Budget__c;
            Map<String, Object> row = lineColumns(line, line.Budget__r.Name, previousVersions);
            row.put('key', String.valueOf(line.Id));
            row.put('slNo', serial);
            for (String fiscalMonth : FISCAL_MONTHS) {
                row.put(fiscalMonth, line.get(fiscalMonth + '_Order__c'));
            }
            row.put('total', line.Total_Order__c);
            rows.add(row);
        }
        return rows;
    }

    /** Monthly report screen: one row for each filled month slot of each line's latest MIS. */
    @AuraEnabled
    public static List<Map<String, Object>> getReportRows(List<Id> budgetIds, String financialYear, String month) {
        Date monthStart = monthStart(financialYear, month);
        Map<Id, Id> previousVersions = previousVersions(budgetIds);
        String monthLabel = month + '-' + String.valueOf(monthStart.year()).right(2);
        Datetime windowStart = windowStart(monthStart);
        Datetime windowEnd = windowEnd(monthStart);

        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        Set<Id> seenLines = new Set<Id>();
        Id currentBudget;
        Integer serial = 0;
        for (MIS_Budget__c mis : [
            SELECT Id, CreatedDate, Mis_Monthly_Report__c, CurrencyIsoCode, Budget_Line_Items__c,
                Budget_Line_Items__r.Budget__c, Budget_Line_Items__r.Budget__r.Name, Budget_Line_Items__r.CurrencyIsoCode, Budget_Line_Items__r.PMG_Name__c,
                Budget_Line_Items__r.Product_Group_Name__c, Budget_Line_Items__r.Description__c,
                Budget_Line_Items__r.Customer_Code__c, Budget_Line_Items__r.Customer_Name__c,
                Budget_Line_Items__r.Annual_Potential__c, Budget_Line_Items__r.Order_Type__c,
                Budget_Line_Items__r.Apr_Order_Actual__c, Budget_Line_Items__r.May_Order_Actual__c,
                Budget_Line_Items__r.Jun_Order_Actual__c, Budget_Line_Items__r.Jul_Order_Actual__c,
                Budget_Line_Items__r.Aug_Order_Actual__c, Budget_Line_Items__r.Sep_Order_Actual__c,
                Budget_Line_Items__r.Oct_Order_Actual__c, Budget_Line_Items__r.Nov_Order_Actual__c,
                Budget_Line_Items__r.Dec_Order_Actual__c, Budget_Line_Items__r.Jan_Order_Actual__c,
                Budget_Line_Items__r.Feb_Order_Actual__c, Budget_Line_Items__r.Mar_Order_Actual__c,
                Order_Expected_Stage_Apr__c, Order_Expected_Stage_May__c, Order_Expected_Stage_Jun__c,
                Order_Expected_Stage_Jul__c, Order_Expected_Stage_Aug__c, Order_Expected_Stage_Sep__c,
                Order_Expected_Stage_Oct__c, Order_Expected_Stage_Nov__c, Order_Expected_Stage_Dec__c,
                Order_Expected_Stage_Jan__c, Order_Expected_Stage_Feb__c, Order_Expected_Stage_Mar__c,
                Remarks_Apr__c, Remarks_May__c, Remarks_Jun__c, Remarks_Jul__c, Remarks_Aug__c, Remarks_Sep__c,
                Remarks_Oct__c, Remarks_Nov__c, Remarks_Dec__c, Remarks_Jan__c, Remarks_Feb__c, Remarks_Mar__c,
                Expected_Order_Value_April__c, Expected_Order_Value_May__c, Expected_Order_Value_June__c,
                Expected_Order_Value_Jul__c, Expected_Order_Value_Aug__c, Expected_Order_Value_Sep__c,
                Expected_Order_Value_Oct__c, Expected_Order_Value_Nov__c, Expected_Order_Value_Dec__c,
                Expected_Order_Value_Jan__c, Expected_Order_Value_Feb__c, Expected_Order_Value_Mar__c
            FROM MIS_Budget__c
            WHERE Budget_Line_Items__r.Budget__c IN :budgetIds AND CreatedDate >= :windowStart AND CreatedDate < :windowEnd
            WITH USER_MODE
            ORDER BY Budget_Line_Items__r.Budget__r.Name, Budget_Line_Items__r.Name, CreatedDate DESC
        ]) {
            // Rows arrive newest first per line, so the first one in the month is the latest.
            if (reportMonth(mis) != monthStart || seenLines.contains(mis.Budget_Line_Items__c)) {
                continue;
            }
            seenLines.add(mis.Budget_Line_Items__c);
            if (mis.Budget_Line_Items__r.Budget__c != currentBudget) {
                currentBudget = mis.Budget_Line_Items__r.Budget__c;
                serial = 0;
            }

            List<String> filledSlots = filledSlots(mis);
            // Keep a line with no slots filled, so a filed report never silently loses a row.
            for (String slot : filledSlots.isEmpty() ? new List<String>{ null } : filledSlots) {
                DC_Budget_Line_Items__c line = mis.Budget_Line_Items__r;
                Map<String, Object> row = lineColumns(line, line.Budget__r.Name, previousVersions);
                row.put('key', mis.Id + '-' + slot);
                row.put('misMonth', monthLabel);
                row.put('currencyCode', mis.CurrencyIsoCode);
                row.put('slNo', ++serial);
                row.put('budgetMonth', slot);
                row.put('conStage', slot == null ? null : mis.get('Order_Expected_Stage_' + slot + '__c'));
                Object received = slot == null ? null : line.get(slot + '_Order_Actual__c');
                row.put('orderReceived', received == null ? 0 : received);
                row.put('remarks', slot == null ? null : mis.get('Remarks_' + slot + '__c'));
                rows.add(row);
            }
        }
        return rows;
    }

    /** Files attached to the budgets currently listed on the status screen. */
    @AuraEnabled
    public static List<AttachmentRow> getAttachments(List<Id> budgetIds) {
        Map<Id, AttachmentRow> attachments = new Map<Id, AttachmentRow>();
        if (budgetIds == null || budgetIds.isEmpty()) {
            return attachments.values();
        }
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.CreatedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :budgetIds
            WITH USER_MODE
        ]) {
            AttachmentRow attachment = new AttachmentRow();
            attachment.documentId = link.ContentDocumentId;
            attachment.title = link.ContentDocument.Title;
            attachment.extension = link.ContentDocument.FileExtension;
            attachment.createdDate = link.ContentDocument.CreatedDate;
            attachments.put(link.ContentDocumentId, attachment);
        }
        return attachments.values();
    }

    /** The calendar month a MIS record reports on, as the first day of that month. */
    @TestVisible
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
        // Apr is calendar month 4; Jan to Mar (index 9 to 11) wrap into the next year.
        return fiscalIndex < 9
            ? Date.newInstance(startYear, fiscalIndex + 4, 1)
            : Date.newInstance(startYear + 1, fiscalIndex - 8, 1);
    }

    private static Datetime windowStart(Date monthStart) {
        return Datetime.newInstance(monthStart.addDays(-(MAX_STAMP_DRIFT_DAYS + 1)), Time.newInstance(0, 0, 0, 0));
    }

    private static Datetime windowEnd(Date monthStart) {
        return Datetime.newInstance(monthStart.addMonths(1).addDays(MAX_STAMP_DRIFT_DAYS + 1), Time.newInstance(0, 0, 0, 0));
    }

    private static List<String> filledSlots(MIS_Budget__c mis) {
        List<String> slots = new List<String>();
        for (String fiscalMonth : FISCAL_MONTHS) {
            String valueField = VALUE_FIELD_EXCEPTIONS.containsKey(fiscalMonth)
                ? VALUE_FIELD_EXCEPTIONS.get(fiscalMonth)
                : 'Expected_Order_Value_' + fiscalMonth + '__c';
            Decimal value = (Decimal) mis.get(valueField);
            if (
                mis.get('Order_Expected_Stage_' + fiscalMonth + '__c') != null ||
                mis.get('Remarks_' + fiscalMonth + '__c') != null ||
                (value != null && value != 0)
            ) {
                slots.add(fiscalMonth);
            }
        }
        return slots;
    }

    private static Map<String, Object> lineColumns(DC_Budget_Line_Items__c line, String budgetName, Map<Id, Id> previousVersions) {
        return new Map<String, Object>{
            'budgetId' => budgetName,
            'rev' => revision(line.Id, previousVersions),
            'currencyCode' => line.CurrencyIsoCode,
            'buName' => line.PMG_Name__c,
            'pgName' => line.Product_Group_Name__c,
            'descr' => line.Description__c,
            'customerCode' => line.Customer_Code__c,
            'customerName' => line.Customer_Name__c,
            'annualPotential' => line.Annual_Potential__c,
            'orderType' => line.Order_Type__c
        };
    }

    private static Map<Id, Id> previousVersions(List<Id> budgetIds) {
        Map<Id, Id> previousVersions = new Map<Id, Id>();
        for (DC_Budget_Line_Items__c line : [
            SELECT Id, Previous_Version__c
            FROM DC_Budget_Line_Items__c
            WHERE Budget__c IN :budgetIds AND Previous_Version__c != NULL
            WITH USER_MODE
        ]) {
            previousVersions.put(line.Id, line.Previous_Version__c);
        }
        return previousVersions;
    }

    /** How many earlier versions a line has: 0 is the original. */
    private static Integer revision(Id lineId, Map<Id, Id> previousVersions) {
        Integer revision = 0;
        Id current = lineId;
        while (previousVersions.containsKey(current)) {
            revision++;
            current = previousVersions.get(current);
        }
        return revision;
    }
}