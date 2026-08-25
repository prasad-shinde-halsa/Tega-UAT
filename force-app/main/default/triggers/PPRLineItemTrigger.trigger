trigger PPRLineItemTrigger on PPR_Line_Item__c (before insert,after insert,before update,after update,before delete, after delete,after undelete){
	public static string triggerName ='PPRLineItemTrigger';
        PPRLineItemTriggerHandler PPRLineItemTriggerHandlerObj = new PPRLineItemTriggerHandler();
    	TriggerDispatcher.run(PPRLineItemTriggerHandlerObj);
}