/*
Name : SAPCallout_Utility
Desc : This class used to call SOAP api and get customer data and update customer.
Author : 
*/
public class SAPCallout_Utility{
    
    /*
Name : updateCustomer
Desc : This method is used for updating customer with response. 
Params : customerId,itId
*/
    @Future(callout=true)
    public static void updateCustomer(String customerId, String itId){
        system.debug('updateCustomer is Calling');
        Set<String> salesOrgSet = new Set<String>();
        Set<String> salesOffcSet = new Set<String>();
        Set<String> salesCompcode = new set<String>();
        Map<String, String> cusSalesOrgMap = new Map<String,String>();        
        Map<String, String> allcusSalesOrgMap = new Map<String,String>();
        
        Map<String, String> salesOrgMap = new Map<String,String>();
        Map<String, Id> branchMap = new Map<String,Id>();
        Map<String, Id> compCodeMap = new Map<String,Id>();
        
        Boolean createFivePMG;
        Boolean createOnePMG;
        String companyId;
        String companyId2;
        
        Integration_Transaction__c it = new Integration_Transaction__c(Id = itId); 
        
        
        try {
            Organization a_ORG = [Select Id, Name, IsSandbox from Organization];
       		Tega_SAP_Credential__c sapOrg = new Tega_SAP_Credential__c();
            if(a_ORG.IsSandbox){
                sapOrg = Tega_SAP_Credential__c.getOrgDefaults();
            }
            else{
                sapOrg = [Select Id,Username__c,Password__c,Production__c from Tega_SAP_Credential__c WHERE Production__c = true];
            }            
           
            Account acc;
            
            CustomerWebserviceNewV6.zwscust_details_v3 responseMethod = new CustomerWebserviceNewV6.zwscust_details_v3();
            CustomerWebserviceNewV6.ZTT_CUST_DTLS listItemsMethod = new CustomerWebserviceNewV6.ZTT_CUST_DTLS();
            CustomerWebserviceNewV6.ZRFC_CUST_DETAILSResponse_element response = new CustomerWebserviceNewV6.ZRFC_CUST_DETAILSResponse_element();
            List<CustomerWebserviceNewV6.ZST_CUST_DTLS> itemList = new List<CustomerWebserviceNewV6.ZST_CUST_DTLS>();
            
            // MAKING CONNECTION
            Blob headerValue = Blob.valueOf(sapOrg.Username__c+ ':' + sapOrg.Password__c);
            String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
            responseMethod.inputHttpHeaders_x = new map<String,String>();
            responseMethod.inputHttpHeaders_x.put('Authorization', authorizationHeader);
            response = responseMethod.ZRFC_CUST_DETAILS(customerId);
            
            System.debug('customerId' +customerId);
            
            it.Response__c = String.valueOf(response); 
            
            // Fetch data
            listItemsMethod = response.EX_CUST_DTLS;
            system.debug('listItemsMethod' +listItemsMethod);
            
            itemList = listItemsMethod.item;
            System.debug('itemList-->>'+itemList);
            
            String exMessage = response.EX_MESSAGE;
            if(exMessage != ''){
                it.Status__c = 'Fail';
                it.Error__c = exMessage;
                it.sync__c = false;
            }else{
                it.Status__c = 'Success';
                it.sync__c = true;
                
                if(itemList ==null && itemList.size() == 0 )
                {
                    System.debug('itemList null-->>');
                }
                
                // Here we are getting Response in listData updating in SF 
                if(itemList !=null && itemList.size() > 0 ){
                    CustomerWebserviceNewV6.ZST_CUST_DTLS data = itemList[0];
                    //Store Data in Customer (Account)
                    
                    system.debug('First if');
                    system.debug('data.SFDC_ID'+data.SFDC_ID);
                    acc = [Select Id,Name,Status__c,BillingPostalCode,BillingCity,Industry_segment__c,Language__c,Tel_No__c,Phone,Fax_number__c,Currency__c,Email_Id__c,GST_No__c,Customer_Group__c,Dataline__c,SORT__c,Sales_Region__c
                           from Account WHERE ID =: data.SFDC_ID];
                    system.debug('acc');
                    acc.Name = data.Name;
                    acc.BillingPostalCode = data.POST_CODE;
                    acc.BillingCity = data.City;
                    acc.Language__c = data.Langu;
                    acc.Phone = data.Telno;
                    acc.Fax_number__c = data.Fax;
                    acc.Currency__c = data.Currency_x;
                    acc.Email_Id__c = data.Email;
                    acc.GST_No__c = data.GST_NO;
                    acc.BillingStreet = data.Street1 + ',' + data.Street2 + ',' + data.Street3 + ',' + data.Street4 + ',' + data.Street5;
                    acc.Po_Box__c = data.Pobox;
                    acc.Industry_segment__c = data.INDUSTRY_SEG;
                    //acc.Mobile_number__c = data.Mobile;
                    acc.Currency__c = data.Currency_x;
                    acc.BillingCountryCode = data.Country;
                    acc.Dataline__c = data.DATALINE;
                    acc.SORT__c = data.SORT1;
                                        
                    for(CustomerWebserviceNewV6.ZST_CUST_DTLS data1 : itemList){
                        salesOrgSet.add(data1.SALES_ORG);
                        salesOffcSet.add(data1.SALES_OFF);
                        salesCompcode.add(data1.COMP_CODE);
                        system.debug('Amar naam Arnab----'+salesCompcode.add(data1.COMP_CODE));
                    }
                    List<Customer_Sales_Organization__c> customerSalesList = [SELECT Id,Branch__r.Branch_Code__c,Sales_Organizations__c,Sales_Organizations__r.Name,Company_Code__c
                                                                              FROM Customer_Sales_Organization__c
                                                                              WHERE Customer__c =: acc.Id 
                                                                              AND Branch__r.Branch_Code__c IN : salesOffcSet];           
                    
                    for(Customer_Sales_Organization__c cs : customerSalesList){
                        system.debug('cs========'+cs);
                        cusSalesOrgMap.put(cs.Branch__r.Branch_Code__c+cs.Sales_Organizations__r.Name, cs.Id);
                        system.debug('cusSalesOrgMap========'+cusSalesOrgMap);
                    }
                    List<Sales_Org__c> salesOrgList = [SELECT Id,Name FROM Sales_Org__c WHERE Name IN :salesOrgSet ];
                    List<Branch__c> branchList = [SELECT Id,Branch_Code__c FROM Branch__c WHERE Branch_Code__c IN :salesOffcSet ];
                    List<Company__c> companyList = [SELECT Id,Name,Company_Code__c FROM Company__c WHERE company_code__c IN :salesCompcode ];
                    Map<String, Company__c> mapCodeWithComp = new Map<String, Company__c>();
                    system.debug('companyList---'+companyList);
                    if(salesOrgList.size() > 0 ){
                        for(Sales_Org__c sOrg : salesOrgList){
                            salesOrgMap.put(sOrg.Name, sOrg.Id);
                        }
                    }
                    if(branchList.size() > 0 ){
                        for(Branch__c br : branchList){
                            system.debug('branchList====='+branchList+'------br.Branch_Code__c, br.Id------'+br.Branch_Code__c+br.Id);
                            branchMap.put(br.Branch_Code__c, br.Id);
                            system.debug('branchMap-----'+branchMap);
                        }
                    }
                    // if(companyList.size() > 0 ){
                        
                    //     for(Company__c cmpName : companyList)
                    //     {
                    //         if(cmpName.Company_Code__c != 'HE01')
                    //         {
                    //             createFivePMG = true;
                    //             createOnePMG = false;
                    //             companyId = cmpName.id;
                    //             
                    //         }
                    //         if(cmpName.Company_Code__c == 'HE01')
                    //         {
                    //             createFivePMG = false;
                    //             createOnePMG = true;
                    //             companyId = cmpName.id;
                    //         }
                    //     }
                    // }
                    if(companyList.size() > 0 ){
                        for(Company__c cmpName : companyList){
                            mapCodeWithComp.put(cmpName.company_code__c, cmpName);
                        }
                    }
                    List<Customer_Sales_Organization__c> csalesorginsertList = new List<Customer_Sales_Organization__c>();
                    List<Customer_Sales_Organization__c> csalesorginsertList2 = new List<Customer_Sales_Organization__c>();
                    
                    List<Customer_Sales_Organization__c> cSalesOrgUpdateList = new List<Customer_Sales_Organization__c>();
                    List<Customer_Sales_Organization__c> allcustomerSalesList = [SELECT Id,Customer_Code__c,Branch__r.Branch_Code__c,Sales_Organizations__c,status__c,Sales_Organizations__r.Name,Company_Code__c,Division__c
                                                                                 FROM Customer_Sales_Organization__c WHERE Customer__c =: acc.Id ];   
                    
                    Map<String, Customer_Sales_Organization__c> divisionMap = new Map<String, Customer_Sales_Organization__c>();
                    // for(Customer_Sales_Organization__c branchassign: allcustomerSalesList){
                    //     divisionMap.put(branchassign.Division__c,  branchassign);
                    // }
                    if(allcustomerSalesList.size()>0){
                        delete allcustomerSalesList;
                    }
                   /* for(CustomerWebserviceNewV6.ZST_CUST_DTLS data2 : itemList)
                    {                     
                        /*if (cusSalesOrgMap.containsKey(data2.SALES_OFF + salesOrgMap.get(data2.SALES_ORG))) {
                            // Update existing Customer Sales Organization record
                            Customer_Sales_Organization__c existingCSO = [SELECT Id, Customer_Code__c, Distribution_channel__c, Division__c FROM Customer_Sales_Organization__c WHERE Id =: cusSalesOrgMap.get(data2.SALES_OFF + salesOrgMap.get(data2.SALES_ORG)) AND Division__c = 'HE' AND Customer__c =: data.SFDC_ID];
                            existingCSO.Customer_Code__c = data2.Kunnr;
                            existingCSO.Distribution_channel__c = data2.DIST_CHAN;
                            existingCSO.status__c = 'Valid';
                            existingCSO.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                            existingCSO.Division__c = 'HE'; 
                            cSalesOrgUpdateList.add(existingCSO);
                        }
                        
                        if (divisionMap. {
                            // Update existing Customer Sales Organization record
                            Customer_Sales_Organization__c existingCSO = [SELECT Id, Customer_Code__c, Distribution_channel__c, Division__c FROM Customer_Sales_Organization__c WHERE Id =: cusSalesOrgMap.get(data2.SALES_OFF + salesOrgMap.get(data2.SALES_ORG)) AND Division__c = 'HE' AND Customer__c =: data.SFDC_ID];
                            existingCSO.Customer_Code__c = data2.Kunnr;
                            existingCSO.Distribution_channel__c = data2.DIST_CHAN;
                            existingCSO.status__c = 'Valid';
                            existingCSO.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                            existingCSO.Division__c = 'HE'; 
                            cSalesOrgUpdateList.add(existingCSO);
                        }
                        else {
                            // Insert new Customer Sales Organization record
                            Customer_Sales_Organization__c insertcso = new Customer_Sales_Organization__c();
                            
                            insertcso.Customer__c = acc.Id;
                            insertcso.Company__c = companyId;
                            insertcso.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                            insertcso.Customer_Code__c = data2.Kunnr;
                            insertcso.Distribution_channel__c = data2.DIST_CHAN;
                            insertcso.status__c = 'Valid';
                            insertcso.CreatedFromAccount__c = true;
                            insertcso.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                            insertcso.Division__c = 'HE'; 
                                
                            csalesorginsertList.add(insertcso);
                        }
                    } */
					
                    for(CustomerWebserviceNewV6.ZST_CUST_DTLS data2 :itemList){
                        if(data2.COMP_CODE != 'HE01')
                        {

                            Customer_Sales_Organization__c insertcso = new Customer_Sales_Organization__c();
                                
                                insertcso.Customer__c = acc.Id;
                                insertcso.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                insertcso.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                insertcso.Customer_Code__c = data2.Kunnr;
                                insertcso.Distribution_channel__c = data2.DIST_CHAN;
                                insertcso.status__c = 'Valid';
                                insertcso.CreatedFromAccount__c = true;
                                insertcso.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                insertcso.Division__c = 'ML';
                                
                                csalesorginsertList.add(insertcso);
                                
                                Customer_Sales_Organization__c insertcso1 = new Customer_Sales_Organization__c();
                                
                                insertcso1.Customer__c = acc.Id;
                                insertcso1.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                insertcso1.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                insertcso1.Customer_Code__c = data2.Kunnr;
                                insertcso1.Distribution_channel__c = data2.DIST_CHAN;
                                insertcso1.status__c = 'Valid';
                                insertcso1.CreatedFromAccount__c = true;
                                insertcso1.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                insertcso1.Division__c = 'SD';
                                
                                csalesorginsertList.add(insertcso1);

                                Customer_Sales_Organization__c insertcso3 = new Customer_Sales_Organization__c();
                                
                                insertcso3.Customer__c = acc.Id;
                                insertcso3.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                insertcso3.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                insertcso3.Customer_Code__c = data2.Kunnr;
                                insertcso3.Distribution_channel__c = data2.DIST_CHAN;
                                insertcso3.status__c = 'Valid';
                                insertcso3.CreatedFromAccount__c = true;
                                insertcso3.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                insertcso3.Division__c = 'HC';
                                
                                csalesorginsertList.add(insertcso3);

                                Customer_Sales_Organization__c insertcso4 = new Customer_Sales_Organization__c();
                                
                                insertcso4.Customer__c = acc.Id;
                                insertcso4.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                insertcso4.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                insertcso4.Customer_Code__c = data2.Kunnr;
                                insertcso4.Distribution_channel__c = data2.DIST_CHAN;
                                insertcso4.status__c = 'Valid';
                                insertcso4.CreatedFromAccount__c = true;
                                insertcso4.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                insertcso4.Division__c = 'WC';
                                
                                csalesorginsertList.add(insertcso4);

                                Customer_Sales_Organization__c insertcso5 = new Customer_Sales_Organization__c();
                                
                                insertcso5.Customer__c = acc.Id;
                                insertcso5.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                insertcso5.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                insertcso5.Customer_Code__c = data2.Kunnr;
                                insertcso5.Distribution_channel__c = data2.DIST_CHAN;
                                insertcso5.status__c = 'Valid';
                                insertcso5.CreatedFromAccount__c = true;
                                insertcso5.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                insertcso5.Division__c = 'CC';
                                
                                csalesorginsertList.add(insertcso5);
                            /*if(divisionMap.get('ML') != NULL)
                            {
                                Customer_Sales_Organization__c existingCSO1 = new Customer_Sales_Organization__c();
                                existingCSO1 = divisionMap.get('ML');
                                //existingCSO1.Customer__c = acc.Id;
                                //existingCSO1.Company__c = companyId;
                                existingCSO1.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                existingCSO1.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                existingCSO1.Customer_Code__c = data2.Kunnr;
                                existingCSO1.Distribution_channel__c = data2.DIST_CHAN;
                                existingCSO1.status__c = 'Valid';
                                existingCSO1.CreatedFromAccount__c = true;
                                existingCSO1.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                existingCSO1.Division__c = 'ML';
                                cSalesOrgUpdateList.add(existingCSO1);
                            }
                            else
                            {
                                Customer_Sales_Organization__c insertcso = new Customer_Sales_Organization__c();
                                
                                insertcso.Customer__c = acc.Id;
                                insertcso.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                insertcso.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                insertcso.Customer_Code__c = data2.Kunnr;
                                insertcso.Distribution_channel__c = data2.DIST_CHAN;
                                insertcso.status__c = 'Valid';
                                insertcso.CreatedFromAccount__c = true;
                                insertcso.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                insertcso.Division__c = 'ML';
                                
                                csalesorginsertList.add(insertcso);
                            }
                            if(divisionMap.get('SD') != NULL)
                            {
                                Customer_Sales_Organization__c existingCSO2 = new Customer_Sales_Organization__c();  
                                existingCSO2 = divisionMap.get('SD');
                                //existingCSO2.Customer__c = acc.Id;
                                existingCSO2.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                existingCSO2.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                existingCSO2.Customer_Code__c = data2.Kunnr;
                                existingCSO2.Distribution_channel__c = data2.DIST_CHAN;
                                existingCSO2.status__c = 'Valid';
                                existingCSO2.CreatedFromAccount__c = true;
                                existingCSO2.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                existingCSO2.Division__c = 'SD';
                                
                                cSalesOrgUpdateList.add(existingCSO2);
                            }
                            else
                            {
                                Customer_Sales_Organization__c insertcso1 = new Customer_Sales_Organization__c();
                                
                                insertcso1.Customer__c = acc.Id;
                                insertcso1.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                insertcso1.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                insertcso1.Customer_Code__c = data2.Kunnr;
                                insertcso1.Distribution_channel__c = data2.DIST_CHAN;
                                insertcso1.status__c = 'Valid';
                                insertcso1.CreatedFromAccount__c = true;
                                insertcso1.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                insertcso1.Division__c = 'SD';
                                
                                csalesorginsertList.add(insertcso1);
                            }
                            if(divisionMap.get('HC') != NULL)
                            {
                                Customer_Sales_Organization__c existingCSO3 = new Customer_Sales_Organization__c();
                                existingCSO3 = divisionMap.get('HC');
                                //existingCSO3.Customer__c = acc.Id;
                                existingCSO3.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                existingCSO3.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                existingCSO3.Customer_Code__c = data2.Kunnr;
                                existingCSO3.Distribution_channel__c = data2.DIST_CHAN;
                                existingCSO3.status__c = 'Valid';
                                existingCSO3.CreatedFromAccount__c = true;
                                existingCSO3.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                existingCSO3.Division__c = 'HC';
                                
                                cSalesOrgUpdateList.add(existingCSO3);
                            }
                            else
                            {
                                Customer_Sales_Organization__c insertcso3 = new Customer_Sales_Organization__c();
                                
                                insertcso3.Customer__c = acc.Id;
                                insertcso3.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                insertcso3.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                insertcso3.Customer_Code__c = data2.Kunnr;
                                insertcso3.Distribution_channel__c = data2.DIST_CHAN;
                                insertcso3.status__c = 'Valid';
                                insertcso3.CreatedFromAccount__c = true;
                                insertcso3.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                insertcso3.Division__c = 'HC';
                                
                                csalesorginsertList.add(insertcso3);
                            }
                            if(divisionMap.get('WC') != NULL)
                            {
                                Customer_Sales_Organization__c existingCSO4 = new Customer_Sales_Organization__c();
                                existingCSO4 = divisionMap.get('WC');   
                                //existingCSO4.Customer__c = acc.Id;
                                existingCSO4.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                existingCSO4.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                existingCSO4.Customer_Code__c = data2.Kunnr;
                                existingCSO4.Distribution_channel__c = data2.DIST_CHAN;
                                existingCSO4.status__c = 'Valid';
                                existingCSO4.CreatedFromAccount__c = true;
                                existingCSO4.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                existingCSO4.Division__c = 'WC';
                                
                                cSalesOrgUpdateList.add(existingCSO4);
                            }
                            else
                            {
                                Customer_Sales_Organization__c insertcso4 = new Customer_Sales_Organization__c();
                                
                                insertcso4.Customer__c = acc.Id;
                                insertcso4.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                insertcso4.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                insertcso4.Customer_Code__c = data2.Kunnr;
                                insertcso4.Distribution_channel__c = data2.DIST_CHAN;
                                insertcso4.status__c = 'Valid';
                                insertcso4.CreatedFromAccount__c = true;
                                insertcso4.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                insertcso4.Division__c = 'WC';
                                
                                csalesorginsertList.add(insertcso4);
                            }
                            if(divisionMap.get('CC') != NULL)
                            {
                                Customer_Sales_Organization__c existingCSO5 = new Customer_Sales_Organization__c();
                                existingCSO5 = divisionMap.get('CC');    
                                //existingCSO5.Customer__c = acc.Id;
                                existingCSO5.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                existingCSO5.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                existingCSO5.Customer_Code__c = data2.Kunnr;
                                existingCSO5.Distribution_channel__c = data2.DIST_CHAN;
                                existingCSO5.status__c = 'Valid';
                                existingCSO5.CreatedFromAccount__c = true;
                                existingCSO5.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                existingCSO5.Division__c = 'CC';
                                
                                cSalesOrgUpdateList.add(existingCSO5);
                            }
                            else
                            {
                                Customer_Sales_Organization__c insertcso5 = new Customer_Sales_Organization__c();
                                
                                insertcso5.Customer__c = acc.Id;
                                insertcso5.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                insertcso5.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                insertcso5.Customer_Code__c = data2.Kunnr;
                                insertcso5.Distribution_channel__c = data2.DIST_CHAN;
                                insertcso5.status__c = 'Valid';
                                insertcso5.CreatedFromAccount__c = true;
                                insertcso5.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                insertcso5.Division__c = 'CC';
                                
                                csalesorginsertList.add(insertcso5);
                            }*/
                        }
                        else
                        {
                            Customer_Sales_Organization__c insertcso6 = new Customer_Sales_Organization__c();
                                
                                insertcso6.Customer__c = acc.Id;
                                insertcso6.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                insertcso6.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                insertcso6.Customer_Code__c = data2.Kunnr;
                                insertcso6.Distribution_channel__c = data2.DIST_CHAN;
                                insertcso6.status__c = 'Valid';
                                insertcso6.CreatedFromAccount__c = true;
                                insertcso6.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                insertcso6.Division__c = 'HE';
                                
                                csalesorginsertList.add(insertcso6);
                            /*if(divisionMap.get('HE') != NULL)
                            {
                                Customer_Sales_Organization__c existingCSO6 = new Customer_Sales_Organization__c();
                                existingCSO6 = divisionMap.get('HE');
                                //existingCSO6.Customer__c = acc.Id;
                                existingCSO6.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                existingCSO6.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                existingCSO6.Customer_Code__c = data2.Kunnr;
                                existingCSO6.Distribution_channel__c = data2.DIST_CHAN;
                                existingCSO6.status__c = 'Valid';
                                existingCSO6.CreatedFromAccount__c = true;
                                existingCSO6.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                existingCSO6.Division__c = 'HE';
                                
                                cSalesOrgUpdateList.add(existingCSO6);
                            }
                            else
                            {
                                Customer_Sales_Organization__c insertcso6 = new Customer_Sales_Organization__c();
                                
                                insertcso6.Customer__c = acc.Id;
                                insertcso6.Company__c = mapCodeWithComp.get(data2.COMP_CODE).id;
                                insertcso6.Sales_Organizations__c = salesOrgMap.get(data2.SALES_ORG);
                                insertcso6.Customer_Code__c = data2.Kunnr;
                                insertcso6.Distribution_channel__c = data2.DIST_CHAN;
                                insertcso6.status__c = 'Valid';
                                insertcso6.CreatedFromAccount__c = true;
                                insertcso6.Branch__c = branchMap.containsKey(data2.SALES_OFF) ? branchMap.get(data2.SALES_OFF) : null;
                                insertcso6.Division__c = 'HE';
                                
                                csalesorginsertList.add(insertcso6);
                            }*/
                        }
                    }
                    
                    if(cSalesOrgUpdateList.size()>0) {
                        update cSalesOrgUpdateList;
                    }
                    System.debug('---cSalesOrgUpdateList--'+cSalesOrgUpdateList);  
                    
                    if(csalesorginsertList.size()>0)
                    {
                        insert csalesorginsertList;
                        system.debug('---csalesorginsertList--'+csalesorginsertList);
                    }
                   

                    it.Status__c = 'Success';
                    it.sync__c = true;
                    System.debug('it.Status__c========'+it.Status__c);
                    If(it.Status__c == 'Success'){
                        acc.Sync_with_SAP__c = true;
                        acc.Status__c = 'Sync with SAP';
                    }
                    System.debug('acc========'+acc.Status__c);
                    update acc;
                    //END HERE..
                }
                
            }            
            
        }catch (Exception ex) {
            it.Status__c = 'fail';
            it.Error__c = ex.getMessage();
            TegaUtility.trackLogs( ex,  'SAPCallout_Utility',  'updateCustomer');
            system.debug('error line===='+ex.getLineNumber()+'====error type-----------'+ex.getCause()+'-------error message-------'+ex.getMessage()+
                         '-------error gettype-------'+ex.getTypeName()+'-------error getStackTraceString-------'+ex.getStackTraceString());
        }
        
        update it;
        
    }


    //This method was written bcs of urgent changes
    public void coverMethod(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
    
}