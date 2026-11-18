public without Sharing class EmailSender {
   public class EmailRequest {
        @InvocableVariable(label='Email Template Id' required=true)
        public Id templateId;

        @InvocableVariable(label='Budget Name' required=false)
        public String BudgetName;

        @InvocableVariable(label='Budget Id' required=false)
        public String BudgetId;
        
        @InvocableVariable(label='QuoteLastModified' required=false)
        public String QuoteLastModified;

        @InvocableVariable(label='User Id' required=true)
        public List<String> userIds;  
    }

   @InvocableMethod(label='Send Email with Template' description='Sends an email with dynamic content')
    public static void sendEmailFromFlow(List<EmailRequest> requests) {
        System.debug('### Starting sendEmailFromFlow');

        List<OrgWideEmailAddress> orgWideEmails = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = 'salesforce.helpdesk@tegaindustries.com' LIMIT 1];
        Id orgWideEmailId = orgWideEmails[0].Id;
        System.debug('### Org-Wide Email ID: ' + orgWideEmailId);

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (EmailRequest req : requests) {
            System.debug('### Processing EmailRequest: ' + req);

            try {
                EmailTemplate template = [SELECT HtmlValue FROM EmailTemplate WHERE Id = :req.templateId LIMIT 1];
                System.debug('### EmailTemplate found: ' + template.Id);

                if (template == null) {
                    throw new AuraHandledException('Template with ID ' + req.templateId + ' not found.');
                }

                // Get the template body as a string to modify it
                String templateBody = template.HtmlValue;

               
                    templateBody = templateBody.replace('{!DC_Budget__c.Name}', req.BudgetName != null ? req.BudgetName : '');
                    templateBody = templateBody.replace('{!DC_Budget__c.Id}', req.BudgetId != null ? req.BudgetId : '');
                    // templateBody = templateBody.replace('{!DC_Budget__c.Last_Modified_Name__c}', req.QuoteLastModified != null ? req.QuoteLastModified : '');

                System.debug('### Modified Template Body: ' + templateBody);

                // Collect email addresses for all user IDs
                List<String> toAddresses = new List<String>();
                List<User> users = [SELECT Id, Email FROM User WHERE Id IN :req.userIds];
                System.debug('### Users found: ' + users);

                for (User user : users) {
                    if (user.Email != null) {
                        toAddresses.add(user.Email);
                        System.debug('### Adding recipient: ' + user.Email);
                    }
                }

                if (!toAddresses.isEmpty()) {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(toAddresses); // Set list of email addresses
                    mail.setOrgWideEmailAddressId(orgWideEmailId);
                    mail.setSaveAsActivity(false);
                    mail.setHtmlBody(templateBody); // Set the modified body with replaced values
                    mail.setSubject('Task has been created.'); 
                    mail.setTargetObjectId(UserInfo.getUserId());
                    emails.add(mail);
                    System.debug('### Email prepared for: ' + toAddresses);
                } else {
                    System.debug('### No valid email addresses found for request: ' + req);
                }
            } catch (Exception e) {
                System.debug('### Error processing request: ' + e.getMessage());
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
            System.debug('### Sent ' + emails.size() + ' emails.');
        } else {
            System.debug('### No emails to send');
        }
    }
}