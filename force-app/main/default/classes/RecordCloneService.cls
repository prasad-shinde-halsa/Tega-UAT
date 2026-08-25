/**
 * RecordCloneService
 *
 * This class is designed to be called from a Flow.
 * It clones a given record (any SObject) and returns the Id of the cloned record.
 * While cloning, it replaces the Budget__c field with a Budget Id that is passed from Flow.
 *
 * Key Behaviors:
 * - Takes a source record Id and a Budget Id from Flow.
 * - Dynamically queries all fields (excluding formula and auto-number fields).
 * - Creates a clone of the source record.
 * - Overrides the Budget__c field on the cloned record with the input Budget Id.
 * - Returns the Id of the cloned record back to Flow.
 * Author - Reetabrata
 * Created Date - 2nd Sep 2025
 * Test Class - RecordCloneServiceTest
 */



public class RecordCloneService {

    /**
     * Input wrapper for Flow
     * Flow must pass:
     *  - recordId: the Id of the record to be cloned
     *  - budgetId: the Id to populate into Budget__c on the cloned record
     */
    public class CloneRequest {
        @InvocableVariable(required=true)
        public Id recordId;   // Record Id passed from Flow
        
        @InvocableVariable(required=true)
        public Id budgetId;   // Budget Id from Flow
        
        @InvocableVariable(required=true)
        public String budgetMonth;   // Budget Month from Flow
        
        @InvocableVariable(required=true)
        public Decimal budgetValue; // Budget Value from Flow
    }
    /**
     * Output wrapper for Flow
     * Returns the Id of the newly cloned record
     */
    public class CloneResponse {
        @InvocableVariable
        public Id clonedRecordId; // Return cloned record Id to Flow
    }
    /**
     * Invocable method that Flow can call.
     *
     * @param requests - list of CloneRequest (Flow will generally pass one item)
     * @return list of CloneResponse containing cloned record Id(s)
     */
    @InvocableMethod(label='Clone Record' description='Clones a record and returns the cloned record Id')
    public static List<CloneResponse> cloneRecords(List<CloneRequest> requests) {
        
       List<CloneResponse> responses = new List<CloneResponse>();
        if (requests.isEmpty() || requests[0].recordId == null) {
            return responses;
        }

        CloneRequest req = requests[0];

        Id sourceId = req.recordId;
        Id budgetId = req.budgetId;

        Schema.SObjectType sObjType = sourceId.getSObjectType();
        Schema.DescribeSObjectResult describe = sObjType.getDescribe();

        // Build field list dynamically (exclude formula + autonumber fields)
        List<String> fieldNames = new List<String>();
        for (Schema.SObjectField field : describe.fields.getMap().values()) {
            Schema.DescribeFieldResult fDescribe = field.getDescribe();
            if (!fDescribe.isCalculated() && !fDescribe.isAutoNumber()) {
                fieldNames.add(fDescribe.getName());
            }
        }

        // Query source record
        String soql = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + describe.getName() + ' WHERE Id = :sourceId';
        SObject sourceRecord = Database.query(soql);

        // Clone
        SObject clonedRecord = sourceRecord.clone(false, true, false, false);

        // Override Budget__c
        if (clonedRecord.getSObjectType().getDescribe().fields.getMap().containsKey('Budget__c')) {
            clonedRecord.put('Budget__c', budgetId);
        }

        // --- Handle Month + Budget Value ---
        Map<String, String> monthFieldMap = new Map<String, String>{
            'Apr' => 'Apr_Order__c',
            'May' => 'May_Order__c',
            'Jun' => 'Jun_Order__c',
            'Jul' => 'Jul_Order__c',
            'Aug' => 'Aug_Order__c',
            'Sep' => 'Sep_Order__c',
            'Oct' => 'Oct_Order__c',
            'Nov' => 'Nov_Order__c',
            'Dec' => 'Dec_Order__c',
            'Jan' => 'Jan_Order__c',
            'Feb' => 'Feb_Order__c',
            'Mar' => 'Mar_Order__c'
        };

        if (req.budgetMonth != null && monthFieldMap.containsKey(req.budgetMonth)) {
            String targetField = monthFieldMap.get(req.budgetMonth);

            // Set target month field = budget value
            clonedRecord.put(targetField, req.budgetValue);

            // Reset all other months = 0
            for (String fieldName : monthFieldMap.values()) {
                if (fieldName != targetField) {
                    if (clonedRecord.getSObjectType().getDescribe().fields.getMap().containsKey(fieldName)) {
                        clonedRecord.put(fieldName, 0);
                    }
                }
            }
        }

        insert clonedRecord;

        CloneResponse res = new CloneResponse();
        res.clonedRecordId = clonedRecord.Id;
        responses.add(res);

        return responses;
    
    }
}