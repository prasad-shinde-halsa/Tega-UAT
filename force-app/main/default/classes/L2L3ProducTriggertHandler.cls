public with sharing class L2L3ProducTriggertHandler extends TriggerHandler {
    private static final string L2L3Product_API = 'L2_L3_Product__c';
    public L2L3ProducTriggertHandler() {
        super(L2L3Product_API);
    }
    public override String getName() {
        return L2L3Product_API;
    }
    public override void beforeInsert(List<SObject> newItems) {
        L2L3ProducTriggertHelper l2l3 = new L2L3ProducTriggertHelper();
        l2l3.updateProductSortingData(newItems);
    }
    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap) {
        L2L3ProducTriggertHelper l2l3 = new L2L3ProducTriggertHelper();
        l2l3.updateProductSortingData(newItems);
    }
    public override void afterUpdate(List<SObject> newItems, Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap) {
    }
    public override void beforeDelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterDelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterUndelete(Map<Id, SObject> oldItemsMap) {
    }
    public override void afterInsert(List<SObject> newItems, Map<Id, SObject> newItemsMap) {
        L2L3ProducTriggertHelper l2l3 = new L2L3ProducTriggertHelper();
        l2l3.createL1L3Product(newItems);
    }
}