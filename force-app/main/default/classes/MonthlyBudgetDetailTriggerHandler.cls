public with sharing class MonthlyBudgetDetailTriggerHandler extends TriggerHandler {
    private static final string MONTHLY_BUDGET_DETAIL_API = 'Monthly_Budget_Detail__c';
    public MonthlyBudgetDetailTriggerHandler() {
        super(MONTHLY_BUDGET_DETAIL_API);
    }
    /*****************************************************************************
	@Description : Return the name of the handler invoked
	******************************************************************************/
    public override String getName() {
        return MONTHLY_BUDGET_DETAIL_API;
    }
    /*****************************************************************************
	@Description : Trigger handlers for events
	******************************************************************************/
    public override void beforeInsert(List<SObject> newItems) {      
    }
    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap) {
        MonthlyBudgetDetailTriggerHelper mbd = new MonthlyBudgetDetailTriggerHelper();
        List<Monthly_Budget_Detail__c> newList = newItems;
        Map<id, Monthly_Budget_Detail__c> newMap = (Map<id, Monthly_Budget_Detail__c>)newItemsMap;
        Map<id, Monthly_Budget_Detail__c> oldMap = (Map<id, Monthly_Budget_Detail__c>)oldItemsMap;  
        mbd.rangeValidation(newList,newMap,oldMap);
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