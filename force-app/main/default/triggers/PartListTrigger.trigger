trigger PartListTrigger on Part_List__c (before update) {

    for (Part_List__c part : Trigger.new) {
        part.PLM_Last_Updated_Date__c = Trigger.oldMap.get(part.Id).LastModifiedDate;
    }

}