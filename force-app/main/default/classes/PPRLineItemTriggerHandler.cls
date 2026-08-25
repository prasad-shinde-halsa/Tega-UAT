public class PPRLineItemTriggerHandler extends TriggerHandler {
    private static final string PPR_Line_API = 'PPR_Line_Item__c';
    public PPRLineItemTriggerHandler() {
        super(PPR_Line_API);
    }
/*****************************************************************************
@Description : Return the name of the handler invoked
******************************************************************************/
    public override String getName() {
        return PPR_Line_API;
    }
/*****************************************************************************
@Description : Trigger handlers for events
******************************************************************************/
    public override void beforeInsert(List<SObject> newItems) {  
        PPRLineItemTriggerHelper pprLItem = new PPRLineItemTriggerHelper();
        pprLItem.pprRecordName(newItems);
    }
    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap) {
    }
    public override void beforeDelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterUpdate(List<SObject> newItems, Map<Id, SObject>newItemsMap, Map <Id, SObject> oldItemsMap) {
       PPRLineItemTriggerHelper pprLI = new PPRLineItemTriggerHelper();
        Map<id, PPR_Line_Item__c> newMap = (Map<id, PPR_Line_Item__c>)newItemsMap;
        Map<id, PPR_Line_Item__c> OldMap = (Map<id, PPR_Line_Item__c>)oldItemsMap;
        pprLI.updateTaskQueue(newMap,oldMap);
    }
    public override void afterDelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterUndelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterInsert(List<SObject> newItems, Map<Id, SObject> newItemsMap) {
        /*PPRLineItemTriggerHelper pprLI = new PPRLineItemTriggerHelper();
        Map<id, PPR_Line_Item__c> newMap = (Map<id, PPR_Line_Item__c>)newItemsMap;
        pprLI.sharePPRRecord(newMap);*/
        
    }
}