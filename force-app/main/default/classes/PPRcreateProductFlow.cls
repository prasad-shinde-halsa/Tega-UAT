public class PPRcreateProductFlow {
    
    // Invocable method to set the isExecuting__c field in the PPRTriggerController__c Custom Setting
    @InvocableMethod(label='Set Trigger Execution Flag' description='Sets the isExecuting flag for controlling the trigger')
    public static void setTriggerControl(List<Boolean> isExecutingList) {
        // Ensure we only get one boolean value from the Flow
        if (isExecutingList == null || isExecutingList.isEmpty()) {
            return;
        }
        Boolean isExecuting = isExecutingList[0];
        
        // Retrieve the organization-wide default for the custom setting
        PPRTriggerController__c setting = PPRTriggerController__c.getOrgDefaults();

        if (setting == null) {
            setting = new PPRTriggerController__c();
        }
        
        // Set the new value for isExecuting__c
        setting.isExecuting__c = isExecuting;
        System.debug('Updating value ' + setting.isExecuting__c);
        try {
            upsert setting;
        } catch (Exception e) {
            System.debug('Error updating custom setting: ' + e.getMessage());
        }
    }
}