@isTest
private class BudgetMonthlyReportControllerTest {
    private static final String FY = '2025-26';

    @testSetup
    static void setupData() {
        Branch__c branch = new Branch__c(
            Name = 'Test Branch',
            Branch_Code__c = 'TB001',
            CIF_Factor__c = 1.04,
            CurrencyIsoCode = 'USD',
            Is_WOS__c = true,
            Branch_Head__c = UserInfo.getUserId()
        );
        insert branch;

        List<Company__c> companies = new List<Company__c>{
            new Company__c(Name = 'Test Company', Company_Code__c = 'LS06', CurrencyIsoCode = 'USD'),
            new Company__c(Name = 'Other Company', Company_Code__c = 'LS07', CurrencyIsoCode = 'USD')
        };
        insert companies;
        insert new Sales_Org_Branch_Relationship__c(Company__c = companies[0].Id, Branch__c = branch.Id);

        // Same owner and branch with two budgets: these must merge into one status row.
        List<DC_Budget__c> budgets = new List<DC_Budget__c>{
            newBudget('Budget A', branch.Id, companies[0].Id),
            newBudget('Budget B', branch.Id, companies[0].Id)
        };
        insert budgets;

        PMG_Master__c pmg = new PMG_Master__c(Name = 'Test PMG');
        insert pmg;
        Account customer = new Account(Name = 'Test Customer');
        insert customer;

        insert new DC_Budget_Line_Items__c(
            Budget__c = budgets[0].Id,
            PMG_Master__c = pmg.Id,
            Customer__c = customer.Id,
            Order_Type__c = 'E-Spares',
            Active_Status__c = true,
            Annual_Potential__c = 500,
            Description__c = 'Test line',
            Aug_Order__c = 100,
            Aug_Order_Actual__c = 40,
            Dec_Order__c = 200
        );
    }

    private static DC_Budget__c newBudget(String name, Id branchId, Id companyId) {
        return new DC_Budget__c(
            Name = name,
            Status__c = '4th Level Approved',
            Financial_Year__c = FY,
            CurrencyIsoCode = 'USD',
            Branch__c = branchId,
            Company__c = companyId
        );
    }

    private static DC_Budget_Line_Items__c firstLine() {
        return [SELECT Id, Budget__c, Customer__c, PMG_Master__c FROM DC_Budget_Line_Items__c LIMIT 1];
    }

    private static MIS_Budget__c insertMis(MIS_Budget__c mis, Datetime createdDate) {
        mis.Budget_Line_Items__c = firstLine().Id;
        mis.CurrencyIsoCode = 'USD';
        insert mis;
        Test.setCreatedDate(mis.Id, createdDate);
        return mis;
    }

    @isTest
    static void statusMergesBudgetsAndShowsNoReportWhenMisIsMissing() {
        List<BudgetMonthlyReportController.StatusRow> rows = BudgetMonthlyReportController.getStatusRows(FY, 'Aug', null, null);

        Assert.areEqual(1, rows.size(), 'Same branch and owner should merge into one row');
        Assert.areEqual(2, rows[0].budgetIds.size());
        Assert.areEqual('Test Branch', rows[0].branchName);
        Assert.areEqual(UserInfo.getName(), rows[0].employeeName);
        Assert.isFalse(rows[0].hasReport);
        Assert.isNull(rows[0].mrEmployeeName);
    }

    @isTest
    static void statusUsesCreatedMonthWhenStampIsStale() {
        // Stamped 2025-09-04 but filed months later, as the live data shows.
        insertMis(new MIS_Budget__c(Mis_Monthly_Report__c = Date.newInstance(2025, 9, 4)), Datetime.newInstance(2026, 1, 15, 10, 0, 0));

        Assert.isTrue(BudgetMonthlyReportController.getStatusRows(FY, 'Jan', null, null)[0].hasReport);
        Assert.isFalse(BudgetMonthlyReportController.getStatusRows(FY, 'Sep', null, null)[0].hasReport);
    }

    @isTest
    static void statusUsesStampWhenItIsCloseToCreatedDate() {
        // Filed just after the month rolled over: it still belongs to the stamped month.
        insertMis(new MIS_Budget__c(Mis_Monthly_Report__c = Date.newInstance(2025, 8, 3)), Datetime.newInstance(2025, 9, 1, 10, 0, 0));

        BudgetMonthlyReportController.StatusRow august = BudgetMonthlyReportController.getStatusRows(FY, 'Aug', null, null)[0];
        Assert.isTrue(august.hasReport);
        Assert.areEqual('Test Branch', august.mrBranchName);
        Assert.areEqual(UserInfo.getName(), august.mrEmployeeName);
        Assert.isFalse(BudgetMonthlyReportController.getStatusRows(FY, 'Sep', null, null)[0].hasReport);
    }

    @isTest
    static void statusAppliesCompanyAndBranchFilters() {
        Company__c other = [SELECT Id FROM Company__c WHERE Name = 'Other Company'];
        Branch__c branch = [SELECT Id FROM Branch__c LIMIT 1];
        Company__c company = [SELECT Id FROM Company__c WHERE Name = 'Test Company'];

        Assert.areEqual(0, BudgetMonthlyReportController.getStatusRows(FY, 'Aug', other.Id, null).size());
        Assert.areEqual(1, BudgetMonthlyReportController.getStatusRows(FY, 'Aug', company.Id, branch.Id).size());
    }

    @isTest
    static void reportCreatesOneRowPerFilledSlotFromTheLatestMis() {
        insertMis(
            new MIS_Budget__c(Order_Type__c = 'E-Spares', Order_Expected_Stage_Aug__c = 'Enquiry', Remarks_Aug__c = 'older'),
            Datetime.newInstance(2025, 8, 5, 10, 0, 0)
        );
        insertMis(
            new MIS_Budget__c(
                Order_Type__c = 'E-Spares',
                Order_Expected_Stage_Aug__c = 'Offer',
                Remarks_Aug__c = 'latest',
                Expected_Order_Value_Dec__c = 75,
                Expected_Order_Value_June__c = 0
            ),
            Datetime.newInstance(2025, 8, 20, 10, 0, 0)
        );

        List<Map<String, Object>> rows = BudgetMonthlyReportController.getReportRows(
            new List<Id>{ firstLine().Budget__c }, FY, 'Aug'
        );

        Assert.areEqual(2, rows.size(), 'Aug and Dec are filled; a zero value in Jun is not');
        Assert.areEqual('Aug', rows[0].get('budgetMonth'));
        Assert.areEqual('Offer', rows[0].get('conStage'));
        Assert.areEqual('latest', rows[0].get('remarks'));
        Assert.areEqual(40, rows[0].get('orderReceived'));
        Assert.areEqual('Aug-25', rows[0].get('misMonth'));
        Assert.areEqual(1, rows[0].get('slNo'));
        Assert.areEqual('Dec', rows[1].get('budgetMonth'));
        Assert.areEqual(0, rows[1].get('orderReceived'));
        Assert.areEqual(2, rows[1].get('slNo'));
    }

    @isTest
    static void reportKeepsALineWithNoFilledSlots() {
        insertMis(new MIS_Budget__c(), Datetime.newInstance(2026, 2, 10, 10, 0, 0));

        List<Map<String, Object>> rows = BudgetMonthlyReportController.getReportRows(
            new List<Id>{ firstLine().Budget__c }, FY, 'Feb'
        );

        Assert.areEqual(1, rows.size());
        Assert.isNull(rows[0].get('budgetMonth'));
        Assert.areEqual('Feb-26', rows[0].get('misMonth'));
    }

    @isTest
    static void budgetRowsShowActiveLinesWithMonthsAndRevision() {
        DC_Budget_Line_Items__c original = firstLine();
        DC_Budget_Line_Items__c current = new DC_Budget_Line_Items__c(
            Budget__c = original.Budget__c,
            Previous_Version__c = original.Id,
            Customer__c = original.Customer__c,
            PMG_Master__c = original.PMG_Master__c,
            Order_Type__c = 'E-Spares',
            Active_Status__c = true,
            Aug_Order__c = 150
        );
        insert current;
        update new DC_Budget_Line_Items__c(Id = original.Id, Active_Status__c = false);

        List<Map<String, Object>> rows = BudgetMonthlyReportController.getBudgetRows(new List<Id>{ original.Budget__c });

        Assert.areEqual(1, rows.size(), 'The inactive version should not be listed');
        Assert.areEqual(1, rows[0].get('rev'));
        Assert.areEqual(150, rows[0].get('Aug'));
        Assert.areEqual(1, rows[0].get('slNo'));
    }

    @isTest
    static void attachmentsListFilesOnTheBudgets() {
        Id budgetId = firstLine().Budget__c;
        Assert.areEqual(0, BudgetMonthlyReportController.getAttachments(new List<Id>()).size());
        Assert.areEqual(0, BudgetMonthlyReportController.getAttachments(new List<Id>{ budgetId }).size());

        insert new ContentVersion(
            Title = 'Previous MR',
            PathOnClient = 'Previous MR.txt',
            VersionData = Blob.valueOf('report'),
            FirstPublishLocationId = budgetId
        );

        List<BudgetMonthlyReportController.AttachmentRow> attachments = BudgetMonthlyReportController.getAttachments(
            new List<Id>{ budgetId }
        );
        Assert.areEqual(1, attachments.size());
        Assert.areEqual('Previous MR', attachments[0].title);
    }

    @isTest
    static void filterOptionsListCompaniesAndBranches() {
        BudgetMonthlyReportController.FilterOptions options = BudgetMonthlyReportController.getFilterOptions();
        Assert.isNotNull(options.financialYears);
        Assert.areEqual(2, options.companies.size());
        Assert.areEqual('Other Company', options.companies[0].label);

        Company__c company = [SELECT Id FROM Company__c WHERE Name = 'Test Company'];
        Company__c other = [SELECT Id FROM Company__c WHERE Name = 'Other Company'];
        Assert.areEqual(1, BudgetMonthlyReportController.getBranches(null).size());
        Assert.areEqual(1, BudgetMonthlyReportController.getBranches(company.Id).size());
        Assert.areEqual(0, BudgetMonthlyReportController.getBranches(other.Id).size());
    }

    @isTest
    static void invalidMonthOrYearIsRejected() {
        for (List<String> input : new List<List<String>>{ new List<String>{ FY, 'Foo' }, new List<String>{ null, 'Aug' } }) {
            try {
                BudgetMonthlyReportController.getStatusRows(input[0], input[1], null, null);
                Assert.fail('Expected an error for ' + input);
            } catch (AuraHandledException e) {
                Assert.isNotNull(e);
            }
        }
    }
}