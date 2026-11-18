@isTest
private class DetailedMISDataControllerTest {
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
        budgets[0].CurrencyIsoCode = 'INR';
        budgets[1].CurrencyIsoCode = 'INR';
        insert budgets;

        insert new List<DC_Budget_Line_Items__c>{
            new DC_Budget_Line_Items__c(
                Budget__c = budgets[0].Id,
                PMG_Master__c = pmg.Id,
                Customer__c = customer.Id,
                Order_Type__c = 'E-Spares',
                Active_Status__c = true,
                Description__c = 'Sales line',
                Jul_Order__c = 100
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
            Branch__c = branchId,
            Company__c = companyId
        );
    }

    private static Id lineId(String description) {
        return [SELECT Id FROM DC_Budget_Line_Items__c WHERE Description__c = :description].Id;
    }

    private static MIS_Budget__c insertMis(Id lineId, MIS_Budget__c mis, Datetime createdDate) {
        mis.Budget_Line_Items__c = lineId;
        mis.Order_Type__c = 'E-Spares';
        insert mis;
        Test.setCreatedDate(mis.Id, createdDate);
        return mis;
    }

    @isTest
    static void returnsAnEntryPerReportedMonthWithItsLine() {
        Id salesLine = lineId('Sales line');
        insertMis(
            salesLine,
            new MIS_Budget__c(
                Order_Expected_Stage_Jul__c = 'Offer',
                Order_Expected_Month_Jul__c = 'Aug, 2025',
                Expected_Order_Value_Jul__c = 80,
                Remarks_Jul__c = 'Waiting on PO',
                Mis_Monthly_Report__c = Date.newInstance(2025, 7, 4)
            ),
            Datetime.newInstance(2025, 7, 10, 10, 0, 0)
        );

        Test.startTest();
        DetailedMISDataController.Payload payload = DetailedMISDataController.getData(FY);
        Test.stopTest();

        Assert.areEqual(1, payload.entries.size(), 'Only July carries data');
        DetailedMISDataController.Entry entry = payload.entries[0];
        Assert.areEqual(salesLine, entry.lineId);
        Assert.areEqual('Jul', entry.slot);
        Assert.areEqual('2025-07', entry.reportKey);
        Assert.areEqual('Offer', entry.stage);
        Assert.areEqual('Aug-25', entry.expectedMonth);
        Assert.areEqual(80000, entry.expectedValueInr, 'Values are in thousands and INR is the corporate currency');
        Assert.areEqual('Waiting on PO', entry.remarks);

        Assert.areEqual(1, payload.lines.size());
        DetailedMISDataController.LineInfo line = payload.lines[0];
        Assert.isFalse(line.isOutside);
        Assert.areEqual('West Africa', line.region);
        Assert.areEqual('Ghana (GHN - TG01)', line.branch);
        Assert.areEqual('Mill', line.pmg);
        Assert.areEqual(100000, line.budgetInr.get('Jul'));
        Assert.isTrue(payload.stages.contains('Order'), 'Stage picklist values are returned');
    }

    @isTest
    static void outsideLineAndOldVersionMapToTheCurrentLine() {
        Id outsideLine = lineId('Outside line');
        DC_Budget_Line_Items__c original = [SELECT Id, Budget__c, Customer__c, PMG_Master__c FROM DC_Budget_Line_Items__c WHERE Id = :outsideLine];
        insertMis(
            outsideLine,
            new MIS_Budget__c(Order_Expected_Stage_Sep__c = 'Enquiry'),
            Datetime.newInstance(2025, 9, 12, 10, 0, 0)
        );
        original.Active_Status__c = false;
        update original;
        DC_Budget_Line_Items__c next = new DC_Budget_Line_Items__c(
            Budget__c = original.Budget__c,
            Customer__c = original.Customer__c,
            PMG_Master__c = original.PMG_Master__c,
            Order_Type__c = 'E-Spares',
            Active_Status__c = true,
            Description__c = 'Outside line v2',
            Previous_Version__c = original.Id
        );
        insert next;

        DetailedMISDataController.Payload payload = DetailedMISDataController.getData(FY);

        Assert.areEqual(1, payload.entries.size());
        Assert.areEqual(next.Id, payload.entries[0].lineId, 'MIS on an old version belongs to the current version');
        Assert.areEqual('2025-09', payload.entries[0].reportKey, 'Without a stamp, CreatedDate gives the report month');
        Assert.isTrue(payload.lines[0].isOutside);
    }

    @isTest
    static void staleStampFallsBackToCreatedDate() {
        MIS_Budget__c mis = insertMis(
            lineId('Sales line'),
            new MIS_Budget__c(Order_Expected_Stage_Jul__c = 'Order', Mis_Monthly_Report__c = Date.newInstance(2025, 4, 4)),
            Datetime.newInstance(2025, 9, 20, 10, 0, 0)
        );
        Assert.areEqual('2025-09', DetailedMISDataController.getData(FY).entries[0].reportKey);
        Assert.isNotNull(mis.Id);
    }

    @isTest
    static void helpersAndValidation() {
        Assert.areEqual('Expected_Order_Value_April__c', DetailedMISDataController.expectedValueField('Apr'));
        Assert.areEqual('Expected_Order_Value_June__c', DetailedMISDataController.expectedValueField('Jun'));
        Assert.areEqual('Expected_Order_Value_Jul__c', DetailedMISDataController.expectedValueField('Jul'));
        Assert.areEqual('Sep-26', DetailedMISDataController.expectedMonthLabel('Sep, 2026'));
        Assert.areEqual('odd', DetailedMISDataController.expectedMonthLabel('odd'));
        Assert.isNotNull(DetailedMISDataController.getFinancialYears());
        try {
            DetailedMISDataController.getData('');
            Assert.fail('A blank year is rejected');
        } catch (AuraHandledException e) {
            Assert.isTrue(true);
        }
    }
}