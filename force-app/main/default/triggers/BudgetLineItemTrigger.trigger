trigger BudgetLineItemTrigger on L2_Budget_Line_Item__c (before insert, after insert, before update, after update) {
    
    public static string triggerName ='BudgetLineItemTrigger';
    BudgetLineItemTriggerHandler bliHandlerObj = new BudgetLineItemTriggerHandler();
    TriggerDispatcher.run(bliHandlerObj);
}