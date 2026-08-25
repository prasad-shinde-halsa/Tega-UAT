trigger MonthlyBudgetDetailTrigger on Monthly_Budget_Detail__c (before insert,after insert,before update,after update,before delete, after delete,after undelete) {
	
    public static string triggerName ='MonthlyBudgetDetailTrigger';
    MonthlyBudgetDetailTriggerHandler monbudDetHandlerObj = new MonthlyBudgetDetailTriggerHandler();
    TriggerDispatcher.run(monbudDetHandlerObj);
}