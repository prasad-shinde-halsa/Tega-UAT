/**
 * @description
 * This Apex controller is used to retrieve company, branch, and DC Budget data
 * along with nested Budget Line Items and MIS Budget entries, specifically for
 * use in Lightning Web Components (LWC) like MIS Entry Status reports.
 * Author - Reetabrata
 * Last Modified Date - 30th July 2025
 */

public class MISEntryStatusController {
    /**
     * @description
     * Fetches all active Company__c records.
     *
     * @returns List<Company__c> - A list of all company records with Id and Name.
     */
    @AuraEnabled
    public static List<Company__c> getAllCompany() {
        List<Company__c> CompanyList = new List<Company__c>();
        
        try {
            CompanyList = [SELECT Id,Name FROM Company__c];
        }
        catch (Exception ex) {
            System.debug('⚠️ Error in getDCBudgetAndChildItems: ' + ex.getMessage());
        }
        return CompanyList;
    }
    
    /**
     * @description
     * Retrieves all Branches related to a specific Company through the 
     * Sales_Org_Branch_Relationship__c junction object.
     *
     * @param companyId - The Id of the selected Company.
     * @returns List<Sales_Org_Branch_Relationship__c> - A list of related branches.
     */
    @AuraEnabled
    public static List<Sales_Org_Branch_Relationship__c> getBranchesForCompany(Id companyId) {
        if (companyId == null) return new List<Sales_Org_Branch_Relationship__c>();

        return [
            SELECT Branch__r.Id, Branch__r.Name 
            FROM Sales_Org_Branch_Relationship__c 
            WHERE Company__c = :companyId
        ];
    }
    
    /**
     * @description
     * Retrieves DC Budget records for the given financial year with status "4th Level Approved".
     * Each budget includes:
     *   - Branch, Company info
     *   - Active Budget Line Items
     *   - Nested MIS Budget entries with Mis_Monthly_Report__c and monthly order expectations
     *
     * @param selectedFY - The selected Financial Year (e.g., "2025-26").
     * @returns List<DC_Budget__c> - A list of approved DC budgets with nested child records.
     */
    @AuraEnabled
    public static List<DC_Budget__c> getDCBudgetAndChildItems(String selectedFY) {
        try {
            
            List<DC_Budget__c> DCBudgetList = [
                SELECT Id, Name, Status__c, Financial_Year__c,Branch__c ,Branch_Name__c ,Company_Name__c ,Company__c ,
                    (
                        SELECT Id, Name,
                            (
                                SELECT Id, Name,CurrencyIsoCode,Mis_Monthly_Report__c,CreatedBy.Name,
                                Order_Expected_Month_Apr__c,Order_Expected_Month_Aug__c,Order_Expected_Month_Dec__c,Order_Expected_Month_Feb__c,Order_Expected_Month_Jan__c,
                                Order_Expected_Month_Jul__c,Order_Expected_Month_Jun__c,Order_Expected_Month_Mar__c,Order_Expected_Month_May__c,Order_Expected_Month_Nov__c,
                                Order_Expected_Month_Oct__c,Order_Expected_Month_Sep__c
                                    
                                FROM MIS_Budgets__r
                            )
                        FROM Budget_Line_Items__r
                        WHERE Active_Status__c = true
                    )
                FROM DC_Budget__c
                WHERE Status__c = '4th Level Approved'
                AND Financial_Year__c =:selectedFY
            ];
             //AND Id IN  ('a1hS20000027YbhIAE','a1hS20000027XSjIAM')

            return DCBudgetList;

        } catch (Exception ex) {
            // Log error if needed: System.debug('Error: ' + ex.getMessage());
            throw new AuraHandledException('An unexpected error occurred while retrieving budget data: ' + ex.getMessage());
        }
    }
}