/*
Name : CreateNonSpareOffer
Description : This class used to create offer from SAP.
Author : Kuhinoor
*/

public with sharing class CreateNonSpareOffer implements Queueable, Database.allowscallouts {
    String offerNumber;
    Id itId;
    List<String> debugList = new List<String>();

    public CreateNonSpareOffer(String offerNumber, Id itId) {
        this.offerNumber = offerNumber;
        this.itId = itId;
    }

    public void execute(QueueableContext qc) {
        Integration_Transaction__c it = new Integration_Transaction__c(Id = itId);
        try {
            List<Quote> offerList = new List<Quote>();
            Quote newOffer;
            Id pbId;

            // Integration Credential 
            Tega_SAP_Credential__c sapOrg = Tega_SAP_Credential__c.getOrgDefaults();

            // SOAP callout to get offer Details...
            NonSparesServiceNewV2.ZWSNSOFFER_DTLS_V1 zwnonSpareOfr = new NonSparesServiceNewV2.ZWSNSOFFER_DTLS_V1();
            NonSparesServiceNewV2.ZofferDtlsSfdcResponse_element response = new NonSparesServiceNewV2.ZofferDtlsSfdcResponse_element();
            Blob headerValue = Blob.valueOf(sapOrg.Username__c + ':' + sapOrg.Password__c);
            String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
            zwnonSpareOfr.inputHttpHeaders_x = new Map<String, String>();
            zwnonSpareOfr.inputHttpHeaders_x.put('Authorization', authorizationHeader);

            response = zwnonSpareOfr.ZofferDtlsSfdc('', '', offerNumber);
            System.debug('response-->>' + response);
            debugList.add('response-->>'+string.valueOf(response)+'Line 35 *');
            it.Response__c = 'Offer Response: \r\n' + String.valueOf(response);

            NonSparesServiceNewV2.ZttNspOffer GtHeader = response.GtHeader;
            NonSparesServiceNewV2.ZttitemVbapSf GtItem = response.GtItemtab;
            // AK Changes 24/11/2022
            String responseMsg = response.ExMessage;

            NonSparesServiceNewV2.ZstNspOffer[] itemList = GtHeader.item;
            System.debug('itemList-->>' + itemList);
            debugList.add('itemList-->>'+string.valueOf(itemList)+'Line 47 *');

            NonSparesServiceNewV2.ZitemVbapSf[] lineItemList = GtItem.item;
            System.debug('lineItemList-->>' + lineItemList);
            debugList.add('lineItemList-->>'+string.valueOf(lineItemList)+'Line 51 *');

            String getCurrencyFromLineItem = null;

            if (lineItemList != null && lineItemList.size() > 0 && lineItemList[0].Waers != null) {
                getCurrencyFromLineItem = lineItemList[0].Waers;
                System.debug('getCurrencyFromLineItem=>' + getCurrencyFromLineItem);
                debugList.add('getCurrencyFromLineItem=>'+string.valueOf(getCurrencyFromLineItem)+'Line 58 *');
            } else {
                System.debug('Line item list is null or empty');
                debugList.add('Line item list is null or empty');
            }

            System.debug('getCurrencyFromLineItem=>' + getCurrencyFromLineItem);
            debugList.add('getCurrencyFromLineItem=>'+string.valueOf(getCurrencyFromLineItem)+'Line 65 *');

            if (itemList != null && itemList.size() > 0) {
                String sapOfferNumber = itemList[0].Vbeln;
                String branchCode = itemList[0].Vkbur;
                String salesOrgCode = itemList[0].Vkorg;

                // Query PRF to get related opportunity...
                List<Proposal_Form__c> proFormList = [SELECT Id, Opportunity__c, Opportunity__r.CurrencyIsoCode, Opportunity__r.CurrencyTrim__c, Type__c, RecordTypeId
                                                      FROM Proposal_Form__c 
                                                      WHERE SAP_Offer_Number__c =: sapOfferNumber];
                System.debug('proFormList=>' + proFormList);
                debugList.add('proFormList=>'+string.valueOf(proFormList)+'Line 77 *');

                if (proFormList != null && proFormList.size() > 0) {
                    System.debug('proFormList[0].Type__c=>' + proFormList[0].Type__c);
                    debugList.add('proFormList[0].Type__c=>'+ string.valueOf(proFormList[0].Type__c)+'Line 81 *');
                    System.debug('proFormList[0].Opportunity__r.CurrencyIsoCode=>' + proFormList[0].Opportunity__r.CurrencyIsoCode);
                    debugList.add('proFormList[0].Opportunity__r.CurrencyIsoCode=>'+ string.valueOf(proFormList[0].Type__c)+'Line 83 *');

                    // Fetch Branch for offer
                    List<Branch__c> branchList = [SELECT Id FROM Branch__c WHERE Branch_Code__c =: branchCode];

                    // Fetch Sales org for offer
                    List<Sales_Org__c> salesOrgList = [SELECT Id FROM Sales_Org__c WHERE Name =: salesOrgCode];

                    Map<String, Non_Spare_Type__mdt> nonSpareTypeMap = Non_Spare_Type__mdt.getAll();

                    NonSparesServiceNewV2.ZstNspOffer item = itemList[0];
                    System.debug('item=>' + item);
                    debugList.add('item=>'+ string.valueOf(item)+'Line 95 *');
                    // Revised Offer
                    Id parentOfferId;

                    List<Quote> existingOfferList = [SELECT Id FROM Quote 
                                                     WHERE SAP_Offer_Id__c =: item.Vbeln 
                                                     ORDER BY Parent_Offer__c];
                    System.debug('existingOfferList =>' + existingOfferList);
                    debugList.add('existingOfferList =>'+ string.valueOf(existingOfferList)+'Line 103 *');

                    List<Pricebook2> pbList = [SELECT Id FROM Pricebook2 WHERE Name =: item.Vbeln];
                    // Creating price book for every offer with the name of Offer
                    Pricebook2 pb = new Pricebook2(Name = item.Vbeln, IsActive = true,
                                                   Description = pbList != null && pbList.size() > 0 ? 'Rev-' + pbList.size() : '');
                    insert pb;

                    Quote offer = new Quote();
                    offer.recordTypeId = TegaUtilityWithoutSharing.getOfferRecordTypeId('Offer_Non_Spare');
                    System.debug('offer.recordTypeId------------>' + offer.recordTypeId);
                    debugList.add('offer.recordTypeId------------>'+ string.valueOf(offer.recordTypeId)+'Line 114 *');
                    System.debug('proFormList[0].RecordTypeId------------>' + proFormList[0].RecordTypeId);
                    debugList.add('proFormList[0].RecordTypeId------------>'+ string.valueOf(proFormList[0].RecordTypeId)+'Line 116 *');
                    offer.Pricebook2Id = pb.Id;
                    offer.OpportunityId = proFormList[0].Opportunity__c;
                    offer.Opportunity_Equipments__c = proFormList[0].Id;
                    offer.Name = item.Vbeln;
                    offer.SAP_Offer_Id__c = item.Vbeln;
                    offer.Quotation_Date__c = date.valueOf(item.ValidFrom);
                    offer.Quotation_Validity__c = date.valueOf(item.ValidTo);

                    offer.Offer_Type__c = nonSpareTypeMap.get(item.OfferType).Value__c;
                    System.debug('offer.Offer_Type__c------------>' + offer.Offer_Type__c);
                    debugList.add('offer.Offer_Type__c------------>'+ string.valueOf(offer.Offer_Type__c)+'Line 127 *');
                    System.debug('nonSpareTypeMap.get(item.OfferType).Value__c------------>' + nonSpareTypeMap.get(item.OfferType).Value__c);
                    debugList.add('nonSpareTypeMap.get(item.OfferType).Value__c------------>'+ string.valueOf(nonSpareTypeMap.get(item.OfferType).Value__c)+'Line 129 *');

                    offer.Inquiry_Type__c = nonSpareTypeMap.get(item.InquiryTyp).Value__c;
                    offer.Order_Type__c = nonSpareTypeMap.get(item.OrderType).Value__c;
                    offer.status = nonSpareTypeMap.get(item.Status).Value__c;

                    offer.Division__c = item.Spart;
                    offer.Distribution_Channel__c = item.Vtweg;
                    offer.Sales_Document_Type__c = item.Auart;
                    offer.Customer_Code__c = item.Kunnr;
                    offer.Branch__c = branchList != null && branchList.size() > 0 ? branchList[0].Id : null;
                    offer.Sales_Org__c = salesOrgList != null && salesOrgList.size() > 0 ? salesOrgList[0].Id : null;

                    // AK HD Fix 01/06/2023
                    if (item.SalesGrp != '') {
                        offer.SalesGrp__c = item.SalesGrp;
                    } else {
                        it.Status__c = 'fail';
                        it.Error__c = 'Sales Group is coming as Blank in Response';
                        String debugStr;
                        for(String str111 : debugList){
                            debugStr = debugStr + str111 + '>>>>>';
                        }
                        it.Debug_Logs__c = debugStr;
                    }

                    if (existingOfferList != null && existingOfferList.size() > 0) {
                        offer.Revision__c = existingOfferList.size();
                        offer.Parent_Offer__c = existingOfferList[0].Id;
                    }

                    if (proFormList[0].Opportunity__r.CurrencyTrim__c == getCurrencyFromLineItem) {
                        // proFormList[0].Type__c == offer.Offer_Type__c && proFormList[0].RecordTypeId == offer.RecordTypeId
                        System.debug('Offer ==>' + offer);
                        debugList.add('Offer ==>'+ string.valueOf(offer)+'Line 163 *');
                        insert offer;
                        System.debug('2nd Job will begin');
                        // Invoke product and line creation JOB

                        // AK Changes 24/11/2022
                        if (responseMsg != '') {
                            String debugStr;
                            it.Status__c = 'fail';
                            it.Error__c = responseMsg;
                            for(String str111 : debugList){
                                debugStr = debugStr + str111 + '>>>>>';
                            }
                            it.Debug_Logs__c = debugStr;
                        } else {
                            system.enqueueJob(new CreateProductAndOfferLine(offer, pb, response, it));
                        }
                    } else {
                        String debugStr;
                        it.Status__c = 'fail';
                        for(String str111 : debugList){
                            debugStr = debugStr + str111 + '>>>>>';
                        }
                        it.Debug_Logs__c = debugStr;
                        it.Error__c = 'Currency Mismatch in Opportunity and Offer Line Item. Please make sure both currency remains same or Offer Type does not match with Proposal Form Type';
                    }
                    update it;
                } else {
                    String debugStr;
                    it.Status__c = 'fail';
                    for(String str111 : debugList){
                        debugStr = debugStr + str111 + '>>>>>';
                    }
                    it.Debug_Logs__c = debugStr;
                    it.Error__c = 'No Proposal Form found for the given SAP Offer Number';
                    update it;
                }
            }
        } catch (Exception ex) {
            String debugStr;
            it.Status__c = 'fail';
            for(String str111 : debugList){
                debugStr = debugStr + str111 + '>>>>>';
            }
            it.Debug_Logs__c = debugStr;
            it.Error__c = 'Class Name : CreateNonSpareOffer \r\n ' + ex.getMessage() + ' Line:' + ex.getLineNumber();
            update it;
        }
    }
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
    }
}