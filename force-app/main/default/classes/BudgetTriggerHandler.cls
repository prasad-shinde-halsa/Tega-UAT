public with sharing class BudgetTriggerHandler extends TriggerHandler {
    private static final string BUDGET_API = 'Budget__c';
    public BudgetTriggerHandler() {
        super(BUDGET_API);
    }
    /*****************************************************************************
	@Description : Return the name of the handler invoked
	******************************************************************************/
    public override String getName() {
        return BUDGET_API;
    }
    /*****************************************************************************
	@Description : Trigger handlers for events
	******************************************************************************/
    public override void beforeInsert(List<SObject> newItems) {
        BudgetTriggerHelper bud = new BudgetTriggerHelper();
        List<Budget__c> budList = newItems;
        bud.validateUser(budList);
        String operation = 'ins';
		bud.checkUserAccessOfBudget(budList,null,null,operation);        
    }
    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap) {
        BudgetTriggerHelper bud = new BudgetTriggerHelper();
        
        List<Budget__c> budList = newItems;
        Map<id, Budget__c> newMap = (Map<id, Budget__c>)newItemsMap;
        Map<id, Budget__c> oldMap = (Map<id, Budget__c>)oldItemsMap;  
        String operation = 'upd';
        
        bud.checkUserAccessOfBudget(budList,newMap,oldMap,operation);
        bud.grantAccessToUsers(oldMap,newMap);
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
        BudgetTriggerHelper bud = new BudgetTriggerHelper();
        Map<id, Budget__c> newMap = (Map<id, Budget__c>)newItemsMap;
        bud.grantAccessToUsers(null,newMap);
    }
}