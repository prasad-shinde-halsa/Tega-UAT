/********************************************************
Company Name : DCC Services Pvt Ltd.
Name : L2L3ProducTriggertHelper 
Desc : this class is a helper class of L2L3ProducTriggertHandler
and contains logic for trigger conditions
Author : Arnab Das
*********************************************************/


public class L2L3ProducTriggertHelper {
    public void updateProductSortingData(List<L2_L3_product__c> L2L3ProdList) {
        Try{
            System.debug('L2L3ProdList: '+ L2L3ProdList);
            Set<String> sCatagory = new Set<String>();
            
            for (L2_L3_product__c l2l3 : L2L3ProdList) {
                sCatagory.add(l2l3.Part_List_Type__c);
            }
            
            system.debug('set: '+ sCatagory);
            List<Product_Sorting_Data__c> PsdList = [SELECT Id, Name, Sorting_Key__c, Product_Catagory__c, Sorting_Number__c
                                                     FROM Product_Sorting_Data__c WHERE Product_Catagory__c IN :sCatagory];
            
            if (PsdList != NULL) {
                system.debug('PsdList: '+ PsdList);
                for (Product_Sorting_Data__c pData : PsdList) {
                    System.debug('@@' + pData.Sorting_Key__c);
                    
                    for (L2_L3_product__c l2l3 : L2L3ProdList) {
                        System.debug('@@@' + l2l3.L3_Prod_Name__c);
                        if (l2l3.L3_Prod_Name__c!= null ){
                            if (l2l3.L3_Prod_Name__c.startsWith(pData.Sorting_Key__c)) {
                                
                                l2l3.Product_Sorting_Data__c = pData.Id;
                            }  
                        }
                    }
                }
            }
        }
        catch(exception e){
            TegaUtility.trackLogs(e,'L2L3ProducTriggertHelper','updateProductSortingData');
        }
    }
    
    public void createL1L3Product(List<L2_L3_product__c> L2L3ProdList) {
        try{
            System.debug('L2L3ProdList: '+ L2L3ProdList);
            Map<String,L1_L3_Product__c> L1L3ProdList = new Map<String,L1_L3_Product__c>(); 
            
            Set<Id> L2L3ID = new Set<Id>();
    
            // 1. Collect IDs
            for (L2_L3_product__c l2l3new : L2L3ProdList) {
                L2L3ID.add(l2l3new.Id);
            }
            
            List<L2_L3_product__c> newL2L3List = [Select Id,Part_List__c,Part_List__r.Name,Product_L3__c,Product_L3__r.Name,
                                                  Part_List__r.Version_Number_Component__c FROM L2_L3_product__c Where ID IN: L2L3ID];
            
            System.Debug('newL2L3List***'+newL2L3List);
            for(L2_L3_product__c l2l3 : newL2L3List){
                String L1L3Code;
                if(String.ISBLANK(l2l3.Part_List__r.Version_Number_Component__c)){
                    L1L3Code = l2l3.Part_List__r.Name+'_'+l2l3.Product_L3__r.Name+'_0';
                }
                else{
                    L1L3Code = l2l3.Part_List__r.Name+'_'+l2l3.Product_L3__r.Name+'_'+l2l3.Part_List__r.Version_Number_Component__c;
                }
                
                L1_L3_Product__c newL1L3 = new L1_L3_Product__c();
                newL1L3.Part_List__c = l2l3.Part_List__c;
                newL1L3.Product_del__c = l2l3.Product_L3__c;
                newL1L3.L1L3_Code__c = L1L3Code;
                L1L3ProdList.put(L1L3Code,newL1L3);
            }
            
            if(!L1L3ProdList.isEmpty()) Database.upsert(L1L3ProdList.values(),L1_L3_Product__c.L1L3_Code__c,false);            
            
        }
        catch(exception e){
            TegaUtility.trackLogs(e,'L2L3ProducTriggertHelper','createL1L3Product');
        }
    }
}