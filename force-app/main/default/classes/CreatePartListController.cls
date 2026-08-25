/*
Name : CreatePartListController
Desc : this class use  to get partLIst from SAP and create into salesforce.
Author : Kuhinoor
*/

public with sharing class CreatePartListController {
    
    /*
    Name : getPartList
    Desc : this method used authorize and get the data from SAP.
    */
    @future(callout = true)
     public static void getPartList(String partListNumner, String itId) {
        Integration_Transaction__c it = new Integration_Transaction__c(Id = itId); 
         try {
            Tega_SAP_Credential__c sapOrg = Tega_SAP_Credential__c.getOrgDefaults();
            PartListWebServiceNew.ZWSPARTLIST  zwPartList = new  PartListWebServiceNew.ZWSPARTLIST();
            PartListWebServiceNew.ZPartlistSfResponse_element response = new PartListWebServiceNew.ZPartlistSfResponse_element();
            //Blob headerValue = Blob.valueOf('rfcuser1'+ ':' + 'Tega@1234');
            Blob headerValue = Blob.valueOf(sapOrg.Username__c+ ':' + sapOrg.Password__c);
            String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
            zwPartList.inputHttpHeaders_x = new map<String,String>();
            zwPartList.inputHttpHeaders_x.put('Authorization', authorizationHeader);
            //
            PartListWebServiceNew.TableOfZplmsgSfdc GtMsg = new PartListWebServiceNew.TableOfZplmsgSfdc();
            PartListWebServiceNew.TableOfZplmspSfdc GtSp = new PartListWebServiceNew.TableOfZplmspSfdc();
            PartListWebServiceNew.TableOfZpltab1Sfdc GtTab1 = new PartListWebServiceNew.TableOfZpltab1Sfdc();
            PartListWebServiceNew.TableOfZpltab2Sfdc GtTab2 = new PartListWebServiceNew.TableOfZpltab2Sfdc();
            PartListWebServiceNew.TableOfZpltab3Sfdc GtTab3 = new PartListWebServiceNew.TableOfZpltab3Sfdc();
            PartListWebServiceNew.TableOfZweightSfdc GtWeight = new PartListWebServiceNew.TableOfZweightSfdc();
            //

            response = zwPartList.ZPartlistSf(' ',GtMsg,GtSp,GtTab1,GtTab2,GtTab3,GtWeight,' ',' ', ' ', ' ',' ', ' ', partListNumner);
            
            //AK Changes 06/12/2022
            String responseMsg = response.ExMessage;
            if(responseMsg != ''){
                it.Status__c = 'fail';
                it.Error__c = responseMsg;
                //update it;  // already updaing in function last 
            }else{
                CreatePartList(response, it);
                it.Response__c +='\n'+ String.valueOf(response);      
                it.Status__c = 'Success';
                it.sync__c = true;
            }
        } catch (Exception ex) {
            it.Status__c = 'fail';
            it.Error__c = ex.getMessage()+ex.getLineNumber();
            TegaUtility.trackLogs( ex,  'CreatePartListController',  'getPartList');
     }

        update it;
       
    }

    /* 
    Name : CreatePartList
    Desc : this method used to create part list and related products records.
    param : response
    */ 
    public static void CreatePartList(PartListWebServiceNew.ZPartlistSfResponse_element response, Integration_Transaction__c it) {
        try {
        Set<String> branchCodeSet = new Set<String>();
        Set<String> salesOrgSet = new Set<String>();
        Map<String, String> salesOrgMap = new Map<String,String>();
        Map<String, Id> branchMap = new Map<String,Id>();
        List<Sales_Organization_Part_List__c> salesOrgpartList = new List<Sales_Organization_Part_List__c>();

        PartListWebServiceNew.TableOfZplmsgSfdc GtMsgObj = response.GtMsg;

        PartListWebServiceNew.TableOfZpltab1Sfdc GtTab1 = response.GtTab1;
        PartListWebServiceNew.Zpltab1Sfdc[] GtTab1List = GtTab1.item;
        PartListWebServiceNew.Zpltab1Sfdc GtTab1Obj = GtTab1List[0];

        for(PartListWebServiceNew.Zpltab1Sfdc tab1 : GtTab1List){
            branchCodeSet.add(tab1.ZLabor);
            salesOrgSet.add(tab1.SalesOrg);
        }

        List<Sales_Org__c> salesOrgList = [SELECT Id,Name FROM Sales_Org__c WHERE Name IN :salesOrgSet ];
        List<Branch__c> branchList = [SELECT Id,Branch_Code__c FROM Branch__c WHERE Branch_Code__c IN :branchCodeSet ];

        if(salesOrgList.size() > 0 ){
            for(Sales_Org__c sOrg : salesOrgList){
                salesOrgMap.put(sOrg.Name, sOrg.Id);
            }
        }
        if(branchList.size() > 0 ){
            for(Branch__c br : branchList){
                branchMap.put(br.Branch_Code__c, br.Id);
            }
        }

        Map<String, Sales_Org_Currency_Mapping__mdt> salesOrgCurrencyMap = Sales_Org_Currency_Mapping__mdt.getAll();
        Map<String, PartList_Revision_Mapping__mdt  > revisionMap = PartList_Revision_Mapping__mdt.getAll();

        system.debug('GtTab1Obj => '+GtTab1Obj);
        system.debug('GtTab1Obj.SfdcId => '+GtTab1Obj.SfdcId);
        
        List<Customer_Equipments__c> custEquip = [Select Id from Customer_Equipments__c where Id =: GtTab1Obj.EquipmentNo FOR UPDATE];
            
            
        // Create partList
        Part_List__c partList = new Part_List__c();
        
            partList.Name = GtTab1Obj.ZGmatnr; 
            partList.Description__c = GtTab1Obj.Gdesc;
            partList.CurrencyIsoCode = GtTab1Obj.Waers;
            partList.Customer__c = GtTab1Obj.SfdcId;
            //partList.Customer__c = '001Ff000001hmK3IAI';
            partList.BOM__c= GtTab1Obj.Ztext;
            partList.Delivery_Req__c = Decimal.valueOf(GtTab1Obj.Plifz);
            partList.Last_Offer_Number__c = GtTab1Obj.LofNum;
            partList.Last_Offer_Value_Foreign_Currency__c = Decimal.valueOf(GtTab1Obj.LofVal);
            partList.Version_Number_Component__c = GtTab1Obj.Revstatus;
            partList.HSN_Code__c = GtTab1Obj.HsnCode;
            partList.Direct_Quoted_Exchange_Rate__c = Decimal.valueOf(GtTab1Obj.Exrate);
            partList.Revision__c = String.isNotBlank(GtTab1Obj.Revstatus) ? revisionMap.get(GtTab1Obj.Revstatus).Revision_Number__c : 10;
            if(custEquip.size() > 0){
                partList.Customer_Equipment__c = custEquip[0].Id;
            }
        // Added by RC 21-11-22
        
        // Added by Ranjeet 21-11-22 - To avoid duplicate record creation for same part list number, checking the existing record with same name before insert

        List<Part_List__c> existingPartLists = [ SELECT Id, Name, Version_Number_Component__c , Active__c FROM Part_List__c  WHERE Name = :GtTab1Obj.ZGmatnr  ];
        
        String incomingVersion = GtTab1Obj.Revstatus;
        
        if(existingPartLists.size() > 0) {
            
            // checking for if any existing PLM record has the SAME version
            Part_List__c sameVersionRecord = null;
            for(Part_List__c existing : existingPartLists){
                if(existing.Version_Number_Component__c == incomingVersion){
                    sameVersionRecord = existing;
                    break;
                }
            }
            
            if(sameVersionRecord != null) {
                // CASE 2 — Same version exists → just UPDATE that record
                partList.Id       = sameVersionRecord.Id;
                partList.Active__c = true;
                System.debug('Case 2: Same version found - updating existing PLM: ' + partList);

            }
            
            else {
                // CASE 1 — Name exists but version is DIFFERENT
                // Step 1 — collecting ALL old PLM Ids (all revisions)
                Set<Id> oldPartListIds = new Set<Id>();
                List<Part_List__c> toDeactivate = new List<Part_List__c>();
                
                for(Part_List__c existing : existingPartLists){
                    oldPartListIds.add(existing.Id);
                    toDeactivate.add(new Part_List__c(
                        Id        = existing.Id,
                        Active__c = false          // deactivate ALL old revisions
                    ));
                }
                
                // Step 2 — deactivate ALL old PLM records
                if(toDeactivate.size() > 0){
                    update toDeactivate;
                }
                
                /*
                // Step 3 — find ALL L2/L3 products linked to ANY old PLM
                List<Product2> oldProducts = [
                    SELECT Id 
                    FROM Product2 
                    WHERE Part_List__c IN :oldPartListIds
                ];
                
                // Step 4 — deactivate ALL old products
                if(oldProducts.size() > 0){
                    for(Product2 p : oldProducts){
                        p.Active__c = false;
                    }
                    update oldProducts;
                } */
                
                // Step 5 — no Id on partList → upsert will INSERT brand new
                partList.Active__c = true;
                System.debug('Case 1: Version mismatch - deactivated all old PLMs, creating new: ' + partList);
            }
            
            
            
        }
            else {
                // CASE 3 — No PLM found at all → fresh insert
                partList.Active__c = true;
                System.debug('Case 3: No existing PLM found - inserting new: ' + partList);
            }
        
        //insert partList;
        upsert partList;

        // Create Sales org part List....
        if(GtTab1List != null && GtTab1List.size() > 0){
            for(PartListWebServiceNew.Zpltab1Sfdc tab1 : GtTab1List){
                salesOrgpartList.add( new Sales_Organization_Part_List__c( Part_List__c = partList.Id,
                    Sales_Org__c = salesOrgMap.get(tab1.SalesOrg) ,
                    Branch__c = branchMap.get(tab1.ZLabor)));
            }
        }
        

        if(salesOrgpartList.size() > 0 ){
            insert salesOrgpartList;
        }

        
        //Create L2 product..
        Map<String, Product2> L2ProductMap = new Map<String,Product2>();
        List<Sales_Organization_Product__c> salesorgProductList = new List<Sales_Organization_Product__c>();
        Id L2ProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Product_Zone_L2').getRecordTypeId();
        PartListWebServiceNew.TableOfZpltab2Sfdc GtTab2 = response.GtTab2;
        PartListWebServiceNew.Zpltab2Sfdc[] GtTab2List = GtTab2.item;

        
        // NEW: collect all incoming L2 codes and check which ones already exist as Product2 records
        Set<String> incomingL2Codes = new Set<String>();
        if(GtTab2List != null && GtTab2List.size() > 0){
            for(PartListWebServiceNew.Zpltab2Sfdc tab2 : GtTab2List){
                incomingL2Codes.add(tab2.ZMmatnr);
            }
        }
 
        Map<String, Product2> existingL2ByCode = new Map<String,Product2>();
        if(!incomingL2Codes.isEmpty()){
            for (Product2 p : [SELECT Id, ProductCode FROM Product2
                                WHERE ProductCode IN :incomingL2Codes AND Product_Level__c = 'L2']) {
                existingL2ByCode.put(p.ProductCode, p);
            }
        }
 
        if(GtTab2List != null && GtTab2List.size() > 0){
            for(PartListWebServiceNew.Zpltab2Sfdc tab2 : GtTab2List){
                String key = tab2.ZMmatnr;
                if(!L2ProductMap.containsKey(key)){
                    Product2 l2Product = existingL2ByCode.containsKey(key)
                        ? existingL2ByCode.get(key)               // already exists -> reuse Id -> UPDATE
                        : new Product2(                           // not found -> new record -> INSERT
                            ProductCode = tab2.ZMmatnr,
                            Name = tab2.ZMmatnr,
                            recordTypeId = L2ProductRecordTypeId,
                            Product_Level__c = 'L2');
 
                    l2Product.Part_List__c          = partList.Id;
                    l2Product.Description           = tab2.Mdesc;
                    l2Product.HSN_Code__c            = tab2.HsnCode;
                    l2Product.Quantity__c            = Decimal.valueOf(tab2.Menge);
                    l2Product.QuantityUnitOfMeasure  = tab2.Meins;
                    l2Product.Active__c              = true;
 
                    L2ProductMap.put(key, l2Product);
                }
            }
        }
 
        if(L2ProductMap.values().size() > 0 ){
            upsert L2ProductMap.values();   // was: insert
        }
 
        if(GtTab2List != null && GtTab2List.size() > 0){
            for(PartListWebServiceNew.Zpltab2Sfdc tab2 : GtTab2List){
                salesorgProductList.add(new Sales_Organization_Product__c( Product__c = L2ProductMap.get(tab2.ZMmatnr).Id,
                Sales_Org__c = salesOrgMap.get(tab2.SalesOrg)));
            }
        }
 
        if (salesorgProductList.size() > 0) {
        insert salesorgProductList;
        }
		
            
            
        /*
       //Create L2 product..
        Map<String, Product2> L2ProductMap = new Map<String,Product2>();
        List<Sales_Organization_Product__c> salesorgProductList = new List<Sales_Organization_Product__c>();
        Id L2ProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Product_Zone_L2').getRecordTypeId();
        PartListWebServiceNew.TableOfZpltab2Sfdc GtTab2 = response.GtTab2;
        PartListWebServiceNew.Zpltab2Sfdc[] GtTab2List = GtTab2.item;
        
        if(GtTab2List != null && GtTab2List.size() > 0){
            for(PartListWebServiceNew.Zpltab2Sfdc tab2 : GtTab2List){
                String key = tab2.ZMmatnr;
                if(!L2ProductMap.containsKey(key)){            
                    L2ProductMap.put(key ,new Product2( ProductCode = tab2.ZMmatnr,
                    Name = tab2.ZMmatnr,
                    Part_List__c = partList.Id,
                    recordTypeId = L2ProductRecordTypeId,
                    Description = tab2.Mdesc,
                    HSN_Code__c=tab2.HsnCode,
                    Quantity__c = Decimal.valueOf(tab2.Menge),
                    Product_Level__c = 'L2',
                    QuantityUnitOfMeasure = tab2.Meins)); 
                }
            }
        }

        if(L2ProductMap.values().size() > 0 ){
            insert L2ProductMap.values();
        }

        if(GtTab2List != null && GtTab2List.size() > 0){
            for(PartListWebServiceNew.Zpltab2Sfdc tab2 : GtTab2List){
                salesorgProductList.add(new Sales_Organization_Product__c( Product__c = L2ProductMap.get(tab2.ZMmatnr).Id,
                Sales_Org__c = salesOrgMap.get(tab2.SalesOrg)));
            }
        }
    

        if (salesorgProductList.size() > 0) {
        insert salesorgProductList;
        } */

         //Create L3 product..
        Map<String, Sales_Organization_Product__c> L3SalesOrgProductMap = new Map<String, Sales_Organization_Product__c>();
        Map<String, Product2> L3ProductMap = new Map<String,Product2>();
        PartListWebServiceNew.TableOfZpltab3Sfdc GtTab3 = response.GtTab3;
        PartListWebServiceNew.Zpltab3Sfdc[] GtTab3List = GtTab3.item;
        
            if(GtTab3List.size() != NULL){
                it.Response__c += 'TAB3: '+GtTab3List.size();
            }
        Id L3ProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Product_L3').getRecordTypeId();
 
        // check whether L3 product already exists in Salesforce before creating a new one
        Set<String> incomingL3Codes = new Set<String>();
        if(GtTab3List != null && GtTab3List.size() > 0){
            for(PartListWebServiceNew.Zpltab3Sfdc tab3 : GtTab3List){
                incomingL3Codes.add(tab3.ZDmatnr);
            }
        }
 
        Map<String, Product2> existingL3ByCode = new Map<String,Product2>();
        if(!incomingL3Codes.isEmpty()){
            for (Product2 p : [SELECT Id, ProductCode FROM Product2
                                WHERE ProductCode IN :incomingL3Codes AND Product_Level__c = 'L3']) {
                existingL3ByCode.put(p.ProductCode, p);
            }
        }
 
        if(GtTab3List != null && GtTab3List.size() > 0){
            for(PartListWebServiceNew.Zpltab3Sfdc tab3 : GtTab3List){
                if(!L3ProductMap.containsKey(tab3.ZDmatnr)){ 
                    Product2 l2Product = L2ProductMap.get(tab3.ZDmatnr);
                    String key = tab3.ZDmatnr;
 
                    if(existingL3ByCode.containsKey(key)){
                        // already exists -> don't create, just link (reuse the existing record)
                        L3ProductMap.put(key, existingL3ByCode.get(key));
                    } else {
                        // not found -> create new
                        L3ProductMap.put(key ,new Product2( ProductCode = tab3.ZDmatnr,
                        Name = tab3.ZDmatnr,
                        recordTypeId = L3ProductRecordTypeId,
                        Description = tab3.Ddesc,
                        Part_List__c = l2Product != null ? l2Product.Part_List__c : null,
                        QuantityUnitOfMeasure = tab3.Meins,
                        Product_Type__c = tab3.Mtart,
                        HSN_Code__c=tab3.HsnCode,
                        Product_group__c = tab3.Matkl,
                        Procurement_Type__c = tab3.Beskz,
                        Document_Number__c = tab3.Zeinr,
                        Product_Level__c = 'L3'
                        ));
                    }
                }
            }
        }
        
 
        // separate the truly new L3 products (no Id yet) so we only insert those, not the existing ones
        List<Product2> newL3Products = new List<Product2>();
        for(Product2 p : L3ProductMap.values()){
            if(p.Id == null){
                newL3Products.add(p);
            }
        }
        if(newL3Products.size() > 0 ){
            insert newL3Products;
        }
 
        if(GtTab3List != null && GtTab3List.size() > 0){
            for(PartListWebServiceNew.Zpltab3Sfdc tab3 : GtTab3List){
                if(!L3SalesOrgProductMap.containsKey(tab3.ZDmatnr)){
                    L3SalesOrgProductMap.put( tab3.ZDmatnr,new Sales_Organization_Product__c( Product__c = L3ProductMap.get(tab3.ZDmatnr).Id,
                    Sales_Org__c = salesOrgMap.get(tab3.SalesOrg),
                    Price__c =  Decimal.valueOf(tab3.Price),
                    CurrencyIsoCode = salesOrgCurrencyMap.get(tab3.SalesOrg).Currency__c
                    ));
                }
            }
        }
 
        
        if(L3SalesOrgProductMap.values().size() > 0 ){
            insert L3SalesOrgProductMap.values();
        }      
 

       //Create L2L3 product..  
        Map<String, L2_L3_product__c> L2L3ProductMap = new Map<String, L2_L3_product__c>();
 
        // check whether this L2-L3 link already exists under this Part List before creating a new one
        Map<String, L2_L3_product__c> existingL2L3ByKey = new Map<String,L2_L3_product__c>();
        if(L2ProductMap.values().size() > 0 && L3ProductMap.values().size() > 0){
            Set<Id> l2Ids = new Set<Id>();
            for(Product2 p : L2ProductMap.values()){ if(p.Id != null){ l2Ids.add(p.Id); } }
            Set<Id> l3Ids = new Set<Id>();
            for(Product2 p : L3ProductMap.values()){ if(p.Id != null){ l3Ids.add(p.Id); } }
 
            if(!l2Ids.isEmpty() && !l3Ids.isEmpty()){
                for(L2_L3_product__c existingLink : [SELECT Id, Product_L2__c, Product_L3__c, Quantity__c
                                                        FROM L2_L3_product__c
                                                        WHERE Part_List__c = :partList.Id
                                                        AND Product_L2__c IN :l2Ids
                                                        AND Product_L3__c IN :l3Ids]){
                    existingL2L3ByKey.put(existingLink.Product_L3__c+''+existingLink.Product_L2__c, existingLink);
                }
            }
        }
 
        if(GtTab3List != null && GtTab3List.size() > 0){
            for(PartListWebServiceNew.Zpltab3Sfdc tab3 : GtTab3List){
                if(!L2L3ProductMap.containsKey(tab3.ZDmatnr+tab3.ZMmatnr)){
                    Id l2Id = L2ProductMap.get(tab3.ZMmatnr).Id;
                    Id l3Id = L3ProductMap.get(tab3.ZDmatnr).Id;
                    String recordKey = l3Id+''+l2Id;
 
                    if(existingL2L3ByKey.containsKey(recordKey)){
                        // already linked -> don't create, just reuse the existing link
                        L2L3ProductMap.put(tab3.ZDmatnr+tab3.ZMmatnr, existingL2L3ByKey.get(recordKey));
                    } else {
                        // not linked yet -> create new
                        L2L3ProductMap.put(tab3.ZDmatnr+tab3.ZMmatnr, new L2_L3_product__c(
                            Part_List__c = partList.Id,
                            Product_L2__c = l2Id,
                            Product_L3__c = l3Id,
                            Quantity__c = Decimal.valueOf(tab3.Menge)
                        ));
                    }
                }
            }
        }
        
 
        // separate the truly new L2L3 links (no Id yet) so we only insert those, not the existing ones
        List<L2_L3_product__c> newL2L3Links = new List<L2_L3_product__c>();
        for(L2_L3_product__c l : L2L3ProductMap.values()){
            if(l.Id == null){
                newL2L3Links.add(l);
            }
        }
        if(newL2L3Links.size() > 0 ){
            insert newL2L3Links;
        }
 
        /*List<Sales_Organization_L2_L3__c> salesOrgL2L3List = new List<Sales_Organization_L2_L3__c>();
        if(GtTab3List != null && GtTab3List.size() > 0){
            for(PartListWebServiceNew.Zpltab3Sfdc tab3 : GtTab3List){
                salesOrgL2L3List.add(new Sales_Organization_L2_L3__c( 
                    L2_L3_Product__c = L2L3ProductMap.get(tab3.ZDmatnr+tab3.ZMmatnr).Id,
                    Sales_Org__c =  salesOrgMap.get(tab3.SalesOrg),
                    Price__c = Decimal.valueOf(tab3.Price)
                    ));
            }
        }
    
 
        if(salesOrgL2L3List.size() > 0 ){
            insert salesOrgL2L3List;
        }*/

        /*List<Sales_Organization_L2_L3__c> salesOrgL2L3List = new List<Sales_Organization_L2_L3__c>();
        if(GtTab3List != null && GtTab3List.size() > 0){
            for(PartListWebServiceNew.Zpltab3Sfdc tab3 : GtTab3List){
                salesOrgL2L3List.add(new Sales_Organization_L2_L3__c( 
                    L2_L3_Product__c = L2L3ProductMap.get(tab3.ZDmatnr+tab3.ZMmatnr).Id,
                    Sales_Org__c =  salesOrgMap.get(tab3.SalesOrg),
                    Price__c = Decimal.valueOf(tab3.Price)
                    ));
            }
        }
    

        if(salesOrgL2L3List.size() > 0 ){
            insert salesOrgL2L3List;
        }*/

        // Create weight table
        List<Item_Weight__c> itemWeightList = new List<Item_Weight__c>();
        PartListWebServiceNew.TableOfZweightSfdc GtWeight = response.GtWeight;
        PartListWebServiceNew.ZweightSfdc[] GtWeightList = GtWeight.item;

        if(GtWeightList != null && GtWeightList.size() > 0){
            for(PartListWebServiceNew.ZweightSfdc wght : GtWeightList){
                itemWeightList.add(new Item_Weight__c(
                    Product_L3__c = L3ProductMap.get(wght.Matnr).Id,
                    Net_Weight__c = Decimal.valueOf(wght.Ntgew)
                ));
            }
        }
        

        if(itemWeightList.size() > 0 ){
            insert itemWeightList;
        }
        
          
        System.debug('#L3SalesOrgProductMap:'+json.serialize(L3SalesOrgProductMap));
        System.debug('#L3SalesOrgProductMap Size:'+L3SalesOrgProductMap.size());
        System.debug('#L3ProductMap:'+json.serialize(L3ProductMap));
        System.debug('#L3ProductMap Size:'+L3ProductMap.size());
        System.debug('#GtTab3:'+GtTab3);
        System.debug('#GtTab3List:'+json.serialize(GtTab3List));
        System.debug('#GtTab3List Size:'+GtTab3List.size());
        
        
        // Create last Sales Price
        Map<String, SAP_Last_Sale_Price__c> lastSalesPriceMap = new Map<String, SAP_Last_Sale_Price__c>();
        List<Sales_Org_Last_SAP_SO__c> salesOrglastSAPList = new List<Sales_Org_Last_SAP_SO__c>();
        
        PartListWebServiceNew.TableOfZplmspSfdc GtSp = response.GtSp;
        PartListWebServiceNew.ZplmspSfdc[] GtSpList = GtSp.item;
        System.debug('GtSpList-->>'+GtSpList);
        
        if(GtSpList != null && GtSpList.size() > 0){
            for(PartListWebServiceNew.ZplmspSfdc sp : GtSpList){
                System.debug('sp-->>'+sp);
                System.debug('#GtSp:'+GtSp);
                System.debug('#GtSpList:'+json.serialize(GtSpList));
                System.debug('#GtSpList Size:'+GtSpList.size());
                System.debug('#lastSalesPriceMap:'+lastSalesPriceMap);
                System.debug('#lastSalesPriceMap Size:'+lastSalesPriceMap.size());
                                if(!lastSalesPriceMap.containsKey(sp.ZDmatnr)){
                    System.debug('@Line 297');
                    //SK - 010223 : PartList Null pointer Fix
                    if(L3ProductMap.containsKey(sp.ZDmatnr)){
                    lastSalesPriceMap.put(sp.ZDmatnr,  new SAP_Last_Sale_Price__c(
                        Product_L3__c = L3ProductMap.get(sp.ZDmatnr).Id));
                    }
                }
            }
        }
        

        
        if(lastSalesPriceMap.values().size() > 0){
            insert lastSalesPriceMap.values();
        }
        System.debug('#GtTab3List :'+GtTab3List);
        System.debug('#L3ProductMap:'+L3ProductMap);
        System.debug('#GtSp:'+GtSp);
        System.debug('#GtSpList:'+GtSpList);
        System.debug('#lastSalesPriceMap:'+lastSalesPriceMap);
        System.debug('#salesOrgMap:'+salesOrgMap);
        

        if(GtSpList != null && GtSpList.size() > 0){
            for(PartListWebServiceNew.ZplmspSfdc sp : GtSpList){
                system.debug('#sp:'+sp);
                if(L3ProductMap.containsKey(sp.ZDmatnr)){
                Sales_Org_Last_SAP_SO__c salesOrgLastSAPRec = new Sales_Org_Last_SAP_SO__c();
              
                    salesOrgLastSAPRec.Sales_Org__c = salesOrgMap.get(sp.SalesOrg);
                     System.debug('#SalesOrg1:'+sp.SalesOrg);
                     System.debug('#SalesOrg2:'+salesOrgMap.get(sp.SalesOrg));
                
                    
                salesOrgLastSAPRec.SAP_Last_Sale__c = lastSalesPriceMap.get(sp.ZDmatnr).Id;  
                salesOrgLastSAPRec.Last_Sales_Price__c = Decimal.valueOf(sp.SalesPrice);
                if(lastSalesPriceMap.containsKey(sp.SalesOrg)){   
                    salesOrgLastSAPRec.CurrencyIsoCode = salesOrgCurrencyMap.get(sp.SalesOrg).Currency__c;
                }
                salesOrgLastSAPRec.Sales_Order__c = sp.SalesOrder;
                salesOrgLastSAPRec.Offer_Number__c = sp.OfferNo;
                if(sp.Audat != '0000-00-00'){
                    salesOrgLastSAPRec.Last_Sales_Date__c = Date.valueOf(sp.Audat);
                }
                if(sp.OrderDate != '0000-00-00'){
                    salesOrgLastSAPRec.Order_date__c = Date.valueOf(sp.OrderDate);
                }
                if(sp.OfferDate != '0000-00-00'){
                    salesOrgLastSAPRec.OfferDate__c = Date.valueOf(sp.OfferDate);
                }
                salesOrglastSAPList.add(salesOrgLastSAPRec);
                }
            }
        }        
        
        if(salesOrglastSAPList.size() > 0 ){
            insert salesOrglastSAPList;
            System.debug('#salesOrglastSAPList:'+salesOrglastSAPList);
        }
           } catch (Exception ex) {
            it.Status__c = 'fail';
            it.Error__c = ex.getMessage()+ex.getLineNumber();
            TegaUtility.trackLogs( ex,  'CreatePartListController',  'CreatePartList');
     } 
    }
   
    
   
}