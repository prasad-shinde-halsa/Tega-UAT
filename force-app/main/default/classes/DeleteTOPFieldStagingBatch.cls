public class DeleteTOPFieldStagingBatch implements Database.Batchable<SObject>, Schedulable {

    @TestVisible
    private static DateTime cutoffOverride = null;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime cutoffDate = cutoffOverride != null ? cutoffOverride : System.now().addDays(-7);
        return Database.getQueryLocator(
            'SELECT Id ' +
            'FROM TOP_Field_Staging__c ' +
            'WHERE LastModifiedDate < :cutoffDate'
        );
    }

    public void execute(Database.BatchableContext bc, List<TOP_Field_Staging__c> scope) {
        if (!scope.isEmpty()) {
            delete scope;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Old TOP_Field_Staging__c records deleted successfully.');
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DeleteTOPFieldStagingBatch(), 200);
    }
}