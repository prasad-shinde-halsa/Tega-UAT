trigger UserBudgerTrigger on User_Budget__c (before insert,after insert,before update,after update,before delete, after delete,after undelete) {
    
    public static string triggerName ='UserBudgerTrigger';
    UserBudgetTriggerHandler userBudHandlerObj = new UserBudgetTriggerHandler();
    TriggerDispatcher.run(userBudHandlerObj);
}