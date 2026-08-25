trigger BudgetTrigger on Budget__c (before insert,after insert,before update,after update,before delete, after delete,after undelete) {
    
    public static string triggerName ='BudgetTrigger';
    BudgetTriggerHandler budHandlerObj = new BudgetTriggerHandler();
    TriggerDispatcher.run(budHandlerObj);
}