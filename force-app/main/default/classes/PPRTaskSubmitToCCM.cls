public class PPRTaskSubmitToCCM {
    @InvocableMethod
    public static List<String> userCCMApproval(List<List<String>> ubList){
        List<String> retToFlow = new List<String>();
        try{
        List<String> ubIdList =  ubList[0];
        System.debug('#ubIdList:'+ubIdList);
        String TaskId = ubIdList[0];
        System.debug('#TaskId:'+TaskId);
        
        
        //Get Task Record.
        List <Task> taskList = [SELECT Id, WhoCount, PPR_Line_Item__c, WhoId, WhatId, Status, Subject,
                                PPR_Line_Item__r.PMG__c,PPR_Line_Item__r.Customer_Branch_Assignment__r.Company__r.Company_Code__c
                                FROM Task 
                                WHERE Id =: TaskId];
        //Get Assigned to Queue Name
        Set<String> toQueueNameSet = new Set<String>();
        for (Task objTask: taskList){
            String toQueueName = objTask.PPR_Line_Item__r.PMG__c+'_PPR_CCM_'+objTask.PPR_Line_Item__r.Customer_Branch_Assignment__r.Company__r.Company_Code__c+'_To';
            System.debug('$toQueueName:'+toQueueName);
            toQueueNameSet.add(toQueueName);
        }
        System.debug('$toQueueNameSet:'+toQueueNameSet);
        
        //get User from CCM-To-queue
        List <GroupMember> groupMembers = [SELECT UserorGroupId
                                           FROM GroupMember
                                           WHERE Group.DeveloperName IN: toQueueNameSet];
        List <User> Users = new List<User>();
        for (GroupMember Member: groupMembers){
            String userOrGroupId = member.UserOrGroupId;
            System.debug('$userOrGroupId:'+userOrGroupId);
            User user = [SELECT Id,Name
                         FROM User
                         WHERE Id =: userOrGroupId];
            Users.add(user);
            System.debug('$Approval UserName:'+user.Name);
        }
        // 2. Approval Process 
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(TaskId);
        List<String> userId = new List<String>();
        userId.add(Users[0].Id);
        system.debug('userId => '+userId);
        req.setNextApproverIds(userId);
        req.setProcessDefinitionNameOrId('PPRTaskAP_Submit_to_CCM');
        Approval.ProcessResult processResult = Approval.process(req);
        retToFlow.add('true');
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'PPRTaskSubmitToCCM',  'userCCMApproval');
        }
        return retToFlow;
    }
}