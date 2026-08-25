trigger QuoteLineItemTrigger on QuoteLineItem (
    after insert,
    after update,
    after delete,
    after undelete
) {

    Set<Id> quoteIds = new Set<Id>();

    // Insert / Update / Undelete
    if(Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete){

        for(QuoteLineItem qli : Trigger.new){

            if(qli.QuoteId != null){
                quoteIds.add(qli.QuoteId);
            }
        }
    }

    // Delete
    if(Trigger.isDelete){

        for(QuoteLineItem qli : Trigger.old){

            if(qli.QuoteId != null){
                quoteIds.add(qli.QuoteId);
            }
        }
    }

    // Get all quote line items
    Map<Id, Set<String>> quoteSettingMap = new Map<Id, Set<String>>();

    for(QuoteLineItem qli : [

        SELECT Id,
               QuoteId,
               settingType__c
        FROM QuoteLineItem
        WHERE QuoteId IN :quoteIds
    ]){

        if(String.isNotBlank(qli.settingType__c)){

            if(!quoteSettingMap.containsKey(qli.QuoteId)){
                quoteSettingMap.put(qli.QuoteId, new Set<String>());
            }

            // Multi picklist split
            List<String> values = qli.settingType__c.split(';');

            quoteSettingMap.get(qli.QuoteId).addAll(values);
        }
    }

    List<Quote> quotesToUpdate = new List<Quote>();

    for(Id qId : quoteIds){

        String finalValue = '';

        if(quoteSettingMap.containsKey(qId)){

            finalValue = String.join(
                new List<String>(quoteSettingMap.get(qId)),
                ';'
            );
        }

        quotesToUpdate.add(new Quote(
            Id = qId,
            settingType__c = finalValue
        ));
    }

    if(!quotesToUpdate.isEmpty()){
        update quotesToUpdate;
    }
}