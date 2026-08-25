/********************************************************
Company Name : DCC Services Pvt Ltd.
Name : ctrl_ParticleSD_Management 
Desc : This controller handle Particle Size Distribution
	   and Particle Size Distribution Line Item creation Logic.	
Author : Arnab Das
*********************************************************/

public class ctrl_ParticleSD_Management {
    
    public id pageId { get; set; }
    public Particle_Size_Distribution__c psd { get; set; }
    public List<Particle_Size_Distribution__c> psdList { get; set; }
    public Particle_Size_Distribution_Line_Item__c psdline { get; set; }
    public List<Particle_Size_Distribution_Line_Item__c> psdlineList { get; set; }
    public Operating_Parameters__c OP { get; set; }
    // public string selectedRecordTypeId { get; set; }
    public date Todaysdate { get; set; }
    public RecordType recId { get; set; }
    //  public String recordTypeId { get; set; }
    //  public String recordTypeName { get; set; }
    
    public ctrl_ParticleSD_Management(ApexPages.StandardController stdController) {
        
        pageId = ApexPages.CurrentPage().getparameters().get('id');
        Todaysdate = system.today();
        
        OP = new Operating_Parameters__c();
        OP = [SELECT id, Name,RecordTypeId,RecordType.Name FROM Operating_Parameters__c WHERE Id = :pageId];
        
        recId = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Particle_Size_Distribution__c' AND Name = :OP.RecordType.Name];
        
        psd = new Particle_Size_Distribution__c();
        
        psdlineList = new List<Particle_Size_Distribution_Line_Item__c>();
        psdlineList.add(new Particle_Size_Distribution_Line_Item__c());
    }
    
    public void addNewRow() {
        if(psdlineList.size() < 12){
            psdlineList.add(new Particle_Size_Distribution_Line_Item__c());
        }
    }
    
    public void removeRow() {
        if (psdlineList.size() > 1) {
            Integer rowIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('rowIndex'));
            psdlineList.remove(rowIndex - 1);
        } else {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, ' At least one Row should be Present!'));
        }
    }
    
    private Boolean allPSDLineItemsFilled() {
        for (Particle_Size_Distribution_Line_Item__c psdl : psdlineList) {
            if (psdl.Sieve_mm__c == null || psdl.Weight__c == null) {
                return false;
            }
        }
        return true;
    }
    
    public PageReference save() {
        try {
            if(psd.Type__c == null){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please fill the Type field in Particle Size Distribution.'));
                return null; 
            }
            
            if (psdlineList.isEmpty() || !allPSDLineItemsFilled()) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please enter a value in both fields to save the record.'));
                return null; 
            }
            
            Particle_Size_Distribution__c p = new Particle_Size_Distribution__c();
            List<Particle_Size_Distribution_Line_Item__c> psdlList = new List<Particle_Size_Distribution_Line_Item__c>();
            
            p.RecordTypeId = recId.Id;
            p.Type__c = psd.Type__c;
            p.Today_s_Date__c = Todaysdate;
            p.Operating_Parameters__c = OP.Id;
            insert p;
            
            for (Particle_Size_Distribution_Line_Item__c psdl : psdlineList) {
                Particle_Size_Distribution_Line_Item__c pl = new Particle_Size_Distribution_Line_Item__c();
                pl.Particle_Size_Distribution__c = p.Id;
                pl.Sieve_mm__c = psdl.Sieve_mm__c;
                pl.Weight__c = psdl.Weight__c;
                psdlList.add(pl);
            }
            
            if (!psdlList.isEmpty()) {
                insert psdlList;
            }
        } catch (exception e) {
            TegaUtility.trackLogs(e, 'ctrl_ParticleSD_Management', 'Save');
        }
        PageReference pr = new PageReference('/' + OP.Id);
        pr.setRedirect(true);
        return pr;
    }
    
    public PageReference cancel(){
        PageReference pr = new PageReference('/'+OP.Id);
        pr.setRedirect(true);
        return pr;
    }
    
}