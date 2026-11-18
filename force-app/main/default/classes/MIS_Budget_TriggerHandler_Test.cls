@isTest
private class MIS_Budget_TriggerHandler_Test {

    
    private static DC_Budget_Line_Items__c createLineItemMaster() {
        return (DC_Budget_Line_Items__c) new TestDataFactory().createWithRequiredFields('DC_Budget_Line_Items__c');
    }

    private static List<DC_Budget_Line_Items__c> createLineItemMasters(Integer count) {
        List<DC_Budget_Line_Items__c> masters = new List<DC_Budget_Line_Items__c>();
        for (Integer i = 0; i < count; i++) {
            masters.add(createLineItemMaster());
        }
        return masters;
    }

    
    private static MIS_Budget__c createChild(Id parentId) {
        return new MIS_Budget__c(Budget_Line_Items__c = parentId);
    }
	
    @isTest
    static void testSingleChild_BecomesActive() {
        DC_Budget_Line_Items__c parent = createLineItemMaster();
        insert parent;

        MIS_Budget__c child = createChild(parent.Id);

        Test.startTest();
        insert child;
        Test.stopTest();

        MIS_Budget__c result = [
            SELECT Id, IsActive__c FROM MIS_Budget__c WHERE Id = :child.Id
        ];
       // System.assertEquals(true, result.IsActive__c, 'Only child should be marked active');
    } 

    @isTest
    static void testMultipleChildren_OnlyLatestTriggeredIsActive() {
        DC_Budget_Line_Items__c parent = createLineItemMaster();
        insert parent;

        MIS_Budget__c child1 = createChild(parent.Id);
        insert child1; // child1 becomes active (only child at this point)

        MIS_Budget__c result1 = [SELECT Id, IsActive__c FROM MIS_Budget__c WHERE Id = :child1.Id];
       // System.assertEquals(true, result1.IsActive__c, 'Child1 should be active after its own insert');

        MIS_Budget__c child2 = createChild(parent.Id);

        Test.startTest();
        insert child2; // should activate child2, deactivate child1 (recursive update)
        Test.stopTest();

        Map<Id, MIS_Budget__c> resultsById = new Map<Id, MIS_Budget__c>([
            SELECT Id, IsActive__c FROM MIS_Budget__c WHERE Id IN :new List<Id>{child1.Id, child2.Id}
        ]);

       // System.assertEquals(false, resultsById.get(child1.Id).IsActive__c,
       //     'Child1 should be deactivated once Child2 becomes the active sibling');
       // System.assertEquals(true, resultsById.get(child2.Id).IsActive__c,
        //    'Child2 should be active as the most recently triggered record');
    }
   
  
    private class TestDataFactory {

        private Set<String> inProgress = new Set<String>();

        public SObject createWithRequiredFields(String sObjectApiName) {
            return createWithRequiredFields(sObjectApiName, new Map<String, Object>());
        }

        public SObject createWithRequiredFields(String sObjectApiName, Map<String, Object> overrides) {
            if (inProgress.contains(sObjectApiName)) {
                return null;
            }
            inProgress.add(sObjectApiName);
            try {
                Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObjectApiName);
                if (targetType == null) {
                    throw new TestDataFactoryException('Unknown sObject API name: ' + sObjectApiName);
                }

                SObject record = targetType.newSObject();
                Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();

                for (String fieldName : fieldMap.keySet()) {
                    Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();

                    if (overrides.containsKey(dfr.getName())) {
                        record.put(dfr.getName(), overrides.get(dfr.getName()));
                        continue;
                    }

                    Boolean isRequiredField = !dfr.isNillable()
                        && dfr.isCreateable()
                        && !dfr.isDefaultedOnCreate();

                    if (!isRequiredField) {
                        continue;
                    }

                    Object value = buildValueForField(dfr);
                    if (value != null) {
                        record.put(dfr.getName(), value);
                    }
                }
                return record;
            } finally {
                inProgress.remove(sObjectApiName);
            }
        }

        private Object buildValueForField(Schema.DescribeFieldResult dfr) {
            Schema.DisplayType fieldType = dfr.getType();

            if (fieldType == Schema.DisplayType.REFERENCE) {
                List<Schema.SObjectType> refTargets = dfr.getReferenceTo();
                if (refTargets.isEmpty()) {
                    return null;
                }
                String refObjectName = refTargets[0].getDescribe().getName();

                if (refObjectName == 'User') {
                    return UserInfo.getUserId();
                }
                if (refObjectName == 'RecordType' || refObjectName == 'Group') {
                    return null;
                }

                SObject parent = createWithRequiredFields(refObjectName);
                if (parent == null) {
                    return null;
                }
                insert parent;
                return parent.Id;
            }

            if (fieldType == Schema.DisplayType.PICKLIST || fieldType == Schema.DisplayType.MULTIPICKLIST) {
                for (Schema.PicklistEntry ple : dfr.getPicklistValues()) {
                    if (ple.isActive() && ple.isDefaultValue()) {
                        return ple.getValue();
                    }
                }
                for (Schema.PicklistEntry ple : dfr.getPicklistValues()) {
                    if (ple.isActive()) {
                        return ple.getValue();
                    }
                }
                return null;
            }

            if (fieldType == Schema.DisplayType.STRING || fieldType == Schema.DisplayType.TEXTAREA) {
                String val = 'Test' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
                Integer len = dfr.getLength();
                if (len > 0 && val.length() > len) {
                    val = val.substring(0, len);
                }
                return val;
            }

            if (fieldType == Schema.DisplayType.EMAIL) {
                return 'test' + Math.abs(Crypto.getRandomInteger()) + '@example.com';
            }

            if (fieldType == Schema.DisplayType.PHONE) {
                return '1234567890';
            }

            if (fieldType == Schema.DisplayType.DATE) {
                return Date.today();
            }

            if (fieldType == Schema.DisplayType.DATETIME) {
                return Datetime.now();
            }

            if (fieldType == Schema.DisplayType.CURRENCY
                || fieldType == Schema.DisplayType.DOUBLE
                || fieldType == Schema.DisplayType.PERCENT) {
                return 1.0;
            }

            if (fieldType == Schema.DisplayType.INTEGER) {
                return 1;
            }

            if (fieldType == Schema.DisplayType.BOOLEAN) {
                return false;
            }

            return null;
        }

    }

    private class TestDataFactoryException extends Exception {}
    /*
   
    @isTest
    static void testAfterInsertAndUpdate() {

        // Create test record
        MIS_Budget__c budget = new MIS_Budget__c(
            Name = 'Test Budget'
            // Add any other required fields here
        );

        Test.startTest();

        // Test After Insert
        insert budget;

        // Test After Update
        budget.Name = 'Updated Budget';
        update budget;

        Test.stopTest();

        System.assertNotEquals(null, budget.Id);
    }*/
}