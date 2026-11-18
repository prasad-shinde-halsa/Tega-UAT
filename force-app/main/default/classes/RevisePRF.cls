public class RevisePRF {
    @InvocableMethod (label = 'Revise PRF Apex' description = 'returns nothing')
    public static void RevisePRFMethod (List<ID> ids){
        try{
        Proposal_Form__c prf = [SELECT Id, Name, CurrencyIsoCode, RecordTypeId, Opportunity__c, ABG_PBG_if_applicable__c, Actual_Response_Time_Days__c, 
                                Additonal_Information_Required__c, Any_instrumentation_standard_as_per_RFQ__c, Any_other_standard_as_per_RFQ_to_follow__c, 
                                Any_specific_testing_requirement_as_per__c, Are_there_wear_issues__c, Available_Capacity_of_Equipment_ton__c, 
                                Ball_Path_Trajectory__c, Ball_trajectory__c, Capital_Insurance_Spare_is_in_scope_not__c, Case_Study_of_Similar_Cases_to_Share__c, 
                                Charge_Motion_Simulation__c, Chart_of_Force_on_LB__c, Competitor_Price_Level__c, Tega_App_PRF_number__c, 
                                Compressed_air_line_available__c, Consignment_Stock_Agreement__c, Contractual_Requirement__c, Conversion__c, 
                                Conversion_sub_type__c, Cost_Economic_Study__c, Customer_Equipment__c, Delivery_Terms__c, Describe_Scenario__c,
                                Design_Parameter__c, Dispatch_Mode__c, Effect_of_Jamming_in_Next_Process__c, Energy_Spectrum_Analysis__c, Equipment_Drawing__c, 
                                Evacuation_Simulation__c, Existing_Jamming_Frequency_hours_day__c, Existing_Solution_of_Solving_Jamming__c, 
                                Expected_Price__c, FAD__c, Flow_solution_AB_Offer_Required__c, Graphic_Force_on_L_B__c, Guarantee_Warranty_Terms_if_applicable__c, 
                                Height_of_Existing_Spiral__c, Improve_Deck_Life__c, Improve_Screen_Efficiency__c, Incoterm_City__c, Incoterms__c, Inquiry_Type__c, 
                                Is_operating_spare_in_scope__c, Is_there_any__c, Jamming_area_marked_in_drawing_sketch__c, Job_Description__c, 
                                Life_Expectation_Study_Analysis_Estimate__c, Life_Guarantee__c, Life_of_Present_Panels_Hrs__c, Max_Capacity_of_Equipment__c, 
                                Offer_Type__c, Operating_Parameters__c, Packing_Forwarding__c, Parent_Proposal_Form__c, Performance_Analysis__c, 
                                Please_specify_instrumentation_standard__c, Please_specify_other_standard__c, Please_specify_testing_requirement__c, 
                                Power_Draw_Analysis__c, Pressure__c, Price_Indicative__c, Price_variation_clause__c, Proposal_Drawing_Reqd__c, 
                                Proposed_Part_List_Reqd__c, Reference_list__c, Regret_Reason__c, Regret__c, Revision_No__c, SAP_Offer_Number__c, 
                                SLA_Trigger_Date__c, SLA_Triggered__c, SLA__c, Spares__c, Special_Requirement__c, Specify_Period_in_years__c, 
                                Spiral_Required__c, Status__c, Tax_Duty_if_applicable__c, Type__c, Type_of_Jamming__c, Warranty__c, Wear_areas_marked_in_drawing_sketch__c, 
                                for_Steel__c, of_Hardox_Plate__c, Total_Floor_Price__c, Total_Price_Quoted__c, Equipment_Record_Type__c, Parent_Proposal_with_Revision__c, 
                                Grand_Total__c FROM Proposal_Form__c where Id =: ids[0]];
        system.debug('prf =>'+prf);
        
        List<Cost_Information_sheet__c> cisList = [SELECT Id, Name, CurrencyIsoCode, Proposal_Form__c, Total_Rate_Kg__c, Total_Weight__c, Total_Value__c FROM Cost_Information_sheet__c where Proposal_Form__c =: prf.Id];
        system.debug('cisList =>'+cisList);
        Set<Id> costInformationIds = new Set<Id>();
        for(Cost_Information_sheet__c cis : cisList){
            costInformationIds.add(cis.Id);
        }
        
        List<Cost_Information__c> ciList = [SELECT Id, Name, CurrencyIsoCode, RecordTypeId, Cost_Information_Sheet__c, Item_Desc__c, Rate_Kg__c, Remarks__c, Total_Weight__c, Value__c, Unit__c, Qty__c, Unit_Rate__c, Total_Cost__c, C_P__c, Price__c FROM Cost_Information__c where Cost_Information_Sheet__c IN: costInformationIds];
        system.debug('ciList =>'+ciList);
        Map<Id,List<Cost_Information__c>> costInformationMap = new Map<Id,List<Cost_Information__c>>();
        for(Cost_Information__c ci : ciList){
            if(!costInformationMap.containsKey(ci.Cost_Information_Sheet__c)){
                List<Cost_Information__c> newCIList = new List<Cost_Information__c>();
                newCIList.add(ci);
                costInformationMap.put(ci.Cost_Information_Sheet__c,newCIList);
            }else if(costInformationMap.containsKey(ci.Cost_Information_Sheet__c)){
                List<Cost_Information__c> newCIList = costInformationMap.get(ci.Cost_Information_Sheet__c);
                newCIList.add(ci);
                costInformationMap.put(ci.Cost_Information_Sheet__c,newCIList);
            }
        }
        system.debug('costInformationMap =>'+costInformationMap);
        
        List<Scope_With_Selection__c> swsList = [SELECT Id, Name, CurrencyIsoCode, RecordTypeId, Proposal_Form__c, Comments__c, Cost_Information_Sheet__c, Delivery_SLA_Weeks__c, Discount__c, Floor_Price__c, Hardware_Included__c, Item_Category__c, Item_Desc__c, Lifter_Bar__c, Material_of_construction_Product_type__c, No_of_Rows__c, Note__c, Offer__c, Price_Quoted__c, Quantity__c, Sealing_System_Included__c, Shell_Plate__c, UOM__c, Unit_Cost__c, Unit_Price_Quoted__c, Unit_of_Measure_on_Quantity__c, Zone__c, Total_Cost__c, Total_Price_Quoted__c FROM Scope_With_Selection__c where Proposal_Form__c =: prf.Id];
        system.debug('swsList =>'+swsList);

        Proposal_Form__c clonedPRF = new Proposal_Form__c();
        
        if(prf.Parent_Proposal_Form__c == null){
            clonedPRF = prf.clone(false, true, false, false);
            List<Proposal_Form__c> latestChildPRFList = [Select Id,Parent_Proposal_Form__c,Revision_No__c from Proposal_Form__c WHERE Parent_Proposal_Form__c =: prf.Id ORDER BY CreatedDate Desc];
            clonedPRF.Parent_Proposal_Form__c = prf.Id;
            clonedPRF.RecordTypeId = prf.RecordTypeId;
            clonedPRF.Opportunity__c = prf.Opportunity__c;
            clonedPRF.Status__c = 'New';
            if(latestChildPRFList.size() > 0 ){
                if(latestChildPRFList[0].Revision_No__c != null){
                clonedPRF.Revision_No__c = latestChildPRFList[0].Revision_No__c + 1;
                }else{
                    clonedPRF.Revision_No__c = 1;
                }
            }else{
                clonedPRF.Revision_No__c = 1;
            }
            system.debug('clonedPRF =>'+clonedPRF);
            insert clonedPRF;
        }else{
            clonedPRF = prf.clone(false, true, false, false);
            List<Proposal_Form__c> latestChildPRFList = [Select Id,Parent_Proposal_Form__c,Revision_No__c from Proposal_Form__c WHERE Parent_Proposal_Form__c =: prf.Parent_Proposal_Form__c ORDER BY CreatedDate Desc];
            clonedPRF.Parent_Proposal_Form__c = prf.Parent_Proposal_Form__c;
            clonedPRF.RecordTypeId = prf.RecordTypeId;
            clonedPRF.Opportunity__c = prf.Opportunity__c;
            clonedPRF.Status__c = 'New';
            if(latestChildPRFList[0].Revision_No__c != null){
                clonedPRF.Revision_No__c = latestChildPRFList[0].Revision_No__c + 1;
            }else{
                clonedPRF.Revision_No__c = 1;
            }
            system.debug('clonedPRFElse =>'+clonedPRF);
            insert clonedPRF;
        }
        
        Map<Id,Cost_Information_sheet__c> newCSIMap = new Map<Id,Cost_Information_sheet__c>();
        
        for(Cost_Information_sheet__c cis : cisList){
            Cost_Information_sheet__c clonedCis = cis.clone(false, true, false, false);
            clonedCis.Proposal_Form__c = clonedPRF.Id;
            newCSIMap.put(cis.Id,clonedCis);
        }
        system.debug('newCSIMap =>'+newCSIMap);
        
        insert newCSIMap.values();
        
        List<Cost_Information__c> newCostInformationList = new List<Cost_Information__c>();
        
        for(Id cisId : newCSIMap.keySet()){
            system.debug('cisId =>'+cisId);
            Cost_Information_sheet__c clonedCis = newCSIMap.get(cisId);
            if(costInformationMap.containsKey(cisId)){
                List<Cost_Information__c> costInformationList = costInformationMap.get(cisId);
                for(Cost_Information__c ci : costInformationList){
                    Cost_Information__c clonedCI = ci.clone(false, true, false, false);
                    clonedCI.Cost_Information_Sheet__c = clonedCis.Id;
                    newCostInformationList.add(clonedCI);
                }
            }
           
        }
        
        system.debug('newCostInformationList =>'+newCostInformationList);
        insert newCostInformationList;
        
        List<Scope_With_Selection__c> newSwsList = new List<Scope_With_Selection__c>();
        
        for(Scope_With_Selection__c sws : swsList){
            Scope_With_Selection__c clonedSWS = sws.clone(false, true, false, false);
            clonedSWS.Proposal_Form__c = clonedPRF.Id;
            newSwsList.add(clonedSWS);
        }
        
        system.debug('newSwsList =>'+newSwsList);
        insert newSwsList;
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'RevisePRF',  'RevisePRFMethod ');
        }
    }
}