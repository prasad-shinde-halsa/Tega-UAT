/**
 * @name        RunRateCalculationController
 * @description Apex controller for Flow and LWC to retrieve a single 
 *              DC_Budget_Line_Items__c record by Id, including monthly
 *              order values (Apr–Mar) and the total order value. 
 *              This data is typically used in a Flow screen component
 *              to display available months and calculate selections.
 * 
 * @author      Reetabrata Mishra
 * @date        09th Aug 2025
 * @version     1.0
 */

public Without Sharing class SelectBudgetMonthForFlowController {

    @AuraEnabled
    public static DC_Budget_Line_Items__c  getDCBudget(String BLIid) {
        
        if (String.isBlank(BLIid)) {
        return null; // Or throw an exception
    }

    DC_Budget_Line_Items__c bli = [
        SELECT Id, Name ,Apr_Order__c,May_Order__c,Jun_Order__c,Jul_Order__c,Aug_Order__c,
        Sep_Order__c,Oct_Order__c,Nov_Order__c,Dec_Order__c,Jan_Order__c,Feb_Order__c,
        Mar_Order__c,Total_Order__c , Budget__r.CurrencyIsoCode
        FROM DC_Budget_Line_Items__c
        WHERE Id = :BLIid
    ];

    return bli;
    }
}