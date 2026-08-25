public without sharing class UserBudgetApprovalProcess {
    
    @InvocableMethod (label = 'Create Approval Process for UserBudget' description = 'returns nothing')
    public static void userBudgetApprovalProcessMethod (List<List<String>> ubList){
        try{
        List<String> ubIdList =  ubList[0];
        String approvalLevel = ubIdList[1];
        User_Budget__c userBudget = [Select Id,PMG__c,Parent_User_Budget__c,Approver__c,Company__r.Company_Code__c,Parent_User_Budget__r.Company__r.Sales_Organization__r.Name,Company__r.Sales_Organization__r.Name 
                                     FROM User_Budget__c where Id =: ubIdList[0]];
        //String salesOrgName = '%' + userBudget.Company__r.Sales_Organization__r.Name + '%';
        String companyCode = '%' + userBudget.Company__r.Company_Code__c + '%';
        
        system.debug('companyCode =>'+companyCode);
        
        List<User_Budget__c> childUserBudgetList = [Select Id,PMG__c,Parent_User_Budget__c from User_Budget__c 
                                                    where Parent_User_Budget__c =: userBudget.Id];
        system.debug('childUserBudgetList =>'+childUserBudgetList);
        
        Map<String,User_Budget__c> childUserBudgetMap = new Map<String,User_Budget__c>();
        Set<Id> childUserBudgetIds = new Set<Id>();
        
        Integer L2ApprovedCounter = 0;
        
        if(approvalLevel == 'L2'){
            
            for(User_Budget__c userBud : childUserBudgetList){
                childUserBudgetMap.put(userBud.PMG__c,userBud);
                childUserBudgetIds.add(userBud.Id);
            }
            system.debug('childUserBudgetMap =>'+childUserBudgetMap);
            
            List<Budget__c> budgetTaggedWithPMGUserBudList = [Select Id,PMG__c,User_Budget__c FROM Budget__C WHERE User_Budget__c IN: childUserBudgetIds];
            system.debug('budgetTaggedWithPMGUserBudList => '+budgetTaggedWithPMGUserBudList);
            
            Map<String,List<Budget__c>> childBudgetMap = new Map<String,List<Budget__c>>();
            
            for(Budget__c bud : budgetTaggedWithPMGUserBudList){
                if(!childBudgetMap.containsKey(bud.PMG__c)){
                    List<Budget__c> newBudList = new List<Budget__c>();
                    newBudList.add(bud);
                    childBudgetMap.put(bud.PMG__c,newBudList);
                }else if(childBudgetMap.containsKey(bud.PMG__c)){
                    List<Budget__c> newBudList = childBudgetMap.get(bud.PMG__c);
                    newBudList.add(bud);
                    childBudgetMap.put(bud.PMG__c,newBudList);
                }
            }
            system.debug('childBudgetMap =>'+childBudgetMap);
            
            List<Group> queueList = [Select Id, Name from Group 
                                     Where Name Like '%PMG Head%' 
                                     AND Name Like: companyCode];
            system.debug('queueList =>'+queueList);
            
            Map<String,Group> queueMap = new Map<String,Group>();
            
            for(Group queue : queueList){
                String pmgQueue = queue.Name;
                String[] pmgQueueArray = pmgQueue.split('-');
                String pmg = pmgQueueArray[0]; 
                queueMap.put(pmg,queue);
            }
            system.debug('queueMap => '+queueMap);
            
            List<User_Budget__Share> userBudShareList = new List<User_Budget__Share>();
            List<Budget__Share> budShareList = new List<Budget__Share>();
            
            for(String pmg : childUserBudgetMap.keyset()){
                system.debug('pmg => '+pmg);
                
                // Sharing Child PMG UserBudget Record with respective PMG
                User_Budget__c usBud = childUserBudgetMap.get(pmg);
                User_Budget__Share userBudShare = new User_Budget__Share();
                userBudShare.AccessLevel = 'Edit';
                userBudShare.UserOrGroupId = queueMap.get(pmg).Id;
                userBudShare.ParentID = usBud.Id;
                userBudShareList.add(userBudShare);
                
                // Sharing Parent UserBudget Record with PMG
                User_Budget__c usBud2 = childUserBudgetMap.get(pmg);
                User_Budget__Share userBudShare2 = new User_Budget__Share();
                userBudShare2.AccessLevel = 'Read';
                userBudShare2.UserOrGroupId = queueMap.get(pmg).Id;
                userBudShare2.ParentID = usBud.Parent_User_Budget__c;
                userBudShareList.add(userBudShare2);
                
                List<Budget__c> budList = childBudgetMap.get(pmg);
                for(Budget__c bud : budList){
                    Budget__Share budShare = new Budget__Share();
                    budShare.AccessLevel = 'Edit';
                    budShare.UserOrGroupId = queueMap.get(pmg).Id;
                    budShare.ParentID = bud.Id;
                    budShareList.add(budShare);
                }
            }
            insert userBudShareList;
            insert budShareList;
            
            //EntityDefinition edObj = [SELECT DurableId FROM EntityDefinition WHERE QualifiedApiName = 'User_Budget__c']; 
            //system.debug('edObj => '+edObj);
            
            Map<String,String> approvalProcessBasedOnPmg = new Map<String,String>();
            approvalProcessBasedOnPmg.put('Mill','Mill_L2_Approval_Process');
            approvalProcessBasedOnPmg.put('Hydrocyclone','Hydrocyclone_L2_Approval_Process');
            approvalProcessBasedOnPmg.put('Screen','Screen_L2_Approval_Process');
            approvalProcessBasedOnPmg.put('Trommel','Trommel_L2_Approval_Process');
            approvalProcessBasedOnPmg.put('Conveyor Component','Conveyor_Component_L2_Approval_Process');
            approvalProcessBasedOnPmg.put('Wear Component','Wear_Component_L2_Approval_Process');
            
            for(String pmg : childUserBudgetMap.keyset()){
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                User_Budget__c usBud = childUserBudgetMap.get(pmg);
                req.setObjectId(usBud.Id);
                String queueId = queueMap.get(pmg).Id;
                List<String> userId = new List<String>();
                userId.add(queueId);
                req.setNextApproverIds(userId);
                req.setProcessDefinitionNameOrId(approvalProcessBasedOnPmg.get(pmg));
                Approval.ProcessResult processResult = Approval.process(req);
            }            
        }else if(approvalLevel == 'L3'){
            List<User_Budget__c> childUserBudgetL3List = [Select Id,PMG__c,Parent_User_Budget__c,Status__c from User_Budget__c 
                                                          where Parent_User_Budget__c =: userBudget.Parent_User_Budget__c];
            
            List<Budget__c> budgetTaggedWithParentUserBudList = [Select Id,Parent_User_Budget__c FROM Budget__C WHERE Parent_User_Budget__c =: userBudget.Parent_User_Budget__c];
            system.debug('budgetTaggedWithParentUserBudList => '+budgetTaggedWithParentUserBudList);
            
            for(User_Budget__c userBud : childUserBudgetL3List){
                if(userBud.Status__c == 'L2 Approved'){
                    L2ApprovedCounter++;
                }
            }
            if(L2ApprovedCounter == childUserBudgetL3List.size()){
                User_Mappings__c globalSalesHead = [Select Id,Name,User__c,Object_Name__c,User_Type__c from User_Mappings__c 
                                                where Object_Name__c = 'User_Budget__c' AND User_Type__c = 'Global Sales Head'];
                system.debug('globalSalesHead => '+globalSalesHead);
                
                User_Budget__Share userBudShare = new User_Budget__Share();
                userBudShare.AccessLevel = 'Edit';
                //userBudShare.UserOrGroupId = queue.Id;
                userBudShare.UserOrGroupId = globalSalesHead.User__c;
                userBudShare.ParentID = userBudget.Parent_User_Budget__c;
                insert userBudShare;
                
                List<Budget__Share> budShareList = new List<Budget__Share>();
                for(Budget__c bud : budgetTaggedWithParentUserBudList){
                    Budget__Share budShare = new Budget__Share();
                    budShare.AccessLevel = 'Edit';
                    //budShare.UserOrGroupId = queue.Id;
                    budShare.UserOrGroupId = globalSalesHead.User__c;
                    budShare.ParentID = bud.Id;
                    budShareList.add(budShare);
                }
                insert budShareList;
                
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(userBudget.Parent_User_Budget__c);
                List<String> userId = new List<String>();
                //userId.add(queue.Id);
                userId.add(globalSalesHead.User__c);
                system.debug('userId => '+userId);
                req.setNextApproverIds(userId);
                req.setProcessDefinitionNameOrId('GlobalSalesHeadApproval2');
                Approval.ProcessResult processResult = Approval.process(req);
            }
        }else if(approvalLevel == 'RML3'){
            List<User_Budget__c> childUserBudgetL3List = [Select Id,PMG__c,Parent_User_Budget__c,Status__c from User_Budget__c 
                                                          where Parent_User_Budget__c =: userBudget.Id];
            List<Budget__c> budgetTaggedWithParentUserBudList = [Select Id,Parent_User_Budget__c FROM Budget__C WHERE Parent_User_Budget__c =: userBudget.Id];
            system.debug('budgetTaggedWithParentUserBudList => '+budgetTaggedWithParentUserBudList);
            
            User_Budget__Share userBudShare = new User_Budget__Share();
            userBudShare.AccessLevel = 'Edit';
            userBudShare.UserOrGroupId = userBudget.Approver__c;
            userBudShare.ParentID = userBudget.Id;
            insert userBudShare;
            
            List<Budget__Share> budShareList = new List<Budget__Share>();
            for(Budget__c bud : budgetTaggedWithParentUserBudList){
                Budget__Share budShare = new Budget__Share();
                budShare.AccessLevel = 'Edit';
                budShare.UserOrGroupId = userBudget.Approver__c;
                budShare.ParentID = bud.Id;
                budShareList.add(budShare);
            }
            insert budShareList;
            
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(userBudget.Id);
            List<String> userId = new List<String>();
            userId.add(userBudget.Approver__c);
            system.debug('userId => '+userId);
            req.setNextApproverIds(userId);
            req.setProcessDefinitionNameOrId('UserBudgetApproval');
            Approval.ProcessResult processResult = Approval.process(req);
        }
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'UserBudgetApprovalProcess',  'userBudgetApprovalProcessMethod ');
        }
    }
}