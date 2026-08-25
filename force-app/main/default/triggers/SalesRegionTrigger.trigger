trigger SalesRegionTrigger on Sales_Region__c (after update) {
    
    //**Collect all changed Sales_Region__c records where Manager__c changed
    if(trigger.isAfter && trigger.isUpdate){
        Set<Id> SalesRegionUpdateId = new Set<Id>();
        for (Sales_Region__c newRegion : Trigger.new) {
            Sales_Region__c oldRegion = Trigger.oldMap.get(newRegion.Id);
            
            if (newRegion.Manager__c != oldRegion.Manager__c) {
                SalesRegionUpdateId.add(newRegion.Id);
            }
        }
        
        if (!SalesRegionUpdateId.isEmpty()) {
            UpdateAccountManagerBatch batch = new UpdateAccountManagerBatch(SalesRegionUpdateId);
            Database.executeBatch(batch);
        }
    }
}