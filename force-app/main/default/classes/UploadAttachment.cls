public class UploadAttachment {
    public static void getAttachmentFromEmail(Messaging.InboundEmail email,Integration_Transaction__c it){
        try{
           		Invoice__c inv = [SELECT id from Invoice__c WHERE id =:it.Record_Id__c ];
            	system.debug(inv);
                      
                //Save any Binary Attachment
                if(email.binaryAttachments != null && email.binaryAttachments.size() >0) {
                    system.debug('is coming inside if');
                    List<contentversion> FilesToinsert = new List<contentversion>();
                    for(integer i=0 ; i < email.binaryAttachments.size() ; i++) {
                        system.debug('is coming inside for');
                        contentversion FilesAttch = new contentversion();
                        system.debug('is coming inside files');
                        FilesAttch.ContentLocation ='S';
                        FilesAttch.PathOnClient =email.binaryAttachments[i].filename; 
                        FilesAttch.Title = email.binaryAttachments[i].filename;
                        FilesAttch.VersionData =  email.binaryAttachments[i].body;
                        FilesToinsert.add(FilesAttch);
                        System.debug('more than 30mb'+email.binaryAttachments[i]);
                    }
                    insert FilesToinsert;
                    system.debug('is it inserting attachments');
                    string versionId  = [SELECT contentDocumentId from contentversion WHERE id =:FilesToinsert[0].Id].contentDocumentId;
                    ContentDocumentLink Doclink = New ContentDocumentLink() ;
                    doclink.ContentDocumentId = versionId;
                    doclink.linkedEntityId =inv.id;
                    doclink.sharetype = 'I';
                    doclink.visibility = 'AllUsers';
                    insert doclink;
                }
                it.Status__c = 'Success';
                it.sync__c = true;
          }catch (Exception ex) {
            it.Status__c = 'fail';
            it.Error__c = ex.getMessage();
            TegaUtility.trackLogs( ex,  'UploadAttachment',  'getAttachmentFromEmail');
            system.debug('error line===='+ex.getLineNumber()+'====error type-----------'+ex.getCause()+'-------error message-------'+ex.getMessage()+
                         '-------error gettype-------'+ex.getTypeName()+'-------error getStackTraceString-------'+ex.getStackTraceString());
        }
        update it;
    }
}