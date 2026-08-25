public with sharing class TopExcellPrintController {

    public String customerName {get; set;}
    public String branch {get; set;}
    public String partList {get; set;}
    public String enquiryNo {get; set;}
    public String description {get; set;}

    public String issuedDate {get; set;}
    public String quoteNo {get; set;}
    public String validity {get; set;}
    public String currency1 {get; set;}
    public String deliverySchedule {get; set;}

    public TopExcellPrintController() {

        
        customerName = 'PRONY RESOURCES NEW CALEDONIA';
        branch = 'Australia';
        partList = 'PLM-00771-01';
        enquiryNo = '4565565';
        description = 'SCRUBBER DIA 7330 X 16650 MM LG.';

        issuedDate = 'Apr 22, 2026';
        quoteNo = 'MG0024';
        validity = 'May 21, 2026';
        currency1 = 'AUD';
        deliverySchedule = '8 Weeks';
    }
   public Blob getLogoBlob() {
        try {
            StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'TegaLogo' LIMIT 1];
            return sr.Body;
        } catch (Exception e) {
            return null;
        }
    }
    
    public String getLogoBase64() {
        Blob logoBlob = getLogoBlob();
        if (logoBlob != null) {
            return 'data:image/png;base64,' + EncodingUtil.base64Encode(logoBlob);
        }
        return '';
    }
}