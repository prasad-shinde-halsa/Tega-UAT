public without sharing class BudgetTriggerHelper {
    
    public void currencyValidation(List<Budget__c> budList){
        try {
        Set<Id> custbranchIdSet = new Set<Id>();
        for(Budget__c bud : budList){
            custbranchIdSet.add(bud.Customer_Branch_Assignment__c);
        }
        
        List<Customer_Sales_Organization__c> custBranchRecList = [Select Id,Branch__c,Sales_Organizations__c,Company__c,Company__r.Company_Code__c  
                                                                  from Customer_Sales_Organization__c where Id IN: custbranchIdSet];
        
        Map<Id,Customer_Sales_Organization__c> custBranchRecMap = new Map<Id,Customer_Sales_Organization__c>();
        Set<Id> branchIdSet = new Set<Id>();
        Set<Id> companyIdSet = new Set<Id>();
        for(Customer_Sales_Organization__c cso : custBranchRecList){
            custBranchRecMap.put(cso.Id,cso);
            branchIdSet.add(cso.Branch__c);
            companyIdSet.add(cso.Company__c);
        }
        
        List<Sales_Org_Branch_Relationship__c> sOrgBranchRelList = [Select Id,Branch__c,Company__c,Currency_Code__c
                                                                    from Sales_Org_Branch_Relationship__c where Branch__c IN: branchIdSet 
                                                                    AND Company__c IN: companyIdSet];
        Map<String,String> sOrgBranchRelMap = new Map<String,String>();
        for(Sales_Org_Branch_Relationship__c sOrgBranchRel : sOrgBranchRelList){
            String compositeKey = sOrgBranchRel.Branch__c + '-' + sOrgBranchRel.Company__c;
            sOrgBranchRelMap.put(compositeKey,sOrgBranchRel.Currency_Code__c);
        }
        
        for(Budget__c bud : budList){
            Customer_Sales_Organization__c cso = custBranchRecMap.get(bud.Customer_Branch_Assignment__c);
            String compositeKey = cso.Branch__c + '-' + cso.Company__c;
            String salesOrgBranchCurrency = sOrgBranchRelMap.get(compositeKey);
            if(bud.CurrencyIsoCode != salesOrgBranchCurrency){
                bud.addError('Currency of Budget and Currency Code of Customer Branch Asisgnment => Branch => Sales Org Branch Relationship should be same');
            }
        }
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'BudgetTriggerHelper',  'currencyValidation');
            
        }
    }
    
    public void validateUser(List<Budget__c> budList){
        try{
        String userId = UserInfo.getUserId();  
        User us = [Select Id,ProfileId from User where Id =: userId];
        Profile prof = [Select Id, Name from Profile where Id =: us.ProfileId];
        
        List<Group> queueList = [Select Id, Name from Group Where Name Like '%PMG Head%'];
        system.debug('queueList =>'+queueList);  
        Map<String,Group> queueMap = new Map<String,Group>();
        Set<Id> queuesId = new Set<Id>();
        for(Group queue : queueList){
            String pmgQueue = queue.Name;
            String[] pmgQueueArray = pmgQueue.split('-');
            String pmg = pmgQueueArray[0]; 
            queueMap.put(pmg,queue);
            queuesId.add(queue.Id);
        }
        system.debug('queueMap => '+queueMap);
        
        List<GroupMember> usersInQueue = [Select GroupId,UserOrGroupId From GroupMember where GroupId IN: queuesId];
        Map<String,List<GroupMember>> groupMembersMap = new Map<String,List<GroupMember>>();
        for(GroupMember gm : usersInQueue){
            if(!groupMembersMap.containsKey(gm.GroupId)){
                List<GroupMember> gmList = new List<GroupMember>();
                gmList.add(gm);
                groupMembersMap.put(gm.GroupId,gmList);
            }else if(groupMembersMap.containsKey(gm.GroupId)){
                List<GroupMember> gmList = groupMembersMap.get(gm.GroupId);
                gmList.add(gm);
                groupMembersMap.put(gm.GroupId,gmList);
            }  
        }
        
        //String salesOrgName = bud.Customer_Branch_Assignment__r.Company__r.Sales_Organization__r.Name;  
        
        if(prof.Name == 'PMG'){
            for(Budget__c bud : budList){
                Group relatedPmgQueue = queueMap.get(bud.PMG__c);
                List<GroupMember> usersInQueue2 = groupMembersMap.get(relatedPmgQueue.Id);
                Set<Id> userIdsInQueue = new Set<Id>();
                for(GroupMember user : usersInQueue2){
                    userIdsInQueue.add(user.UserOrGroupId);
                }
                if(!userIdsInQueue.contains(us.Id)){
                    bud.addError('User do not have necessary previlages to create this record');
                }
            }
        }
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'BudgetTriggerHelper',  'validateUser');
            
        }
    }
    
    public void checkUserAccessOfBudget(List<Budget__c> budList, Map<id, Budget__c> newMap, Map<id, Budget__c> oldMap, String operation){
        try{
        String userId = UserInfo.getUserId();
        User us = [Select Id,ProfileId from User where Id =: userId];
        
        Set<Id> userBudgetIds = new Set<Id>();
        
        Set<Id> childUserBudIds = new Set<Id>();
        Map<Id,Id> childParentUserBudgetMap = new Map<Id,Id>();
        
        list<Id> cbaList = new list<Id>();
        for(Budget__c bud : budList){
            userBudgetIds.add(bud.Parent_User_Budget__c);
            cbaList.add(bud.Customer_Branch_Assignment__c); // Modified by RC
            if(bud.User_Budget__c != null){
                childParentUserBudgetMap.put(bud.Id,bud.User_Budget__c);
                childUserBudIds.add(bud.User_Budget__c);
            }
        }
        // Modified by RC 3rd May
        map<Id,Customer_Sales_Organization__c> cSOMap = new map<id,Customer_Sales_Organization__c>([select id,branch__c,company__c from Customer_Sales_Organization__c where Id in:cbaList]);
        // To associate User Budget id with record
        List<User_Budget__c> userBudgetRecList = [Select Id,Branch__c,Name,Status__c,Approver__r.Id,Approver__c from User_Budget__c where Id IN: childUserBudIds];
        Map<Id,User_Budget__c> userBudgetRecMap = new Map<Id,User_Budget__c>();
        for(User_Budget__c userBud : userBudgetRecList){
            userBudgetRecMap.put(userBud.Id, userBud);
        }
        
        //Below List will be used in case of L1 and L3
        List<User_Budget__c> userBudList = [Select Id,Branch__c,Name,Status__c,Approver__r.Id,Approver__c,company__c from User_Budget__c where Id IN: userBudgetIds];
        system.debug('userBudList =>'+userBudList);
        Map<Id,User_Budget__c> userBudgetMap = new Map<Id,User_Budget__c>();
        for(User_Budget__c userBud : userBudList){
            userBudgetMap.put(userBud.Id, userBud);
        }
        
        
        //Below List will be used in case of L2
        List<User_Budget__c> childUserBudList = [Select Id,Branch__c,Name,Status__c,Approver__r.Id,Approver__c,Parent_User_Budget__c from User_Budget__c 
                                                 where Parent_User_Budget__c IN: userBudgetMap.keySet()];
        system.debug('childUserBudList =>'+childUserBudList);
        Map<Id,List<User_Budget__c>> childUserBudgetMap = new Map<Id,List<User_Budget__c>>();
        for(User_Budget__c userBud : childUserBudList){
            if(!childUserBudgetMap.containsKey(userBud.Parent_User_Budget__c)){
                List<User_Budget__c> newUserBudList = new List<User_Budget__c>();
                newUserBudList.add(userBud);
                childUserBudgetMap.put(userBud.Parent_User_Budget__c,newUserBudList);
            }else if(childUserBudgetMap.containsKey(userBud.Parent_User_Budget__c)){
                List<User_Budget__c> newUserBudList = childUserBudgetMap.get(userBud.Parent_User_Budget__c);
                newUserBudList.add(userBud);
                childUserBudgetMap.put(userBud.Parent_User_Budget__c,newUserBudList);
            }           
        }
        system.debug('childUserBudgetMap =>'+childUserBudgetMap);
        
        // Below Group and GroupMember will be used for PMG Head Queue Purpose
        List<Group> queueList = [Select Id, Name from Group Where Name Like '%PMG Head%'];
        system.debug('queueList =>'+queueList);
        
        Map<String,Group> queueMap = new Map<String,Group>();
        Set<Id> queuesId = new Set<Id>();
        for(Group queue : queueList){
            String pmgQueue = queue.Name;
            String[] pmgQueueArray = pmgQueue.split('-');
            String pmg = pmgQueueArray[0]; 
            queueMap.put(pmg,queue);
            queuesId.add(queue.Id);
        }
        system.debug('queueMap => '+queueMap);
        
        List<GroupMember> usersInQueue = [Select GroupId,UserOrGroupId From GroupMember where GroupId IN: queuesId];      
        Map<String,List<GroupMember>> groupMembersMap = new Map<String,List<GroupMember>>();
        for(GroupMember gm : usersInQueue){
            if(!groupMembersMap.containsKey(gm.GroupId)){
                List<GroupMember> gmList = new List<GroupMember>();
                gmList.add(gm);
                groupMembersMap.put(gm.GroupId,gmList);
            }else if(groupMembersMap.containsKey(gm.GroupId)){
                List<GroupMember> gmList = groupMembersMap.get(gm.GroupId);
                gmList.add(gm);
                groupMembersMap.put(gm.GroupId,gmList);
            }  
        }
         
        User_Mappings__c globalSalesHead = [Select Id,Name,User__c,Object_Name__c,User_Type__c from User_Mappings__c 
                                            where Object_Name__c = 'User_Budget__c' AND User_Type__c = 'Global Sales Head'];
        system.debug('globalSalesHead => '+globalSalesHead);
        
        for(Budget__c bud : budList){
            if((operation == 'ins' && bud.Parent_User_Budget__c != null) || (operation == 'upd' && oldMap.get(bud.Id).Parent_User_Budget__c != newMap.get(bud.Id).Parent_User_Budget__c)){
                
                User_Budget__c userBud = userBudgetMap.get(bud.Parent_User_Budget__c);
                if(userBud.Branch__c != cSOMap.get(bud.Customer_Branch_Assignment__c).Branch__c || userBud.Company__c != cSOMap.get(bud.Customer_Branch_Assignment__c).Company__c){ // modied by RC 3rd May
                    bud.addError('Branch & Company of User Budget and Budget should be same');
                }
                
                Id childUserBudId = childParentUserBudgetMap.get(bud.Id);
                User_Budget__c userBudChild = userBudgetRecMap.get(childUserBudId);
                
                if(userBud.Status__c == 'Submitted to RM'){
                    if(us.Id != userBud.Approver__r.Id){
                        bud.addError('Only RM can edit this record');
                    }
                }else if(userBudChild != null && userBudChild.Status__c == 'Submitted at L2 Level'){
                    
                    Group relatedPmgQueue = queueMap.get(bud.PMG__c);
                    List<GroupMember> usersInQueue2 = groupMembersMap.get(relatedPmgQueue.Id);
                    Set<Id> userIdsInQueue = new Set<Id>();
                    for(GroupMember user : usersInQueue2){
                        userIdsInQueue.add(user.UserOrGroupId);
                    }
                    if(!userIdsInQueue.contains(us.Id)){
                        bud.addError('User do not have necessary previlages to create this record');
                    }
                }else if(userBud.Status__c == 'Submitted'){
                    Set<Id> userIdsInQueue = new Set<Id>();
                    userIdsInQueue.add(globalSalesHead.User__c);
                    if(!userIdsInQueue.contains(us.Id)){
                        bud.addError('User do not have necessary previlages to create this record');
                    }
                }
            }
            if((operation == 'ins' && bud.User_Budget__c != null) || 
               (operation == 'upd' && oldMap.get(bud.Id).User_Budget__c != newMap.get(bud.Id).User_Budget__c)){
                   
                Id childUserBudId = childParentUserBudgetMap.get(bud.Id);
                User_Budget__c userBudChild = userBudgetRecMap.get(childUserBudId);
                system.debug('userBudChild => 149 '+userBudChild);
                   
                if(userBudChild.Status__c == 'L2 Approved'){
                    Boolean flag = false;
                    List<User_Budget__c> userBudgetList = childUserBudgetMap.get(bud.Parent_User_Budget__c);
                    system.debug('userBudgetList ==>'+userBudgetList);
                    for(User_Budget__c userBud2 : userBudgetList){
                        if(userBud2.Status__c == 'Submitted at L2 Level'){
                            flag = true;
                        }
                    }
                    if(flag == true){
                        bud.addError('User do not have necessary previlages to create this record');
                    } 
                }
            }
        }
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'BudgetTriggerHelper',  'checkUserAccessOfBudget');
            
        }
    }
    
    public void grantAccessToUsers(Map<id, Budget__c> oldBudgetMap,Map<id, Budget__c> newBudgetMap){
        try{
        Id  outsideBudgetRecTypeId = Schema.SObjectType.Budget__c.getRecordTypeInfosByDeveloperName().get('Budget_Outside_Of_Development').getRecordTypeId();
        
        List<Budget__c> budgetToBePassed = new List<Budget__c>();
        for(Budget__c bud : newBudgetMap.values()){ 
            if(bud.RecordTypeId == outsideBudgetRecTypeId){
                budgetToBePassed.add(bud);
            }else if(oldBudgetMap != null && bud.Finalize__c == true && oldBudgetMap.get(bud.Id).Finalize__c == false){
                budgetToBePassed.add(bud);
            }
        }
        
        accessToBudgetUsers(budgetToBePassed);
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'BudgetTriggerHelper',  'grantAccessToUsers');
            
        }
    }
    
    public void accessToBudgetUsers(List<Budget__c> budList){
        try{        
        List<Group> pmgQueueList = new List<Group>([Select Id, Name from Group Where Name Like '%Budget%' AND Name Like '%PMG Head%']);
        system.debug('pmgQueueList =>'+pmgQueueList);
        
        User_Mappings__c globalSalesHead = [Select Id,Name,User__c,Object_Name__c,User_Type__c from User_Mappings__c 
                                            where Object_Name__c = 'User_Budget__c' AND User_Type__c = 'Global Sales Head'];
        system.debug('globalSalesHead => '+globalSalesHead);
        
        Map<Id,Id> budgetRMMap = new Map<Id,Id>();
        Set<Id> csoIdSet = new Set<Id>();
        Map<Id,String> csomap = new Map<Id,String>();
                
        for(Budget__c bud : budList){
            system.debug(bud.SalesRegionUserId__c);
            budgetRMMap.put(bud.Id,bud.SalesRegionUserId__c);
            csoIdSet.add(bud.Customer_Branch_Assignment__c);
        }
        
        List<Customer_Sales_Organization__c> csoList = [Select Id,Company__r.Company_Code__c from Customer_Sales_Organization__c 
                                                      WHERE Id IN: csoIdSet];
        for(Customer_Sales_Organization__c cso : csoList){
            csomap.put(cso.Id,cso.Company__r.Company_Code__c);
        }
        
        Map<String,Group> pmgQueueMap = new Map<String,Group>();
        
        for(Group queue : pmgQueueList){
            String pmgQueue = queue.Name;
            String[] pmgQueueArray = pmgQueue.split('-');
            String pmg = pmgQueueArray[0];
            String companyCode = pmgQueueArray[2];
            String compositeKey = pmg + '-' + companyCode;
            pmgQueueMap.put(compositeKey,queue);
        }
        system.debug('pmgQueueMap => '+pmgQueueMap);
        
        List<Budget__Share> budShareList = new List<Budget__Share>();
        
        for(Budget__c bud : budList){
            Budget__Share gshBudShare = new Budget__Share();   
            gshBudShare.AccessLevel = 'Edit';
            gshBudShare.UserOrGroupId = globalSalesHead.User__c;
            gshBudShare.ParentID = bud.Id;
            budShareList.add(gshBudShare);
            
            Budget__Share rmBudShare = new Budget__Share();   
            rmBudShare.AccessLevel = 'Edit';
            rmBudShare.UserOrGroupId = budgetRMMap.get(bud.Id);
            rmBudShare.ParentID = bud.Id;
            budShareList.add(rmBudShare);
            
            Budget__Share pmgBudShare = new Budget__Share();
            pmgBudShare.AccessLevel = 'Edit';
            String companyCode = csomap.get(bud.Customer_Branch_Assignment__c);
            system.debug('companyCode =>'+companyCode);
            String pmg = bud.PMG__c;
            String compositeKey = pmg + '-' +companyCode;
            system.debug('compositeKey =>'+compositeKey);
            pmgBudShare.UserOrGroupId = pmgQueueMap.get(compositeKey).Id;
            pmgBudShare.ParentID = bud.Id;
            system.debug('pmgBudShare =>'+pmgBudShare);
            budShareList.add(pmgBudShare);
        }
        insert budShareList;
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'BudgetTriggerHelper',  'accessToBudgetUsers');
            
        }
    }
}