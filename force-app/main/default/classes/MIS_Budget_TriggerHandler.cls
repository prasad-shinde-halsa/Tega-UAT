public class MIS_Budget_TriggerHandler {

    
    private static Set<Id> processedIds = new Set<Id>();

    public static void handleActiveFlag(List<MIS_Budget__c> newRecords) {

        
        List<MIS_Budget__c> recordsToProcess = new List<MIS_Budget__c>();
        for (MIS_Budget__c rec : newRecords) {
            if (!processedIds.contains(rec.Id)) {
                recordsToProcess.add(rec);
            }
        }
        if (recordsToProcess.isEmpty()) return;

        Set<Id> parentIds = new Set<Id>();
        Map<Id, Id> triggeredIdByParent = new Map<Id, Id>();

        for (MIS_Budget__c rec : recordsToProcess) {
            if (rec.Budget_Line_Items__c != null) {
                parentIds.add(rec.Budget_Line_Items__c);
                triggeredIdByParent.put(rec.Budget_Line_Items__c, rec.Id);
            }
        }
        if (parentIds.isEmpty()) return;

        List<MIS_Budget__c> allChildren = [
            SELECT Id, IsActive__c, Budget_Line_Items__c
            FROM MIS_Budget__c
            WHERE Budget_Line_Items__c IN :parentIds
        ];

        List<MIS_Budget__c> toUpdate = new List<MIS_Budget__c>();
        for (MIS_Budget__c child : allChildren) {
            Boolean shouldBeActive = (child.Id == triggeredIdByParent.get(child.Budget_Line_Items__c));
            if (child.IsActive__c != shouldBeActive) {
                child.IsActive__c = shouldBeActive;
                toUpdate.add(child);
            }
        }

       
        for (MIS_Budget__c rec : recordsToProcess) {
            processedIds.add(rec.Id);
        }
        for (MIS_Budget__c child : toUpdate) {
            processedIds.add(child.Id);
        }

        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, AccessLevel.SYSTEM_MODE);
        }
    }
}