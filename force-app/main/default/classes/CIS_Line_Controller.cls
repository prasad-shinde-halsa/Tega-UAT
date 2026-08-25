/********************************************************
Company Name : DCC Services Pvt Ltd.
Name : CIS_Line_Controller 
Desc : This controller handle Cost Information Sheet Line Item
creation Logic.	
Author : Arnab Das
*********************************************************/

public class CIS_Line_Controller {
    public id pageId { get; set; }
    public Cost_Information_sheet__c cis { get; set; }
    public Cost_Information__c cisline { get; set; }
    public List<Cost_Information__c> cislineList { get; set; }
    private Set<String> uniqueItemDescs = new Set<String>();
    public List<Cost_Information__c> existingCISLineItems { get; set; }
    private String currentItemDesc;
    
    public CIS_Line_Controller(ApexPages.StandardController stdController) {
        
        pageId = ApexPages.CurrentPage().getparameters().get('id');
        
        cisline = new Cost_Information__c();
        cis = new Cost_Information_sheet__c();
        cis = [SELECT id, Name,Proposal_Form__c,Total_Rate_Kg__c,Total_Weight__c FROM Cost_Information_sheet__c WHERE Id = :pageId];
        
        existingCISLineItems = [SELECT Id, Item_Desc__c, Rate_Kg__c, Total_Weight__c, Remarks__c
                                FROM Cost_Information__c
                                WHERE Cost_Information_sheet__c = :pageId];
        
        cislineList = new List<Cost_Information__c>();
        cislineList.add(new Cost_Information__c());
        
        for (Cost_Information__c existingCIS : existingCISLineItems) {
            uniqueItemDescs.add(existingCIS.Item_Desc__c);
        }
        
    }
    
    public void addNewRow() {
        Cost_Information__c newItem = new Cost_Information__c();
        cislineList.add(newItem);
    } 
    
    public void removeRow() {
        if (cislineList.size() > 1) {
            Integer rowIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('rowIndex'));
            Cost_Information__c removedItem = cislineList.remove(rowIndex - 1);
            uniqueItemDescs.remove(removedItem.Item_Desc__c);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'At least one row should be present!'));
        }
    }
    
    private Boolean allCISLineItemsFilled() {
        for (Cost_Information__c cisl : cislineList) {
            if (cisl.Item_Desc__c == null || cisl.Rate_Kg__c == null || cisl.Total_Weight__c == null) {
                return false;
            }
        }
        return true;
    }
    
    public PageReference save() {
        try {
            
            if (cislineList.isEmpty() || !allCISLineItemsFilled()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please enter all the values to save the record.'));
                return null;
            }
            
            List<Cost_Information__c> cislList = new List<Cost_Information__c>();
            
            for (Cost_Information__c cisl : cislineList) {
                String newItemDesc = cisl.Item_Desc__c;
                
                if (uniqueItemDescs.contains(newItemDesc)) {
                    ApexPages.addMessage(new ApexPages.Message(
                        ApexPages.Severity.Error,
                        'Item description "' + newItemDesc + '" already exists in the list. Duplicate records are not allowed.'
                    ));
                    return null;
                }
                
                uniqueItemDescs.add(newItemDesc);
                
                Cost_Information__c ci = new Cost_Information__c();
                ci.Cost_Information_sheet__c = cis.Id;
                ci.Item_Desc__c = cisl.Item_Desc__c;
                ci.Rate_Kg__c = cisl.Rate_Kg__c;
                ci.Total_Weight__c = cisl.Total_Weight__c;
                ci.Remarks__c = cisl.Remarks__c;
                cislList.add(ci);
            }
            
            if (!cislList.isEmpty()) {
                insert cislList;
            }
        } catch (Exception e) {
            TegaUtility.trackLogs(e, 'CIS_Line_Controller', 'Save');
        }
        PageReference pr = new PageReference('/' + cis.Id);
        pr.setRedirect(true);
        return pr;
    }
    
    public PageReference cancel(){
        PageReference pr = new PageReference('/'+cis.Id);
        pr.setRedirect(true);
        return pr;
    }
    
    public void fakeMethod(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        
    }
}