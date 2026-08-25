public class UserBudgetTriggerHelper {
    
    public void disableRejectInApprovalProcess(Map<id, User_Budget__c> newMap, Map<id, User_Budget__c> oldMap){
        try{
        for(User_Budget__c userBud : newMap.values()) {
            String oldStatus = oldMap.get(userBud.Id).Status__c;
            if(userBud.Status__c== 'Rejected' && oldStatus != 'Rejected') {    
                userBud.addError('Cannot Reject Approval Process, please make amendments on records and then approve');
            }
        }
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'UserBudgetTriggerHelper ',  'disableRejectInApprovalProcess');
        }
    }
}