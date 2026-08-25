/* Class : PPRApprovalProccess
* Flow Name: Flow PPRLi: Submit for Approval to CCM.
* Functionallities : 1. Check Product must be present with PPR product relationship.
*                     2. Trigger Approval process when Salesrep Submits PPR.
*                     3. Share PPR record with To & CC Queue. 
*/
public class PPRApprovalProccess {
    @InvocableMethod
    public static List<String> userCCMApproval(List<List<String>> ubList){
        List<String> ubIdList =  ubList[0];
        System.debug('#ubIdList:'+ubIdList);
        String pprID = ubIdList[0];
        System.debug('#pprID:'+pprID);
        List <String> retToFlow = new List<String>();
        try{
        // 1.Check if ppr contains any product in PPR product Relationship object.
        List <PPR_Product_Relationship__c> pprProductList = [SELECT Id, Name, PPR_Line_Item__c, Part_List__c, 
                                                             Product__c, Item_Code__c, Item_Description__c, 
                                                             PartList_Revision_No__c, FRO_Quantity__c, Required_Quantity__c, 
                                                             Deadline_for_action__c 
                                                             FROM PPR_Product_Relationship__c 
                                                             WHERE PPR_Line_Item__c =: pprID];
        
        if (pprProductList.size() >0){
            
            //Get PPR Record.
            List <PPR_Line_Item__c> pprList = [SELECT Id, Name, PMG__c, Company_Code__c,Customer_Branch_Assignment__r.Company__r.Company_Code__c, Customer_Name__c,
                                               Company__c, Status__c
                                               FROM PPR_Line_Item__c 
                                               WHERE Id =: pprID];
            //Get Assigned to Queue Name
            Set<String> toQueueNameSet = new Set<String>();
            for (PPR_Line_Item__c objPPR: pprList){
                String toQueueName = objPPR.PMG__c+'_PPR_CCM_'+objPPR.Customer_Branch_Assignment__r.Company__r.Company_Code__c+'_To';
                System.debug('$toQueueName:'+toQueueName);
                toQueueName = toQueueName.replaceAll('\\s+', '_');
                System.debug('$toQueueName after condition:'+toQueueName);
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
            req.setObjectId(pprID);
            List<String> userId = new List<String>();
            userId.add(Users[0].Id);
            system.debug('userId => '+userId);
            req.setNextApproverIds(userId);
            req.setProcessDefinitionNameOrId('PPRAP_Submit_to_CCM');
            Approval.ProcessResult processResult = Approval.process(req);
            
            //3. Sharing record with to & cc queue.
            
            // Variable declaration.
            String PMGcompanyCode;
            
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
                // Replace any spaces with underscores before adding to the sets
                //pk changes 14-11-2024
                String queToSetValue = PMG+'_PPR_CCM_'+companyCode+'_To';
                String queCcSetValue = PMG+'_PPR_CCM_'+companyCode+'_Cc';
                
                // Replace spaces with underscores in the generated strings
                queToSet.add(queToSetValue.replaceAll('\\s+', '_'));
                queCcSet.add(queCcSetValue.replaceAll('\\s+', '_'));
            }
            System.debug('$To Queue:'+queToSet+' Cc Queue:'+queCcSet);
            
            //Sharing the recrd & setting Accessibillity via Apex.
            List<PPR_Line_Item__Share> shareListTobeInserted = new List<PPR_Line_Item__Share>();
            
            //To Map w/ queue Id
            Map<String, Id> queNameToIdMap = new Map<String,Id>();
            for(Group objGrp: [SELECT Id, Name, DeveloperName, Email, Type FROM Group where Type='Queue' And DeveloperName IN: queToSet]){
                queNameToIdMap.put(objGrp.DeveloperName, objGrp.Id);
            }
            System.debug('==queNameToIdMap=='+queNameToIdMap);
            //Cc Map w/ queue Id
            Map<String, Id> queNameCcIdMap = new Map<String, Id>();
            for(Group objGrp: [SELECT Id, Name, DeveloperName, Email, Type FROM Group where Type='Queue' And DeveloperName IN: queCcSet]){
                queNameCcIdMap.put(objGrp.DeveloperName, objGrp.Id);
            }
            
            // AK Changes 02/05/2023 Start
            List<User_Mappings__c> sboUserMapRec = new List<User_Mappings__c>([Select Id,Object_Name__c,PMG__c,User__c,User_Type__c from User_Mappings__c 
                                              Where Object_Name__c = 'PPR_Line_Item__c' 
                                              AND User_Type__c = 'SBO' 
                                              AND PMG__c =: pprList[0].PMG__c]);
            if(sboUserMapRec.size() > 0){
                PPR_Line_Item__Share shareToSBO = new PPR_Line_Item__Share();
                shareToSBO.ParentId = pprList[0].Id;               
                shareToSBO.UserOrGroupId = sboUserMapRec[0].User__c;
                shareToSBO.AccessLevel = 'Edit';
                system.debug('shareToSBO =>'+shareToSBO);
                if (shareToSBO != NULL)
                    insert shareToSBO;
            }            
            
            // AK Changes 02/05/2023 End*/ 
            
            
            //Sharing Records.
            for(PPR_Line_Item__c objPPrLi: pprList){
                String pmg = objPPrLi.PMG__c;
                String compCode = objPPrLi.Company_Code__c;
                String queueNameTo = pmg+'_PPR_CCM_'+compCode+'_To';
                queueNameTo = queueNameTo.replaceAll('\\s+', '_');
                String queueNameCc = pmg+'_PPR_CCM_'+compCode+'_Cc';
                queueNameCc = queueNameCc.replaceAll('\\s+', '_');
                system.debug('===queueNameTo=='+queueNameTo);
                system.debug('---'+queNameToIdMap.get(queueNameTo));
                //Share record w/ To Queue
                PPR_Line_Item__Share shareTo = new PPR_Line_Item__Share();
                shareTo.ParentId = objPPrLi.Id;
                if (queNameToIdMap.containsKey(queueNameTo)){
                    shareTo.UserOrGroupId = queNameToIdMap.get(queueNameTo);
                    System.debug('$ToQueID: '+queNameCcIdMap.get(queueNameTo));
                     shareTo.AccessLevel = 'Edit';
                    shareListTobeInserted.add(shareTo);
                    System.debug('$Record Name Shared w/ ToQueue:'+objPPrLi.Name);
                }
               
                    
                
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
                TegaUtility.trackLogs(e,'userCCMApproval','Id');
            }
            retToFlow.add('true');
        }
        else{
            System.debug('$product missing in PPR product relationship object');
            retToFlow.add('false');
        }
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'PPRApprovalProccess',  'userCCMApproval');
        }
        return retToFlow;
    }
}