/**
* Trigger: ProposalFormTriggering
* Object: Proposal_Form__c
* Events: After Insert, After Update
* ... (docblock unchanged, see original)
*/
 
trigger ProposalFormTriggering on Proposal_Form__c (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
 
        Budget_FY_year_Config__mdt budgetConfig = [
            SELECT MIS_Edit_Start_Date__c, MIS_Edit_End_Date__c
            FROM Budget_FY_year_Config__mdt
            WHERE Active__c = TRUE
            LIMIT 1
        ];
 
        String[] monthNames = new String[]{
            'Jan','Feb','Mar','Apr','May','Jun',
            'Jul','Aug','Sep','Oct','Nov','Dec'
        };
 
        // 1. Collect all qualifying proposals + related budget line Ids
        Set<Id> budgetLineIds = new Set<Id>();
        List<Proposal_Form__c> qualifyingProposals = new List<Proposal_Form__c>();
 
        for (Integer i = 0; i < Trigger.new.size(); i++) {
            Proposal_Form__c newValueProposal = Trigger.New[i];
            Proposal_Form__c oldValueProposal = Trigger.isUpdate ? Trigger.Old[i] : new Proposal_Form__c();
 
            if (newValueProposal.Status__c == 'Closed'
&& oldValueProposal.Status__c != 'Closed'
&& newValueProposal.DC_Budget_Line_Items__c != null) {
 
                budgetLineIds.add(newValueProposal.DC_Budget_Line_Items__c);
                qualifyingProposals.add(newValueProposal);
            }
        }
 
        if (budgetLineIds.isEmpty()) {
            return;
        }
 
        // 2. Bulk query existing MIS records, map by Budget Line Item Id
        //    (keeps only the record that falls inside the current MIS edit window, if any)
        Map<Id, MIS_Budget__c> misByBudgetLine = new Map<Id, MIS_Budget__c>();
        for (MIS_Budget__c mis : [
            SELECT Id, Order_Type__c, CreatedDate, Budget_Line_Items__c
            FROM MIS_Budget__c
            WHERE Budget_Line_Items__c IN :budgetLineIds
        ]) {
            if (mis.CreatedDate >= budgetConfig.MIS_Edit_Start_Date__c
&& mis.CreatedDate <= budgetConfig.MIS_Edit_End_Date__c) {
                // Prefer the in-window record; if duplicates exist, first one wins
                if (!misByBudgetLine.containsKey(mis.Budget_Line_Items__c)) {
                    misByBudgetLine.put(mis.Budget_Line_Items__c, mis);
                }
            }
        }
 
        // 3. Bulk query budget line items, map by Id
        Map<Id, DC_Budget_Line_Items__c> bliById = new Map<Id, DC_Budget_Line_Items__c>([
            SELECT Id, Name, Order_Type__c
            FROM DC_Budget_Line_Items__c
            WHERE Id IN :budgetLineIds
        ]);
 
        List<MIS_Budget__c> newMISRecords = new List<MIS_Budget__c>();
        List<MIS_Budget__c> updateMisRecord = new List<MIS_Budget__c>();
 
        // 4. Loop over every qualifying proposal (not just the first)
        for (Proposal_Form__c proposal : qualifyingProposals) {
 
            Id bliId = proposal.DC_Budget_Line_Items__c;
            DC_Budget_Line_Items__c bli = bliById.get(bliId);
            if (bli == null) {
                continue; // safety guard, shouldn't happen given the query above
            }
 
            MIS_Budget__c newMIS = new MIS_Budget__c();
            newMIS.Budget_Line_Items__c = bliId;
            newMIS.Mis_Monthly_Report__c = budgetConfig.MIS_Edit_Start_Date__c;
 
            Date closedDate = proposal.Closed_Date__c;
            String PF_Order_Expected_Month = proposal.Order_Expected_Month__c;
            String budgetedOrderMonth = proposal.Budgeted_Order_Month__c;
            Decimal PF_Total_price_qouted = proposal.Total_Price_Quoted__c;
 
            if (String.isNotBlank(budgetedOrderMonth) && String.isNotBlank(PF_Order_Expected_Month) && closedDate != null) {
                String monthValue = budgetedOrderMonth.trim();
                Integer closeDateYear = closedDate.year();
                String formatedcloseDatemonthName = PF_Order_Expected_Month + ', ' + closeDateYear;
 
                // Reset all months first so an UPDATE clears stale data from other months
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
                        newMIS.Order_Expected_Stage_Jan__c = bli.Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ';
                        newMIS.Order_Expected_Month_Jan__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_Jan__c = PF_Total_price_qouted / 1000;
                    }
                    when 'Feb' {
                        newMIS.Order_Expected_Stage_Feb__c = bli.Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ';
                        newMIS.Order_Expected_Month_Feb__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_Feb__c = PF_Total_price_qouted / 1000;
                    }
                    when 'Mar' {
                        newMIS.Order_Expected_Stage_Mar__c = bli.Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ';
                        newMIS.Order_Expected_Month_Mar__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_Mar__c = PF_Total_price_qouted / 1000;
                    }
                    when 'Apr' {
                        newMIS.Order_Expected_Stage_Apr__c = bli.Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ';
                        newMIS.Order_Expected_Month_Apr__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_April__c = PF_Total_price_qouted / 1000;
                    }
                    when 'May' {
                        newMIS.Order_Expected_Stage_May__c = bli.Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ';
                        newMIS.Order_Expected_Month_May__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_May__c = PF_Total_price_qouted / 1000;
                    }
                    when 'Jun' {
                        newMIS.Order_Expected_Stage_Jun__c = bli.Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ';
                        newMIS.Order_Expected_Month_Jun__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_June__c = PF_Total_price_qouted / 1000;
                    }
                    when 'Jul' {
                        newMIS.Order_Expected_Stage_Jul__c = bli.Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ';
                        newMIS.Order_Expected_Month_Jul__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_Jul__c = PF_Total_price_qouted / 1000;
                    }
                    when 'Aug' {
                        newMIS.Order_Expected_Stage_Aug__c = bli.Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ';
                        newMIS.Order_Expected_Month_Aug__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_Aug__c = PF_Total_price_qouted / 1000;
                    }
                    when 'Sep' {
                        newMIS.Order_Expected_Stage_Sep__c = bli.Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ';
                        newMIS.Order_Expected_Month_Sep__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_Sep__c = PF_Total_price_qouted / 1000;
                    }
                    when 'Oct' {
                        newMIS.Order_Expected_Stage_Oct__c = bli.Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ';
                        newMIS.Order_Expected_Month_Oct__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_Oct__c = PF_Total_price_qouted / 1000;
                    }
                    when 'Nov' {
                        newMIS.Order_Expected_Stage_Nov__c = bli.Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ';
                        newMIS.Order_Expected_Month_Nov__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_Nov__c = PF_Total_price_qouted / 1000;
                    }
                    when 'Dec' {
                        newMIS.Order_Expected_Stage_Dec__c = bli.Order_Type__c != 'C-Conversion' ? 'Offer' : 'Generation of RFQ';
                        newMIS.Order_Expected_Month_Dec__c = formatedcloseDatemonthName;
                        newMIS.Expected_Order_Value_Dec__c = PF_Total_price_qouted / 1000;
                    }
                }
            }
 
            // 5. Decide insert vs update using the maps built above
            MIS_Budget__c existingMIS = misByBudgetLine.get(bliId);
            if (existingMIS != null) {
                newMIS.Id = existingMIS.Id;
                newMIS.Order_Type__c = existingMIS.Order_Type__c;
                updateMisRecord.add(newMIS);
            } else {
                newMIS.Order_Type__c = bli.Order_Type__c;
                newMISRecords.add(newMIS);
            }
        }
 
        // 6. Single DML outside the loop
        if (!updateMisRecord.isEmpty()) {
            update updateMisRecord;
        }
        if (!newMISRecords.isEmpty()) {
            insert newMISRecords;
        }
    }
}