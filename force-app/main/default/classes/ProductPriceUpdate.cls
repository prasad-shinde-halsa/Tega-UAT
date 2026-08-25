public class ProductPriceUpdate {
    public static void updatePriceFromEmail(String itId){
        Integration_Transaction__c it = new Integration_Transaction__c(Id = itId);
        try{
            //SK - 180123: Set custom settings value to true via mail on product price update.
            PPU__c objPPu = PPU__c.getInstance('Is Product price Updated?');
            system.debug('& Before Update:'+objPPu);
            
            if (objPPu.Product_price_update__c == false){
                objPPu.Product_price_update__c = true;
                update objPPu;
                system.debug('& Updated Custom Setting:'+objPPu);
                
                if (objPPu.Product_price_update__c == true){
                    system.debug('$ Product_price_update: '+objPPu.Product_price_update__c);
                    /*for (Quote offer : [SELECT Id, Name, Status, Subtotal FROM Quote WHERE Status == 'PD']){
                        if (offer != NULL){ 
                            offer.Status= 'Blocked';
                            update offer;
                        }    
                    }*/
                    
                    it.Response__c = 'OFFERs BLOCKED: Price Updated in the custom Setting PPU__c';
                    it.Status__c = 'Success';                
                    it.sync__c = true;
                }
            }else{
                it.Status__c = 'fail';
                it.Response__c = 'OFFERs ALREADY BLOCKED: custom Setting PPU__c is already checked';
            }
           update it; 
        }catch(Exception ex){
            it.Error__c = ex.getMessage()+ex.getLineNumber();
            TegaUtility.trackLogs( ex,  'PriceUpdate',  'updatePriceFromEmail');
        }
    }
}