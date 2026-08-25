public class PPRRcaValidationCheck {
    @InvocableMethod
    public static List<String> rcaValidationCheck(List<List<String>> ubList){
        List<String> retToFlow = new List<String>();
        try{
        //getting List back from flow Apex Action.
        List<String> ubIdList =  ubList[0];
        System.debug('#ubIdList:'+ubIdList);
        
        //Storing recordId of the record coming from flow to variable.
        String recordId = ubIdList[0];
        System.debug('#recordId:'+recordId);
        
        //get Task associated w/ Case
        List<Task> taskList = [SELECT Id, WhatId, Subject, Department_Name__c, PPR_Line_Item__r.Id FROM Task WHERE WhatId =: recordId];
        if (taskList != NULL){
            System.debug('$taskList:'+taskList);  
        }
        else{
            System.debug('Tasks not Created.');
        }
        
        
        //get PPR_Line_Item__c record
        List<PPR_Line_Item__c> pprLineItemList = [SELECT Id, IsDeleted, Name, Installed__c, Description_of_Problem__c, 
                                                  Cause_Give_Your_Opinion__c, Suggested_action__c, FRO_required_for_this_item__c, SAP_Quantity__c, 
                                                  Installation_date__c, PMG__c, Drafting_Dept__c, Failure_Category__c, Quality_QC__c, Quality_QA__c, 
                                                  Sales__c, Drawing_Change__c, Purchase__c, Logistics__c, Sales_Back_Office__c, TSS__c, Offer_Team__c, Manufacturing__c, 
                                                  Others__c, Drafting_Dept_RCA__c, Quality_QC_RCA__c, Quality_QA_RCA__c, Sales_RCA__c, Drawing_Change_RCA__c, 
                                                  Purchase_RCA__c, Logistics_RCA__c, Sales_Back_Office_RCA__c, TSS_RCA__c, Offer_Team_RCA__c, Manufacturing_RCA__c, 
                                                  Others_RCA__c, Status__c, FRO_Details__c, FRO_Value__c, FRO_Date__c, FRO_Number__c 
                                                  FROM PPR_Line_Item__c WHERE Id =: recordId];
        
        //create List to store the labels of the Checked checboxes.
        //List<String> checkedFields = new List <String>();
        
        //create Map<Id, List<String>> to store the PPR_Line_Item__c Id & it's checked RCA fields label.
        Map<Id, List<String>> pprRcaMap = new Map<Id,List<String>>();
        for (PPR_Line_Item__c objPPR: pprLineItemList){
            
            //getting RCA FieldSet from RCA_Fields on PPR_Line_Item__c obj
            Schema.FieldSet rcaFS = Schema.SObjectType.PPR_Line_Item__c.fieldsets.RCA_Fields;
            
            //Iterate over fields in the fieldset.
            for (Schema.FieldSetMember fieldSetRCA: rcaFS.getFields()){
                if (fieldSetRCA.getType()==Schema.DisplayType.BOOLEAN){
                    // Check if the field is Checkbox
                    String fieldname = fieldSetRCA.getFieldpath();
                    Boolean isChecked =(Boolean)objPPR.get(fieldName);
                    if (isChecked){
                        if(!pprRcaMap.containsKey(objPPR.Id)){
                            List<String> rcaCheckedFieldsList = new List<String>();
                            rcaCheckedFieldsList.add(fieldSetRCA.getLabel());
                            pprRcaMap.put(objPPR.Id,rcaCheckedFieldsList);
                        }else if(pprRcaMap.containsKey(objPPR.Id)){
                            List<String> rcaCheckedFieldsList = pprRcaMap.get(objPPR.Id);
                            rcaCheckedFieldsList.add(fieldSetRCA.getLabel());
                            pprRcaMap.put(objPPR.Id,rcaCheckedFieldsList);
                        }
                    }
                }
            }
        }
        if (pprRcaMap != NULL){
            System.debug('$pprRcaMap:'+pprRcaMap);
        }else {
            System.debug('$pprRcaMap: RCA not Filled.');
        }
        
        
        //Prepare Map<Id,List<Task>> to store PPR_Line_Item__c.Id & related LongTermTask.
        Map <Id, List<String>> pprTaskDeptMap = new Map<Id, List<String>>();
        for (Task objTask : taskList){
            //variable declaration
            String deptval;
            String label;
            if (!pprTaskDeptMap.containsKey(objTask.PPR_Line_Item__r.Id) && objTask.Subject == 'Long Term'){
                List<String> longTermTaskList = new List<String>();
                //
                deptval = objTask.Department_Name__c;
                if (deptval != NULL){
                    Schema.DescribeFieldResult deptField = Task.Department_Name__c.getDescribe();
                    List <Schema.PicklistEntry> deptEntry = deptField.getPicklistValues();
                    for (Schema.PicklistEntry pickEntry : deptEntry){
                        if (pickEntry.getValue() == deptval){
                            label = pickEntry.getLabel();
                        }
                    }
                }
                //
                longTermTaskList.add(label);
                pprTaskDeptMap.put(objTask.PPR_Line_Item__r.Id,longTermTaskList);
            }else if(pprTaskDeptMap.containsKey(objTask.PPR_Line_Item__r.Id) && objTask.Subject == 'Long Term'){
                List<String> longTermTaskList = pprTaskDeptMap.get(objTask.PPR_Line_Item__r.Id);
                //
                deptval = objTask.Department_Name__c;
                if (deptval != NULL){
                    Schema.DescribeFieldResult deptField = Task.Department_Name__c.getDescribe();
                    List <Schema.PicklistEntry> deptEntry = deptField.getPicklistValues();
                    for (Schema.PicklistEntry pickEntry : deptEntry){
                        if (pickEntry.getValue() == deptval){
                            label = pickEntry.getLabel();
                        }
                    }
                }
                //
                longTermTaskList.add(label);
                pprTaskDeptMap.put(objTask.PPR_Line_Item__r.Id,longTermTaskList);
            }
        }
        if (pprTaskDeptMap != NULL){
            System.debug('$pprTaskDeptMap:'+pprTaskDeptMap);
        } else {
            System.debug('$pprTaskDeptMap: CAPA not created.');
        }
        
        ///////////////
        //Prepare Map<Id,List<Task>> to store PPR_Line_Item__c.Id & related ShortTermTask.
        Map <Id, List<String>> pprSTTaskDeptMap = new Map<Id, List<String>>();
        for (Task objTasks : taskList){
            //variable declaration
            String deptval;
            String label;
            if (!pprSTTaskDeptMap.containsKey(objTasks.PPR_Line_Item__r.Id) && objTasks.Subject == 'Short Term'){
                List<String> shortTermTaskList = new List<String>();
                //
                deptval = objTasks.Department_Name__c;
                if (deptval != NULL){
                    Schema.DescribeFieldResult deptField = Task.Department_Name__c.getDescribe();
                    List <Schema.PicklistEntry> deptEntry = deptField.getPicklistValues();
                    for (Schema.PicklistEntry pickEntry : deptEntry){
                        if (pickEntry.getValue() == deptval){
                            label = pickEntry.getLabel();
                        }
                    }
                }
                //
                shortTermTaskList.add(label);
                pprSTTaskDeptMap.put(objTasks.PPR_Line_Item__r.Id,shortTermTaskList);
            }else if(pprSTTaskDeptMap.containsKey(objTasks.PPR_Line_Item__r.Id) && objTasks.Subject == 'Short Term'){
                List<String> shortTermTaskList = pprSTTaskDeptMap.get(objTasks.PPR_Line_Item__r.Id);
                //
                deptval = objTasks.Department_Name__c;
                if (deptval != NULL){
                    Schema.DescribeFieldResult deptField = Task.Department_Name__c.getDescribe();
                    List <Schema.PicklistEntry> deptEntry = deptField.getPicklistValues();
                    for (Schema.PicklistEntry pickEntry : deptEntry){
                        if (pickEntry.getValue() == deptval){
                            label = pickEntry.getLabel();
                        }
                    }
                }
                //
                shortTermTaskList.add(label);
                pprSTTaskDeptMap.put(objTasks.PPR_Line_Item__r.Id,shortTermTaskList);
            }
        }
        if (pprSTTaskDeptMap != NULL){
            System.debug('$pprSTTaskDeptMap:'+pprSTTaskDeptMap);
        } 
        ////////////////
        
        // Compare pprRcaMap && pprTaskMap
        for (Id id: pprRcaMap.keySet()){
            if(id != NULL){
                List<String> rcaList = pprRcaMap.get(id);
                List<String> pprLTtaskList = new list<String>();
                if(pprTaskDeptMap.containsKey(id))  
                    pprLTtaskList = pprTaskDeptMap.get(id);
                if (pprSTTaskDeptMap != NULL){
                    List<String> pprSTtaskList = pprSTTaskDeptMap.get(id);
                    if (pprTaskDeptMap.containsKey(id) && (pprRcaMap.get(id).size() == pprTaskDeptMap.get(id).size())){
                        System.debug('#Submit to CCM');
                        retToFlow.add('Submit');
                    }else if (pprLTtaskList == NULL){
                        System.debug('#Long term CAPA Missing @ppr: '+id);
                        if (pprSTtaskList != NULL){
                            Set<String> rcaList1 = new Set<String>(pprSTtaskList);
                            System.debug('$rcaList1'+rcaList1);
                            if(pprLTtaskList != NULL){
                                rcaList1.removeAll(pprLTtaskList);
                                System.debug('$rcaList1'+rcaList1);
                            }
                            List<String> rcaList2 = new List<String>(rcaList1);
                            String oddVal = String.join(rcaList2, ',');
                            if (oddval != NULL){
                                retToFlow.add(oddVal);
                                System.debug('$retToFlow:'+retToFlow);
                            }
                        }
                    }
                }
            }
        }
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'PPRRcaValidationCheck',  'rcaValidationCheck');
        }
        return retToFlow;
    }
}