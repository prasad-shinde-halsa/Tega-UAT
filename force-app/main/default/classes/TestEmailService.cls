global class TestEmailService implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(
        Messaging.InboundEmail email,
        Messaging.InboundEnvelope envelope
    ) {
        system.debug('Email service called');
        system.debug('Emai--------'+email);
        system.debug('envelope service called------'+envelope);
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();    
        String subToCompare = email.subject;                                   
        String accid1=subToCompare.substringAfterLast(':');
        String oppType=subToCompare.substringBefore(':');
        String accid= accid1.trim();  
        String emailBody = email.plainTextBody;
        // String custCode1 = emailBody.substringAfterLast(':');
        // String custCode = custCode1.substringBefore('Thank');
        // custCode = custCode.trim();
        system.debug('Customer ID: '+ accid);
        system.debug('oppType-->> '+ oppType);
        
        //SK - 180123: Set custom settings value to true via mail on product price update.
        /*PPU__c objPPu = PPU__c.getInstance('Is Product price Updated?');
            system.debug(objPPu);
            objPPu.Product_price_update__c = true;
            update objPPu;
                if (objPPu.Product_price_update__c == true){
                    system.debug('$ Product_price_update: '+objPPu.Product_price_update__c);
                    for (Quote offer : [SELECT Id, Name, Status, Subtotal FROM Quote WHERE Status != 'Blocked']){
                       if (offer != NULL){ 
                           offer.Status= 'Blocked';
                           update offer;
                           }    
                        }
                     }*/
        
        Integration_Transaction__c it = new Integration_Transaction__c(
            Record_Id__c = accid,
            Status__c = 'Draft',
            Operation__c = oppType,
            Request__c = subToCompare +'\r\n'+emailBody
        );
        
        insert it;
        
        if(it.Operation__c == 'Attach Invoice'){
                UploadAttachment.getAttachmentFromEmail(email,it);
        }
        
        return result;  
    
    }
}