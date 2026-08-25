trigger L2L3ProductTrigger on L2_L3_Product__c (before insert,after insert,before update,after update,before delete, after delete,after undelete) {
    public static string triggerName ='L2L3ProductTrigger';
    L2L3ProducTriggertHandler L2L3 = new L2L3ProducTriggertHandler();
    TriggerDispatcher.run(L2L3);
}