global class L2L3ProductBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start( Database.BatchableContext BC ) {
        
        String query = 'SELECT id,Part_List__c,L2_Prod_Name__c,L3_Prod_Name__c,Product_L2__c,Product_L3__c,Quantity__c,Item_Description__c,Product_Category__c,Product_Category_Test__c,Product_Sorting_Data__c,Part_List_Type__c FROM L2_L3_product__c order by createddate desc';
        return Database.getQueryLocator( query );
    }
    
    global void execute( Database.BatchableContext BC, List< L2_L3_product__c > scope ) {
        List<L2_L3_product__c> l2l3List = new List<L2_L3_product__c>();
            for ( L2_L3_product__c l2l3 : scope ){
                if(l2l3.Product_Sorting_Data__c == NULL){
                    l2l3.Check_PSD__c = true;
                    l2l3List.add(l2l3);
                }
            }
        update l2l3List;
    }
    
    global void finish( Database.BatchableContext BC ) {
        
        system.debug('job finished');
        
    }
    
}