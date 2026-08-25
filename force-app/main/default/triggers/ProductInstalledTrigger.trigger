trigger ProductInstalledTrigger on Product_Installed__c (before insert,after insert,before update,after update,before delete, after delete,after undelete) {
    
    
    public static string triggerName ='ProductInstalledTrigger';
    ProductInstalledHandler piHandlerObj = new ProductInstalledHandler();
    TriggerDispatcher.run(piHandlerObj);
}