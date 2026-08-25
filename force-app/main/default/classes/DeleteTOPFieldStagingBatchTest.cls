@isTest
private class DeleteTOPFieldStagingBatchTest {

    @TestSetup
    static void setupData() {
        List<TOP_Field_Staging__c> records = new List<TOP_Field_Staging__c>();
        for (Integer i = 0; i < 5; i++) {
            records.add(new TOP_Field_Staging__c());
        }
        insert records;
    }

    @isTest
    static void testBatchDeletesOldRecords() {
        
        DeleteTOPFieldStagingBatch.cutoffOverride = System.now().addDays(1);

        Integer beforeCount = [SELECT COUNT() FROM TOP_Field_Staging__c];
        System.assertEquals(5, beforeCount, 'Should have 5 records before batch');

        Test.startTest();
        Database.executeBatch(new DeleteTOPFieldStagingBatch(), 200);
        Test.stopTest();

        Integer afterCount = [SELECT COUNT() FROM TOP_Field_Staging__c];
        System.assertEquals(0, afterCount, 'All records should be deleted after batch');
    }

    @isTest
    static void testBatchNoRecordsToDelete() {
        
        DeleteTOPFieldStagingBatch.cutoffOverride = System.now().addDays(-30);

        Integer beforeCount = [SELECT COUNT() FROM TOP_Field_Staging__c];
        System.assertEquals(5, beforeCount, 'Should have 5 records before batch');

        Test.startTest();
        Database.executeBatch(new DeleteTOPFieldStagingBatch(), 200);
        Test.stopTest();

        Integer afterCount = [SELECT COUNT() FROM TOP_Field_Staging__c];
        System.assertEquals(5, afterCount, 'No records should be deleted');
    }

    @isTest
    static void testSchedulable() {
        DeleteTOPFieldStagingBatch.cutoffOverride = System.now().addDays(1);

        Test.startTest();
        String cronExp = '0 0 0 * * ?';
        System.schedule('TestDeleteTOPBatch', cronExp, new DeleteTOPFieldStagingBatch());
        Test.stopTest();
    }
}