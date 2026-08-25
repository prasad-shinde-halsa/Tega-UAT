trigger ProductDetailSOWTrigger on Product_Proposal_Form__c (before insert,after insert,before update,after update,before delete, after delete,after undelete) {


public static string triggerName ='ProductDetailSOWTrigger';
    ProductDetailSOWTriggerHandler ProdSOWHandlerObj = new ProductDetailSOWTriggerHandler();
    TriggerDispatcher.run(ProdSOWHandlerObj);


}