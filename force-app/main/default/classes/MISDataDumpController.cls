/**
 * @name        MISDataDumpController
 * @description 
 * 
 * @author      Reetabrata Mishra
 * @date        7th Aug 2025
 * @version     1.0
 */

public class MISDataDumpController {
	@AuraEnabled
    public static List<MIS_Budget__c > getMisAndParentItems(String selectedFY) {
        List<MIS_Budget__c> MISList = new List<MIS_Budget__c>();
        
        try {
            MISList = [
                SELECT Id, Name, Budget_Line_Items__r.Budget__r.Name,Budget_Line_Items__r.Budget__r.Status__c,
                Mis_Monthly_Report__c ,Budget_Line_Items__r.Budget__r.CurrencyIsoCode, Budget_Line_Items__r.PMG_Name__c, 
                Budget_Line_Items__r.Product_Group_Name__c, Budget_Line_Items__r.Description__c, Budget_Line_Items__r.Customer_Code__c,
                Budget_Line_Items__r.Customer_Name__c, Budget_Line_Items__r.Annual_Potential__c ,Order_Type__c,Budget_Line_Items__r.Budget__r.RecordType.Name,
                Budget_Line_Items__r.Budget_FN_Year__c,Budget_Line_Items__r.Budget__r.Branch_Name__c,CreatedBy.Name,
                
                Remarks_Apr__c,Remarks_Jun__c,Remarks_Aug__c,Remarks_Oct__c,Remarks_Dec__c,Remarks_Mar__c,Remarks_Feb__c,Remarks_Jan__c,
                Remarks_Nov__c,Remarks_Sep__c,Remarks_Jul__c,Remarks_May__c,
                
                Order_Expected_Stage_Apr__c,
                Order_Expected_Stage_May__c,Order_Expected_Stage_Jun__c,Order_Expected_Stage_Jul__c,Order_Expected_Stage_Aug__c,
                Order_Expected_Stage_Sep__c,Order_Expected_Stage_Oct__c ,Order_Expected_Stage_Nov__c , Order_Expected_Stage_Dec__c,
                Order_Expected_Stage_Jan__c , Order_Expected_Stage_Feb__c, Order_Expected_Stage_Mar__c ,
                
                Order_Expected_Month_Apr__c, Order_Expected_Month_May__c , Order_Expected_Month_Jun__c, Order_Expected_Month_Jul__c ,
                Order_Expected_Month_Aug__c , Order_Expected_Month_Sep__c, Order_Expected_Month_Oct__c , Order_Expected_Month_Nov__c ,
                Order_Expected_Month_Dec__c , Order_Expected_Month_Jan__c , Order_Expected_Month_Feb__c , Order_Expected_Month_Mar__c ,
                
                Expected_Order_Value_April__c,Expected_Order_Value_May__c,Expected_Order_Value_June__c,Expected_Order_Value_Jul__c,
                Expected_Order_Value_Aug__c,Expected_Order_Value_Sep__c,Expected_Order_Value_Oct__c,Expected_Order_Value_Nov__c,
                Expected_Order_Value_Dec__c,Expected_Order_Value_Jan__c,Expected_Order_Value_Feb__c,
                
                Budget_Line_Items__r.Apr_Order__c,Budget_Line_Items__r.May_Order__c,Budget_Line_Items__r.Jun_Order__c,Budget_Line_Items__r.Jul_Order__c,
                Budget_Line_Items__r.Aug_Order__c,Budget_Line_Items__r.Sep_Order__c,Budget_Line_Items__r.Oct_Order__c,Budget_Line_Items__r.Nov_Order__c,
                Budget_Line_Items__r.Dec_Order__c,Budget_Line_Items__r.Jan_Order__c,Budget_Line_Items__r.Feb_Order__c,Budget_Line_Items__r.Mar_Order__c,
                Budget_Line_Items__r.Total_Order__c 
                FROM MIS_Budget__c WHERE Budget_Line_Items__r.Budget_FN_Year__c =: selectedFY
                
            ];
           // AND Id IN ('a1iC3000000dq1xIAA')
        } catch (Exception ex) {
            System.debug('⚠️ Error in getDCBudgetAndChildItems: ' + ex.getMessage());
        }
        
        return MISList;
    }
}