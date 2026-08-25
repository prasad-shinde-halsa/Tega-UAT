public with sharing class BudgetLineItemTriggerHandler extends TriggerHandler {
    private static final string BUDGET_LINE_ITEM_API = 'L2_Budget_Line_Item__c';
    public BudgetLineItemTriggerHandler() {
        super(BUDGET_LINE_ITEM_API);
    }
    /*****************************************************************************
    @Description : Return the name of the handler invoked
    ******************************************************************************/
    public override String getName() {
        return BUDGET_LINE_ITEM_API;
    }
    /*****************************************************************************
    @Description : Trigger handlers for events
    ******************************************************************************/
    public override void beforeInsert(List<SObject> newItems) {   
    }
    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap) {      
    }
    public override void beforeDelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterUpdate(List<SObject> newItems, Map<Id, SObject>newItemsMap, Map <Id, SObject> oldItemsMap) {
        BudgetLineItemTriggerHelper bli = new BudgetLineItemTriggerHelper();
        Map<id, L2_Budget_Line_Item__c> newMap = (Map<id, L2_Budget_Line_Item__c>)newItemsMap;
        Map<id, L2_Budget_Line_Item__c> OldMap = (Map<id, L2_Budget_Line_Item__c>)oldItemsMap;
        bli.updateMonthlyChildFromParentBLI(newMap,oldMap);
    }
    public override void afterDelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterUndelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterInsert(List<SObject> newItems, Map<Id, SObject> newItemsMap) {
    }
}