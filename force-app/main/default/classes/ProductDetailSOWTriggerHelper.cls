public class ProductDetailSOWTriggerHelper {
    public ProductDetailSOWTriggerHelper(){}
    
    public void UpdateOnInsertion(List<Product_Proposal_Form__c> newItems){
        try{
        Set<id> LocationIdSet = new Set<Id>();
        for( Product_Proposal_Form__c pds :newItems)
        {
            LocationIdSet.add(pds.Location__c);
            
        }
        system.debug('LocationIdSet =>'+LocationIdSet);
        List<Location__c> locationlist = [Select id , Customer_Equipment__c FROM Location__c where Id IN : LocationIdSet];
        system.debug('locationlist =>'+locationlist);
        
        Map<Id,Id> equipmentlocationMap = new Map<Id,Id>();  
        
        for(Location__c loc : locationlist){
            equipmentlocationMap.put(loc.id , loc.Customer_Equipment__c);
        }
        system.debug('equipmentlocationMap =>'+equipmentlocationMap);
        
        List<string> ListOfRecordtype = new List<string>{
            'Belt_tracker_roller','CeraDisc','Ceramic_Pully_Lagging','Hosch_Scraper',
                'Impact_Pad_Without_Frame_Impact_Bed_System','Skirt_Sealing_System'
                };
                    
                    /*ListOfRecordtype.add('Belt_tracker_roller');
ListOfRecordtype.add('CeraDisc');
ListOfRecordtype.add('Ceramic_Pully_Lagging');
ListOfRecordtype.add('Hosch_Scraper');
ListOfRecordtype.add('Impact_Pad_Without_Frame_Impact_Bed_System');
ListOfRecordtype.add('Skirt_Sealing_System');*/
                    
                    
                    
                    /*List<Product_Installed__c> pilst =[Select ID , Present_Sway__c ,Location__c, Trough_Angle__c , Return_Belt_Condition__c 
from Product_Installed__c where Location__c =: LocationIdSet and
recordType.developername ='Belt_tracker_roller' order by createdDate DESC];*/
                    
                    
                    List<Product_Installed__c> pilst =[Select ID ,recordType.developername, Present_Sway__c ,Location__c, Trough_Angle__c , Return_Belt_Condition__c ,
                                                       Roller_Dia__c,Roller_Length__c,N_of_Rollers__c,Face_Width__c,Dia_of_Pulley__c,
                                                       Type_of_Pulley__c,Crowning_of_Pulley__c,Belt_Run_Back__c ,Any_Special_Paint__c,
                                                       Any_Other_Special_Requirement__c,RecordTypeId,Free_Fall_Height__c,Length_of_Impact_Bed__c,
                                                       Gap_Between_Skirt_and_Belt_Edge__c  from Product_Installed__c where Location__c =: LocationIdSet and
                                                       recordType.developername =: ListOfRecordtype  order by createdDate DESC];
        
        map<String,Product_Installed__c> piRecordTypeMap = new Map<String,Product_Installed__c>();
        map<String,String> protypeAndRecordTypemap = new map<String,string>();
        protypeAndRecordTypemap.put('Belt_tracker_roller','Belt Tracker Roller');
        protypeAndRecordTypemap.put('Hosch_Scraper','Belt Scrapers');
        protypeAndRecordTypemap.put('Skirt_Sealing_System','Side Skirt Sealing'+';'+'Rear Skirt Sealing');
        
        protypeAndRecordTypemap.put('Impact_Pad_Without_Frame_Impact_Bed_System','Impact Pad Without Frame'+';'+'Impact Bed System');
       
        protypeAndRecordTypemap.put('Ceramic_Pully_Lagging','Ceramic Pulley Lagging');
        
        protypeAndRecordTypemap.put('CeraDisc','Ceradisc');
        
        //Belt_tracker_roller','CeraDisc','Ceramic_Pully_Lagging','Hosch_Scraper',
             //   'Impact_Pad_Without_Frame_Impact_Bed_System','Skirt_Sealing_System
        
        for(Product_Installed__c pi : pilst){
            system.debug(pi.recordType.developername);
            if(!piRecordTypeMap.containskey(protypeAndRecordTypemap.get(pi.recordType.developername)+pi.Location__c)){
                system.debug(protypeAndRecordTypemap);
                if(protypeAndRecordTypemap.get(pi.recordType.developername).contains(';')){
                    String MapValues = protypeAndRecordTypemap.get(pi.recordType.developername);
                    System.debug(MapValues);
                    // split basis on ; and insert individual value (product type)   
                    String[] ProdType = MapValues.split(';');
                    for(String p : ProdType)
                    {
                        piRecordTypeMap.put(p+pi.location__c,pi);
                    }
                    
                    //String Prod1 = ProdType[0]; 
                    //String Prod2 = ProdType[1];
                    // System.debug(Prod1);
                    // System.debug(Prod2);
                    //piRecordTypeMap.put(Prod1+pi.location__c,pi);
                    //piRecordTypeMap.put(Prod2+pi.location__c,pi);
                    
                    
                }
                else
                    piRecordTypeMap.put(protypeAndRecordTypemap.get(pi.recordType.developername)+pi.location__c,pi);
            }  
        }
        //recordTypeId developername
        
        system.debug('piRecordTypeMap =>'+piRecordTypeMap);
        
        for(Product_Proposal_Form__c pdsow :newItems){
            system.debug('pdsow =>'+pdsow);
            if(pdsow.Product_Type__c == 'Belt Tracker Roller'){
                pdsow.Trough_Angle_deg__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Trough_Angle__c;
                pdsow.Present_sway__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Present_Sway__c;
                pdsow.Return_Belt_Condition__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Return_Belt_Condition__c;
            }
            else if(pdsow.Product_Type__c =='Belt Scrapers'){
                pdsow.Type_of_Pulley__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Type_of_Pulley__c;
                pdsow.Crowning_of_Pulley__c =piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Crowning_of_Pulley__c;
                pdsow.Belt_Run_Back__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Belt_Run_Back__c;
                pdsow.Any_Special_Paint__c =piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Any_Special_Paint__c;
                pdsow.Any_Other_Special_Requirement__c =piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Any_Other_Special_Requirement__c;
                
            }
            else if(pdsow.Product_Type__c =='Side Skirt Sealing'){
                system.debug('Inside SSS');
                pdsow.Trough_Angle_deg__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Trough_Angle__c;
                pdsow.Gap_Between_Skirt_and_Belt_Edge__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Gap_Between_Skirt_and_Belt_Edge__c;
                system.debug('pdsow.Trough_Angle_deg__c =>'+pdsow.Trough_Angle_deg__c);
                system.debug('pdsow.Gap_Between_Skirt_and_Belt_Edge__c =>'+pdsow.Gap_Between_Skirt_and_Belt_Edge__c);
                
            }
            
            else if(pdsow.Product_Type__c =='Rear Skirt Sealing'){
                pdsow.Trough_Angle_deg__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Trough_Angle__c;
                pdsow.Gap_Between_Skirt_and_Belt_Edge__c =piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Gap_Between_Skirt_and_Belt_Edge__c;
                
                
            }
            else if(pdsow.Product_Type__c =='Impact Pad Without Frame'){
                pdsow.Trough_Angle_deg__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Trough_Angle__c;
                system.debug(pdsow.Trough_Angle_deg__c);
                pdsow.Free_Fall_Height__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Free_Fall_Height__c;
                system.debug(pdsow.Free_Fall_Height__c);
                pdsow.Length_of_Impact_Bed__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Length_of_Impact_Bed__c;
                system.debug(pdsow.Length_of_Impact_Bed__c);
                
            }
            else if(pdsow.Product_Type__c =='Impact Bed System'){
                pdsow.Trough_Angle_deg__c =  piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Trough_Angle__c;
                system.debug(pdsow.Trough_Angle_deg__c);
                pdsow.Free_Fall_Height__c =  piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Free_Fall_Height__c;
                pdsow.Length_of_Impact_Bed__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Length_of_Impact_Bed__c;
                
                
            }
            else if(pdsow.Product_Type__c =='Ceramic Pulley Lagging'){
                pdsow.Face_Width__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Face_Width__c;
                pdsow.Dia_of_Pulley__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Dia_of_Pulley__c;
                
            }
            else if(pdsow.Product_Type__c =='Impact Pad With Frame'){
                pdsow.Trough_Angle_deg__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Trough_Angle__c;
                pdsow.Free_Fall_Height__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Free_Fall_Height__c;
                pdsow.Length_of_Impact_Bed__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Length_of_Impact_Bed__c;
                
            }
            else if(pdsow.Product_Type__c =='Ceradisc'){
                system.debug('Inside CD');
                system.debug('Product_Type__c ===>'+pdsow.Product_Type__c);
                system.debug('location__c ===>'+pdsow.location__c);
                
                pdsow.N_of_Rollers__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).N_of_Rollers__c;
                pdsow.Roller_Dia__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Roller_Dia__c;
                pdsow.Roller_Length__c = piRecordTypeMap.get(pdsow.Product_Type__c+pdsow.location__c).Roller_Length__c;
                
            }
        }
        
        
        
        List<Operating_Parameters__c> listOfOp = [Select Id,Customer_Equipment__c From Operating_Parameters__c Where Customer_Equipment__c
                                                  IN: equipmentlocationMap.values() order by createdDate DESC];
        system.debug('listOfOp =>'+listOfOp);
        
        map<Id,ID> equipmentTOLatestOP = new Map<Id,ID>();
        
        for(Operating_Parameters__c OP : listOfOp){
            if(!equipmentTOLatestOP.containsKey(OP.Customer_Equipment__c))
                equipmentTOLatestOP.put(OP.Customer_Equipment__c, OP.id);
            //here we got latest op of the equipment 
        }
        system.debug('equipmentTOLatestOP =>'+equipmentTOLatestOP);
        
        if(pilst.size() > 0 && pilst[0].Location__c != null){
            for(Product_Proposal_Form__c pdSOW :newItems){
                if(pdsow.Product_Type__c != ''){                    
                    if(pdsow.Location__c == pilst[0].Location__c){
                        system.debug('equipmentlocationMap.get(pdsow.Location__c) =>'+equipmentlocationMap.get(pdsow.Location__c));
                        pdSOW.Operating_Parameters__c = equipmentTOLatestOP.get(equipmentlocationMap.get(pdsow.Location__c));
                        
                        
                    }
                } 
            }
        }
        } catch (Exception e) {
            TegaUtility.trackLogs( e,  'ProductDetailSOWTriggerHelper',  'UpdateOnInsertion');
        }
    }
}