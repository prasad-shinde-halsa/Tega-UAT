public class DC_BudgetCloner {
    
    /**
     * Clones a DC_Budget__c record along with its child records (DC_Budget_Line_Items__c)
     * based on fields specified in custom metadata.
     * @param budgetId The Id of the DC_Budget__c record to be cloned.
     * @return Id of the newly cloned DC_Budget__c record.
     */
    public static ResponseWrapper cloneDCBudgetWithChildren(String budgetId ) {
        if (budgetId == null) {
            //throw new CustomException('No DC_Budget__c record ID provided.');
        }

        DC_Budget__c clonedBudget = new DC_Budget__c();

        String newBudgetId = '';

        try{
                // *********** if all field copy ************* //
                // Step 1: Clone the parent DC_Budget__c record
                DC_Budget__c originalBudget = [SELECT Id, Financial_Year__c, Parent_Budget__c, Parent_Budget__r.Financial_Year__c FROM DC_Budget__c WHERE Id = :budgetId LIMIT 1];

                if(String.isBlank(originalBudget.Financial_Year__c)){
                    ResponseWrapper rws = new ResponseWrapper();
                    rws.status=204;
                    rws.message='Financial Year is blank in this Budget';
                    rws.createdBudget= '';
                    return rws;
                }

                Budget_FY_year_Config__mdt isClone = [select Id, Clone_from_previous_FN__c, Active_Financial_Year__c from Budget_FY_year_Config__mdt where Active__c = true Limit 1];

                String currentFY = getFinancialYear(Datetime.now());
                Integer currentStartYear = Integer.valueOf(currentFY.split('-')[0]);

                String budgetFn = originalBudget.Financial_Year__c.split('-')[0];
                Integer budgetStartYear = Integer.valueOf(budgetFn.split('-')[0]);


                if( isClone.Clone_from_previous_FN__c != true && budgetStartYear < currentStartYear ){
                    ResponseWrapper rws = new ResponseWrapper();
                    rws.status=204;
                    rws.message='Clone from previous FN year is disabled by Admin, Please contact with admin';
                    rws.createdBudget= '';
                    return rws;
                }

                if( isClone.Clone_from_previous_FN__c == true && budgetStartYear+1 != currentStartYear && budgetStartYear < currentStartYear){
                    ResponseWrapper rws = new ResponseWrapper();
                    rws.status=204;
                    rws.message='You can only clone from last FN year Budget';
                    rws.createdBudget= '';
                    return rws;
                }

                
                
                if(originalBudget.Parent_Budget__c != null){
                    Integer parentBudgetFN = Integer.valueOf(originalBudget.Parent_Budget__r.Financial_Year__c.split('-')[0]);
                    Integer clonedBudgetFN = Integer.valueOf(originalBudget.Financial_Year__c.split('-')[0]);

                    if(clonedBudgetFN >= currentStartYear){
                        ResponseWrapper rws = new ResponseWrapper();
                        rws.status=204;
                        rws.message='You cannot clone Advanced year Budget';
                        rws.createdBudget= '';
                        return rws;

                    }


                    if((parentBudgetFN+3) == clonedBudgetFN){
                        ResponseWrapper rws = new ResponseWrapper();
                        rws.status=204;
                        rws.message='You can clone upto 3 Advanced year Budget';
                        rws.createdBudget= '';
                        return rws;
                    }
                }
               

                
                List<DC_Budget__c> existBudgets = checkForExistingBudget(originalBudget);
                if(existBudgets.size() > 0){
                    ResponseWrapper rws = new ResponseWrapper();
                    rws.status=203;
                    rws.message= 'Already a clone of this budget is exist for FN ' + existBudgets[0].Financial_Year__c;
                    rws.createdBudget = existBudgets[0].Id;
                    return rws;
                }

                clonedBudget = cloneParentRecord(originalBudget, 'full');

                // Step 2: Clone child records (DC_Budget_Line_Items__c)
                cloneChildRecords(budgetId, clonedBudget.Id, 'full');
                
            

            ResponseWrapper rw = new ResponseWrapper();
            rw.createdBudget = clonedBudget.Id;
            rw.status = 201;
            rw.message = 'created successfully';

            return rw;

        }
        catch(Exception ex){
            ResponseWrapper rw = new ResponseWrapper();
            rw.createdBudget = null;
            rw.status = 404;
            if(newBudgetId != ''){
               DC_Budget__c delBudget = [SELECT Id FROM DC_Budget__c WHERE Id =: newBudgetId LIMIT 1];
                delete delBudget;
            }

            rw.message = 'clone budget not getting created';
            rw.message = ex.getMessage();
            return rw;
        }
    }

    /**
     * Clones the parent DC_Budget__c record based on fields specified in custom metadata.
     * @param originalBudget The original DC_Budget__c record to clone.
     * @return A new DC_Budget__c record with copied fields.
     */
    private static DC_Budget__c cloneParentRecord(DC_Budget__c originalBudget, String copyType) {
        
        String idBudget = originalBudget.Id;
        // Create a new instance of DC_Budget__c
        DC_Budget__c clonedBudget = new DC_Budget__c();


        // get logedin user details
        List<User> currentUser = [SELECT Id, CompanyName, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        String budgetName = '';

            String fieldList  = getAllFieldsList('DC_Budget__c');
            String queryString = 'select '+ fieldList +' from DC_Budget__c WHERE Id=\''+ idBudget +'\' LIMIT 1';
            system.debug('queryString::'+ queryString);
            DC_Budget__c getParent = Database.query(queryString);

            // Clone the record
            clonedBudget = getParent.clone(false, false, false, false);

            if(clonedBudget.Cloned_Budget__c == true){
                clonedBudget.Parent_Budget__c = getParent.Parent_Budget__c;
            }
            else{
                clonedBudget.Parent_Budget__c = idBudget;
            }
            // clonedBudget.Parent_Budget__c = idBudget;
            budgetName = clonedBudget.Company_Name__c+'-'+clonedBudget.Branch_Name__c+'-'+clonedBudget.Owner_Name__c+'-';
        

        String currentFY = getFinancialYear(Datetime.now());
        Integer startYear = Integer.valueOf(currentFY.split('-')[0]);
        Integer endYear = Integer.valueOf(currentFY.split('-')[1]);
        String nextFY = String.valueOf(startYear + 1) +'-'+ String.valueOf(endYear + 1);

        String budgetFY = clonedBudget.Financial_Year__c;
        Integer budgetStartFY = Integer.valueOf(clonedBudget.Financial_Year__c.split('-')[0]);
        Integer budgetEndFY = Integer.valueOf(clonedBudget.Financial_Year__c.split('-')[1]);

        // check financial year
        if(budgetFY == currentFY){
            clonedBudget.Financial_Year__c = nextFY;
            clonedBudget.recordTypeId = Schema.SObjectType.DC_Budget__c.getRecordTypeInfosByName().get('Advance Budget').getRecordTypeId();
            clonedBudget.Name = budgetName+clonedBudget.Financial_Year__c+'-Advanced Budget';
            //Schema.SObjectType.DC_Budget__c.getRecordTypeInfosByName().get('Forecast Budget').getRecordTypeId()
        }
        // else 
        if(budgetStartFY < startYear){
            clonedBudget.Financial_Year__c = currentFY;
            
            String newOwnerName = currentUser[0].Name;

            clonedBudget.Name = clonedBudget.Company_Name__c+'-'+clonedBudget.Branch_Name__c+'-'+newOwnerName+'-'+currentFY;
            clonedBudget.recordTypeId = Schema.SObjectType.DC_Budget__c.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        }
        if(budgetStartFY > startYear){
            clonedBudget.Financial_Year__c = (budgetStartFY + 1) +'-'+ (budgetEndFY+1);
            clonedBudget.recordTypeId = Schema.SObjectType.DC_Budget__c.getRecordTypeInfosByName().get('Advance Budget').getRecordTypeId();
            clonedBudget.Name = clonedBudget.Name = budgetName+clonedBudget.Financial_Year__c+'-Advanced Budget';
        }

        clonedBudget.Cloned_Budget__c = true;
        clonedBudget.Status__c = 'Draft';
        // Insert the cloned parent record
        insert clonedBudget;

        return clonedBudget;
    }

    /**
     * Clones child records (Master-Detail relationship) of type DC_Budget_Line_Items__c
     * based on fields specified in custom metadata.
     * @param originalBudgetId The ID of the original DC_Budget__c record.
     * @param clonedBudgetId The ID of the newly cloned DC_Budget__c record.
     */
    private static void cloneChildRecords(String originalBudgetId, Id clonedBudgetId, String copyType) {
        
        
        List<DC_Budget_Line_Items__c> clonedLineItems = new List<DC_Budget_Line_Items__c>();
        List<DC_Budget_Line_Items__c> fetchedLineItems = new List<DC_Budget_Line_Items__c>();
        
        

            String fieldList = getAllFieldsList('DC_Budget_Line_Items__c');

            String queryString = 'select '+ fieldList +' from DC_Budget_Line_Items__c where Active_Status__c=true AND Budget__c=\''+ originalBudgetId +'\'';

            List<DC_Budget_Line_Items__c> getDatas = Database.query(queryString);

            // Copy the child records based on metadata fields
            for (DC_Budget_Line_Items__c lineItem : getDatas) {

                DC_Budget_Line_Items__c lineItemClone = lineItem.clone(false, false, false, false);
                lineItemClone.Budget__c = clonedBudgetId;
                lineItemClone.Status__c = '';

                clonedLineItems.add(lineItemClone);
            }

            // Clone the record
            // fetchedLineItems = getParent.clone(false, false, false, false);

        

        // Insert cloned child records if any
        if (!clonedLineItems.isEmpty()) {
            insert clonedLineItems;
            System.debug('clonedLineItems:: '+ clonedLineItems);
        }
        else{
            system.debug('empty');
        }
    }


    public static String getAllFieldsList(String objectName){
        // Get the describe information for the object
        Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
        
        // Get the map of fields
        Map<String, Schema.SObjectField> fieldsMap = objectDescribe.fields.getMap();
        // Create a list to store field names
        List<String> fieldNames = new List<String>();
        
        // Add field names to the list
        for (String fieldName : fieldsMap.keySet()) {
            if(fieldName.contains('id')){
                
            }else{
                fieldNames.add(fieldName);
            }
            
        }
        
        // Join field names with commas
        return String.join(fieldNames, ', ');
    }

    public static String getFinancialYear(Datetime inputDateTime) {
    //    // Convert Datetime to Date
    //    Date inputDate = inputDatetime.date();

    //    // Get the year and month of the input date
    //    Integer year = inputDate.year();
    //    Integer month = inputDate.month();

    //    // Determine the financial year
    //    Integer startYear;
    //    Integer endYear;

    //    if (month < 4) {
    //        // Before April, it belongs to the previous financial year
    //        startYear = year - 1;
    //        endYear = year;
    //    } else {
    //        // From April onwards, it belongs to the current financial year
    //        startYear = year;
    //        endYear = year + 1;
    //    }

    //    // Format the end year as two digits
    //    String endYearShort = String.valueOf(endYear).substring(2);

    //    // Return financial year in the format "YYYY-YY"
    //    return startYear + '-' + endYearShort;
        List<Budget_FY_year_Config__mdt> getActiveFN = [select id, Active_Financial_Year__c from Budget_FY_year_Config__mdt where Active__c=true LIMIT 1];
        if( getActiveFN.Size() > 0){
            return getActiveFN[0].Active_Financial_Year__c;
        }
        else {
            return '';
        }
   }

   public static List<DC_Budget__c> checkForExistingBudget( DC_Budget__c originalBudget){
        Integer budgetFNstart = Integer.valueOf(originalBudget.Financial_Year__c.split('-')[0]);
        string currentFN = getFinancialYear(Datetime.now());
        Integer currentFNStart = Integer.valueOf(currentFN.split('-')[0]);

        String searchOn = '';

        system.debug('budgetFNstart : '+budgetFNstart);

        if(budgetFNstart < currentFNStart){
            searchOn = currentFN;
        }
        else{
            searchOn = (budgetFNstart + 1) +'-'+ (Integer.valueOf(originalBudget.Financial_Year__c.split('-')[1]) + 1);
        }

        system.debug('searchOn: '+ searchOn);
        String parentId = '';
        if(!String.isBlank(originalBudget.Parent_Budget__c)){
            parentId = originalBudget.Parent_Budget__c;
        }
        else{
            parentId = originalBudget.Id;
        }

        List<DC_Budget__c> clonedBudgets = [select id, Financial_Year__c from DC_Budget__c where Financial_Year__c =:searchOn AND Parent_Budget__c =: parentId];

        system.debug('clonedBudgets: '+ clonedBudgets);

        return clonedBudgets;

   }

   
   public class ResponseWrapper{
        @AuraEnabled
        public String createdBudget;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public Integer status;
   }

    @AuraEnabled
    public static ResponseWrapper cloneBudget(String recordId, String copyType){
        return cloneDCBudgetWithChildren(recordId);
    }
}