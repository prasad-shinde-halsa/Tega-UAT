/**********************************************************************************

@Company Name : DCC Services Pvt Ltd.
@Class Name : Ctrl_PartList_Metrix
@Date : 24/07/2023
@Author : Arnab Das
@Description : This code is used to show the Part List's L2 Product and L3Product 
data in an organized manner.

*********************************************************************************/

public class Ctrl_PartList_Metrix {
    
    public id Pageid{get;set;}
    public Part_List__c PL{get;set;}
    public List<Part_List__c> plList{get;set;}
    public List<L2_L3_product__c> L2L3List{get;set;}
    public Map<String,List<L2_L3_product__c>>L2L3Map{get;set;}
    public List<L2L3Wrapper> filterList { get;set; }
    public List<L2L3Wrapper> filterList2 { get;set; }
    public List<L2L3Wrapper> filterList3 { get;set; }
    public Integer FilterQuantity{get;set;}
    public List<L2L3Wrapper> excelExportData { get; set; }
    public List<L2L3Wrapper> PDFExportData { get; set; }
    
    /********************************************************************
@Description : This method is used for L2Product and L3Product
Product sorting 
*********************************************************************/
    
    public Ctrl_PartList_Metrix(ApexPages.StandardController controller){
        Pageid = ApexPages.CurrentPage().getparameters().get('id');
        
        PL= new Part_List__c();
        PL = [SELECT id,Name,Customer__c,Description__c,Customer_Name__c FROM Part_List__c WHERE id=: Pageid];
        plList = new List<Part_List__c>();
        plList = [SELECT id,Name,Customer__c,Description__c,Customer_Name__c FROM Part_List__c WHERE id=: Pageid];
        L2L3List = [SELECT id,Part_List__c,L2_Prod_Name__c,L3_Prod_Name__c,Product_L2__c,Product_L3__c,Quantity__c,Item_Description__c,Product_Category__c,Product_Category_Test__c,Product_Sorting_Data__c FROM L2_L3_product__c WHERE Part_List__c =:PL.id order by Sorting__c asc];
        
        Set<String>PCT = new set<String>();
        
        for(L2_L3_product__c l2:L2L3List){
            PCT.add(l2.Product_Category_Test__c);
        }
        system.debug('PCT: '+PCT);
        
        List<String>listOfPCT = new List<String>(PCT);
        
        Map<String,List<L2_L3_product__c>>L2L3Map = new Map<String,List<L2_L3_product__c>>();
        
        for(L2_L3_product__c plm:L2L3List){
            if(L2L3Map.containsKey(plm.L3_Prod_Name__c)){
                L2L3Map.get(plm.L3_Prod_Name__c).add(plm);
            }
            else{
                List<L2_L3_product__c> L2L3 =new List<L2_L3_product__c>();
                L2L3.add(plm);
                L2L3Map.put(plm.L3_Prod_Name__c,L2L3);
            }                
        }
        system.debug('Map: '+ L2L3Map);
        FilterQuantity = L2L3Map.size();
        system.debug('FilterQuantity:'+ FilterQuantity);
        
        filterList = new List<L2L3Wrapper>();
        filterList2 = new List<L2L3Wrapper>();
        filterList3 = new List<L2L3Wrapper>();
        
        for(String key:L2L3Map.keyset()){
            
            L2L3Wrapper l2l3p = new L2L3Wrapper();
            l2l3p.L2ProductName = key;
            
            for(L2_L3_product__c l2l3:L2L3Map.get(key)){
                
                if(l2l3.Product_Category_Test__c == 'FEH'){
                    l2l3p.fehQuantity = l2l3.Quantity__c;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                    
                }
                else if(l2l3p.fehQuantity == NULL){
                    l2l3p.fehQuantity = 0;
                }
                
                if(l2l3.Product_Category_Test__c == 'DEH'){
                    l2l3p.dehQuantity = l2l3.Quantity__c;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                else if(l2l3p.dehQuantity == NULL){
                    l2l3p.dehQuantity = 0;
                }
                
                if(l2l3.Product_Category_Test__c == 'SHELL'){
                    l2l3p.shellQuantity = l2l3.Quantity__c;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                else if(l2l3p.shellQuantity == NULL){
                    l2l3p.shellQuantity = 0;
                }
                
                if(l2l3.Product_Category_Test__c == 'SPARE'){
                    l2l3p.spareQuantity = l2l3.Quantity__c;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                else if(l2l3p.spareQuantity == NULL){
                    l2l3p.spareQuantity = 0;
                }
                if(l2l3.Product_Category_Test__c == 'PNL'){
                    l2l3p.pnlQuantity = l2l3.Quantity__c;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                else if(l2l3p.pnlQuantity == NULL){
                    l2l3p.pnlQuantity = 0;
                }
                if(l2l3.Product_Category_Test__c == 'SFB'){
                    l2l3p.sfbQuantity = l2l3.Quantity__c;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                else if(l2l3p.sfbQuantity == NULL){
                    l2l3p.sfbQuantity = 0;
                }
                if(l2l3.Product_Category_Test__c == 'MFB'){
                    l2l3p.mfbQuantity = l2l3.Quantity__c;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                else if(l2l3p.mfbQuantity == NULL){
                    l2l3p.mfbQuantity = 0;
                }
                if(l2l3.Product_Category_Test__c == 'STR'){
                    l2l3p.strQuantity = l2l3.Quantity__c;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                else if(l2l3p.strQuantity == NULL){
                    l2l3p.strQuantity = 0;
                }
                if(l2l3.Product_Category_Test__c == 'SPRL'){
                    l2l3p.sprlQuantity = l2l3.Quantity__c;
                    l2l3p.ItemDescription = l2l3.Item_Description__c;
                }
                else if(l2l3p.sprlQuantity == NULL){
                    l2l3p.sprlQuantity = 0;
                }
            }
            
            l2l3p.PLMtotalQuantity = l2l3p.fehQuantity + l2l3p.dehQuantity + l2l3p.shellQuantity + l2l3p.spareQuantity;
            system.debug('l2l3p: ' +l2l3p);	
            filterList.add(l2l3p);
            
            l2l3p.PLStotalQuantity = l2l3p.pnlQuantity + l2l3p.sfbQuantity + l2l3p.mfbQuantity + l2l3p.spareQuantity;
            system.debug('l2l3p: ' +l2l3p);	
            filterList2.add(l2l3p);
            
            l2l3p.PLTtotalQuantity = l2l3p.strQuantity + l2l3p.pnlQuantity + l2l3p.sprlQuantity + l2l3p.spareQuantity;
            system.debug('l2l3p: ' +l2l3p);	
            filterList3.add(l2l3p);
            
            
        }
        System.debug('filterList: '+filterList);
    }
    
    /**********************************************************
@Description : This class used as a data container.
***********************************************************/
    
    public class L2L3Wrapper{
        public String sortingOrder { get; set; }
        public Integer SrNo { get; set; }
        public string L2ProductName { get; set; }
        public string ItemDescription { get; set; }
        public decimal fehQuantity { get; set; }
        public decimal dehQuantity { get; set; }
        public decimal shellQuantity { get; set; }
        public decimal pnlQuantity { get; set; }
        public decimal sfbQuantity { get; set; }
        public decimal mfbQuantity { get; set; }
        public decimal strQuantity { get; set; }
        public decimal sprlQuantity { get; set; }
        public decimal spareQuantity { get; set; }
        public decimal PLMtotalQuantity {get; set;}
        public decimal PLStotalQuantity {get; set;}
        public decimal PLTtotalQuantity {get; set;}
       // public L2_L3_product__c l2l3prod { get; set; }
        
        public L2L3Wrapper(String l2ProductName) {
            this.L2ProductName = l2ProductName;
        }
        
        public L2L3Wrapper(){
            
        }
    }
    
    /************************************************************
@description : This methods are for Downloading the Excel
*************************************************************/
    
    public PageReference downloadExcelPLM() {
        List<L2L3Wrapper> excelData = new List<L2L3Wrapper>();
        Integer srNo = 1;
        for (L2L3Wrapper PLM : filterList) {
            L2L3Wrapper excelRow = new L2L3Wrapper(PLM.L2ProductName);
            excelRow.SrNo = srNo;
            excelRow.ItemDescription = PLM.ItemDescription;
            excelRow.fehQuantity = PLM.fehQuantity;
            excelRow.dehQuantity = PLM.dehQuantity;
            excelRow.shellQuantity = PLM.shellQuantity;
            excelRow.spareQuantity = PLM.spareQuantity;
            excelRow.PLMtotalQuantity = PLM.PLMtotalQuantity;
            excelData.add(excelRow);
            srNo++;
        }
        
        excelExportData = excelData;
        
        return Page.vf_ExcelPage_PLM;
        
    }
    
    public PageReference downloadExcelPLS() {
        List<L2L3Wrapper> excelData = new List<L2L3Wrapper>();
        Integer srNo = 1;
        for (L2L3Wrapper PLM : filterList2) {
            L2L3Wrapper excelRow = new L2L3Wrapper(PLM.L2ProductName);
            excelRow.SrNo = srNo;
            excelRow.ItemDescription = PLM.ItemDescription;
            excelRow.pnlQuantity = PLM.pnlQuantity;
            excelRow.sfbQuantity = PLM.sfbQuantity;
            excelRow.mfbQuantity = PLM.mfbQuantity;
            excelRow.spareQuantity = PLM.spareQuantity;
            excelRow.spareQuantity = PLM.spareQuantity;
            excelData.add(excelRow);
            srNo++;
        }
        
        excelExportData = excelData;
        
        return Page.vf_ExcelPage_PLS;
    } 
    
     public PageReference downloadExcelPLT() {
        List<L2L3Wrapper> excelData = new List<L2L3Wrapper>();
        Integer srNo = 1;
        for (L2L3Wrapper PLT : filterList3) {
            L2L3Wrapper excelRow = new L2L3Wrapper(PLT.L2ProductName);
            excelRow.SrNo = srNo;
            excelRow.ItemDescription = PLT.ItemDescription;
            excelRow.strQuantity = PLT.strQuantity;
            excelRow.pnlQuantity = PLT.pnlQuantity;
            excelRow.sprlQuantity = PLT.sprlQuantity;
            excelRow.spareQuantity = PLT.spareQuantity;
            excelData.add(excelRow);
            srNo++;
        }
        
        excelExportData = excelData;
        
        return Page.vf_ExcelPage_PLT;
    } 
    
    /************************************************************
@description : This methods are for Downloading the PDF
*************************************************************/
    
    public PageReference downloadPDFPLM() {
        List<L2L3Wrapper> PDFData = new List<L2L3Wrapper>();
        Integer srNo = 1;
        for (L2L3Wrapper PLM : filterList) {
            L2L3Wrapper pdfRow = new L2L3Wrapper(PLM.L2ProductName);
            pdfRow.SrNo = srNo;
            pdfRow.ItemDescription = PLM.ItemDescription;
            pdfRow.fehQuantity = PLM.fehQuantity;
            pdfRow.dehQuantity = PLM.dehQuantity;
            pdfRow.shellQuantity = PLM.shellQuantity;
            pdfRow.spareQuantity = PLM.spareQuantity;
            pdfRow.PLMtotalQuantity = PLM.PLMtotalQuantity;
            PDFData.add(pdfRow);
            srNo++;
        }
        
        PDFExportData = PDFData;
        string pageURL =  '/apex/vf_PDF_PLM?'+PDFExportData;
        
        PageReference downloadPDFpage = new PageReference(pageURL);
        downloadPDFpage.getHeaders().put('content-disposition', 'attachment; filename=PLM_PartList_Data.pdf');
        
        return downloadPDFpage;
        
    }
    
    public PageReference downloadPDFPLS() {
        List<L2L3Wrapper> PDFData = new List<L2L3Wrapper>();
        Integer srNo = 1;
        for (L2L3Wrapper PLM : filterList2) {
            L2L3Wrapper pdfRow = new L2L3Wrapper(PLM.L2ProductName);
            pdfRow.SrNo = srNo;
            pdfRow.ItemDescription = PLM.ItemDescription;
            pdfRow.pnlQuantity = PLM.pnlQuantity;
            pdfRow.sfbQuantity = PLM.sfbQuantity;
            pdfRow.mfbQuantity = PLM.mfbQuantity;
            pdfRow.spareQuantity = PLM.spareQuantity;
            pdfRow.PLStotalQuantity = PLM.PLStotalQuantity;
            PDFData.add(pdfRow);
            srNo++;
        }
        
        PDFExportData = PDFData;
        string pageURL =  '/apex/vf_PDF_PLS?'+PDFExportData;
        
        PageReference downloadPDFpage = new PageReference(pageURL);
        downloadPDFpage.getHeaders().put('content-disposition', 'attachment; filename=PLS_PartList_Data.pdf');
        
        return downloadPDFpage;
        
    }
    
    public PageReference downloadPDFPLT() {
        List<L2L3Wrapper> PDFData = new List<L2L3Wrapper>();
        Integer srNo = 1;
        for (L2L3Wrapper PLM : filterList3) {
            L2L3Wrapper pdfRow = new L2L3Wrapper(PLM.L2ProductName);
            pdfRow.SrNo = srNo;
            pdfRow.ItemDescription = PLM.ItemDescription;
            pdfRow.strQuantity = PLM.strQuantity;
            pdfRow.pnlQuantity = PLM.pnlQuantity;
            pdfRow.sprlQuantity = PLM.sprlQuantity;
            pdfRow.spareQuantity = PLM.spareQuantity;
            pdfRow.PLTtotalQuantity = PLM.PLTtotalQuantity;
            PDFData.add(pdfRow);
            srNo++;
        }
        
        PDFExportData = PDFData;
        string pageURL =  '/apex/vf_PDF_PLT?'+PDFExportData;
        
        PageReference downloadPDFpage = new PageReference(pageURL);
        downloadPDFpage.getHeaders().put('content-disposition', 'attachment; filename=PLT_PartList_Data.pdf');
        
        return downloadPDFpage;
        
    }
    
}