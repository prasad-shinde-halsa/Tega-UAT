@isTest
private class BudgetStageTrackerControllerTest {
    private static final String FY = '2025-26';

    @testSetup
    static void setupData() {
        Sales_Region__c region = new Sales_Region__c(Name = 'West Africa');
        insert region;
        Branch__c branch = new Branch__c(
            Name = 'Ghana',
            Branch_Code__c = 'GHN',
            CIF_Factor__c = 1.04,
            CurrencyIsoCode = 'USD',
            Is_WOS__c = true,
            Branch_Head__c = UserInfo.getUserId(),
            Sales_Region__c = region.Id
        );
        insert branch;
        Company__c company = new Company__c(Name = 'Test Company', Company_Code__c = 'TG01', CurrencyIsoCode = 'USD');
        insert company;
        PMG_Master__c pmg = new PMG_Master__c(Name = 'Mill');
        insert pmg;
        Account customer = new Account(Name = 'Test Customer');
        insert customer;

        Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.DC_Budget__c.getRecordTypeInfosByDeveloperName();
        List<DC_Budget__c> budgets = new List<DC_Budget__c>{
            newBudget('Sales Budget', recordTypes.get('Sales').getRecordTypeId(), branch.Id, company.Id),
            newBudget('Outside Budget', recordTypes.get('Development_Budget').getRecordTypeId(), branch.Id, company.Id)
        };
        // A line inherits its currency from the budget (master-detail).
        budgets[0].CurrencyIsoCode = 'INR';
        insert budgets;

        insert new List<DC_Budget_Line_Items__c>{
            new DC_Budget_Line_Items__c(
                Budget__c = budgets[0].Id,
                PMG_Master__c = pmg.Id,
                Customer__c = customer.Id,
                Order_Type__c = 'E-Spares',
                Active_Status__c = true,
                Description__c = 'Sales line',
                Jan_Order__c = 100,
                Aug_Order__c = 50
            ),
            new DC_Budget_Line_Items__c(
                Budget__c = budgets[1].Id,
                PMG_Master__c = pmg.Id,
                Customer__c = customer.Id,
                Order_Type__c = 'E-Spares',
                Active_Status__c = true,
                Description__c = 'Outside line'
            )
        };
    }

    private static DC_Budget__c newBudget(String name, Id recordTypeId, Id branchId, Id companyId) {
        return new DC_Budget__c(
            Name = name,
            RecordTypeId = recordTypeId,
            Status__c = '4th Level Approved',
            Financial_Year__c = FY,
            CurrencyIsoCode = 'USD',
            Branch__c = branchId,
            Company__c = companyId
        );
    }

    private static DC_Budget_Line_Items__c lineFor(String description) {
        return [
            SELECT Id, Budget__c, Customer__c, PMG_Master__c
            FROM DC_Budget_Line_Items__c
            WHERE Description__c = :description
        ];
    }

    private static void insertMis(Id lineId, MIS_Budget__c mis, Datetime createdDate) {
        mis.Budget_Line_Items__c = lineId;
        mis.Order_Type__c = 'E-Spares';
        insert mis;
        Test.setCreatedDate(mis.Id, createdDate);
    }

    private static BudgetStageTrackerController.TrackerRow rowFor(
        List<BudgetStageTrackerController.TrackerRow> rows, Id lineId, String month
    ) {
        for (BudgetStageTrackerController.TrackerRow row : rows) {
            if (row.key == lineId + '-' + month) {
                return row;
            }
        }
        return null;
    }

    @isTest
    static void budgetLineCreatesARowPerValuedMonthInInr() {
        Id lineId = lineFor('Sales line').Id;
        List<BudgetStageTrackerController.TrackerRow> rows = BudgetStageTrackerController.getRows(FY, 'Mar');

        Assert.areEqual(2, rows.size(), 'Only Aug and Jan have a value, and the Outside line has no value or MIS');
        BudgetStageTrackerController.TrackerRow january = rowFor(rows, lineId, 'Jan');
        Assert.isFalse(january.isOutside);
        Assert.areEqual('JAN-26', january.budgetMonthLabel);
        Assert.areEqual('AUG-25', rowFor(rows, lineId, 'Aug').budgetMonthLabel);
        Assert.areEqual(100000, january.amountInr, 'Values are in thousands and INR is the corporate currency');
        Assert.areEqual('Ghana (GHN - TG01)', january.branch);
        Assert.areEqual('West Africa', january.region);
        Assert.areEqual('Mill', january.pmg);
    }

    @isTest
    static void outsideLineWithZeroValueAppearsOnceItHasAStage() {
        Id lineId = lineFor('Outside line').Id;
        insertMis(
            lineId,
            new MIS_Budget__c(Order_Expected_Stage_Jul__c = 'Order', Order_Expected_Month_Jul__c = 'Jul, 2025'),
            Datetime.newInstance(2025, 7, 10, 10, 0, 0)
        );

        BudgetStageTrackerController.TrackerRow row = rowFor(BudgetStageTrackerController.getRows(FY, 'Mar'), lineId, 'Jul');

        Assert.isTrue(row.isOutside);
        Assert.areEqual('Jul-25', row.expectedMonth);
        Assert.areEqual('Order', row.stages.get('Jul'));
        Assert.areEqual(0, row.amountInr);
    }

    @isTest
    static void stagesFollowReportMonthAndStopAtTheSelectedMonth() {
        Id lineId = lineFor('Sales line').Id;
        insertMis(lineId, new MIS_Budget__c(Order_Expected_Stage_Jan__c = 'Enquiry'), Datetime.newInstance(2025, 5, 5, 10, 0, 0));
        insertMis(lineId, new MIS_Budget__c(Order_Expected_Stage_Jan__c = 'Indent'), Datetime.newInstance(2025, 5, 20, 10, 0, 0));
        // Stale stamp: this was filed in December, so it belongs in the December column.
        insertMis(
            lineId,
            new MIS_Budget__c(Mis_Monthly_Report__c = Date.newInstance(2025, 9, 4), Order_Expected_Stage_Jan__c = 'Offer'),
            Datetime.newInstance(2025, 12, 15, 10, 0, 0)
        );

        BudgetStageTrackerController.TrackerRow row = rowFor(BudgetStageTrackerController.getRows(FY, 'Dec'), lineId, 'Jan');
        Assert.areEqual('Indent', row.stages.get('May'), 'The latest MIS in a report month wins');
        Assert.areEqual('Offer', row.stages.get('Dec'));
        Assert.isFalse(row.stages.containsKey('Sep'));

        row = rowFor(BudgetStageTrackerController.getRows(FY, 'Nov'), lineId, 'Jan');
        Assert.isFalse(row.stages.containsKey('Dec'), 'Reports after the selected month are excluded');
        Assert.areEqual('Indent', row.stages.get('May'));
    }

    @isTest
    static void misOnAnOlderVersionCarriesToTheActiveLine() {
        DC_Budget_Line_Items__c original = lineFor('Sales line');
        insertMis(original.Id, new MIS_Budget__c(Order_Expected_Stage_Jan__c = 'Offer'), Datetime.newInstance(2025, 6, 10, 10, 0, 0));
        DC_Budget_Line_Items__c current = new DC_Budget_Line_Items__c(
            Budget__c = original.Budget__c,
            Previous_Version__c = original.Id,
            Customer__c = original.Customer__c,
            PMG_Master__c = original.PMG_Master__c,
            Order_Type__c = 'E-Spares',
            Active_Status__c = true,
            Jan_Order__c = 200
        );
        insert current;
        update new DC_Budget_Line_Items__c(Id = original.Id, Active_Status__c = false);

        List<BudgetStageTrackerController.TrackerRow> rows = BudgetStageTrackerController.getRows(FY, 'Mar');

        Assert.isNull(rowFor(rows, original.Id, 'Jan'), 'The inactive version should not be listed');
        Assert.areEqual('Offer', rowFor(rows, current.Id, 'Jan').stages.get('Jun'));
    }

    @isTest
    static void foreignCurrencyUsesTheRateDatedAtTheStartOfTheYear() {
        DC_Budget_Line_Items__c line = lineFor('Outside line');
        update new DC_Budget_Line_Items__c(Id = line.Id, Sep_Order__c = 10);
        Date yearStart = Date.newInstance(2025, 4, 1);
        Decimal rate = [
            SELECT ConversionRate
            FROM DatedConversionRate
            WHERE IsoCode = 'USD' AND StartDate <= :yearStart AND NextStartDate > :yearStart
        ].ConversionRate;

        BudgetStageTrackerController.TrackerRow row = rowFor(BudgetStageTrackerController.getRows(FY, 'Mar'), line.Id, 'Sep');

        Assert.areEqual((10 * 1000 / rate).setScale(2), row.amountInr);
    }

    @isTest
    static void addressIsCleanedForDisplay() {
        Assert.areEqual(
            '275 MINERAL PARK RD, KINGMAN, Cote d\'Ivoire',
            BudgetStageTrackerController.addressLabel('275 MINERAL PARK RD,,,,<br>KINGMAN<br>Cote d&#39;Ivoire')
        );
        Assert.isNull(BudgetStageTrackerController.addressLabel(null));
    }

    @isTest
    static void nonApprovedBudgetsAreExcluded() {
        DC_Budget_Line_Items__c approved = lineFor('Sales line');
        DC_Budget__c draft = new DC_Budget__c(
            Name = 'Draft Budget',
            RecordTypeId = Schema.SObjectType.DC_Budget__c.getRecordTypeInfosByDeveloperName().get('Sales').getRecordTypeId(),
            Status__c = 'Draft',
            Financial_Year__c = FY,
            CurrencyIsoCode = 'INR'
        );
        insert draft;
        DC_Budget_Line_Items__c draftLine = new DC_Budget_Line_Items__c(
            Budget__c = draft.Id,
            Customer__c = approved.Customer__c,
            PMG_Master__c = approved.PMG_Master__c,
            Order_Type__c = 'E-Spares',
            Active_Status__c = true,
            Jan_Order__c = 100
        );
        insert draftLine;

        List<BudgetStageTrackerController.TrackerRow> rows = BudgetStageTrackerController.getRows(FY, 'Mar');

        Assert.isNull(rowFor(rows, draftLine.Id, 'Jan'));
        Assert.isNotNull(rowFor(rows, approved.Id, 'Jan'));
    }

    @isTest
    static void invalidMonthOrYearIsRejected() {
        for (List<String> input : new List<List<String>>{ new List<String>{ FY, 'Foo' }, new List<String>{ null, 'Aug' } }) {
            try {
                BudgetStageTrackerController.getRows(input[0], input[1]);
                Assert.fail('Expected an error for ' + input);
            } catch (AuraHandledException e) {
                Assert.isNotNull(e);
            }
        }
    }

    @isTest
    static void financialYearsAreReadFromConfig() {
        Assert.isNotNull(BudgetStageTrackerController.getFinancialYears());
    }
}