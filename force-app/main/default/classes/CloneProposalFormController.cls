public with sharing class CloneProposalFormController {

    @AuraEnabled(cacheable=true)
    public static OpportunityInfo getOpportunityInfo(Id proposalFormId) {
        Proposal_Form__c pf = [
            SELECT Id,
                   Opportunity__c,
                   Opportunity__r.Name,
                   Opportunity__r.StageName,
                   Opportunity__r.IsClosed,
                   Opportunity__r.AccountId          //  added
            FROM Proposal_Form__c
            WHERE Id = :proposalFormId
            LIMIT 1
        ];

        OpportunityInfo info = new OpportunityInfo();
        info.opportunityId   = pf.Opportunity__c;
        info.opportunityName = pf.Opportunity__r?.Name;
        info.stageName       = pf.Opportunity__r?.StageName;
        info.isClosed        = pf.Opportunity__r != null && pf.Opportunity__r.IsClosed;
        info.customerNameId  = pf.Opportunity__r?.AccountId;  //  added
        return info;
    }

    @AuraEnabled
    public static Id cloneRecord(Id sourceId, Id newOpportunityId) {
        Map<String, Schema.SObjectField> fieldMap =
            Schema.SObjectType.Proposal_Form__c.fields.getMap();

        List<String> queryFields = new List<String>();
        Set<String>  skipFields  = new Set<String>();

        for (String f : fieldMap.keySet()) {
            Schema.DescribeFieldResult fd = fieldMap.get(f).getDescribe();
            if (!fd.isAccessible()) continue;
            if (fd.isAutoNumber() || !fd.isCreateable() || fd.isUnique()) {
                skipFields.add(f);
                continue;
            }
            queryFields.add(f);
        }

        String soql = 'SELECT ' + String.join(queryFields, ',') +
                      ' FROM Proposal_Form__c WHERE Id = :sourceId LIMIT 1';
        SObject original = Database.query(soql);
        SObject cloned   = original.clone(false, true, false, false);

        for (String f : skipFields) {
            try { cloned.put(f, null); } catch (Exception e) { }
        }

        cloned.put('Tega_App_PRF_Number__c', null);
        cloned.put('DC_Budget_Line_Items__c', null);

        if (newOpportunityId != null) {
            cloned.put('Opportunity__c', newOpportunityId);
        }

        cloned.put('Is_Cloned_PRF__c', true);

        Database.SaveResult sr = Database.insert(cloned, false);

        if (!sr.isSuccess()) {
            List<String> errors = new List<String>();
            for (Database.Error err : sr.getErrors()) {
                errors.add(err.getMessage());
            }
            throw new AuraHandledException(String.join(errors, '\n'));
        }

        return cloned.Id;
    }

    // Fixed: added accountId param + RecordType + Account fields
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> searchOpportunities(String keyword, Id accountId) {
        String searchKey = '%' + keyword + '%';
        if (accountId != null) {
            return [
                SELECT Id, Name, StageName, CloseDate,
                       RecordType.Name,
                       Account.Name
                FROM Opportunity
                WHERE IsClosed = false
                  AND AccountId = :accountId
                  AND Name LIKE :searchKey
                ORDER BY Name ASC
                LIMIT 10
            ];
        } else {
            return [
                SELECT Id, Name, StageName, CloseDate,
                       RecordType.Name,
                       Account.Name
                FROM Opportunity
                WHERE IsClosed = false
                  AND Name LIKE :searchKey
                ORDER BY Name ASC
                LIMIT 10
            ];
        }
    }

    public class OpportunityInfo {
        @AuraEnabled public Id      opportunityId;
        @AuraEnabled public String  opportunityName;
        @AuraEnabled public String  stageName;
        @AuraEnabled public Boolean isClosed;
        @AuraEnabled public Id      customerNameId;   // added
    }
}