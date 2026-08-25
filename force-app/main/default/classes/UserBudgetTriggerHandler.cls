public with sharing class UserBudgetTriggerHandler extends TriggerHandler {
    private static final string USER_BUDGET_API = 'User_Budget__c';
    public UserBudgetTriggerHandler() {
        super(USER_BUDGET_API);
    }
    /*****************************************************************************
	@Description : Return the name of the handler invoked
	******************************************************************************/
    public override String getName() {
        return USER_BUDGET_API;
    }
    /*****************************************************************************
	@Description : Trigger handlers for events
	******************************************************************************/
    public override void beforeInsert(List<SObject> newItems) {        
    }
    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap) {
        UserBudgetTriggerHelper userBud = new UserBudgetTriggerHelper();
        Map<id, User_Budget__c> newMap = (Map<id, User_Budget__c>)newItemsMap;
        Map<id, User_Budget__c> oldMap = (Map<id, User_Budget__c>)oldItemsMap;     
        userBud.disableRejectInApprovalProcess(newMap,oldMap);
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