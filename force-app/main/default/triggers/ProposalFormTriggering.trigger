/**
* Trigger: ProposalFormTriggering
* Object: Proposal_Form__c
* Events: After Insert, After Update
*
* Description:
* This trigger creates or updates related MIS_Budget__c records whenever a 
* Proposal_Form__c record is marked as "Closed".
* Test class - ProposalFormTriggeringTest
* Key Logic:
*  - Runs only on after insert and after update.
*  - Collects Budget Line Item IDs from newly closed Proposal_Form__c records.
*  - For each related Budget Line Item:
*      • Queries existing MIS_Budget__c records for that Budget Line Item.
*      • If an MIS record exists within the current MIS edit window
*        (based on Budget_FY_year_Config__mdt), it updates that record.
*      • Otherwise, it inserts a new MIS_Budget__c record.
*  - Monthly Expected Stage and Month fields are set dynamically:
*      • Uses Budgeted_Order_Month__c from Proposal_Form__c to determine the month.
*      • Populates Order_Expected_Stage_*__c based on Order_Type__c of the Budget Line:
*            - For "C-Conversion" → stage = "Generation of RFQ"
*            - For others → stage = "Offer"
*      • Populates Order_Expected_Month_*__c with "<Month>, <SaleYear>".
*  - Financial Year logic:
*      • FY starts in April and ends in March.
*      • SaleYear is derived from current date and FY calculation.
* Author - 
* Last Modified By - Reetabrata
* Last Modified Date = 1st sep 2025
*/

trigger ProposalFormTriggering on Proposal_Form__c (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        
        Budget_FY_year_Config__mdt budgetConfig = [SELECT MIS_Edit_Start_Date__c, MIS_Edit_End_Date__c FROM Budget_FY_year_Config__mdt WHERE Active__c = TRUE LIMIT 1];
        
        List<MIS_Budget__c> newMISRecords = new List<MIS_Budget__c>();
        List<MIS_Budget__c> updateMisRecord = new List<MIS_Budget__c>();
        
        list<String> allRealtedBudgetLine = new List<String>();
        
        List<Proposal_Form__c> allNewProposals = new List<Proposal_Form__c>();
        
        for ( Integer i=0; Trigger.new.size() > i; i++ ) {
            Proposal_Form__c newValueProposal = Trigger.New[i];
            Proposal_Form__c oldValueProposal = Trigger.isUpdate ? Trigger.Old[i] : new Proposal_Form__c();
            
            
            if(newValueProposal.Status__c == 'Closed' && oldValueProposal.Status__c != 'Closed' && newValueProposal.DC_Budget_Line_Items__c != null ){
                allRealtedBudgetLine.add(newValueProposal.DC_Budget_Line_Items__c);
                allNewProposals.add(newValueProposal);
            }
            // else if(newValueProposal.Status__c == 'Closed' && newValueProposal.DC_Budget_Line_Items__c != null ){
            //     allRealtedBudgetLine.add(newValueProposal.DC_Budget_Line_Items__c);
            //     allNewProposals.add(newValueProposal);
            // }
        }
        
        if(allRealtedBudgetLine.size() > 0){
            system.debug('allRealtedBudgetLine:::: '+allRealtedBudgetLine);
            
            List<MIS_Budget__c> existingMISRecords = [SELECT Id, Order_Type__c, CreatedDate FROM MIS_Budget__c WHERE Budget_Line_Items__c = :allRealtedBudgetLine[0]]; 
            List<DC_Budget_Line_Items__c> allBLI = [SELECT Id, Name, Order_Type__c FROM DC_Budget_Line_Items__c WHERE Id = :allRealtedBudgetLine[0]];
            
            MIS_Budget__c newMIS = new MIS_Budget__c();
            newMIS.Budget_Line_Items__c = allNewProposals[0].DC_Budget_Line_Items__c;
            newMIS.Mis_Monthly_Report__c = budgetConfig.MIS_Edit_Start_Date__c; 
            
            
            Date closedDate = allNewProposals[0].Closed_Date__c; // taking wrong data old code 
            String PF_Order_Expected_Month = allNewProposals[0].Order_Expected_Month__c; // added by Ranjeet 
            String budgetedOrderMonth = allNewProposals[0].Budgeted_Order_Month__c;
            Decimal PF_Total_price_qouted = allNewProposals[0].Total_Price_Quoted__c;
            if (String.isNotBlank(budgetedOrderMonth) && (String.isNotBlank(PF_Order_Expected_Month))) {
                String monthValue = budgetedOrderMonth.trim();
                Integer closedMonth = closedDate.month();
                Integer closeDateYear  = closedDate.year();
                
                String[] monthNames = new String[]{
                    'Jan','Feb','Mar','Apr','May','Jun',
                        'Jul','Aug','Sep','Oct','Nov','Dec'
                        };
                            
                String closeDatemonthName = monthNames[closedMonth - 1];
                // String formatedcloseDatemonthName = closeDatemonthName + ', ' + closeDateYear; // old logic
                String formatedcloseDatemonthName = PF_Order_Expected_Month + ', ' + closeDateYear;
                
                
                // Reset all month fields to blank first so update wipes stale data from other months
                newMIS.Order_Expected_Stage_Jan__c = null;  newMIS.Order_Expected_Month_Jan__c = null;  newMIS.Expected_Order_Value_Jan__c = null;
                newMIS.Order_Expected_Stage_Feb__c = null;  newMIS.Order_Expected_Month_Feb__c = null;  newMIS.Expected_Order_Value_Feb__c = null;
                newMIS.Order_Expected_Stage_Mar__c = null;  newMIS.Order_Expected_Month_Mar__c = null;  newMIS.Expected_Order_Value_Mar__c = null;
                newMIS.Order_Expected_Stage_Apr__c = null;  newMIS.Order_Expected_Month_Apr__c = null;  newMIS.Expected_Order_Value_April__c = null;
                newMIS.Order_Expected_Stage_May__c = null;  newMIS.Order_Expected_Month_May__c = null;  newMIS.Expected_Order_Value_May__c = null;
                newMIS.Order_Expected_Stage_Jun__c = null;  newMIS.Order_Expected_Month_Jun__c = null;  newMIS.Expected_Order_Value_June__c = null;
                newMIS.Order_Expected_Stage_Jul__c = null;  newMIS.Order_Expected_Month_Jul__c = null;  newMIS.Expected_Order_Value_Jul__c = null;
                newMIS.Order_Expected_Stage_Aug__c = null;  newMIS.Order_Expected_Month_Aug__c = null;  newMIS.Expected_Order_Value_Aug__c = null;
                newMIS.Order_Expected_Stage_Sep__c = null;  newMIS.Order_Expected_Month_Sep__c = null;  newMIS.Expected_Order_Value_Sep__c = null;
                newMIS.Order_Expected_Stage_Oct__c = null;  newMIS.Order_Expected_Month_Oct__c = null;  newMIS.Expected_Order_Value_Oct__c = null;
                newMIS.Order_Expected_Stage_Nov__c = null;  newMIS.Order_Expected_Month_Nov__c = null;  newMIS.Expected_Order_Value_Nov__c = null;
                newMIS.Order_Expected_Stage_Dec__c = null;  newMIS.Order_Expected_Month_Dec__c = null;  newMIS.Expected_Order_Value_Dec__c = null;


                switch on monthValue {
                    when 'Jan' { 
                        newMIS.Order_Expected_Stage_Jan__c = allBLI[0].Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ'; 
                        newMIS.Order_Expected_Month_Jan__c = formatedcloseDatemonthName; 
                        newMIS.Expected_Order_Value_Jan__c = PF_Total_price_qouted/1000;
                    }
                    when 'Feb' { 
                        newMIS.Order_Expected_Stage_Feb__c = allBLI[0].Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ'; 
                        newMIS.Order_Expected_Month_Feb__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_Feb__c = PF_Total_price_qouted/1000;
                    }
                    when 'Mar' { 
                        newMIS.Order_Expected_Stage_Mar__c = allBLI[0].Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ'; 
                        newMIS.Order_Expected_Month_Mar__c = formatedcloseDatemonthName; 
                        newMIS.Expected_Order_Value_Mar__c = PF_Total_price_qouted/1000;
                    }
                    when 'Apr' { 
                        newMIS.Order_Expected_Stage_Apr__c = allBLI[0].Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ'; 
                        newMIS.Order_Expected_Month_Apr__c = formatedcloseDatemonthName; 
                        newMIS.Expected_Order_Value_April__c = PF_Total_price_qouted/1000;
                    }
                    when 'May' { 
                        newMIS.Order_Expected_Stage_May__c = allBLI[0].Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ'; 
                        newMIS.Order_Expected_Month_May__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_May__c = PF_Total_price_qouted/1000;
                    }
                    when 'Jun' { 
                        newMIS.Order_Expected_Stage_Jun__c = allBLI[0].Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ'; 
                        newMIS.Order_Expected_Month_Jun__c = formatedcloseDatemonthName; 
                        newMIS.Expected_Order_Value_June__c = PF_Total_price_qouted/1000;

                    }
                    when 'Jul' { 
                        newMIS.Order_Expected_Stage_Jul__c = allBLI[0].Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ'; 
                        newMIS.Order_Expected_Month_Jul__c = formatedcloseDatemonthName; 
                        newMIS.Expected_Order_Value_Jul__c = PF_Total_price_qouted/1000;
                    }
                    when 'Aug' { 
                        newMIS.Order_Expected_Stage_Aug__c = allBLI[0].Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ'; 
                        newMIS.Order_Expected_Month_Aug__c = formatedcloseDatemonthName; 
                        newMIS.Expected_Order_Value_Aug__c = PF_Total_price_qouted/1000;
                    }
                    when 'Sep' { 
                        newMIS.Order_Expected_Stage_Sep__c = allBLI[0].Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ'; 
                        newMIS.Order_Expected_Month_Sep__c = formatedcloseDatemonthName; 
                        newMIS.Expected_Order_Value_Sep__c = PF_Total_price_qouted/1000;
                    }
                    when 'Oct' { 
                        newMIS.Order_Expected_Stage_Oct__c = allBLI[0].Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ'; 
                        newMIS.Order_Expected_Month_Oct__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_Oct__c = PF_Total_price_qouted/1000;
                    }
                    when 'Nov' { 
                        newMIS.Order_Expected_Stage_Nov__c = allBLI[0].Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ'; 
                        newMIS.Order_Expected_Month_Nov__c = formatedcloseDatemonthName; 
                        newMIS.Expected_Order_Value_Nov__c = PF_Total_price_qouted/1000;
                    }
                    when 'Dec' { 
                        newMIS.Order_Expected_Stage_Dec__c = allBLI[0].Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ'; 
                        newMIS.Order_Expected_Month_Dec__c = formatedcloseDatemonthName; 
                        newMIS.Expected_Order_Value_Dec__c = PF_Total_price_qouted/1000;
                    }
                }
            }
            
            
            if(existingMISRecords.size() > 0 && existingMISRecords[0].CreatedDate >= budgetConfig.MIS_Edit_Start_Date__c 
               && existingMISRecords[0].CreatedDate <= budgetConfig.MIS_Edit_End_Date__c){
                   MIS_Budget__c existingMIS = existingMISRecords[0];
                   newMIS.Id = existingMIS.Id;
                   newMIS.Order_Type__c = existingMIS.Order_Type__c; 
                   newMIS.Mis_Monthly_Report__c = budgetConfig.MIS_Edit_Start_Date__c; 
                   
                   
                   updateMisRecord.add(newMIS); 
               }
            else {
                newMIS.Order_Type__c = allBLI[0].Order_Type__c; 
                newMIS.Mis_Monthly_Report__c = budgetConfig.MIS_Edit_Start_Date__c; 
                
                newMISRecords.add(newMIS);
            }
            
            if (!updateMisRecord.isEmpty()) {
                update updateMisRecord; 
            }
            if(!newMISRecords.isEmpty()){
                insert newMISRecords;
                
            }
        }
        
    }
}