/******************************************************************************************************************
Class Name  : DcBudgetLWCController
Description : This class is responsible for Data table management in Tega for 14 lwc component .
Date        : 20 Nov 2024.
Author      : Reetabrata
Test class. : DcBudgetLWCControllerTest
*******************************************************************************************************************/

public class DcBudgetLWCController {
    
    // For fetching the picklist values of Order Type
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistValuesLwc(String ObjectApi_name, String Field_name) {
        List<Map<String, String>> lstPickvals = new List<Map<String, String>>();
        
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);
        SObject Object_name = targetType.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType(); 
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
        List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues();
        
        for (Schema.PicklistEntry a : pick_list_values) {
            Map<String, String> picklistEntry = new Map<String, String>();
            picklistEntry.put('label', a.getLabel().trim());  // Label as displayed in the UI
            picklistEntry.put('value', a.getValue().trim());  // API value used in comparisons
            lstPickvals.add(picklistEntry);
        }
        
        return lstPickvals;
    }
    //Get All Budget Line Items with specific profile
    @AuraEnabled
    public static List<DC_Budget_Line_Items__c> getDCBudgetLineItems(String DCBudgetId, String UserId) {
        List<DC_Budget_Line_Items__c> DCBudgetLineItemsList = new List<DC_Budget_Line_Items__c>();
        String ProfileName;
        system.debug('User Id '+UserId);
        system.debug('DCBudgetId '+DCBudgetId);
        
        User userRecord = [
            SELECT Profile.Name 
            FROM User 
            WHERE Id = :UserId
            LIMIT 1
        ];
        ProfileName = userRecord.Profile.Name;
        system.debug('ProfileName '+ProfileName);
        // Profile-specific logic
        if (ProfileName == 'PMG') {
            List<PMG_Mapping__mdt> pmgMappings = new List<PMG_Mapping__mdt>();
            // Query PMG_Mapping__mdt to get the relevant PMG__c value
            List<PMG_Mapping__mdt> pmgMappings_ApproverList = [
                SELECT PMG__c 
                FROM PMG_Mapping__mdt 
                WHERE PMG_Approver_ID__c = :UserId
            ];

            List<PMG_Mapping__mdt> pmgMappings_HeadList = [
                SELECT PMG__c 
                FROM PMG_Mapping__mdt 
                WHERE PMG_Head_ID__c = :UserId
            ];

            if(!pmgMappings_ApproverList.isEmpty()) pmgMappings.addAll(pmgMappings_ApproverList);
            if(!pmgMappings_HeadList.isEmpty()) pmgMappings.addAll(pmgMappings_HeadList);

            system.debug('pmgMappings '+pmgMappings);
            if (!pmgMappings.isEmpty()) {
                // Extract the PMG__c value(s) from the metadata
                Set<String> pmgNames = new Set<String>();
                for (PMG_Mapping__mdt mapping : pmgMappings) {
                    pmgNames.add(mapping.PMG__c);
                }
                system.debug('pmgNames '+pmgNames);
                // Query DC_Budget_Line_Items__c based on PMG_Master__r.Name matching PMG__c values
                DCBudgetLineItemsList = [
                    SELECT Id, Name, Order_Type__c, Jan_Order__c, Feb_Order__c, Mar_Order__c, Apr_Order__c,Budget__c,Budget__r.RecordTypeId,
                    May_Order__c, Jun_Order__c, Jul_Order__c, Aug_Order__c, Sep_Order__c, Oct_Order__c,Customer__c,Created_by_PMG__c,
                    Nov_Order__c, Dec_Order__c, Total_Order__c, Customer__r.Name, CurrencyIsoCode, Product__r.Name,CreatedById,
                    Jan_Sales__c, Feb_Sales__c, Mar_Sales__c, Apr_Sales__c, May_Sales__c, Jun_Sales__c, CreatedDate,Modified_By__c,Version_Stage__c,
                    Jul_Sales__c, Aug_Sales__c, Sep_Sales__c, Oct_Sales__c, Nov_Sales__c, Dec_Sales__c, Total_Sales__c,Description__c,
                    PMG_Master__r.Name, PG_Master__r.Name, Application_Type_Master__r.Name,Customer_Name__c, Part_List__r.Name,Is_PMG_Label_Approved__c,
                    PMG_Master__c,PG_Master__c,Application_Type_Master__c,Part_List__c,Product__c,Budget__r.Status__c,Approval_Stage__c,
                    Order_Expected_Month__c,Order_Expected_Stage__c,Budget__r.Financial_Year__c,
                    /*Order_Expected_Stage_Jun__c, Order_Expected_Month_Jun__c,*/
                    Jul_Order_Actual__c, Jul_Order_Enquiry__c, Jul_Order_Lost__c, Jul_Order_Offer_In_Making__c, Jul_Order_Offer_Submitted__c,
                    /*Order_Expected_Stage_Jul__c, Order_Expected_Month_Jul__c,*/
                    May_Order_Actual__c, May_Order_Enquiry__c, May_Order_Lost__c, May_Order_Offer_In_Making__c, May_Order_Offer_Submitted__c,
                    /*Order_Expected_Stage_May__c, Order_Expected_Month_May__c,*/
                    Aug_Order_Actual__c, Aug_Order_Enquiry__c, Aug_Order_Lost__c, Aug_Order_Offer_In_Making__c, Aug_Order_Offer_Submitted__c,
                    /*Order_Expected_Stage_Aug__c, Order_Expected_Month_Aug__c,*/
                    Sep_Order_Actual__c, Sep_Order_Enquiry__c, Sep_Order_Lost__c, Sep_Order_Offer_In_Making__c, Sep_Order_Offer_Submitted__c,
                    /*Order_Expected_Stage_Sep__c, Order_Expected_Month_Sep__c,*/
                    Oct_Order_Actual__c, Oct_Order_Enquiry__c, Oct_Order_Lost__c, Oct_Order_Offer_In_Making__c, Oct_Order_Offer_Submitted__c,
                    /*Order_Expected_Stage_Oct__c, Order_Expected_Month_Oct__c,*/
                    Nov_Order_Actual__c, Nov_Order_Enquiry__c, Nov_Order_Lost__c, Nov_Order_Offer_In_Making__c, Nov_Order_Offer_Submitted__c,
                    /*Order_Expected_Stage_Nov__c, Order_Expected_Month_Nov__c,*/
                    Dec_Order_Actual__c, Dec_Order_Enquiry__c, Dec_Order_Lost__c, Dec_Order_Offer_In_Making__c, Dec_Order_Offer_Submitted__c,
                    /*Order_Expected_Stage_Dec__c, Order_Expected_Month_Dec__c,*/
                    Jan_Order_Actual__c, Jan_Order_Enquiry__c, Jan_Order_Lost__c, Jan_Order_Offer_In_Making__c, Jan_Order_Offer_Submitted__c,
                    /*Order_Expected_Stage_Jan__c, Order_Expected_Month_Jan__c,*/
                    Feb_Order_Actual__c, Feb_Order_Enquiry__c, Feb_Order_Lost__c, Feb_Order_Offer_In_Making__c, Feb_Order_Offer_Submitted__c,
                    /*Order_Expected_Stage_Feb__c, Order_Expected_Month_Feb__c,*/
                    Mar_Order_Actual__c, Mar_Order_Enquiry__c, Mar_Order_Lost__c, Mar_Order_Offer_In_Making__c, Mar_Order_Offer_Submitted__c,
                    /*Order_Expected_Stage_Mar__c, Order_Expected_Month_Mar__c,*/
                    Total_Order_Actual__c, Total_Order_Enquiry__c, Total_Order_Lost__c, Total_Order_Offer_In_Making__c, Total_Order_Offer_Submitted__c,
                    Total_Order_Actual_in_INR__c, Total_Order_Enquiry_In_INR__c, Total_Order_Lost_In_INR__c, Total_Order_Offer_In_Making_In_INR__c, Total_Order_Offer_Submitted_In_INR__c,
                    Address__c, Application_Type_Name__c, Customer_Name_Fo__c, Industry_Group_Fo__c, Item_Level_Fo__c,
                    Merged_Parent_Record_Name__c, PMG_Name__c, Part_List_Name__c, Product_Group_Name__c, Product_Name__c,
                    Apr_Order_Actual__c, April_Order_Enquiry__c, April_Order_Lost__c, April_Order_Offer_In_Making__c,
                    Jun_Order_Actual__c, Jun_Order_Enquiry__c, Jun_Order_Lost__c, Jun_Order_Offer_In_Making__c, Jun_Order_Offer_Submitted__c,
                    Previous_Version__c, Active_Status__c, Annual_Potential__c, Industry_Group__c, Item_Level__c, Status__c,
                    Competitor__c, Application_Type__c,
                    
                    (Select id, Order_Expected_Month_Apr__c,Order_Expected_Month_Aug__c,Order_Expected_Month_Dec__c,Order_Expected_Month_Feb__c,
                     Order_Expected_Month_Jan__c,Order_Expected_Month_Jul__c,Order_Expected_Month_Jun__c,Order_Expected_Month_Mar__c,Order_Expected_Month_May__c,
                     Order_Expected_Month_Nov__c,Order_Expected_Month_Oct__c,Order_Expected_Month_Sep__c,Order_Expected_Stage_Apr__c,Order_Expected_Stage_Aug__c,
                     Order_Expected_Stage_Dec__c,Order_Expected_Stage_Feb__c,Order_Expected_Stage_Jan__c,Order_Expected_Stage_Jul__c,Order_Expected_Stage_Jun__c,
                     Order_Expected_Stage_Mar__c,Order_Expected_Stage_May__c,Order_Expected_Stage_Nov__c,Order_Expected_Stage_Oct__c,Order_Expected_Stage_Sep__c,createdDate, Order_Type__c,
                     Expected_Order_Value_Mar__c, Expected_Order_Value_Jan__c, Expected_Order_Value_Feb__c, 
                     Expected_Order_Value_June__c, Expected_Order_Value_May__c, Expected_Order_Value_April__c, 
                     Expected_Order_Value_Jul__c, Expected_Order_Value_Dec__c, Expected_Order_Value_Nov__c, 
                     Expected_Order_Value_Oct__c, Expected_Order_Value_Sep__c, Expected_Order_Value_Aug__c,
                     Remarks_Jan__c, Remarks_Feb__c, Remarks_Mar__c, Remarks_Apr__c, Remarks_May__c, Remarks_Jun__c,
                     Remarks_Jul__c, Remarks_Aug__c, Remarks_Sep__c, Remarks_Oct__c, Remarks_Nov__c, Remarks_Dec__c from MIS_Budgets__r Order By createdDate DESC)
                    
                    FROM DC_Budget_Line_Items__c
                    WHERE Budget__c = :DCBudgetId
                    AND Active_Status__c = true
                    AND PMG_Master__r.Name IN :pmgNames
                    ORDER BY CreatedDate ASC
                ];
            }
        } else {
            // Default logic for non-PMG profiles
            DCBudgetLineItemsList = [
                SELECT Id, Name, Order_Type__c, Jan_Order__c, Feb_Order__c, Mar_Order__c, Apr_Order__c,Budget__c,Budget__r.RecordTypeId,
                May_Order__c, Jun_Order__c, Jul_Order__c, Aug_Order__c, Sep_Order__c, Oct_Order__c,Customer__c,Created_by_PMG__c,
                Nov_Order__c, Dec_Order__c, Total_Order__c, Customer__r.Name, CurrencyIsoCode, Product__r.Name,CreatedById,
                Jan_Sales__c, Feb_Sales__c, Mar_Sales__c, Apr_Sales__c, May_Sales__c, Jun_Sales__c, CreatedDate,Modified_By__c,Version_Stage__c,
                Jul_Sales__c, Aug_Sales__c, Sep_Sales__c, Oct_Sales__c, Nov_Sales__c, Dec_Sales__c, Total_Sales__c,Description__c,
                PMG_Master__r.Name, PG_Master__r.Name,Customer_Name__c, Application_Type_Master__r.Name, Part_List__r.Name,Is_PMG_Label_Approved__c,
                PMG_Master__c,PG_Master__c,Application_Type_Master__c,Part_List__c,Product__c,Budget__r.Status__c,Approval_Stage__c,
                Order_Expected_Month__c,Order_Expected_Stage__c,Budget__r.Financial_Year__c,
                /*Order_Expected_Stage_Jun__c, Order_Expected_Month_Jun__c,*/
                Jul_Order_Actual__c, Jul_Order_Enquiry__c, Jul_Order_Lost__c, Jul_Order_Offer_In_Making__c, Jul_Order_Offer_Submitted__c,
                /*Order_Expected_Stage_Jul__c, Order_Expected_Month_Jul__c,*/
                May_Order_Actual__c, May_Order_Enquiry__c, May_Order_Lost__c, May_Order_Offer_In_Making__c, May_Order_Offer_Submitted__c,
                /*Order_Expected_Stage_May__c, Order_Expected_Month_May__c,*/
                Aug_Order_Actual__c, Aug_Order_Enquiry__c, Aug_Order_Lost__c, Aug_Order_Offer_In_Making__c, Aug_Order_Offer_Submitted__c,
                /*Order_Expected_Stage_Aug__c, Order_Expected_Month_Aug__c,*/
                Sep_Order_Actual__c, Sep_Order_Enquiry__c, Sep_Order_Lost__c, Sep_Order_Offer_In_Making__c, Sep_Order_Offer_Submitted__c,
                /*Order_Expected_Stage_Sep__c, Order_Expected_Month_Sep__c,*/
                Oct_Order_Actual__c, Oct_Order_Enquiry__c, Oct_Order_Lost__c, Oct_Order_Offer_In_Making__c, Oct_Order_Offer_Submitted__c,
                /*Order_Expected_Stage_Oct__c, Order_Expected_Month_Oct__c,*/
                Nov_Order_Actual__c, Nov_Order_Enquiry__c, Nov_Order_Lost__c, Nov_Order_Offer_In_Making__c, Nov_Order_Offer_Submitted__c,
                /*Order_Expected_Stage_Nov__c, Order_Expected_Month_Nov__c,*/
                Dec_Order_Actual__c, Dec_Order_Enquiry__c, Dec_Order_Lost__c, Dec_Order_Offer_In_Making__c, Dec_Order_Offer_Submitted__c,
                /*Order_Expected_Stage_Dec__c, Order_Expected_Month_Dec__c,*/
                Jan_Order_Actual__c, Jan_Order_Enquiry__c, Jan_Order_Lost__c, Jan_Order_Offer_In_Making__c, Jan_Order_Offer_Submitted__c,
                /*Order_Expected_Stage_Jan__c, Order_Expected_Month_Jan__c,*/
                Feb_Order_Actual__c, Feb_Order_Enquiry__c, Feb_Order_Lost__c, Feb_Order_Offer_In_Making__c, Feb_Order_Offer_Submitted__c,
                /*Order_Expected_Stage_Feb__c, Order_Expected_Month_Feb__c,*/
                Mar_Order_Actual__c, Mar_Order_Enquiry__c, Mar_Order_Lost__c, Mar_Order_Offer_In_Making__c, Mar_Order_Offer_Submitted__c,
                /*Order_Expected_Stage_Mar__c, Order_Expected_Month_Mar__c,*/
                Total_Order_Actual__c, Total_Order_Enquiry__c, Total_Order_Lost__c, Total_Order_Offer_In_Making__c, Total_Order_Offer_Submitted__c,
                Total_Order_Actual_in_INR__c, Total_Order_Enquiry_In_INR__c, Total_Order_Lost_In_INR__c, Total_Order_Offer_In_Making_In_INR__c, Total_Order_Offer_Submitted_In_INR__c,
                Address__c, Application_Type_Name__c, Customer_Name_Fo__c, Industry_Group_Fo__c, Item_Level_Fo__c,
                Merged_Parent_Record_Name__c, PMG_Name__c, Part_List_Name__c, Product_Group_Name__c, Product_Name__c,
                Apr_Order_Actual__c, April_Order_Enquiry__c, April_Order_Lost__c, April_Order_Offer_In_Making__c,
                Jun_Order_Actual__c, Jun_Order_Enquiry__c, Jun_Order_Lost__c, Jun_Order_Offer_In_Making__c, Jun_Order_Offer_Submitted__c,
                Previous_Version__c, Active_Status__c, Annual_Potential__c, Industry_Group__c, Item_Level__c, Status__c,
                Competitor__c, Application_Type__c,
                
                (Select id, Order_Expected_Month_Apr__c,Order_Expected_Month_Aug__c,Order_Expected_Month_Dec__c,Order_Expected_Month_Feb__c,
                 Order_Expected_Month_Jan__c,Order_Expected_Month_Jul__c,Order_Expected_Month_Jun__c,Order_Expected_Month_Mar__c,Order_Expected_Month_May__c,
                 Order_Expected_Month_Nov__c,Order_Expected_Month_Oct__c,Order_Expected_Month_Sep__c,Order_Expected_Stage_Apr__c,Order_Expected_Stage_Aug__c,
                 Order_Expected_Stage_Dec__c,Order_Expected_Stage_Feb__c,Order_Expected_Stage_Jan__c,Order_Expected_Stage_Jul__c,Order_Expected_Stage_Jun__c,
                 Order_Expected_Stage_Mar__c,Order_Expected_Stage_May__c,Order_Expected_Stage_Nov__c,Order_Expected_Stage_Oct__c,Order_Expected_Stage_Sep__c,createdDate,
                 Remarks_Jan__c, Remarks_Feb__c, Remarks_Mar__c, Remarks_Apr__c, Remarks_May__c, Remarks_Jun__c,
                 Expected_Order_Value_Mar__c, Expected_Order_Value_Jan__c, Expected_Order_Value_Feb__c, 
                 Expected_Order_Value_June__c, Expected_Order_Value_May__c, Expected_Order_Value_April__c, 
                 Expected_Order_Value_Jul__c, Expected_Order_Value_Dec__c, Expected_Order_Value_Nov__c, 
                 Expected_Order_Value_Oct__c, Expected_Order_Value_Sep__c, Expected_Order_Value_Aug__c,
                 Remarks_Jul__c, Remarks_Aug__c, Remarks_Sep__c, Remarks_Oct__c, Remarks_Nov__c, Remarks_Dec__c from MIS_Budgets__r Order By createdDate DESC)
                
                
                FROM DC_Budget_Line_Items__c
                WHERE Budget__c = :DCBudgetId
                AND Active_Status__c = true
                ORDER BY CreatedDate ASC
            ];
        }
        
        return DCBudgetLineItemsList;
    }
    
    @AuraEnabled
    public static String updateBudgetLineItems(List<MIS_Budget__c> updateMis) {
        
        System.debug('update Mis'+updateMis[0].Budget_Line_Items__c);
        System.debug('update Mis==?'+updateMis);
        try {
            // create MIS under budget line item
            List<MIS_Budget__c> misToCreate = new List<MIS_Budget__c>();
            List<MIS_Budget__c> misToUpdate = new List<MIS_Budget__c>();
            
            List<DC_Budget_Line_Items__c> getLineItems = [
                SELECT id, Budget__c, Budget__r.Financial_Year__c 
                FROM DC_Budget_Line_Items__c 
                WHERE id = :updateMis[0].Budget_Line_Items__c
            ];
            List<Budget_FY_year_Config__mdt> misRanges = getMisDateRange(
                getLineItems.size() > 0 ? getLineItems[0].Budget__r.Financial_Year__c : null
            );
            Budget_FY_year_Config__mdt misRange = misRanges.size() > 0 ? misRanges[0] : new Budget_FY_year_Config__mdt();
            
            Integer startDateMonth = misRange.MIS_Edit_Start_Date__c.month();
            system.debug('Start Date Month: ' + startDateMonth);
            
            for(MIS_Budget__c eachDcBudLine : updateMis) {
                system.debug('startdate:: '+misRange.MIS_Edit_Start_Date__c+' -- '+ misRange.MIS_Edit_End_Date__c+' -- '+eachDcBudLine.Mis_Date__c);
                
                if(eachDcBudLine.Mis_Date__c != null && eachDcBudLine.Mis_Date__c.month() == startDateMonth) {
                    eachDcBudLine.Mis_Monthly_Report__c = misRange.MIS_Edit_Start_Date__c; 
                    misToUpdate.add(eachDcBudLine);
                    system.debug('misToUpdate::: '+ eachDcBudLine);
                }
                else {
                    eachDcBudLine.Id = null;
                    eachDcBudLine.Mis_Date__c = null;
                    eachDcBudLine.Mis_Monthly_Report__c = misRange.MIS_Edit_Start_Date__c; 
                    misToCreate.add(eachDcBudLine);
                    system.debug('misToCreate::: '+ eachDcBudLine);
                }
            }
            
            if (!misToCreate.isEmpty()) {
                upsert misToCreate; // Update the relevant records
            }
            if(!misToUpdate.isEmpty()){
                update misToUpdate;
            }
            return 'Records successfully processed.';
            
            // Perform DML operations
            /* if (!recordsToUpdate.isEmpty()) {
update recordsToUpdate; // Update the relevant records
}
if (!recordsToCreate.isEmpty()) {
insert recordsToCreate; // Insert new active records
}

return 'Records successfully processed.'; */
        } catch (DmlException dmlEx) {
            throw new AuraHandledException('DML Error: ' + dmlEx.getMessage());
        } 
        // catch (Exception ex) {
        //     throw new AuraHandledException('Unexpected Error: ' + ex.getMessage());
        // }
    }
    
    @AuraEnabled
    public static String updateEditedBudgetLineItems(List<DC_Budget_Line_Items__c> budgetLineItems) {
        try {
            // Validate input
            if (budgetLineItems == null || budgetLineItems.isEmpty()) {
                throw new AuraHandledException('No records provided for processing.');
            }
            
            // Separate records for update and create
            List<DC_Budget_Line_Items__c> recordsToUpdate = new List<DC_Budget_Line_Items__c>();
            List<DC_Budget_Line_Items__c> recordsToCreate = new List<DC_Budget_Line_Items__c>();
            
            // Get the current user ID
            Id currentUserId = UserInfo.getUserId();
            
            // Process each item
            for (DC_Budget_Line_Items__c item : budgetLineItems) {
                if (item.CreatedById == currentUserId) {
                    // If the line item was created by the current user, update it directly
                    recordsToUpdate.add(item);
                } else {
                    // Clone record for new creation with updated status
                    DC_Budget_Line_Items__c newRecord = item.clone(false, true, false, false);
                    newRecord.Active_Status__c = true; // Mark the new record as active
                    newRecord.Previous_Version__c = item.Id;
                    newRecord.Version_Stage__c = item.Budget__r.Status__c;
                    newRecord.Modified_By__c = currentUserId;
                    recordsToCreate.add(newRecord);
                    
                    // Update the original record to deactivate it
                    item.Active_Status__c = false;
                    recordsToUpdate.add(item);
                }
            }
            
            // Perform DML operations
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate; // Update the relevant records
            }
            if (!recordsToCreate.isEmpty()) {
                insert recordsToCreate; // Insert new active records
            }
            
            return 'Records successfully processed.';
        } catch (DmlException dmlEx) {
            throw new AuraHandledException('DML Error: ' + dmlEx.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException('Unexpected Error: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String createMISRecord(List<DC_Budget_Line_Items__c> budgetLineItems) {
        List<MIS_Budget__c> misRecords = new List<MIS_Budget__c>();
        Id currentUserId = UserInfo.getUserId();
        Date today = Date.today();
        Integer currentMonth = today.month();
        Integer currentYear = today.year();
        
        Set<Id> itemIds = new Set<Id>();
        for (DC_Budget_Line_Items__c item : budgetLineItems) {
            itemIds.add(item.Id);
        }
        
        Map<Id, List<MIS_Budget__c>> existingRecordsMap = new Map<Id, List<MIS_Budget__c>>();
        // if (!itemIds.isEmpty()) {
        //     List<MIS_Budget__c> existingRecords = [
        //         SELECT Id, Order_Expected_Month_Apr__c, Order_Expected_Stage_Apr__c,CreatedDate,Order_Type__c, Budget_Line_Items__c 
        //         FROM MIS_Budget__c 
        //         WHERE Budget_Line_Items__c IN :itemIds 
        //         AND CreatedById = :currentUserId 
        //         AND CALENDAR_MONTH(CreatedDate) = :currentMonth 
        //         AND CALENDAR_YEAR(CreatedDate) = :currentYear
        //     ];
        //     for (MIS_Budget__c record : existingRecords) {
        //         if (!existingRecordsMap.containsKey(record.Budget_Line_Items__c)) {
        //             existingRecordsMap.put(record.Budget_Line_Items__c, new List<MIS_Budget__c>());
        //         }
        //         existingRecordsMap.get(record.Budget_Line_Items__c).add(record);
        //     }
        // }
        
        List<MIS_Budget__c> misbudget = new List<MIS_Budget__c>();
        
        
        if (!itemIds.isEmpty()) {
            misbudget = [
                SELECT Id,CreatedDate, Order_Expected_Month_Apr__c, Order_Expected_Month_May__c, Order_Expected_Month_Jun__c, 
                Order_Expected_Month_Jul__c, Order_Expected_Month_Aug__c, Order_Expected_Month_Sep__c, 
                Order_Expected_Month_Oct__c, Order_Expected_Month_Nov__c, Order_Expected_Month_Dec__c,
                Order_Expected_Stage_Apr__c, Order_Expected_Stage_May__c, Order_Expected_Stage_Jun__c, 
                Order_Expected_Stage_Jul__c, Order_Expected_Stage_Aug__c, Order_Expected_Stage_Sep__c, 
                Order_Expected_Stage_Oct__c, Order_Expected_Stage_Nov__c, Order_Expected_Stage_Dec__c,
                Order_Type__c, Budget_Line_Items__c 
                FROM MIS_Budget__c 
                WHERE Budget_Line_Items__c IN :itemIds 
                AND CreatedById = :currentUserId 
                Order by CreatedDate desc
            ];
            
        }
        
        
        for (DC_Budget_Line_Items__c item : budgetLineItems) {
            List<MIS_Budget__c> existingRecords = misbudget;
            
            if ( existingRecords.size() > 0 && today.month() != existingRecords[0].CreatedDate.month() && today.day() > 2) {
                MIS_Budget__c misRecord = new MIS_Budget__c();
                misRecord.Order_Expected_Month_Apr__c = item.Order_Expected_Month__c; 
                misRecord.Order_Expected_Stage_Apr__c = item.Order_Expected_Stage__c; 
                misRecord.Order_Expected_Month_May__c = item.Order_Expected_Month__c; 
                misRecord.Order_Expected_Stage_May__c = item.Order_Expected_Stage__c; 
                misRecord.Order_Expected_Month_Jun__c = item.Order_Expected_Month__c; 
                misRecord.Order_Expected_Stage_Jun__c = item.Order_Expected_Stage__c; 
                misRecord.Order_Expected_Month_Jul__c = item.Order_Expected_Month__c; 
                misRecord.Order_Expected_Stage_Jul__c = item.Order_Expected_Stage__c; 
                misRecord.Order_Expected_Month_Aug__c = item.Order_Expected_Month__c; 
                misRecord.Order_Expected_Stage_Aug__c = item.Order_Expected_Stage__c; 
                misRecord.Order_Expected_Month_Sep__c = item.Order_Expected_Month__c; 
                misRecord.Order_Expected_Stage_Sep__c = item.Order_Expected_Stage__c; 
                misRecord.Order_Expected_Month_Oct__c = item.Order_Expected_Month__c; 
                misRecord.Order_Expected_Stage_Oct__c = item.Order_Expected_Stage__c; 
                misRecord.Order_Expected_Month_Nov__c = item.Order_Expected_Month__c; 
                misRecord.Order_Expected_Stage_Nov__c = item.Order_Expected_Stage__c; 
                misRecord.Order_Expected_Month_Dec__c = item.Order_Expected_Month__c; 
                misRecord.Order_Expected_Stage_Dec__c = item.Order_Expected_Stage__c; 
                misRecord.Order_Type__c = item.Order_Type__c;
                misRecord.Budget_Line_Items__c = item.Id; 
                misRecords.add(misRecord);
                
            }
            else if (existingRecords != null && existingRecords.size() > 0  ) {
                MIS_Budget__c existingRecord = existingRecords[0];
                existingRecord.Order_Expected_Month_Apr__c = item.Order_Expected_Month__c; 
                existingRecord.Order_Expected_Stage_Apr__c = item.Order_Expected_Stage__c; 
                existingRecord.Order_Expected_Month_May__c = item.Order_Expected_Month__c; 
                existingRecord.Order_Expected_Stage_May__c = item.Order_Expected_Stage__c; 
                existingRecord.Order_Expected_Month_Jun__c = item.Order_Expected_Month__c; 
                existingRecord.Order_Expected_Stage_Jun__c = item.Order_Expected_Stage__c; 
                existingRecord.Order_Expected_Month_Jul__c = item.Order_Expected_Month__c; 
                existingRecord.Order_Expected_Stage_Jul__c = item.Order_Expected_Stage__c; 
                existingRecord.Order_Expected_Month_Aug__c = item.Order_Expected_Month__c; 
                existingRecord.Order_Expected_Stage_Aug__c = item.Order_Expected_Stage__c; 
                existingRecord.Order_Expected_Month_Sep__c = item.Order_Expected_Month__c; 
                existingRecord.Order_Expected_Stage_Sep__c = item.Order_Expected_Stage__c; 
                existingRecord.Order_Expected_Month_Oct__c = item.Order_Expected_Month__c; 
                existingRecord.Order_Expected_Stage_Oct__c = item.Order_Expected_Stage__c; 
                existingRecord.Order_Expected_Month_Nov__c = item.Order_Expected_Month__c; 
                existingRecord.Order_Expected_Stage_Nov__c = item.Order_Expected_Stage__c; 
                existingRecord.Order_Expected_Month_Dec__c = item.Order_Expected_Month__c; 
                existingRecord.Order_Expected_Stage_Dec__c = item.Order_Expected_Stage__c; 
                existingRecord.Order_Type__c = item.Order_Type__c;
                misRecords.add(existingRecord);
            }
        }
        
        if (!misRecords.isEmpty()) {
            upsert misRecords; 
        }
        
        return 'MIS records processed successfully.';
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, Object>>> getAllStageMetadata() {
        Map<String, List<Map<String, Object>>> metadataMap = new Map<String, List<Map<String, Object>>>();
        
        metadataMap.put('C-Conversion', fetchMetadata('C_Conversion_Stage__mdt'));
        metadataMap.put('P-Project', fetchMetadata('P_Project_Stage__mdt'));
        metadataMap.put('E-Spares', fetchMetadata('E_Spares_Stages__mdt'));
        
        return metadataMap;
    }
    
    private static List<Map<String, Object>> fetchMetadata(String metadataType) {
        List<Map<String, Object>> metadataList = new List<Map<String, Object>>();
        String query = 'SELECT DeveloperName, Name__c, Stage_Sequence__c FROM ' + metadataType;
        
        for (SObject record : Database.query(query)) {
            Map<String, Object> metadataRecord = new Map<String, Object>();
            metadataRecord.put('DeveloperName', record.get('DeveloperName'));
            metadataRecord.put('Name__c', record.get('Name__c'));
            metadataRecord.put('Stage_Sequence__c', record.get('Stage_Sequence__c'));
            metadataList.add(metadataRecord);
        }
        return metadataList;
    }
    
    //subham deb
    //get the active time slot for MIS entry
    @AuraEnabled(cacheable=true)
    public static List<Budget_FY_year_Config__mdt> getMisDateRange(String FNyear){
        List<Budget_FY_year_Config__mdt> misRange = [Select MIS_Edit_Start_Date__c, MIS_Edit_End_Date__c from Budget_FY_year_Config__mdt where Active_Financial_Year__c=:FNyear limit 1];
        return misRange;
    }

// ADDED By Ranjeet
@AuraEnabled(cacheable=true)
public static String getBudgetDetails(Id recordId) {

    // 1. Sanity check
    if (recordId == null) {
        return null;
    }

    try {
        // 2. Query with security enforced
        DC_Budget__c record = [
            SELECT Name, CurrencyIsoCode
            FROM DC_Budget__c
            WHERE Id = :recordId
            WITH USER_MODE
            LIMIT 1
        ];

        return record.CurrencyIsoCode;

    } catch (Exception e) {
        // 3. Handle errors gracefully
        throw new AuraHandledException(
            'Error fetching budget: ' + e.getMessage()
        );
    }
}


}