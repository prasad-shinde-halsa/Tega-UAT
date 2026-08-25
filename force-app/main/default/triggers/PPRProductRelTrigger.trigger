trigger PPRProductRelTrigger on PPR_Product_Relationship__c (before insert,after insert,before update,after update,before delete, after delete,after undelete) {
    public static string triggerName ='PPRProductRel';
    PPRProductRelTriggerHandler pprProdRelHandlerObj = new PPRProductRelTriggerHandler();
    TriggerDispatcher.run(pprProdRelHandlerObj);
}