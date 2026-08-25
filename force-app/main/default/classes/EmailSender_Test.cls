@isTest
public class EmailSender_Test {
    @testSetup
    static void setup() {
        // Create a test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com.salesforce',
            Alias = 'testuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Create an email template
        EmailTemplate template = new EmailTemplate(
            Name = 'Test Template',
            DeveloperName = 'Test_Template',
            HtmlValue = '<html><body>Budget: {!DC_Budget__c.Name}, Budget ID: {!DC_Budget__c.Id}</body></html>',
            Subject = 'Test Email',
            TemplateType = 'Custom',
            FolderId = UserInfo.getUserId()
        );
        insert template;
        
        // Create an org-wide email address
        /*OrgWideEmailAddress orgWideEmail = new OrgWideEmailAddress(
            Address = 'indiateam+tega@datacolada.com',
            DisplayName = 'Test OrgWide Email',
            IsAllowAllProfiles = true
        );
        insert orgWideEmail; */
    }
    
    @isTest
    static void testSendEmailFromFlow() {
        // Fetch test data
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE Name = 'Test Template' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        
        // Prepare test data for the invocable method
        EmailSender.EmailRequest request = new EmailSender.EmailRequest();
        request.templateId = template.Id;
        request.BudgetName = 'Test Budget';
        request.BudgetId = 'BUD-12345';
        request.QuoteLastModified = '2025-01-30T12:00:00Z';
        request.userIds = new List<String>{ testUser.Id };
        
        Test.startTest();
        EmailSender.sendEmailFromFlow(new List<EmailSender.EmailRequest>{ request });
        Test.stopTest();
        
        // Verify email was sent
       // List<Messaging.SingleEmailMessage> sentEmails = [SELECT Id FROM Messaging.SingleEmailMessage];
       // System.assertEquals(1, sentEmails.size(), 'One email should have been sent.');
    }
}