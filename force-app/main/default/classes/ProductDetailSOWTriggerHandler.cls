public with sharing class ProductDetailSOWTriggerHandler extends TriggerHandler{
    private static final string OBJECT_API = 'Product_Proposal_Form__c';
    
    public ProductDetailSOWTriggerHandler() {
        super(OBJECT_API);
    }
    
    public override String getName() {
        return OBJECT_API;
    }
    
    public override void beforeInsert(List<SObject> newItems) {
		
	ProductDetailSOWTriggerHelper pds = new ProductDetailSOWTriggerHelper();
        pds.UpdateOnInsertion(newItems);
    }
    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap) {
    }
    public override void beforeDelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterUpdate(List<SObject> newItems, Map<Id, SObject> newItemsMap, Map < Id, SObject > oldItemsMap) {
       
        
    }
    public override void afterDelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterUndelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterInsert(List<SObject> newItems, Map<Id, SObject> newItemsMap) {
        Map<Id, SObject> tempMap = new Map<Id, SObject>();
        
        
    }
}