@isTest
public class PPRcreateProductFlowTest {
    
    @testSetup
    static void setup() {
        PPRTriggerController__c setting = new PPRTriggerController__c();
        setting.isExecuting__c = false;
        insert setting;
    }

    @isTest
    static void testSetTriggerControlTrue() {
        List<Boolean> isExecutingList = new List<Boolean>{true};
        
        Test.startTest();
        PPRcreateProductFlow.setTriggerControl(isExecutingList);
        Test.stopTest();
        
        PPRTriggerController__c setting = PPRTriggerController__c.getOrgDefaults();
        
        System.assertNotEquals(null, setting, 'Custom setting should not be null');
        System.assertEquals(true, setting.isExecuting__c, 'isExecuting__c should be true');
    }
    
    @isTest
    static void testSetTriggerControlFalse() {
        List<Boolean> isExecutingList = new List<Boolean>{false};
        
        Test.startTest();
        PPRcreateProductFlow.setTriggerControl(isExecutingList);
        Test.stopTest();
        
        PPRTriggerController__c setting = PPRTriggerController__c.getOrgDefaults();
        
        // Validate the result
        System.assertNotEquals(null, setting, 'Custom setting should not be null');
        System.assertEquals(false, setting.isExecuting__c, 'isExecuting__c should be false');
    }
    
    @isTest
    static void testSetTriggerControlNull() {
        List<Boolean> isExecutingList = null;
        
        Test.startTest();
        PPRcreateProductFlow.setTriggerControl(isExecutingList);
        Test.stopTest();
        
        PPRTriggerController__c setting = PPRTriggerController__c.getOrgDefaults();
        
        System.assertEquals(false, setting.isExecuting__c, 'isExecuting__c should not change');
    }
    
    @isTest
    static void testSetTriggerControlEmptyList() {
        List<Boolean> isExecutingList = new List<Boolean>();
        
        Test.startTest();
        PPRcreateProductFlow.setTriggerControl(isExecutingList);
        Test.stopTest();
        
        PPRTriggerController__c setting = PPRTriggerController__c.getOrgDefaults();
        
        System.assertEquals(false, setting.isExecuting__c, 'isExecuting__c should not change');
    }
}