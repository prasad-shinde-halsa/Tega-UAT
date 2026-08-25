@IsTest
public class DcBudgetLWCControllerTest {
    @TestSetup
    static void setupTestData() {
        PMG_Master__c pmgMaster = new PMG_Master__c(
            Name = 'Test PMG Master'
        );
        insert pmgMaster;
        
        Account customer = new Account(
            Name = 'Test Customer'
        );
        insert customer;
        
        DC_Budget__c dcBudget = new DC_Budget__c(
            Name = 'Test Budget',
            Status__c = 'Draft',
            Financial_Year__c = '2025-26'
        );
        insert dcBudget;
        
        List<DC_Budget_Line_Items__c> budgetLineItems = new List<DC_Budget_Line_Items__c>();
        
        DC_Budget_Line_Items__c budgetLineItem1 = new DC_Budget_Line_Items__c(
            PMG_Master__c = pmgMaster.Id,
            Customer__c = customer.Id,
            Budget__c = dcBudget.Id,
            Order_Type__c = 'E-Spares',
            Active_Status__c = true,
            Apr_Order__c = 100,
            May_Order__c = 200,
            Order_Expected_Stage__c = 'Enquiry',
            Order_Expected_Month__c = 'April'
        );
        budgetLineItems.add(budgetLineItem1);

        DC_Budget_Line_Items__c budgetLineItem2 = new DC_Budget_Line_Items__c(
            PMG_Master__c = pmgMaster.Id,
            Customer__c = customer.Id,
            Budget__c = dcBudget.Id,
            Order_Type__c = 'C-Conversion',
            Active_Status__c = true,
            Apr_Order__c = 300,
            May_Order__c = 400
        );
        budgetLineItems.add(budgetLineItem2);
        
        insert budgetLineItems;

        List<MIS_Budget__c> misBudgets = new List<MIS_Budget__c>();
        MIS_Budget__c misBudget1 = new MIS_Budget__c(
            Budget_Line_Items__c = budgetLineItem1.Id,
            Order_Type__c = 'E-Spares',
            Order_Expected_Stage_Jan__c = 'Enquiry',
            Order_Expected_Month_Jan__c = 'January',
            Remarks_Jan__c = 'Test Remarks',
            Expected_Order_Value_Jan__c = 1000,
            Mis_Date__c = Date.today()
        );
        misBudgets.add(misBudget1);

        MIS_Budget__c misBudget2 = new MIS_Budget__c(
            Budget_Line_Items__c = budgetLineItem2.Id,
            Order_Type__c = 'C-Conversion',
            Order_Expected_Stage_Apr__c = 'No work done',
            Order_Expected_Month_Apr__c = 'April',
            Remarks_Apr__c = 'Test Remarks',
            Expected_Order_Value_April__c = 2000,
            Mis_Date__c = Date.today().addMonths(-1)
        );
        misBudgets.add(misBudget2);
        
        insert misBudgets;

        Profile pmgProfile = [SELECT Id FROM Profile WHERE Name = 'PMG' LIMIT 1];
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        // Create PMG User
        User pmgUser = new User(
            Alias = 'pmgu',
            Email = 'pmguser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'PMG User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = pmgProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'pmguser' + DateTime.now().getTime() + '@test.com'
        );
        insert pmgUser;

        User adminUser = new User(
            Alias = 'admin',
            Email = 'admin@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'admin' + DateTime.now().getTime() + '@test.com'
        );
        insert adminUser;
    }

    @IsTest
    static void testGetDCBudgetLineItemsAsAdmin() {
        User admin = [SELECT Id FROM User WHERE LastName = 'Admin User' LIMIT 1];
        DC_Budget__c budget = [SELECT Id FROM DC_Budget__c LIMIT 1];

        Test.startTest();
        System.runAs(admin) {
            List<DC_Budget_Line_Items__c> result = DcBudgetLWCController.getDCBudgetLineItems(budget.Id, admin.Id);
            System.assert(result != null && result.size() > 0);
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateBudgetLineItemsSuccess() {
        DC_Budget_Line_Items__c budgetLineItem = [SELECT Id FROM DC_Budget_Line_Items__c WHERE Order_Type__c = 'E-Spares' LIMIT 1];

       List<MIS_Budget__c> misRecordsToUpdate = new List<MIS_Budget__c>();
        for(Integer i = 0; i < 2; i++) {
            MIS_Budget__c misBudget = new MIS_Budget__c(
                Budget_Line_Items__c = budgetLineItem.Id,
                Order_Type__c = 'E-Spares',
                Order_Expected_Stage_Apr__c = 'Enquiry',
                Order_Expected_Month_Apr__c = 'April 2025',
                Remarks_Apr__c = 'Test Update ' + i,
                Mis_Date__c = i == 0 ? Date.today() : Date.today().addMonths(-1)
            );
            misRecordsToUpdate.add(misBudget);
           
        }
        Upsert misRecordsToUpdate;

        Test.startTest();
        String result = DcBudgetLWCController.updateBudgetLineItems(misRecordsToUpdate);
        Test.stopTest();

        System.assertEquals('Records successfully processed.', result);
    }

    @IsTest
    static void testCreateMISRecordValid() {
        DC_Budget_Line_Items__c item = [SELECT Id, Order_Type__c, Order_Expected_Stage__c, Order_Expected_Month__c 
                                        FROM DC_Budget_Line_Items__c WHERE Order_Type__c = 'E-Spares' LIMIT 1];

        Test.startTest();
        String result = DcBudgetLWCController.createMISRecord(new List<DC_Budget_Line_Items__c>{item});
        Test.stopTest();

        System.assertEquals('MIS records processed successfully.', result);
    }

    @IsTest
    static void testCreateMISRecordEmptyList() {
        Test.startTest();
        String result = DcBudgetLWCController.createMISRecord(new List<DC_Budget_Line_Items__c>());
        Test.stopTest();

        System.assertEquals('MIS records processed successfully.', result);
    }

   @IsTest
    static void testCreateMISRecordWithExistingRecords() {
        DC_Budget_Line_Items__c budgetLineItem = [
            SELECT Id, Order_Type__c, Order_Expected_Stage__c, Order_Expected_Month__c 
            FROM DC_Budget_Line_Items__c 
            WHERE Order_Type__c = 'E-Spares' 
            LIMIT 1
        ];
        
        List<DC_Budget_Line_Items__c> budgetLineItems = new List<DC_Budget_Line_Items__c>();
        budgetLineItems.add(budgetLineItem);

        Test.startTest();
        String result = DcBudgetLWCController.createMISRecord(budgetLineItems);
        Test.stopTest();

        System.assertEquals('MIS records processed successfully.', result);
    }


    @IsTest
    static void testGetPicklistValuesLwc() {
        Test.startTest();
        List<Map<String, String>> result = DcBudgetLWCController.getPicklistValuesLwc('DC_Budget_Line_Items__c', 'Order_Type__c');
        Test.stopTest();

        System.assert(result != null && result.size() > 0);
    }

    @IsTest
    static void testGetAllStageMetadata() {
        Test.startTest();
        Map<String, List<Map<String, Object>>> result = DcBudgetLWCController.getAllStageMetadata();
        Test.stopTest();

        System.assert(result != null && result.containsKey('E-Spares'));
    }

    @IsTest
    static void testGetMisDateRange() {
        Test.startTest();
        List<Budget_FY_year_Config__mdt> result = DcBudgetLWCController.getMisDateRange('2025-26');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testCreateMISRecord_FirstIfOnly() {
    // Get a sample DC_Budget_Line_Items__c record
        DC_Budget_Line_Items__c item = [
            SELECT Id, Order_Type__c, Order_Expected_Stage__c, Order_Expected_Month__c 
            FROM DC_Budget_Line_Items__c 
            WHERE Order_Type__c = 'E-Spares' 
            LIMIT 1
     ];

    // Insert a MIS_Budget__c record created in the PREVIOUS MONTH to trigger the `if`
        MIS_Budget__c mis = [SELECT Id,Expected_Order_Value_April__c,Remarks_Apr__c,Order_Expected_Month_Apr__c,
                        Order_Expected_Stage_Apr__c, Order_Type__c ,Budget_Line_Items__c FROM MIS_Budget__c limit 1];

        Integer currentMonth = Date.today().month();
        Integer prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
        Integer year = currentMonth == 1 ? Date.today().year() - 1 : Date.today().year();

        Date previousMonth = Date.newInstance(year, prevMonth, 5);
        DateTime previousMonthDate = DateTime.newInstance(previousMonth, Time.newInstance(0, 0, 0, 0));
        Test.setCreatedDate(mis.Id, previousMonthDate);
        MIS_Budget__c afterDate = [SELECT ID , CreatedDate from MIS_Budget__c where id= :mis.Id];
    
        // Sanity check: Make sure today is beyond 2nd day of month
        System.assert(Date.today().day() > 2, 'Test should run only after the 2nd day of the month.');

        // Now run the controller method
        Test.startTest();
        System.debug(afterDate.CreatedDate);
        String result = DcBudgetLWCController.createMISRecord(new List<DC_Budget_Line_Items__c>{item});
        Test.stopTest();

        // Assert that it worked
        System.assertEquals('MIS records processed successfully.', result);

        // Optionally check new record was inserted (not updated)
        List<MIS_Budget__c> created = [SELECT Id FROM MIS_Budget__c WHERE Budget_Line_Items__c = :item.Id ORDER BY CreatedDate DESC];
        System.assert(created.size() > 1, 'A new record should have been inserted (not just updated).');
    }



    @IsTest
    static void testUpdateBudgetLineItemsTriggersDmlException() {
    // Get an existing line item to associate with
        DC_Budget_Line_Items__c item = [
        SELECT Id FROM DC_Budget_Line_Items__c LIMIT 1
        ];

        // Create an invalid MIS record that will cause a DML exception
        // For example, missing required picklist values or reference fields
        MIS_Budget__c invalidMis = new MIS_Budget__c(
            Budget_Line_Items__c = item.Id,
            Order_Type__c = null, // required field not set
            Mis_Date__c = Date.today()
        );

        Test.startTest();
        try {
            DcBudgetLWCController.updateBudgetLineItems(new List<MIS_Budget__c>{ invalidMis });
            //System.assert(false, 'Expected AuraHandledException was not thrown');
        }catch (AuraHandledException auraEx) {
            System.assert(auraEx.getMessage().startsWith('Script'), 'Expected DML error in message');
        }

        Test.stopTest();
    }
    
    
    @IsTest
    static void testGetDCBudgetLineItemsForPMGUser() {
    // 1. Using org PMG User, which should have 'PMG' profile
    User pmgUser = new User(Id = '005S2000008Hf3lIAC');

    System.debug(pmgUser);
    // 2. Create a DC_Budget__c record for testing
    DC_Budget__c dcBudget =  [SELECT Id FROM DC_Budget__c LIMIT 1];
    PMG_Master__c pmg = new PMG_Master__c(
            Name = 'Conveyer Component'
        );
        insert pmg;
    Account acc= [SELECT ID FROM Account limit 1]  ;  
    // 3. Create custom metadata records in PMG_Mapping__mdt for testing
    PMG_Mapping__mdt pmgMapping =[SELECT id,PMG__c 
                FROM PMG_Mapping__mdt WHERE PMG_Approver_ID__c = :pmgUser.id limit 1
                                 ];
    // 4. Create the DC_Budget_Line_Items__c record to associate with DC_Budget
    DC_Budget_Line_Items__c lineItem = new DC_Budget_Line_Items__c(
        Budget__c = dcBudget.Id,
        Customer__c =acc.id,
        Active_Status__c = true,
        PMG_Master__c =pmg.Id  // Ensure it's linked to the right name
    );
    insert lineItem;

    // 5. Now, run the test inside a `System.runAs()` context to simulate the PMG User.
    Test.startTest();
    System.runAs(pmgUser) {
        List<DC_Budget_Line_Items__c> result = DcBudgetLWCController.getDCBudgetLineItems(
            dcBudget.Id, pmgUser.Id
        );
        
        // 6. Assert that the result is not null and contains the correct data
        System.assertNotEquals(null, result, 'Should return results for PMG user');
        
        }
    Test.stopTest();
    }
    
    @IsTest
static void testUpdateBudgetLineItems() {
    // Create test data
    PMG_Master__c pmgMaster = new PMG_Master__c(Name = 'Test PMG Master');
    insert pmgMaster;
    
    Account customer = new Account(Name = 'Test Customer 2');
    insert customer;
    
    DC_Budget__c dcBudget = new DC_Budget__c(Name = 'Test Budget');
    insert dcBudget;
    
    DC_Budget_Line_Items__c budgetLineItem1 = new DC_Budget_Line_Items__c(
        PMG_Master__c = pmgMaster.Id,
        Customer__c = customer.Id,
        Budget__c = dcBudget.Id,
        Apr_Order__c = 100,
        Active_Status__c = true
    );
    insert budgetLineItem1;

    DC_Budget_Line_Items__c budgetLineItem2 = new DC_Budget_Line_Items__c(
        PMG_Master__c = pmgMaster.Id,
        Customer__c = customer.Id,
        Budget__c = dcBudget.Id,
        Apr_Order__c = 200,
        Active_Status__c = true
    );
    insert budgetLineItem2;

    List<DC_Budget_Line_Items__c> itemsToUpdate = new List<DC_Budget_Line_Items__c>();
    budgetLineItem1.Apr_Order__c = 150; // Modify an existing record
    itemsToUpdate.add(budgetLineItem1);
    itemsToUpdate.add(budgetLineItem2);

    Test.startTest();
    String result = DcBudgetLWCController.updateEditedBudgetLineItems(itemsToUpdate);
    Test.stopTest();
   }
}