public without sharing class  PPRLineItemTriggerHelper {
    /* 
* Name : sharePPRRecord
* Desc : This Method is used for Sharing the record with the To & CC queues.
*/
    /*public void sharePPRRecord(Map<id, PPR_Line_Item__c> newMap){
// Variable declaration.
String PMGcompanyCode;
//get PPRLineItem Record.
List<PPR_Line_Item__c> pprList = [SELECT Id, Name, Company__c, Customer_Name__c, Status__c, PMG__c,
Customer_Branch_Assignment__r.Company__r.Company_Code__c
FROM PPR_Line_Item__c
WHERE Id =: newMap.KeySet()];
System.debug('$pprList:'+pprList);
//Map to store PMG & company code.
Map<String, String> pmgCompanyMap = new Map <String, String>();
//Iterate over PPR to get PMG & companyCode.
for (PPR_Line_Item__c objPPRLi: pprList){
PMGcompanyCode = objPPRLi.PMG__c +'-'+ objPPRLi.Customer_Branch_Assignment__r.Company__r.Company_Code__c;
pmgCompanyMap.put(PMGcompanyCode, objPPRLi.Id);
System.debug('$PMG-CompanyCode:'+PMGcompanyCode);
}
//Initiallize variable queueName to get the que dynamically.
Set<String> queToSet = new Set<String>();
Set<String> queCcSet = new Set<String>();
//Split on the basis of '-'
for (String pmgComCode: pmgCompanyMap.KeySet()){
String [] splitValue = pmgComCode.split('-');
String PMG = splitValue[0];
String companyCode = splitValue[1];
queToSet.add(PMG+'_PPR_CCM_'+companyCode+'_To');
queCcSet.add(PMG+'_PPR_CCM_'+companyCode+'_Cc');
}
System.debug('$To Queue:'+queToSet+' Cc Queue:'+queCcSet);
//Sharing the recrd & setting Accessibillity via Apex.
List<PPR_Line_Item__Share> shareListTobeInserted = new List<PPR_Line_Item__Share>();
//To Map w/ queue Id
Map<String, Id> queNameToIdMap = new Map<String,Id>();
for(Group objGrp: [SELECT Id, Name, DeveloperName, Email, Type FROM Group where Type='Queue' And DeveloperName IN: queToSet]){
queNameToIdMap.put(objGrp.DeveloperName, objGrp.Id);
}
//Cc Map w/ queue Id
Map<String, Id> queNameCcIdMap = new Map<String, Id>();
for(Group objGrp: [SELECT Id, Name, DeveloperName, Email, Type FROM Group where Type='Queue' And DeveloperName IN: queCcSet]){
queNameCcIdMap.put(objGrp.DeveloperName, objGrp.Id);
}
//Sharing Records.
for(PPR_Line_Item__c objPPrLi: pprList){
String pmg = objPPrLi.PMG__c;
String compCode = objPPrLi.Customer_Branch_Assignment__r.Company__r.Company_Code__c;
String queueNameTo = pmg+'_PPR_CCM_'+compCode+'_To';
String queueNameCc = pmg+'_PPR_CCM_'+compCode+'_Cc';
//Share record w/ To Queue
PPR_Line_Item__Share shareTo = new PPR_Line_Item__Share();
shareTo.ParentId = objPPrLi.Id;
if (queNameToIdMap.containsKey(queueNameTo)){
shareTo.UserOrGroupId = queNameToIdMap.get(queueNameTo);
System.debug('$ToQueID: '+queNameCcIdMap.get(queueNameTo));
}
shareTo.AccessLevel = 'Edit';
shareListTobeInserted.add(shareTo);
System.debug('$Record Name Shared w/ ToQueue:'+objPPrLi.Name);
//Share Record w/ CC Queue
PPR_Line_Item__Share shareCc = new PPR_Line_Item__Share();
shareCc.ParentId = objPPrLi.Id;
if (queNameCcIdMap.containsKey(queueNameCc)){
shareCc.UserOrGroupId = queNameCcIdMap.get(queueNameCc);
System.debug('$CCQueID: '+queNameCcIdMap.get(queueNameCc));
}
shareCc.AccessLevel = 'Read';
shareListTobeInserted.add(shareCc);
System.debug('$shareListTobeInserted:'+shareListTobeInserted);
System.debug('$Record Name Shared w/ CcQueue:'+objPPrLi.Name);
}
try{
insert shareListTobeInserted;
}catch(exception e){
TegaUtility.trackLogs(e,'PPRLineItemTriggerHelper','Id');
}
}*/
    /*
* Name : updateTaskQueue
* Desc : This Method is used for updating the task related to PPRLine Item when Status on PPRLi = Submit to Department then task is updated with the new Assigned to queue.
*/
    public void updateTaskQueue(Map<id, PPR_Line_Item__c> newMap, Map<id, PPR_Line_Item__c> oldMap){
        //Creating Set<ID>
        Set <Id> pprIdSet = new Set <Id>();
        for (PPR_Line_Item__c objPPR: newMap.values()){
            if (newMap.get(objPPR.Id).Status__c != oldMap.get(objPPR.Id).Status__c && newMap.get(objPPR.Id).Status__c == 'Submit to Department'){
                pprIdSet.add(objPPR.Id);
            }
            if(pprIdSet.size()>0){
                //Variable declaration
                String PMG;
                String companyCode;
                String department;
                //Create List taskListToBeUpdated
                List<task> taskListToBeUpdated = new List<Task>();
                //Create Set <String> to store queName
                Set<String> qNameSet = new Set<String>();
                //Creating Map<String, Task>
                Map<String,List<Task>> groupTaskMap = new Map <String,List<Task>>();
                //Create List of Task related to that PPR Line Item
                List<Task> taskList = [SELECT Id, WhoId, WhatId, PPR_Line_Item__c,Department_Name__c,Subject,OwnerId,PPR_Line_Item__r.Other_user__c,
                                       PPR_Line_Item__r.PMG__c, PPR_Line_Item__r.OwnerId,PPR_Line_Item__r.Company_Code__c 
                                       FROM Task WHERE PPR_Line_Item__c =: newMap.KeySet()];
                System.debug('$TaskList:'+taskList);
                //Check Department with long term action.
                Set<String> longTermTaskDeptSet = new Set<String>();
                List<Task> taskWLongTermActionDeptList = new List<Task>();
                //
                for (Task objTasks: taskList){
                    if(objTasks.Subject == 'Long Term'){
                        longTermTaskDeptSet.add(objTasks.Department_Name__c);
                    }
                    System.debug('$longTermTaskDeptSet:'+longTermTaskDeptSet);
                }
                //Get PMG, CompanyCode
                for (Task objTask: [SELECT Id, WhoId, WhatId, PPR_Line_Item__c,Department_Name__c,Subject,OwnerId,PPR_Line_Item__r.Other_user__c,
                                    PPR_Line_Item__r.PMG__c, PPR_Line_Item__r.OwnerId,PPR_Line_Item__r.Company_Code__c
                                    FROM Task WHERE PPR_Line_Item__c =: newMap.KeySet() AND Department_Name__c IN:longTermTaskDeptSet]){
                                        PMG = objTask.PPR_Line_Item__r.PMG__c;
                                        companyCode = objTask.PPR_Line_Item__r.Company_Code__c;
                                        department = objTask.Department_Name__c;
                                        //formatting queueName
                                        String queueName = (PMG+'_PPR_'+companyCode+'_'+department);
                                        System.debug('&queueName:'+queueName);
                                        qNameSet.add(queueName);
                                        /* if (!groupTaskMap.containsKey(queueName)){
List<Task> taskListU = new List<Task>();
taskListU.add(objTask);
groupTaskMap.put(queueName,taskListU);
}else{
groupTaskMap.get(queueName).add(objTask);
}*/
                                    }
                
                //update Task
                
                list<PPR_Line_Item__Share> pprLineItemShareList = new list<PPR_Line_Item__Share>();
                map<String,list<Id>> departmentQueueIds = new map<String,list<Id>>();
                Set<Id> uniqueTaskIds = new Set<Id>();
                list<Group> objGrpList = new list<Group>([SELECT Id, Name, DeveloperName, Email, Type FROM Group where Type='Queue' And DeveloperName =: qNameSet]);
                map<String,Id> groupNameToId = new map<String,Id>();
                for(Group que: objGrpList){
                    groupNameToId.put(que.DeveloperName, que.Id);
                }
                System.debug('==groupNametoId=='+groupNameToId);
                // for(Group objGrp: [SELECT Id, Name, DeveloperName, Email, Type FROM Group where Type='Queue' And DeveloperName =: qNameSet]){
                //  if(groupTaskMap.containsKey(objGrp.DeveloperName)){
                //      List<Task> objTskList = groupTaskMap.get(objGrp.DeveloperName);
                for(Task objTsk: taskList){
                    PMG = objTsk.PPR_Line_Item__r.PMG__c;
                    companyCode = objTsk.PPR_Line_Item__r.Company_Code__c;
                    department = objTsk.Department_Name__c;
                    //formatting queueName
                    String queueName = (PMG+'_PPR_'+companyCode+'_'+department);
                    String QueueId = '';
                    if(groupNameToId.containsKey(queueName)){
                        QueueId = groupNameToId.get(queueName);
                    }
                    System.debug('--QueueId-'+QueueId);
                    objTsk.Status = newMAp.get(objTsk.PPR_Line_Item__r.Id).Status__c;
                    if(String.isNotBlank(QueueId) && (objTsk.Department_Name__c != 'CCSL') && (objTsk.Department_Name__c != 'CCOT')){
                        objTsk.OwnerId = QueueId;
                        if(!departmentQueueIds.containsKey(objTsk.PPR_Line_Item__r.Id))
                            departmentQueueIds.put(objTsk.PPR_Line_Item__r.Id,new list<Id>{});
                        departmentQueueIds.get(objTsk.PPR_Line_Item__r.Id).add(QueueId);
                        /* commented by Rahul
//Share ppr with OwnerId on task.
List<PPR_Line_Item__Share> shareListTobeInserted = new List<PPR_Line_Item__Share>();
PPR_Line_Item__Share shareTo = new PPR_Line_Item__Share();
shareTo.ParentId = objTsk.PPR_Line_Item__r.Id;
shareTo.UserOrGroupId = objGrp.Id;
shareTo.AccessLevel = 'Edit';
shareListTobeInserted.add(shareTo);
System.debug('$Record Shared w/ ToQueue:'+objTsk.OwnerId);
//
insert shareListTobeInserted;       
END commented by Rahul*/
                    }
                    else if(objTsk.Department_Name__c == 'CCSL'){
                        objTsk.OwnerId = objTsk.PPR_Line_Item__r.OwnerId;
                    }
                    else if(objTsk.Department_Name__c == 'CCOT'){
                        objTsk.OwnerId = objTsk.PPR_Line_Item__r.Other_user__c;
                        
                        System.debug('$ objTsk.OwnerId :'+ objTsk.OwnerId );
                        PPR_Line_Item__Share pprLineItemToOther = new PPR_Line_Item__Share();
                        pprLineItemToOther.ParentId = objTsk.PPR_Line_Item__r.Id;
                        pprLineItemToOther.UserOrGroupId = objTsk.PPR_Line_Item__r.Other_user__c;
                        pprLineItemToOther.AccessLevel = 'Edit';
                        pprLineItemShareList.add(pprLineItemToOther);
                        //Share ppr with OwnerId on task.
                        /* Comment start by Rahul
List<PPR_Line_Item__Share> shareListTobeInsertedOthers = new List<PPR_Line_Item__Share>();
PPR_Line_Item__Share shareToOthers = new PPR_Line_Item__Share();
shareToOthers.ParentId = objTsk.PPR_Line_Item__r.Id;
shareToOthers.UserOrGroupId = objGrp.Id;
shareToOthers.AccessLevel = 'Edit';
shareListTobeInsertedOthers.add(shareToOthers);
System.debug('$Record Name Shared w/ Others:'+objTsk.OwnerId);
//
insert shareListTobeInsertedOthers;
ENd Commented by Rahul*/
                    }
                    if(!uniqueTaskIds.contains(objtsk.Id)){
                        uniqueTaskIds.add(objtsk.id);
                        taskListToBeUpdated.add(objTsk);
                    }    
                }
                // }
                //  }
                if(departmentQueueIds.size() > 0){
                    list<Id> allQueueId = new list<Id>();
                    for(list<Id> queueIds : departmentQueueIds.values()){
                        allQueueId.addAll(queueIds);
                    }   
                    list<GroupMember> departmentGroupMembers = new list<GroupMember>([Select UserOrGroupId,GroupId From GroupMember where GroupId in:allQueueId]);
                    map<Id, list<Id>> queueTouserIds = new map<Id, list<Id>>();
                    for(GroupMember gm : departmentGroupMembers){
                        if(!queueTouserIds.containsKey(gm.Id))
                            queueTouserIds.put(gm.GroupId, new list<Id>{});
                        queueTouserIds.get(gm.GroupId).add(gm.UserOrGroupId);
                    }
                    
                    // prepare share record list
                    system.debug('===department queue map--'+departmentQueueIds);
                    system.debug('===queue Id user map--'+queueTouserIds);
                    for(Id PPRId : departmentQueueIds.keyset()){
                        for(Id queueId : departmentQueueIds.get(PPRId)){
                            if(queueTouserIds.containsKey(queueId)){
                                system.debug('===single queue id=='+queueId);
                                for(Id userIdShare : queueTouserIds.get(queueId)){
                                    system.debug('--user--id-'+userIdShare);
                                    PPR_Line_Item__Share pprLineItemShare = new PPR_Line_Item__Share();
                                    pprLineItemShare.ParentId = PPRId;
                                    pprLineItemShare.UserOrGroupId = userIdShare;
                                    pprLineItemShare.AccessLevel = 'Edit';
                                    pprLineItemShareList.add(pprLineItemShare);                                    
                                }
                            }
                            
                        }
                        
                    }
                    
                }
                System.debug('&taskListToBeUpdated:'+taskListToBeUpdated);
                try{
                    system.debug('--sharerecord--'+pprLineItemShareList);
                    if(pprLineItemShareList.size() > 0)
                        insert pprLineItemShareList;
                    update taskListToBeUpdated;
                    
                }catch(exception e){
                    TegaUtility.trackLogs(e,'PPRLineItemTriggerHelper','Id');
                }
            }
        }
    }
    
    public void pprRecordName(List<PPR_Line_Item__c> pprList){
        try{
        Set<Id> csoIds = new Set<Id>();
        List<PPR_Line_Item__c> pprListSys = new List<PPR_Line_Item__c>([SELECT id , Name , Customer_Branch_Assignment__c from PPR_Line_Item__c Order by createdDate DESC limit 1]) ;
        // output = 'ABC-DEF-GHI-7';
        system.debug('pprList===>'+pprListSys);
        
        for(PPR_Line_Item__c pprs : pprList){
            csoIds.add(pprs.Customer_Branch_Assignment__c);
        }
        system.debug('csoIds===>'+csoIds);
        //String Name = ppr.Name;
        //List<Customer_Sales_Organization__c> csoList = [Select Id,Branch__c,branch__r.branch_code__c,Company__c,Company__r.Company_Code__c from Customer_Sales_Organization__c where Id IN:csoIds];
        List<Customer_Sales_Organization__c> csoList = [Select Id,Branch__c,branch__r.branch_code__c,Company__c,Company__r.Company_Code__c from Customer_Sales_Organization__c where Id IN:csoIds];
        
        system.debug('csoList===>'+csoList);
        map<id,Customer_Sales_Organization__c> csoMap = new Map<id,Customer_Sales_Organization__c>();
        
        for( Customer_Sales_Organization__c cso : csoList){ 
            csoMap.put(cso.id,cso);            
        }
        system.debug('csoMap==>'+csoMap);
        
        Integer serialNum = 0;
        
        if(pprListSys.size() > 0){
            String[] nameArray = pprListSys[0].Name.split('-');
            system.debug('nameArray===>'+nameArray);
            if(nameArray!=null && nameArray.size()>3 )
            serialNum = Integer.valueOf(nameArray[3]);
            //Integer FinalNumber = serialNum + 1;
        }
        
        for(PPR_Line_Item__c pprs : pprList){
            Customer_Sales_Organization__c custOrg = csoMap.get(pprs.Customer_Branch_Assignment__c);
            system.debug('custOrg==>'+custOrg);
            serialNum++;
            String companyCode = custOrg.company__r.Company_Code__c;
            String branchCode = custOrg.branch__r.branch_code__c;
            pprs.Name = companyCode + '-' + 'PPR' + '-' + branchCode + '-' + serialNum;
        }
        }catch(exception e){
                    TegaUtility.trackLogs(e,'PPRLineItemTriggerHelper','pprRecordName');
        }
    }
}