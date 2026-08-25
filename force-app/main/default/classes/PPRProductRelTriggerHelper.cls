public class PPRProductRelTriggerHelper {
    public void calcualteL2L3Qty(List<PPR_Product_Relationship__c> newItems){
        try{
        system.debug('Trigger beforeupdate running');
        Set<Id> prodIdSet = new Set<Id>();
        Set<Id> partListSet = new Set<Id>();
        Set<Id> pprLineItemIdSet = new Set<Id>();
        
        Map<Id,List<PPR_Product_Relationship__c>> pprProdRelMap = new Map<Id,List<PPR_Product_Relationship__c>>();
        
        for(PPR_Product_Relationship__c pprProdRel : newItems){
            pprLineItemIdSet.add(pprProdRel.PPR_Line_Item__c);
        }
        
        //Key is pprLineItem id and Value is PartList Id id here
        Map<Id,Id> pprLineItemMap = new Map<Id,Id>();
        if(pprLineItemIdSet.size() > 0){
            List<PPR_Line_Item__c> pprLineItemList = [Select Id,Part_List__c from PPR_Line_Item__c where Id =: pprLineItemIdSet];
            
            for(PPR_Line_Item__c pprLineItem : pprLineItemList){
                pprLineItemMap.put(pprLineItem.Id,pprLineItem.Part_List__c);
            }
        }        
        
        for(PPR_Product_Relationship__c pprProdRel : newItems){
            if(pprProdRel.Product__c != null){
                Id partListIdFromPPRLineItem = pprLineItemMap.get(pprProdRel.PPR_Line_Item__c);
                prodIdSet.add(pprProdRel.Product__c);
                partListSet.add(partListIdFromPPRLineItem);
                system.debug('prodIdSet =>'+prodIdSet);
                system.debug('partListSet =>'+partListSet);
                
                if(!pprProdRelMap.containsKey(pprProdRel.Product__c)){
                    List<PPR_Product_Relationship__c> newPPRProdRelList = new List<PPR_Product_Relationship__c>();
                    newPPRProdRelList.add(pprProdRel);
                    pprProdRelMap.put(pprProdRel.Product__c,newPPRProdRelList);
                }else if(pprProdRelMap.containsKey(pprProdRel.Product__c)){
                    List<PPR_Product_Relationship__c> newPPRProdRelList = pprProdRelMap.get(pprProdRel.Product__c);
                    newPPRProdRelList.add(pprProdRel);
                    pprProdRelMap.put(pprProdRel.Product__c,newPPRProdRelList);
                }
            }
            
        }
        
        
        
        if(prodIdSet.size() > 0){
            List<L2_L3_product__c> l3l3ProdList = [Select Id,Product_L2__c,Product_L3__c,Quantity__c,Part_List__c from L2_L3_product__c 
                                                   Where Product_L3__c IN: prodIdSet and Part_List__c IN: partListSet];
            system.debug('l3l3ProdList =>'+l3l3ProdList);
            Map<String,Decimal> l2l3ProdQtyMap = new Map<String,Decimal>();
            
            //Below map will have ProdId as key and PartList as value
            Map<Id,Id> l2l3ProdPLMap = new Map<Id,Id>();
            
            for(L2_L3_product__c l2l3Prod : l3l3ProdList){
                system.debug('l2l3Prod =>'+l2l3Prod);
                String compositeKey = (String)l2l3Prod.Product_L3__c + '-' + (String)l2l3Prod.Part_List__c;
                system.debug('compositeKey =>'+compositeKey);
                if(!l2l3ProdQtyMap.containsKey(compositeKey)){
                    Decimal sumOfAllQty = 0;
                    sumOfAllQty = l2l3Prod.Quantity__c;
                    l2l3ProdQtyMap.put(compositeKey,sumOfAllQty);
                }else if(l2l3ProdQtyMap.containsKey(compositeKey)){
                    Decimal sumOfAllQty = l2l3ProdQtyMap.get(compositeKey);
                    if(l2l3Prod.Quantity__c != null){
                        sumOfAllQty += l2l3Prod.Quantity__c;
                    }
                    l2l3ProdQtyMap.put(compositeKey,sumOfAllQty);
                }
            }
            
            system.debug('l2l3ProdQtyMap =>'+l2l3ProdQtyMap);
            
            for(PPR_Product_Relationship__c pprProdRel : newItems){
                Id partListIdOfPPRLineItem = pprLineItemMap.get(pprProdRel.PPR_Line_Item__c);
                /*if(pprProdRel.Part_List__c != null && partListIdOfPPRLineItem != pprProdRel.Part_List__c){
                    pprProdRel.addError('Part List of PPR Line Item & PPR Prod Relationship should be same');
                }*/
                String compositeKey = (String)pprProdRel.Product__c + '-' + (String)partListIdOfPPRLineItem;
                system.debug('compositeKey2 =>'+compositeKey);
                if(!l2l3ProdQtyMap.containsKey(compositeKey)){
                    pprProdRel.addError('Partlist of Product should be same as Partlist of PPR Product Relationship');
                }
                pprProdRel.FRO_Quantity__c = l2l3ProdQtyMap.get(compositeKey);
            }
        }
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'PPRProductRelTriggerHelper',  'calcualteL2L3Qty');
        }
    }
}