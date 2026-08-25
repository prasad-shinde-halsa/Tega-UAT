public with sharing class PPRProductRelTriggerHandler extends TriggerHandler{
	private static final string PPR_PRODUCT_REL_API = 'PPR_Product_Relationship__c';
     public PPRProductRelTriggerHandler() {
        super(PPR_PRODUCT_REL_API);
    }
    /*****************************************************************************
    @Description : Return the name of the handler invoked
    ******************************************************************************/
    public override String getName() {
        return PPR_PRODUCT_REL_API;
    }
    /*****************************************************************************
    @Description : Trigger handlers for events
    ******************************************************************************/
    public override void beforeInsert(List<SObject> newItems) {

        PPRTriggerController__c setting = PPRTriggerController__c.getOrgDefaults();
        if (setting != null && setting.isExecuting__c) {
            return; // Exit the method if the trigger should not run
        }
        
        // If isExecuting__c is false, proceed with the calculations
        PPRProductRelTriggerHelper pprProdRel = new PPRProductRelTriggerHelper();
        pprProdRel.calcualteL2L3Qty(newItems);
    }
    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap) {
    }
    public override void beforeDelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterUpdate(List<SObject> newItems, Map<Id, SObject>newItemsMap, Map <Id, SObject> oldItemsMap) {
    }
    public override void afterDelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterUndelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterInsert(List<SObject> newItems, Map<Id, SObject> newItemsMap) {
    }
}