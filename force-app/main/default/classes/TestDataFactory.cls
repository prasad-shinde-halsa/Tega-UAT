/**
 * Generic test data helper. Given an sObject API name, inspects its schema
 * and populates every required (not-nillable, createable, not-defaulted-on-create)
 * field with a reasonable dummy value. Reference fields are satisfied by
 * recursively building AND INSERTING a minimal parent record first, then using
 * its Id. This is meant to unblock "REQUIRED_FIELD_MISSING" errors in test
 * classes without having to manually chase every object in a lookup chain.
 *
 * LIMITATIONS (by design - this is a best-effort generic fallback, not a
 * replacement for real test data where business logic depends on specific values):
 *  - Does not know about validation rules. If a required field (or a field a
 *    validation rule depends on) needs a specific format/pattern (e.g. a
 *    "Customer Code" that must match CTxxxx), this factory's random value will
 *    fail that validation rule. You'll see a different error
 *    (FIELD_CUSTOM_VALIDATION_EXCEPTION) rather than REQUIRED_FIELD_MISSING -
 *    if that happens, override that specific field's value via the
 *    `overrides` map param rather than trying to make the factory smarter.
 *  - Dependent/controlling picklists are not resolved - it just picks the
 *    first active value of the required picklist, which may not be a valid
 *    combination if another field controls it.
 *  - Polymorphic lookups (e.g. OwnerId on some objects) and RecordType
 *    lookups are skipped rather than guessed.
 *  - Circular required references between two custom objects will resolve to
 *    null for the second occurrence (guarded via a recursion set) rather than
 *    infinite-looping - if you hit that, the two objects have a real required
 *    circular dependency and need manual handling (e.g. insert one first,
 *    then update the other).
 */
public class TestDataFactory {

    private static Set<String> inProgress = new Set<String>();

    public static SObject createWithRequiredFields(String sObjectApiName) {
        return createWithRequiredFields(sObjectApiName, new Map<String, Object>());
    }

    /**
     * @param sObjectApiName  e.g. 'DC_Budget_Line_Items__c'
     * @param overrides       field API name -> value, takes precedence over the
     *                        auto-generated value (use this to satisfy validation
     *                        rules the factory can't know about, e.g.
     *                        new Map<String, Object>{ 'Customer_Code__c' => 'CT0001' })
     * Does NOT insert the returned record - the caller decides when to insert it.
     * Any required PARENT records discovered along the way ARE inserted
     * immediately, since their Id is needed to populate the lookup field.
     */
    public static SObject createWithRequiredFields(String sObjectApiName, Map<String, Object> overrides) {
        if (inProgress.contains(sObjectApiName)) {
            // Circular required reference - bail out rather than recurse forever.
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

    private static Object buildValueForField(Schema.DescribeFieldResult dfr) {
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
                // Best effort - these need org-specific knowledge, skip rather than guess.
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
            // Booleans are never non-nillable in Salesforce (they default to false),
            // so isRequiredField should already exclude these - this is a safety net.
            return false;
        }

        return null;
    }

    public class TestDataFactoryException extends Exception {}
}